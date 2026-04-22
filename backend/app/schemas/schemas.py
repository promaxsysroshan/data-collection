from pydantic import BaseModel, EmailStr, Field
from typing import Optional, List
from datetime import datetime
from uuid import UUID


# ─── Auth ────────────────────────────────────────────────────────────────────

class LoginRequest(BaseModel):
    email: str
    password: str

class SignupRequest(BaseModel):
    email: EmailStr
    password: str = Field(min_length=6)
    full_name: str
    role: str = "level1"

class TokenResponse(BaseModel):
    access_token: str
    token_type: str = "bearer"


# ─── User / Profile ───────────────────────────────────────────────────────────

class UserBase(BaseModel):
    id: UUID
    email: str
    full_name: str
    role: str
    wallet_balance: float
    is_active: bool
    created_at: datetime
    profile_image_url: Optional[str] = None

    class Config:
        from_attributes = True

class UserProfile(UserBase):
    age: Optional[int] = None
    date_of_birth: Optional[str] = None
    gender: Optional[str] = None
    phone: Optional[str] = None
    address: Optional[str] = None
    city: Optional[str] = None
    state: Optional[str] = None
    pincode: Optional[str] = None
    aadhar_number: Optional[str] = None
    pan_number: Optional[str] = None
    bank_name: Optional[str] = None
    bank_account_number: Optional[str] = None
    bank_ifsc: Optional[str] = None
    bank_branch: Optional[str] = None
    upi_id: Optional[str] = None

class ProfileUpdateRequest(BaseModel):
    full_name: Optional[str] = None
    age: Optional[int] = None
    date_of_birth: Optional[str] = None
    gender: Optional[str] = None
    phone: Optional[str] = None
    address: Optional[str] = None
    city: Optional[str] = None
    state: Optional[str] = None
    pincode: Optional[str] = None
    aadhar_number: Optional[str] = None
    pan_number: Optional[str] = None
    bank_name: Optional[str] = None
    bank_account_number: Optional[str] = None
    bank_ifsc: Optional[str] = None
    bank_branch: Optional[str] = None
    upi_id: Optional[str] = None


# ─── Task ─────────────────────────────────────────────────────────────────────

class TaskCreate(BaseModel):
    title: str
    description: Optional[str] = None
    instructions: Optional[str] = None
    assigned_to_id: Optional[str] = None
    priority: str = "medium"
    due_date: Optional[datetime] = None
    payment_amount: float = 0.0

class TaskUpdate(BaseModel):
    title: Optional[str] = None
    description: Optional[str] = None
    instructions: Optional[str] = None
    assigned_to_id: Optional[str] = None
    priority: Optional[str] = None
    due_date: Optional[datetime] = None
    payment_amount: Optional[float] = None
    status: Optional[str] = None

class TaskResponse(BaseModel):
    id: UUID
    title: str
    description: Optional[str]
    instructions: Optional[str]
    status: str
    priority: str
    due_date: Optional[datetime]
    payment_amount: float
    created_at: datetime
    updated_at: datetime
    assigned_to_id: Optional[UUID]
    created_by_id: UUID
    assignee_name: Optional[str] = None
    creator_name: Optional[str] = None
    submission_count: int = 0

    class Config:
        from_attributes = True


# ─── Submission ───────────────────────────────────────────────────────────────

class SubmissionFileResponse(BaseModel):
    id: UUID
    filename: str
    original_filename: str
    file_size: int
    mime_type: Optional[str]
    created_at: datetime

    class Config:
        from_attributes = True

class SubmissionResponse(BaseModel):
    id: UUID
    task_id: UUID
    user_id: UUID
    status: str
    notes: Optional[str]
    admin_remarks: Optional[str]
    created_at: datetime
    updated_at: datetime
    files: List[SubmissionFileResponse] = []
    task_title: Optional[str] = None
    user_name: Optional[str] = None

    class Config:
        from_attributes = True

class SubmissionReview(BaseModel):
    status: str  # approved / rejected
    admin_remarks: Optional[str] = None


# ─── Wallet ───────────────────────────────────────────────────────────────────

class WalletTransactionResponse(BaseModel):
    id: UUID
    amount: float
    transaction_type: str
    description: Optional[str]
    balance_after: float
    created_at: datetime

    class Config:
        from_attributes = True

class WalletTopup(BaseModel):
    user_id: str
    amount: float
    description: Optional[str] = "Admin top-up"


# ─── Dashboard ────────────────────────────────────────────────────────────────

class AdminDashboard(BaseModel):
    total_users: int
    total_tasks: int
    pending_tasks: int
    completed_tasks: int
    pending_submissions: int
    approved_submissions: int
    rejected_submissions: int
    total_wallet_disbursed: float

class Level1Dashboard(BaseModel):
    total_tasks: int
    pending_tasks: int
    in_progress_tasks: int
    completed_tasks: int
    total_submissions: int
    approved_submissions: int
    rejected_submissions: int
    wallet_balance: float


# ─── Common ───────────────────────────────────────────────────────────────────

class ApiResponse(BaseModel):
    success: bool
    message: str
    data: Optional[dict] = None
