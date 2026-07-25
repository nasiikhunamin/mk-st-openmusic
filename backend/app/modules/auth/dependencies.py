import uuid

from fastapi import Depends, Header
from jose import JWTError
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.config import Settings, get_settings
from app.core.dependencies import get_db
from app.core.exceptions import AppError, ErrorCode
from app.core.security import decode_access_token
from app.modules.auth.models import User


async def get_current_user(
    authorization: str | None = Header(default=None),
    db: AsyncSession = Depends(get_db),
    settings: Settings = Depends(get_settings),
) -> User:
    if not authorization or not authorization.startswith("Bearer "):
        raise AppError(ErrorCode.AUTHENTICATION_ERROR, "Token tidak ditemukan", 401)
    
    token = authorization.split(" ")[1]
    
    try:
        payload = decode_access_token(token, settings.secret_key)
        user_id: str | None = payload.get("sub")
        if user_id is None:
            raise AppError(ErrorCode.AUTHENTICATION_ERROR, "Token tidak valid", 401)
    except JWTError:
        raise AppError(ErrorCode.AUTHENTICATION_ERROR, "Token tidak valid atau kadaluarsa", 401)
        
    try:
        uid = uuid.UUID(user_id)
    except ValueError:
        raise AppError(ErrorCode.AUTHENTICATION_ERROR, "Token tidak valid", 401)
        
    user = await db.scalar(select(User).where(User.id == uid))
    if not user:
        raise AppError(ErrorCode.AUTHENTICATION_ERROR, "User tidak ditemukan", 401)
        
    return user
