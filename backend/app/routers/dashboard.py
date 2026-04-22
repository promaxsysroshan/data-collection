from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session
from sqlalchemy import func
from ..database import get_db
from ..models import User, Task, Submission, WalletTransaction, TaskStatus, SubmissionStatus, TransactionType, UserRole
from ..utils.auth import get_current_user, require_admin

router = APIRouter(prefix="/dashboard", tags=["Dashboard"])


@router.get("/admin")
def admin_dashboard(
    db: Session = Depends(get_db),
    current_user: User = Depends(require_admin),
):
    total_users = db.query(User).filter(User.role == UserRole.level1).count()
    total_tasks = db.query(Task).count()
    pending_tasks = db.query(Task).filter(Task.status == TaskStatus.pending).count()
    in_progress_tasks = db.query(Task).filter(Task.status == TaskStatus.in_progress).count()
    submitted_tasks = db.query(Task).filter(Task.status == TaskStatus.submitted).count()
    approved_tasks = db.query(Task).filter(Task.status == TaskStatus.approved).count()
    rejected_tasks = db.query(Task).filter(Task.status == TaskStatus.rejected).count()

    pending_subs = db.query(Submission).filter(Submission.status == SubmissionStatus.pending).count()
    approved_subs = db.query(Submission).filter(Submission.status == SubmissionStatus.approved).count()
    rejected_subs = db.query(Submission).filter(Submission.status == SubmissionStatus.rejected).count()

    disbursed = db.query(func.sum(WalletTransaction.amount)).filter(
        WalletTransaction.transaction_type == TransactionType.credit
    ).scalar() or 0.0

    recent_submissions = db.query(Submission).order_by(Submission.created_at.desc()).limit(5).all()
    recent_tasks = db.query(Task).order_by(Task.created_at.desc()).limit(5).all()

    return {
        "success": True,
        "data": {
            "total_users": total_users,
            "total_tasks": total_tasks,
            "pending_tasks": pending_tasks,
            "in_progress_tasks": in_progress_tasks,
            "submitted_tasks": submitted_tasks,
            "approved_tasks": approved_tasks,
            "rejected_tasks": rejected_tasks,
            "pending_submissions": pending_subs,
            "approved_submissions": approved_subs,
            "rejected_submissions": rejected_subs,
            "total_wallet_disbursed": float(disbursed),
            "recent_submissions": [
                {
                    "id": str(s.id),
                    "task_title": s.task.title if s.task else "",
                    "user_name": s.user.full_name if s.user else "",
                    "status": s.status.value,
                    "created_at": s.created_at.isoformat(),
                }
                for s in recent_submissions
            ],
            "recent_tasks": [
                {
                    "id": str(t.id),
                    "title": t.title,
                    "status": t.status.value,
                    "assignee_name": t.assignee.full_name if t.assignee else None,
                    "created_at": t.created_at.isoformat(),
                }
                for t in recent_tasks
            ],
        },
    }


@router.get("/l1")
def level1_dashboard(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    uid = current_user.id
    total_tasks = db.query(Task).filter(Task.assigned_to_id == uid).count()
    pending_tasks = db.query(Task).filter(Task.assigned_to_id == uid, Task.status == TaskStatus.pending).count()
    in_progress = db.query(Task).filter(Task.assigned_to_id == uid, Task.status == TaskStatus.in_progress).count()
    submitted = db.query(Task).filter(Task.assigned_to_id == uid, Task.status == TaskStatus.submitted).count()
    approved_tasks = db.query(Task).filter(Task.assigned_to_id == uid, Task.status == TaskStatus.approved).count()
    rejected_tasks = db.query(Task).filter(Task.assigned_to_id == uid, Task.status == TaskStatus.rejected).count()

    total_subs = db.query(Submission).filter(Submission.user_id == uid).count()
    approved_subs = db.query(Submission).filter(Submission.user_id == uid, Submission.status == SubmissionStatus.approved).count()
    rejected_subs = db.query(Submission).filter(Submission.user_id == uid, Submission.status == SubmissionStatus.rejected).count()
    pending_subs = db.query(Submission).filter(Submission.user_id == uid, Submission.status == SubmissionStatus.pending).count()

    recent_tasks = db.query(Task).filter(Task.assigned_to_id == uid).order_by(Task.created_at.desc()).limit(5).all()

    return {
        "success": True,
        "data": {
            "total_tasks": total_tasks,
            "pending_tasks": pending_tasks,
            "in_progress_tasks": in_progress,
            "submitted_tasks": submitted,
            "approved_tasks": approved_tasks,
            "rejected_tasks": rejected_tasks,
            "total_submissions": total_subs,
            "approved_submissions": approved_subs,
            "rejected_submissions": rejected_subs,
            "pending_submissions": pending_subs,
            "wallet_balance": current_user.wallet_balance,
            "recent_tasks": [
                {
                    "id": str(t.id),
                    "title": t.title,
                    "status": t.status.value,
                    "priority": t.priority,
                    "due_date": t.due_date.isoformat() if t.due_date else None,
                    "payment_amount": t.payment_amount,
                }
                for t in recent_tasks
            ],
        },
    }
