"""
FastAPI main application module.
Source: https://fastapi.tiangolo.com/advanced/events/
"""

import logging
from contextlib import asynccontextmanager

import redis
from fastapi import FastAPI, Request
from fastapi.exceptions import RequestValidationError
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse
from sqlalchemy import text
from sqlalchemy.exc import SQLAlchemyError
from starlette.exceptions import HTTPException as StarletteHTTPException

from app.api.v1.router import api_router
from app.core.config import get_settings
from app.core.exceptions import AppError, ErrorCode
from app.db import session as db_session
from app.services.cache import cache_service

logger = logging.getLogger(__name__)


@asynccontextmanager
async def lifespan(app: FastAPI):
    """
    Application lifespan manager.
    Handles startup and shutdown events for resources like DB and Redis.
    Source: https://fastapi.tiangolo.com/advanced/events/
    """
    logger.info("Application startup: Initializing resources.")
    db_session.init_db()
    # If redis URL is configured, we could set use_redis=True here or in config
    if settings.redis_url:
        cache_service.use_redis = True
    await cache_service.connect()

    yield

    logger.info("Application shutdown: Cleaning up resources.")
    await cache_service.disconnect()
    await db_session.close_db()


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

# Include Main API Router
app.include_router(api_router)


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
    db_status = "disconnected"
    redis_status = "disconnected"

    # Check DB
    if db_session.engine is not None:
        try:
            async with db_session.engine.connect() as conn:
                await conn.execute(text("SELECT 1"))
            db_status = "connected"
        except SQLAlchemyError as e:
            logger.error(f"Database health check failed: {e}")

    # Check Redis
    if cache_service.use_redis and cache_service.redis_client is not None:
        try:
            await cache_service.redis_client.ping()
            redis_status = "connected"
        except redis.exceptions.RedisError as e:
            logger.error(f"Redis health check failed: {e}")
    elif not cache_service.use_redis:
        # In-memory fallback
        redis_status = "connected (in-memory)"

    return {"status": "ok", "db": db_status, "redis": redis_status}
