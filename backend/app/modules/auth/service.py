import uuid
from datetime import datetime, timedelta, timezone

from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.config import get_settings
from app.core.exceptions import AppError, ErrorCode
from app.core.security import (
    create_access_token,
    create_refresh_token,
    hash_password,
    hash_token,
    verify_password,
)
from app.modules.auth.models import RefreshToken, User
from app.modules.auth.schemas import (
    AuthTokens,
    LoginInput,
    RegisterInput,
    UserProfile,
)

settings = get_settings()


class AuthService:
    async def _create_token_pair(
        self, db: AsyncSession, user_id: uuid.UUID
    ) -> AuthTokens:
        # Create access token
        access_token_expires = timedelta(minutes=settings.access_token_expire_minutes)
        access_token = create_access_token(
            subject=str(user_id),
            expires_delta=access_token_expires,
            secret_key=settings.secret_key,
        )

        # Create refresh token
        refresh_token_plain = create_refresh_token()
        refresh_token_expires = datetime.now(timezone.utc) + timedelta(
            days=settings.refresh_token_expire_days
        )

        # Store hashed refresh token in DB
        db_refresh_token = RefreshToken(
            user_id=user_id,
            token_hash=hash_token(refresh_token_plain),
            expires_at=refresh_token_expires,
        )
        db.add(db_refresh_token)

        return AuthTokens(
            access_token=access_token,
            refresh_token=refresh_token_plain,
            token_type="bearer",
            expires_in=settings.access_token_expire_minutes * 60,
        )

    async def register(self, db: AsyncSession, input_data: RegisterInput) -> AuthTokens:
        # Cek duplicate email
        existing_email = await db.scalar(
            select(User).where(User.email == input_data.email)
        )
        if existing_email:
            raise AppError(ErrorCode.CONFLICT, "Email sudah terdaftar", 409)

        # Cek duplicate username
        existing_username = await db.scalar(
            select(User).where(User.username == input_data.username)
        )
        if existing_username:
            raise AppError(ErrorCode.CONFLICT, "Username sudah terdaftar", 409)

        # Buat user
        user = User(
            username=input_data.username,
            email=input_data.email,
            password_hash=hash_password(input_data.password),
        )
        db.add(user)
        await db.flush()

        # Buat token pair
        tokens = await self._create_token_pair(db, user.id)
        await db.commit()
        return tokens

    async def login(self, db: AsyncSession, input_data: LoginInput) -> AuthTokens:
        user = await db.scalar(select(User).where(User.email == input_data.email))
        if not user or not verify_password(input_data.password, user.password_hash):
            raise AppError(
                ErrorCode.AUTHENTICATION_ERROR, "Email atau password salah", 401
            )

        tokens = await self._create_token_pair(db, user.id)
        await db.commit()
        return tokens

    async def refresh(self, db: AsyncSession, refresh_token: str) -> AuthTokens:
        token_hash_value = hash_token(refresh_token)
        # Cari token di DB
        db_token = await db.scalar(
            select(RefreshToken).where(RefreshToken.token_hash == token_hash_value)
        )

        if not db_token:
            raise AppError(
                ErrorCode.AUTHENTICATION_ERROR, "Refresh token tidak valid", 401
            )

        if db_token.revoked_at is not None:
            raise AppError(
                ErrorCode.AUTHENTICATION_ERROR, "Refresh token sudah dicabut", 401
            )

        expires_at = db_token.expires_at
        if expires_at.tzinfo is None:
            expires_at = expires_at.replace(tzinfo=timezone.utc)

        if expires_at < datetime.now(timezone.utc):
            raise AppError(
                ErrorCode.AUTHENTICATION_ERROR, "Refresh token sudah kadaluarsa", 401
            )

        user_id = db_token.user_id

        # Token rotation: hapus token lama (atau revoke)
        await db.delete(db_token)
        await db.flush()

        # Buat token pair baru
        tokens = await self._create_token_pair(db, user_id)
        await db.commit()
        return tokens

    async def logout(self, db: AsyncSession, refresh_token: str) -> None:
        token_hash_value = hash_token(refresh_token)
        db_token = await db.scalar(
            select(RefreshToken).where(RefreshToken.token_hash == token_hash_value)
        )
        if db_token:
            db_token.revoked_at = datetime.now(timezone.utc)
            await db.commit()

    async def get_profile(self, db: AsyncSession, user_id: str) -> UserProfile:
        try:
            uid = uuid.UUID(user_id)
        except ValueError:
            raise AppError(ErrorCode.NOT_FOUND, "User tidak ditemukan", 404)

        user = await db.scalar(select(User).where(User.id == uid))
        if not user:
            raise AppError(ErrorCode.NOT_FOUND, "User tidak ditemukan", 404)

        return UserProfile(
            id=str(user.id),
            username=user.username,
            email=user.email,
            created_at=user.created_at,
        )


auth_service = AuthService()
