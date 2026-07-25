from enum import Enum
from typing import Any


class ErrorCode(str, Enum):
    """
    Error codes as defined in PRD-openmusic.md section 4.3 (Error Contract).
    """
    VALIDATION_ERROR = "VALIDATION_ERROR"
    AUTHENTICATION_ERROR = "AUTHENTICATION_ERROR"
    AUTHORIZATION_ERROR = "AUTHORIZATION_ERROR"
    NOT_FOUND = "NOT_FOUND"
    CONFLICT = "CONFLICT"
    RATE_LIMIT_EXCEEDED = "RATE_LIMIT_EXCEEDED"
    INTERNAL_ERROR = "INTERNAL_ERROR"
    EXTERNAL_API_ERROR = "EXTERNAL_API_ERROR"


class AppError(Exception):
    """
    Base application exception.
    Handled by the global exception handler in main.py to enforce the Error Contract.
    """

    def __init__(
        self,
        code: ErrorCode,
        message: str,
        status_code: int,
        details: Any = None,
    ):
        self.code = code
        self.message = message
        self.status_code = status_code
        self.details = details
