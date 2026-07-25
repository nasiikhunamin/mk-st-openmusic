"""
FastAPI main application module.
Source: https://fastapi.tiangolo.com/advanced/events/
"""

import logging
from contextlib import asynccontextmanager

from fastapi import FastAPI, Request
from fastapi.exceptions import RequestValidationError
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse
from starlette.exceptions import HTTPException as StarletteHTTPException

from app.core.config import get_settings
from app.core.exceptions import AppError, ErrorCode

logger = logging.getLogger(__name__)


@asynccontextmanager
async def lifespan(app: FastAPI):
    """
    Application lifespan manager.
    Handles startup and shutdown events for resources like DB and Redis.
    Source: https://fastapi.tiangolo.com/advanced/events/
    """
    logger.info("Application startup: Initializing resources.")
    # Initialize DB and Redis here in future tasks
    yield
    logger.info("Application shutdown: Cleaning up resources.")
    # Cleanup DB and Redis here in future tasks


settings = get_settings()

app = FastAPI(
    title="OpenMusic API",
    version="0.1.0",
    lifespan=lifespan,
    docs_url="/docs",
    redoc_url=None,
)

# CORS Middleware
app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.cors_origins,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


@app.exception_handler(AppError)
async def app_error_handler(request: Request, exc: AppError):
    """Handles custom AppError exceptions globally."""
    return JSONResponse(
        status_code=exc.status_code,
        content={
            "error": {
                "code": exc.code.value,
                "message": exc.message,
                "details": exc.details,
            }
        },
    )


@app.exception_handler(StarletteHTTPException)
async def http_exception_handler(request: Request, exc: StarletteHTTPException):
    """Overrides default HTTP exceptions to match Error Contract."""
    # Map common status codes to our ErrorCode enum
    code = ErrorCode.INTERNAL_ERROR
    if exc.status_code == 404:
        code = ErrorCode.NOT_FOUND
    elif exc.status_code == 401:
        code = ErrorCode.AUTHENTICATION_ERROR
    elif exc.status_code == 403:
        code = ErrorCode.AUTHORIZATION_ERROR

    return JSONResponse(
        status_code=exc.status_code,
        content={
            "error": {
                "code": code.value,
                "message": str(exc.detail),
                "details": None,
            }
        },
    )


@app.exception_handler(RequestValidationError)
async def validation_exception_handler(request: Request, exc: RequestValidationError):
    """Overrides default validation errors to match Error Contract."""
    return JSONResponse(
        status_code=422,
        content={
            "error": {
                "code": ErrorCode.VALIDATION_ERROR.value,
                "message": "Input validation failed",
                "details": exc.errors(),
            }
        },
    )


@app.get("/api/health")
async def health_check():
    """Health check endpoint."""
    return {"status": "ok"}
