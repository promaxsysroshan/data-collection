from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from fastapi.staticfiles import StaticFiles
import os

from .database import engine, Base
from .models import models  # ensure models are imported
from .config import settings

from .routers import (
    auth_router,
    users_router,
    tasks_router,
    submissions_router,
    wallet_router,
    dashboard_router,
    files_router,
)
from .utils.auth import hash_password

# ------------------ DATABASE ------------------

Base.metadata.create_all(bind=engine)

# ------------------ CREATE DIRECTORIES ------------------

BASE_DIR = os.path.dirname(os.path.abspath(__file__))
UPLOAD_DIR = os.path.join(BASE_DIR, "uploads")

os.makedirs(os.path.join(UPLOAD_DIR, "profiles"), exist_ok=True)
os.makedirs(os.path.join(UPLOAD_DIR, "submissions"), exist_ok=True)

# ------------------ APP INIT ------------------

app = FastAPI(
    title="Audio Dataset System API",
    description="Backend API for Audio Dataset Collection Platform",
    version="2.0.0",
)

# ------------------ CORS ------------------

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # ⚠ change in production
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# ------------------ STATIC FILES (IMPORTANT) ------------------

app.mount("/uploads", StaticFiles(directory=UPLOAD_DIR), name="uploads")

# ------------------ ROUTERS ------------------

app.include_router(auth_router)          # /auth/login
app.include_router(users_router)         # /users
app.include_router(tasks_router)         # /tasks
app.include_router(submissions_router)   # /submissions
app.include_router(wallet_router)        # /wallet
app.include_router(dashboard_router)     # /dashboard
app.include_router(files_router)         # /files

# ------------------ ROOT ------------------

@app.get("/")
def root():
    return {
        "message": "Audio Dataset System API",
        "version": "2.0.0",
        "status": "running",
    }

# ------------------ STARTUP ------------------

@app.on_event("startup")
def seed_default_admin():
    """Create default admin if not exists."""
    from .database import SessionLocal
    from .models.models import User, UserRole

    db = SessionLocal()

    try:
        existing = db.query(User).filter(User.email == "admin@example.com").first()

        if not existing:
            admin = User(
                email="admin@example.com",
                hashed_password=hash_password("admin123"),
                full_name="System Admin",
                role=UserRole.admin,
                wallet_balance=10000.0,
            )

            level1 = User(
                email="level1@example.com",
                hashed_password=hash_password("level1123"),
                full_name="Demo Level1 User",
                role=UserRole.level1,
                wallet_balance=0.0,
            )

            db.add(admin)
            db.add(level1)
            db.commit()

            print("✅ Default users created")
            print("ADMIN: admin@example.com / admin123")
            print("LEVEL1: level1@example.com / level1123")

    except Exception as e:
        print(f"⚠ Seed error: {e}")
        db.rollback()

    finally:
        db.close()