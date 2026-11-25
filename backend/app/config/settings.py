import os
from dotenv import load_dotenv

load_dotenv()


class Config:
    FLASK_DEBUG = os.getenv(
        "FLASK_DEBUG", "false"
    ).lower() in {"true", "1", "yes", "on"}

    FRONTEND_ORIGIN = os.getenv(
        "FRONTEND_ORIGIN",
        "http://localhost:3000"
    )

    SUPABASE_URL = os.getenv("SUPABASE_URL")
    SUPABASE_PUBLISHABLE_KEY = os.getenv(
        "SUPABASE_PUBLISHABLE_KEY"
    )
    SUPABASE_SECRET_KEY = os.getenv("SUPABASE_SECRET_KEY")

    SUPABASE_STORAGE_BUCKET = os.getenv(
        "SUPABASE_STORAGE_BUCKET",
        "travel-photos"
    )

    MAX_CONTENT_LENGTH = int(
        os.getenv("MAX_CONTENT_LENGTH", 10 * 1024 * 1024)
    )

    MAX_PHOTOS_PER_UPLOAD = int(
        os.getenv("MAX_PHOTOS_PER_UPLOAD", 30)
    )

    ALLOWED_EXTENSIONS = {"jpg", "jpeg", "png", "webp"}