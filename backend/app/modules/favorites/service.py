import math
import uuid

from sqlalchemy import func, select
from sqlalchemy.exc import IntegrityError
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.exceptions import AppError, ErrorCode
from app.modules.favorites.models import Favorite as FavoriteModel
from app.modules.favorites.schemas import AddFavoriteInput
from app.modules.tracks.schemas import PaginatedResponse, PaginationMeta, Track


class FavoriteService:
    async def add(
        self, db: AsyncSession, user_id: uuid.UUID, input_data: AddFavoriteInput
    ) -> None:
        favorite = FavoriteModel(
            user_id=user_id,
            track_id=input_data.track_id,
            track_metadata=input_data.track_metadata,
        )
        db.add(favorite)
        try:
            await db.commit()
        except IntegrityError:
            await db.rollback()
            raise AppError(ErrorCode.CONFLICT, "Lagu sudah ada di daftar favorit", 409)

    async def list_by_user(
        self, db: AsyncSession, user_id: uuid.UUID, page: int = 1, page_size: int = 20
    ) -> PaginatedResponse[Track]:
        # Count total items
        count_stmt = select(func.count()).where(FavoriteModel.user_id == user_id)
        total = await db.scalar(count_stmt) or 0

        # Get items
        stmt = (
            select(FavoriteModel)
            .where(FavoriteModel.user_id == user_id)
            .order_by(FavoriteModel.added_at.desc())
            .offset((page - 1) * page_size)
            .limit(page_size)
        )
        result = await db.execute(stmt)
        rows = result.scalars().all()

        data = [Track.model_validate(row.track_metadata) for row in rows]
        total_pages = math.ceil(total / page_size) if page_size > 0 else 0

        return PaginatedResponse(
            data=data,
            meta=PaginationMeta(
                total=total, page=page, page_size=page_size, total_pages=total_pages
            ),
        )

    async def remove(
        self, db: AsyncSession, user_id: uuid.UUID, track_id: str
    ) -> None:
        stmt = select(FavoriteModel).where(
            FavoriteModel.user_id == user_id, FavoriteModel.track_id == track_id
        )
        result = await db.execute(stmt)
        favorite = result.scalar_one_or_none()

        if not favorite:
            raise AppError(
                ErrorCode.NOT_FOUND, "Lagu tidak ditemukan di daftar favorit", 404
            )

        await db.delete(favorite)
        await db.commit()
