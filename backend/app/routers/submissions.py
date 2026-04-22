from fastapi import APIRouter, Depends, HTTPException, UploadFile, File, Form
from fastapi.responses import FileResponse
from sqlalchemy.orm import Session
from typing import List, Optional
import os, uuid
from datetime import datetime
import subprocess

from ..database import get_db
from ..models import (
    User, Task, Submission, SubmissionFile,
    SubmissionStatus, TaskStatus,
    WalletTransaction, TransactionType
)
from ..schemas.schemas import SubmissionReview
from ..utils.auth import get_current_user, require_admin
from ..config import settings

import subprocess
import os

def convert_video(input_path):
    base, ext = os.path.splitext(input_path)
    output_path = base + "_converted.mp4"

    command = [
        "ffmpeg",
        "-i", input_path,
        "-c:v", "libx264",
        "-preset", "fast",
        "-movflags", "+faststart",
        "-c:a", "aac",
        "-y",
        output_path
    ]

    subprocess.run(command, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)

    return output_path

router = APIRouter(prefix="/submissions", tags=["Submissions"])

# ------------------ HELPERS ------------------

def _file_dict(f: SubmissionFile) -> dict:
    return {
        "id": str(f.id),
        "filename": f.filename,
        "original_filename": f.original_filename,
        "file_path": f.file_path,
        "file_size": f.file_size,
        "mime_type": f.mime_type,
        "created_at": f.created_at.isoformat(),
        "submission_id": str(f.submission_id),
        # Provide a public URL path so the Flutter app can reference files
        "file_url": f"/uploads/submissions/{f.submission_id}/{f.filename}",
    }

def _submission_dict(s: Submission) -> dict:
    return {
        "id": str(s.id),
        "task_id": str(s.task_id),
        "user_id": str(s.user_id),
        "status": s.status.value,
        "notes": s.notes,
        "admin_remarks": s.admin_remarks,
        "created_at": s.created_at.isoformat(),
        "updated_at": s.updated_at.isoformat(),
        "files": [_file_dict(f) for f in s.files],
        "task_title": s.task.title if s.task else None,
        "user_name": s.user.full_name if s.user else None,
        "user_email": s.user.email if s.user else None,
    }

# ------------------ GET ALL (ADMIN sees all, Level1 sees own) ------------------
@router.get("")
def list_submissions(
    task_id: Optional[str] = None,
    status: Optional[str] = None,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    query = db.query(Submission)

    # Level1 → only their own submissions
    # Admin → sees ALL submissions
    if current_user.role.value == "level1":
        query = query.filter(Submission.user_id == current_user.id)

    if task_id:
        query = query.filter(Submission.task_id == task_id)

    if status:
        try:
            query = query.filter(Submission.status == SubmissionStatus(status))
        except ValueError:
            pass  # ignore invalid status filter

    submissions = query.order_by(Submission.created_at.desc()).all()

    return {
        "success": True,
        "data": [_submission_dict(s) for s in submissions],
        "total": len(submissions),
    }

# ------------------ CREATE (Level1 submits) ------------------
@router.post("")
async def create_submission(
    task_id: str = Form(...),
    notes: Optional[str] = Form(None),
    files: List[UploadFile] = File(default=[]),
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    # Fetch the task
    task = db.query(Task).filter(Task.id == task_id).first()
    if not task:
        raise HTTPException(status_code=404, detail="Task not found")

    # Check task is assigned to this user (compare as strings)
    if task.assigned_to_id is None or str(task.assigned_to_id) != str(current_user.id):
        raise HTTPException(status_code=403, detail="This task is not assigned to you")

    # Block if task is already approved
    if task.status == TaskStatus.approved:
        raise HTTPException(status_code=400, detail="Task already approved — cannot submit again")

    # Block duplicate submission if task is already submitted/pending review
    if task.status == TaskStatus.submitted:
        # Check if there's already a pending submission for this task by this user
        existing = db.query(Submission).filter(
            Submission.task_id == task_id,
            Submission.user_id == current_user.id,
            Submission.status == SubmissionStatus.pending
        ).first()
        if existing:
            raise HTTPException(
                status_code=400,
                detail="You have already submitted this task and it is pending review. Please wait for admin feedback."
            )

    # Create the submission record
    submission = Submission(
        task_id=task_id,
        user_id=current_user.id,
        notes=notes,
        status=SubmissionStatus.pending,
    )

    db.add(submission)
    db.flush()  # get submission.id before saving files

    upload_folder = os.path.join(
        settings.UPLOAD_DIR, "submissions", str(submission.id)
    )
    os.makedirs(upload_folder, exist_ok=True)

    saved_files = []
    for upload in files:
     if not upload.filename:
        continue

    content = await upload.read()

    max_bytes = settings.MAX_FILE_SIZE_MB * 1024 * 1024
    if len(content) > max_bytes:
        db.rollback()
        raise HTTPException(
            status_code=413,
            detail=f"File '{upload.filename}' exceeds {settings.MAX_FILE_SIZE_MB}MB limit"
        )

    ext = upload.filename.rsplit(".", 1)[-1] if "." in upload.filename else "bin"
    new_name = f"{uuid.uuid4()}.{ext}"
    save_path = os.path.join(upload_folder, new_name)

    # ✅ SAVE FILE
    with open(save_path, "wb") as f:
        f.write(content)

    # ✅ CONVERSION (CORRECTLY INSIDE LOOP)
    if save_path.lower().endswith((".mp4", ".mov", ".avi", ".mkv")):
        try:
            converted_path = convert_video(save_path)

            os.remove(save_path)

            save_path = converted_path
            new_name = os.path.basename(converted_path)

        except Exception as e:
            print("Video conversion failed:", e)

    # ✅ SAVE TO DB (INSIDE LOOP)
    sub_file = SubmissionFile(
        submission_id=submission.id,
        filename=new_name,
        original_filename=upload.filename,
        file_path=save_path,
        file_size=len(content),
        mime_type=upload.content_type,
    )

    db.add(sub_file)
    saved_files.append(upload.filename)

    # Update task status to submitted so admin can see it
    task.status = TaskStatus.submitted
    task.updated_at = datetime.utcnow()

    # Commit everything — submission + files + task status update
    db.commit()
    db.refresh(submission)

    return {
        "success": True,
        "message": f"Submission created successfully with {len(saved_files)} file(s)",
        "data": _submission_dict(submission),
    }

# ------------------ GET ONE ------------------
@router.get("/{submission_id}")
def get_submission(
    submission_id: str,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    s = db.query(Submission).filter(Submission.id == submission_id).first()

    if not s:
        raise HTTPException(status_code=404, detail="Submission not found")

    if current_user.role.value == "level1" and str(s.user_id) != str(current_user.id):
        raise HTTPException(status_code=403, detail="Access denied")

    return {"success": True, "data": _submission_dict(s)}

# ------------------ REVIEW (Admin approves/rejects) ------------------
@router.patch("/{submission_id}/review")
def review_submission(
    submission_id: str,
    payload: SubmissionReview,
    db: Session = Depends(get_db),
    current_user: User = Depends(require_admin),
):
    s = db.query(Submission).filter(Submission.id == submission_id).first()

    if not s:
        raise HTTPException(status_code=404, detail="Submission not found")

    if s.status != SubmissionStatus.pending:
        raise HTTPException(
            status_code=400,
            detail=f"Submission is already {s.status.value}. Cannot re-review."
        )

    if payload.status == "approved":
        s.status = SubmissionStatus.approved
        s.task.status = TaskStatus.approved

        submitter = db.query(User).filter(User.id == s.user_id).first()

        if submitter and s.task.payment_amount > 0:
            submitter.wallet_balance += s.task.payment_amount

            txn = WalletTransaction(
                user_id=submitter.id,
                amount=s.task.payment_amount,
                transaction_type=TransactionType.credit,
                description=f"Payment for task: {s.task.title}",
                reference_id=str(s.id),
                balance_after=submitter.wallet_balance,
            )
            db.add(txn)

    elif payload.status == "rejected":
        s.status = SubmissionStatus.rejected
        # Allow task to be restarted after rejection so user can resubmit
        s.task.status = TaskStatus.in_progress

    else:
        raise HTTPException(
            status_code=400,
            detail="Status must be 'approved' or 'rejected'"
        )

    s.admin_remarks = payload.admin_remarks
    s.updated_at = datetime.utcnow()

    db.commit()
    db.refresh(s)

    return {
        "success": True,
        "message": f"Submission {payload.status}",
        "data": _submission_dict(s),
    }

# ------------------ DOWNLOAD FILE (Admin or owner) ------------------
@router.get("/{submission_id}/files/{file_id}/download")
def download_file(
    submission_id: str,
    file_id: str,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    """Download a specific submission file."""
    s = db.query(Submission).filter(Submission.id == submission_id).first()
    if not s:
        raise HTTPException(status_code=404, detail="Submission not found")

    if current_user.role.value == "level1" and str(s.user_id) != str(current_user.id):
        raise HTTPException(status_code=403, detail="Access denied")

    file_record = db.query(SubmissionFile).filter(
        SubmissionFile.id == file_id,
        SubmissionFile.submission_id == s.id
    ).first()

    if not file_record:
        raise HTTPException(status_code=404, detail="File not found")

    if not os.path.exists(file_record.file_path):
        raise HTTPException(status_code=404, detail="File not found on disk")

    return FileResponse(
        path=file_record.file_path,
        filename=file_record.original_filename,
        media_type=file_record.mime_type or "application/octet-stream",
    )


# ------------------ DELETE SUBMISSION (Admin only) ------------------
@router.delete("/{submission_id}")
def delete_submission(
    submission_id: str,
    db: Session = Depends(get_db),
    current_user: User = Depends(require_admin),
):
    """Admin can delete any submission and its files from disk."""
    import shutil

    s = db.query(Submission).filter(Submission.id == submission_id).first()
    if not s:
        raise HTTPException(status_code=404, detail="Submission not found")

    # Reset task status back to in_progress so user can resubmit
    if s.task:
        s.task.status = TaskStatus.in_progress
        s.task.updated_at = datetime.utcnow()

    # Delete physical files from disk
    upload_folder = os.path.join(settings.UPLOAD_DIR, "submissions", str(s.id))
    if os.path.exists(upload_folder):
        shutil.rmtree(upload_folder, ignore_errors=True)

    db.delete(s)
    db.commit()

    return {"success": True, "message": "Submission deleted successfully"}
