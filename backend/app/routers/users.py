from fastapi import APIRouter, Depends, HTTPException, UploadFile, File
from sqlalchemy.orm import Session
from typing import List, Optional
import os, uuid, shutil
from ..database import get_db
from ..models import User, UserRole
from ..schemas.schemas import ProfileUpdateRequest
from ..utils.auth import get_current_user, require_admin
from ..config import settings

router = APIRouter(prefix="/users", tags=["Users"])


def _profile_dict(user: User) -> dict:
    return {
        "id": str(user.id),
        "email": user.email,
        "full_name": user.full_name,
        "role": user.role.value,
        "wallet_balance": user.wallet_balance,
        "is_active": user.is_active,
        "created_at": user.created_at.isoformat(),
        "profile_image_url": user.profile_image_url,
        "age": user.age,
        "date_of_birth": user.date_of_birth,
        "gender": user.gender,
        "phone": user.phone,
        "address": user.address,
        "city": user.city,
        "state": user.state,
        "pincode": user.pincode,
        "aadhar_number": user.aadhar_number,
        "pan_number": user.pan_number,
        "bank_name": user.bank_name,
        "bank_account_number": user.bank_account_number,
        "bank_ifsc": user.bank_ifsc,
        "bank_branch": user.bank_branch,
        "upi_id": user.upi_id,
    }


@router.get("")
def list_users(
    role: Optional[str] = None,
    db: Session = Depends(get_db),
    current_user: User = Depends(require_admin),
):
    query = db.query(User)
    if role:
        try:
            r = UserRole(role)
            query = query.filter(User.role == r)
        except ValueError:
            pass
    users = query.all()
    return {
        "success": True,
        "data": [_profile_dict(u) for u in users],
    }


@router.get("/profile")
def get_profile(current_user: User = Depends(get_current_user)):
    return {"success": True, "data": _profile_dict(current_user)}


@router.patch("/profile")
def update_profile(
    payload: ProfileUpdateRequest,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    for field, value in payload.model_dump(exclude_none=True).items():
        setattr(current_user, field, value)
    db.commit()
    db.refresh(current_user)
    return {"success": True, "message": "Profile updated", "data": _profile_dict(current_user)}


@router.post("/profile/image")
async def upload_profile_image(
    file: UploadFile = File(...),
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    allowed = {"image/jpeg", "image/png", "image/webp"}
    if file.content_type not in allowed:
        raise HTTPException(status_code=400, detail="Only JPEG, PNG, WebP images allowed")

    ext = file.filename.rsplit(".", 1)[-1] if "." in file.filename else "jpg"
    filename = f"profile_{current_user.id}.{ext}"
    folder = os.path.join(settings.UPLOAD_DIR, "profiles")
    os.makedirs(folder, exist_ok=True)
    path = os.path.join(folder, filename)

    with open(path, "wb") as f:
        shutil.copyfileobj(file.file, f)

    current_user.profile_image_url = f"/files/profiles/{filename}"
    db.commit()
    return {"success": True, "data": {"url": current_user.profile_image_url}}


@router.get("/{user_id}")
def get_user(
    user_id: str,
    db: Session = Depends(get_db),
    current_user: User = Depends(require_admin),
):
    user = db.query(User).filter(User.id == user_id).first()
    if not user:
        raise HTTPException(status_code=404, detail="User not found")
    return {"success": True, "data": _profile_dict(user)}


@router.patch("/{user_id}/toggle-active")
def toggle_user_active(
    user_id: str,
    db: Session = Depends(get_db),
    current_user: User = Depends(require_admin),
):
    user = db.query(User).filter(User.id == user_id).first()
    if not user:
        raise HTTPException(status_code=404, detail="User not found")
    user.is_active = not user.is_active
    db.commit()
    return {"success": True, "message": f"User {'activated' if user.is_active else 'deactivated'}"}
