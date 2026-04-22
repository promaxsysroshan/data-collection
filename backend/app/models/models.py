import uuid
from datetime import datetime
from sqlalchemy import Column, String, Integer, Boolean, Float, DateTime, ForeignKey, Text, Enum as SAEnum
from sqlalchemy.orm import relationship
from sqlalchemy.dialects.postgresql import UUID

from app.database import Base

import enum


class UserRole(str, enum.Enum):
    admin = "admin"
    level1 = "level1"


class TaskStatus(str, enum.Enum):
    pending = "pending"
    in_progress = "in_progress"
    submitted = "submitted"
    approved = "approved"
    rejected = "rejected"


class SubmissionStatus(str, enum.Enum):
    pending = "pending"
    approved = "approved"
    rejected = "rejected"


class TransactionType(str, enum.Enum):
    credit = "credit"
    debit = "debit"


class User(Base):
    __tablename__ = "users"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    email = Column(String(255), unique=True, nullable=False, index=True)
    hashed_password = Column(String(255), nullable=False)
    full_name = Column(String(255), nullable=False)
    role = Column(SAEnum(UserRole), nullable=False, default=UserRole.level1)
    is_active = Column(Boolean, default=True)
    wallet_balance = Column(Float, default=0.0)
    created_at = Column(DateTime, default=datetime.utcnow)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)

    # Profile fields
    age = Column(Integer, nullable=True)
    date_of_birth = Column(String(20), nullable=True)
    gender = Column(String(20), nullable=True)
    phone = Column(String(20), nullable=True)
    address = Column(Text, nullable=True)
    city = Column(String(100), nullable=True)
    state = Column(String(100), nullable=True)
    pincode = Column(String(10), nullable=True)
    aadhar_number = Column(String(20), nullable=True)
    pan_number = Column(String(20), nullable=True)
    profile_image_url = Column(String(500), nullable=True)

    # Bank details
    bank_name = Column(String(100), nullable=True)
    bank_account_number = Column(String(50), nullable=True)
    bank_ifsc = Column(String(20), nullable=True)
    bank_branch = Column(String(100), nullable=True)
    upi_id = Column(String(100), nullable=True)

    # Relationships
    assigned_tasks = relationship("Task", foreign_keys="Task.assigned_to_id", back_populates="assignee")
    created_tasks = relationship("Task", foreign_keys="Task.created_by_id", back_populates="creator")
    submissions = relationship("Submission", back_populates="user")
    wallet_transactions = relationship("WalletTransaction", back_populates="user")


class Task(Base):
    __tablename__ = "tasks"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    title = Column(String(255), nullable=False)
    description = Column(Text, nullable=True)
    instructions = Column(Text, nullable=True)
    status = Column(SAEnum(TaskStatus), default=TaskStatus.pending)
    priority = Column(String(20), default="medium")
    due_date = Column(DateTime, nullable=True)
    payment_amount = Column(Float, default=0.0)
    created_at = Column(DateTime, default=datetime.utcnow)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)

    assigned_to_id = Column(UUID(as_uuid=True), ForeignKey("users.id"), nullable=True)
    created_by_id = Column(UUID(as_uuid=True), ForeignKey("users.id"), nullable=False)

    assignee = relationship("User", foreign_keys=[assigned_to_id], back_populates="assigned_tasks")
    creator = relationship("User", foreign_keys=[created_by_id], back_populates="created_tasks")
    submissions = relationship("Submission", back_populates="task")


class Submission(Base):
    __tablename__ = "submissions"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    task_id = Column(UUID(as_uuid=True), ForeignKey("tasks.id"), nullable=False)
    user_id = Column(UUID(as_uuid=True), ForeignKey("users.id"), nullable=False)
    status = Column(SAEnum(SubmissionStatus), default=SubmissionStatus.pending)
    notes = Column(Text, nullable=True)
    admin_remarks = Column(Text, nullable=True)
    created_at = Column(DateTime, default=datetime.utcnow)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)

    task = relationship("Task", back_populates="submissions")
    user = relationship("User", back_populates="submissions")
    files = relationship("SubmissionFile", back_populates="submission", cascade="all, delete-orphan")


class SubmissionFile(Base):
    __tablename__ = "submission_files"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    submission_id = Column(UUID(as_uuid=True), ForeignKey("submissions.id"), nullable=False)
    filename = Column(String(500), nullable=False)
    original_filename = Column(String(500), nullable=False)
    file_path = Column(String(1000), nullable=False)
    file_size = Column(Integer, default=0)
    mime_type = Column(String(200), nullable=True)
    created_at = Column(DateTime, default=datetime.utcnow)

    submission = relationship("Submission", back_populates="files")


class WalletTransaction(Base):
    __tablename__ = "wallet_transactions"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    user_id = Column(UUID(as_uuid=True), ForeignKey("users.id"), nullable=False)
    amount = Column(Float, nullable=False)
    transaction_type = Column(SAEnum(TransactionType), nullable=False)
    description = Column(String(500), nullable=True)
    reference_id = Column(String(255), nullable=True)
    balance_after = Column(Float, nullable=False)
    created_at = Column(DateTime, default=datetime.utcnow)

    user = relationship("User", back_populates="wallet_transactions")