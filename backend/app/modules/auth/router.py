from fastapi import APIRouter, Depends, status
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.dependencies import get_db
from app.modules.auth.dependencies import get_current_user
from app.modules.auth.models import User
from app.modules.auth.schemas import (
    AuthTokens,
    LoginInput,
    RefreshInput,
    RegisterInput,
    UserProfile,
)
from app.modules.auth.service import auth_service

auth_router = APIRouter()


@auth_router.post(
    "/register",
    response_model=AuthTokens,
    status_code=status.HTTP_201_CREATED,
)
async def register(
    input_data: RegisterInput,
    db: AsyncSession = Depends(get_db),
):
    return await auth_service.register(db, input_data)


@auth_router.post(
    "/login",
    response_model=AuthTokens,
)
async def login(
    input_data: LoginInput,
    db: AsyncSession = Depends(get_db),
):
    return await auth_service.login(db, input_data)


@auth_router.post(
    "/refresh",
    response_model=AuthTokens,
)
async def refresh(
    input_data: RefreshInput,
    db: AsyncSession = Depends(get_db),
):
    return await auth_service.refresh(db, input_data.refresh_token)


@auth_router.post(
    "/logout",
    status_code=status.HTTP_200_OK,
)
async def logout(
    input_data: RefreshInput,
    db: AsyncSession = Depends(get_db),
):
    await auth_service.logout(db, input_data.refresh_token)
    return {"message": "Berhasil logout"}


@auth_router.get(
    "/me",
    response_model=UserProfile,
)
async def get_me(
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    return await auth_service.get_profile(db, str(current_user.id))
