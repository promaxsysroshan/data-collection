from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from typing import Optional
from ..database import get_db
from ..models import User, WalletTransaction, TransactionType
from ..schemas.schemas import WalletTopup
from ..utils.auth import get_current_user, require_admin

router = APIRouter(prefix="/wallet", tags=["Wallet"])


def _txn_dict(t: WalletTransaction) -> dict:
    return {
        "id": str(t.id),
        "amount": t.amount,
        "transaction_type": t.transaction_type.value,
        "description": t.description,
        "balance_after": t.balance_after,
        "created_at": t.created_at.isoformat(),
    }


@router.get("/balance")
def get_balance(current_user: User = Depends(get_current_user)):
    return {"success": True, "data": {"balance": current_user.wallet_balance}}


@router.get("/transactions")
def get_transactions(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    txns = (
        db.query(WalletTransaction)
        .filter(WalletTransaction.user_id == current_user.id)
        .order_by(WalletTransaction.created_at.desc())
        .all()
    )
    return {"success": True, "data": [_txn_dict(t) for t in txns]}


@router.post("/topup")
def topup_wallet(
    payload: WalletTopup,
    db: Session = Depends(get_db),
    current_user: User = Depends(require_admin),
):
    user = db.query(User).filter(User.id == payload.user_id).first()
    if not user:
        raise HTTPException(status_code=404, detail="User not found")
    if payload.amount <= 0:
        raise HTTPException(status_code=400, detail="Amount must be positive")

    user.wallet_balance += payload.amount
    txn = WalletTransaction(
        user_id=user.id,
        amount=payload.amount,
        transaction_type=TransactionType.credit,
        description=payload.description or "Admin top-up",
        balance_after=user.wallet_balance,
    )
    db.add(txn)
    db.commit()
    return {"success": True, "message": f"₹{payload.amount} credited", "data": {"new_balance": user.wallet_balance}}


@router.post("/deduct")
def deduct_wallet(
    payload: WalletTopup,
    db: Session = Depends(get_db),
    current_user: User = Depends(require_admin),
):
    user = db.query(User).filter(User.id == payload.user_id).first()
    if not user:
        raise HTTPException(status_code=404, detail="User not found")
    if payload.amount <= 0:
        raise HTTPException(status_code=400, detail="Amount must be positive")
    if user.wallet_balance < payload.amount:
        raise HTTPException(status_code=400, detail="Insufficient balance")

    user.wallet_balance -= payload.amount
    txn = WalletTransaction(
        user_id=user.id,
        amount=payload.amount,
        transaction_type=TransactionType.debit,
        description=payload.description or "Admin deduction",
        balance_after=user.wallet_balance,
    )
    db.add(txn)
    db.commit()
    return {"success": True, "message": f"₹{payload.amount} deducted", "data": {"new_balance": user.wallet_balance}}
