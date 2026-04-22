from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from typing import Optional
from datetime import datetime
from ..database import get_db
from ..models import User, Task, TaskStatus
from ..schemas.schemas import TaskCreate, TaskUpdate
from ..utils.auth import get_current_user, require_admin

router = APIRouter(prefix="/tasks", tags=["Tasks"])


def _task_dict(task: Task) -> dict:
    return {
        "id": str(task.id),
        "title": task.title,
        "description": task.description,
        "instructions": task.instructions,
        "status": task.status.value,
        "priority": task.priority,
        "due_date": task.due_date.isoformat() if task.due_date else None,
        "payment_amount": task.payment_amount,
        "created_at": task.created_at.isoformat(),
        "updated_at": task.updated_at.isoformat(),
        "assigned_to_id": str(task.assigned_to_id) if task.assigned_to_id else None,
        "created_by_id": str(task.created_by_id),
        "assignee_name": task.assignee.full_name if task.assignee else None,
        "creator_name": task.creator.full_name if task.creator else None,
        "submission_count": len(task.submissions),
    }


@router.get("")
def list_tasks(
    status: Optional[str] = None,
    assigned_to: Optional[str] = None,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    query = db.query(Task)

    if current_user.role.value == "level1":
        query = query.filter(Task.assigned_to_id == current_user.id)
    else:
        if assigned_to:
            query = query.filter(Task.assigned_to_id == assigned_to)

    if status:
        try:
            s = TaskStatus(status)
            query = query.filter(Task.status == s)
        except ValueError:
            pass

    tasks = query.order_by(Task.created_at.desc()).all()
    return {"success": True, "data": [_task_dict(t) for t in tasks]}


@router.post("")
def create_task(
    payload: TaskCreate,
    db: Session = Depends(get_db),
    current_user: User = Depends(require_admin),
):
    task = Task(
        title=payload.title,
        description=payload.description,
        instructions=payload.instructions,
        priority=payload.priority,
        due_date=payload.due_date,
        payment_amount=payload.payment_amount,
        created_by_id=current_user.id,
        assigned_to_id=payload.assigned_to_id,
        status=TaskStatus.pending,
    )
    db.add(task)
    db.commit()
    db.refresh(task)
    return {"success": True, "message": "Task created", "data": _task_dict(task)}


@router.get("/{task_id}")
def get_task(
    task_id: str,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    task = db.query(Task).filter(Task.id == task_id).first()
    if not task:
        raise HTTPException(status_code=404, detail="Task not found")
    if current_user.role.value == "level1" and str(task.assigned_to_id) != str(current_user.id):
        raise HTTPException(status_code=403, detail="Access denied")
    return {"success": True, "data": _task_dict(task)}


@router.patch("/{task_id}")
def update_task(
    task_id: str,
    payload: TaskUpdate,
    db: Session = Depends(get_db),
    current_user: User = Depends(require_admin),
):
    task = db.query(Task).filter(Task.id == task_id).first()
    if not task:
        raise HTTPException(status_code=404, detail="Task not found")

    for field, value in payload.model_dump(exclude_none=True).items():
        if field == "status":
            task.status = TaskStatus(value)
        else:
            setattr(task, field, value)

    task.updated_at = datetime.utcnow()
    db.commit()
    db.refresh(task)
    return {"success": True, "message": "Task updated", "data": _task_dict(task)}


@router.delete("/{task_id}")
def delete_task(
    task_id: str,
    db: Session = Depends(get_db),
    current_user: User = Depends(require_admin),
):
    task = db.query(Task).filter(Task.id == task_id).first()
    if not task:
        raise HTTPException(status_code=404, detail="Task not found")
    db.delete(task)
    db.commit()
    return {"success": True, "message": "Task deleted"}


@router.patch("/{task_id}/start")
def start_task(
    task_id: str,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    task = db.query(Task).filter(Task.id == task_id).first()
    if not task:
        raise HTTPException(status_code=404, detail="Task not found")
    if str(task.assigned_to_id) != str(current_user.id):
        raise HTTPException(status_code=403, detail="Not assigned to you")
    if task.status != TaskStatus.pending:
        raise HTTPException(status_code=400, detail="Task cannot be started")
    task.status = TaskStatus.in_progress
    task.updated_at = datetime.utcnow()
    db.commit()
    return {"success": True, "message": "Task started"}
