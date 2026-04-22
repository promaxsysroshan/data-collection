from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from ..database import get_db
from ..models import User, UserRole
from ..schemas.schemas import LoginRequest, SignupRequest, UserBase, UserProfile
from ..utils.auth import hash_password, verify_password, create_access_token, get_current_user

router = APIRouter(prefix="/auth", tags=["Auth"])


def _user_to_dict(user: User) -> dict:
    return {
        "id": str(user.id),
        "email": user.email,
        "full_name": user.full_name,
        "role": user.role.value,
        "wallet_balance": user.wallet_balance,
        "is_active": user.is_active,
        "created_at": user.created_at.isoformat(),
        "profile_image_url": user.profile_image_url,
    }


@router.post("/login")
def login(payload: LoginRequest, db: Session = Depends(get_db)):
    user = db.query(User).filter(User.email == payload.email.lower()).first()
    if not user or not verify_password(payload.password, user.hashed_password):
        raise HTTPException(status_code=401, detail="Invalid email or password")
    if not user.is_active:
        raise HTTPException(status_code=403, detail="Account is deactivated")

    token = create_access_token({"sub": str(user.id), "role": user.role.value})
    return {
        "success": True,
        "message": "Login successful",
        "data": {
            "access_token": token,
            "token_type": "bearer",
            "user": _user_to_dict(user),
        },
    }


@router.post("/signup")
def signup(payload: SignupRequest, db: Session = Depends(get_db)):
    existing = db.query(User).filter(User.email == payload.email.lower()).first()
    if existing:
        raise HTTPException(status_code=400, detail="Email already registered")

    role = UserRole.level1
    if payload.role == "admin":
        role = UserRole.admin

    user = User(
        email=payload.email.lower(),
        hashed_password=hash_password(payload.password),
        full_name=payload.full_name,
        role=role,
    )
    db.add(user)
    db.commit()
    db.refresh(user)

    token = create_access_token({"sub": str(user.id), "role": user.role.value})
    return {
        "success": True,
        "message": "Account created successfully",
        "data": {
            "access_token": token,
            "token_type": "bearer",
            "user": _user_to_dict(user),
        },
    }


@router.get("/me")
def get_me(current_user: User = Depends(get_current_user)):
    return {
        "success": True,
        "data": {
            "id": str(current_user.id),
            "email": current_user.email,
            "full_name": current_user.full_name,
            "role": current_user.role.value,
            "wallet_balance": current_user.wallet_balance,
            "is_active": current_user.is_active,
            "created_at": current_user.created_at.isoformat(),
            "age": current_user.age,
            "date_of_birth": current_user.date_of_birth,
            "gender": current_user.gender,
            "phone": current_user.phone,
            "address": current_user.address,
            "city": current_user.city,
            "state": current_user.state,
            "pincode": current_user.pincode,
            "aadhar_number": current_user.aadhar_number,
            "pan_number": current_user.pan_number,
            "bank_name": current_user.bank_name,
            "bank_account_number": current_user.bank_account_number,
            "bank_ifsc": current_user.bank_ifsc,
            "bank_branch": current_user.bank_branch,
            "upi_id": current_user.upi_id,
            "profile_image_url": current_user.profile_image_url,
        },
    }
