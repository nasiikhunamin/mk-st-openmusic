from fastapi import APIRouter, Depends, Query
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.dependencies import get_db
from app.modules.auth.dependencies import get_current_user
from app.modules.auth.models import User
from app.modules.history.dependencies import get_history_service
from app.modules.history.schemas import HistoryEntry
from app.modules.history.service import HistoryService
from app.modules.tracks.schemas import PaginatedResponse

history_router = APIRouter()


@history_router.get(
    "",
    response_model=PaginatedResponse[HistoryEntry],
)
async def list_history(
    page: int = Query(1, ge=1),
    pageSize: int = Query(20, ge=1, le=100),
    current_user: User = Depends(get_current_user),
    history_service: HistoryService = Depends(get_history_service),
    db: AsyncSession = Depends(get_db),
):
    return await history_service.list_by_user(db, current_user.id, page, pageSize)
