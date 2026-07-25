import math
import uuid

from sqlalchemy import func, select
from sqlalchemy.ext.asyncio import AsyncSession

from app.modules.history.models import History as HistoryModel
from app.modules.history.schemas import HistoryEntry
from app.modules.tracks.schemas import PaginatedResponse, PaginationMeta, Track


class HistoryService:
    async def record(
        self, db: AsyncSession, user_id: uuid.UUID, track_id: str, track_metadata: dict
    ) -> None:
        history = HistoryModel(
            user_id=user_id,
            track_id=track_id,
            track_metadata=track_metadata,
        )
        db.add(history)
        await db.commit()

    async def list_by_user(
        self, db: AsyncSession, user_id: uuid.UUID, page: int = 1, page_size: int = 20
    ) -> PaginatedResponse[HistoryEntry]:
        # Count total items
        count_stmt = select(func.count()).where(HistoryModel.user_id == user_id)
        total = await db.scalar(count_stmt) or 0

        # Get items
        stmt = (
            select(HistoryModel)
            .where(HistoryModel.user_id == user_id)
            .order_by(HistoryModel.played_at.desc())
            .offset((page - 1) * page_size)
            .limit(page_size)
        )
        result = await db.execute(stmt)
        rows = result.scalars().all()

        data = [
            HistoryEntry(
                id=row.id,
                track=Track.model_validate(row.track_metadata),
                played_at=row.played_at,
            )
            for row in rows
        ]
        total_pages = math.ceil(total / page_size) if page_size > 0 else 0

        return PaginatedResponse(
            data=data,
            meta=PaginationMeta(
                total=total, page=page, page_size=page_size, total_pages=total_pages
            ),
        )
