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
ALLOWED_EXTENSIONS = [".pdf", ".txt", ".docx", ".doc"]
MAX_FILE_SIZE_MB = 200
MAX_FILE_SIZE_BYTES = MAX_FILE_SIZE_MB * 1024 * 1024

# Excludes only dangerous characters like path separators and control characters
ALLOWED_FILENAME_PATTERN = r'^[^/\\<>:"|?*\x00-\x1f]+$'

def sanitize_filename(filename: str) -> str:
    """
    Remove path traversal but preserve the original filename.
    """
    # Only remove path traversal, but keep the original filename
    return os.path.basename(filename)

def is_allowed_filetype(mime_type: str, extension: str) -> bool:
    return mime_type in ALLOWED_MIME_TYPES and extension.lower() in ALLOWED_EXTENSIONS

def is_file_size_valid(size: int) -> bool:
    return size <= MAX_FILE_SIZE_BYTES

def is_filename_valid(filename: str) -> bool:
    """
    Check if filename contains only safe characters.
    Excludes path separators, reserved characters, and control characters.
    Allows spaces, parentheses, and other common filename characters.
    Returns True if valid, False otherwise.
    """
    # Get the basename to strip any potential path components
    basename = os.path.basename(filename)
    
    # Check if filename is not empty after stripping whitespace
    if not basename.strip():
        return False
    
    # Check against dangerous characters pattern
    if not re.match(ALLOWED_FILENAME_PATTERN, basename):
        return False
    
    # Additional check: filename should not be only dots (., .., etc.)
    if basename.strip('.') == '':
        return False
    
    return True
