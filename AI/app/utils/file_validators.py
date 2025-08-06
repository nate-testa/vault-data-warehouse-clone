import os
import re
from typing import List

ALLOWED_MIME_TYPES = [
    "application/pdf",
    "text/plain",
    "application/vnd.openxmlformats-officedocument.wordprocessingml.document",
    "application/msword",
    "image/png",
    "image/jpeg",
]
ALLOWED_EXTENSIONS = [".pdf", ".txt", ".docx", ".doc", ".png", ".jpg", ".jpeg"]
MAX_FILE_SIZE_MB = 200
MAX_FILE_SIZE_BYTES = MAX_FILE_SIZE_MB * 1024 * 1024

def sanitize_filename(filename: str) -> str:
    """
    Remove path traversal, dangerous characters, and normalize filename.
    """
    filename = os.path.basename(filename)
    filename = re.sub(r'[^A-Za-z0-9._-]', '_', filename)
    return filename

def is_allowed_filetype(mime_type: str, extension: str) -> bool:
    return mime_type in ALLOWED_MIME_TYPES and extension.lower() in ALLOWED_EXTENSIONS

def is_file_size_valid(size: int) -> bool:
    return size <= MAX_FILE_SIZE_BYTES
