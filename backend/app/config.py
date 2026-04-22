from pydantic_settings import BaseSettings
from typing import Optional
import os

class Settings(BaseSettings):
    DATABASE_URL: str = "postgresql://postgres:admin123@localhost:5432/datacollect"
    SECRET_KEY: str = "change-me-in-production-use-a-long-random-string-here-32-chars"
    ALGORITHM: str = "HS256"
    ACCESS_TOKEN_EXPIRE_MINUTES: int = 10080  # 7 days
    UPLOAD_DIR: str = os.path.join(os.path.dirname(__file__), "uploads")
    MAX_FILE_SIZE_MB: int = 500

    class Config:
        env_file = ".env"

settings = Settings()

