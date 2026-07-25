from fastapi import APIRouter, Depends, Query, status
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.dependencies import get_db
from app.modules.auth.dependencies import get_current_user
from app.modules.auth.models import User
from app.modules.favorites.dependencies import get_favorite_service
from app.modules.favorites.schemas import AddFavoriteInput
from app.modules.favorites.service import FavoriteService
from app.modules.tracks.schemas import PaginatedResponse, Track


favorites_router = APIRouter()


@favorites_router.post(
    "",
    status_code=status.HTTP_201_CREATED,
)
async def add_favorite(
    input_data: AddFavoriteInput,
    current_user: User = Depends(get_current_user),
    favorite_service: FavoriteService = Depends(get_favorite_service),
    db: AsyncSession = Depends(get_db),
):
    await favorite_service.add(db, current_user.id, input_data)


@favorites_router.get(
    "",
    response_model=PaginatedResponse[Track],
)
async def list_favorites(
    page: int = Query(1, ge=1),
    pageSize: int = Query(20, ge=1, le=100),
    current_user: User = Depends(get_current_user),
    favorite_service: FavoriteService = Depends(get_favorite_service),
    db: AsyncSession = Depends(get_db),
):
    return await favorite_service.list_by_user(db, current_user.id, page, pageSize)


@favorites_router.delete(
    "/{track_id}",
    status_code=status.HTTP_204_NO_CONTENT,
)
async def remove_favorite(
    track_id: str,
    current_user: User = Depends(get_current_user),
    favorite_service: FavoriteService = Depends(get_favorite_service),
    db: AsyncSession = Depends(get_db),
):
    await favorite_service.remove(db, current_user.id, track_id)
