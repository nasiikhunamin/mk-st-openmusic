from fastapi import APIRouter, Depends, Query
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.dependencies import get_db
from app.modules.auth.dependencies import get_current_user
from app.modules.auth.models import User
from app.modules.history.dependencies import get_history_service
from app.modules.history.service import HistoryService
from app.modules.tracks.dependencies import get_track_service
from app.modules.tracks.schemas import PaginatedResponse, Track, TrackLyrics
from app.modules.tracks.service import TrackService

tracks_router = APIRouter()


@tracks_router.get(
    "",
    response_model=PaginatedResponse[Track],
)
async def search_tracks(
    q: str = Query(..., min_length=1),
    page: int = Query(1, ge=1),
    pageSize: int = Query(20, ge=1, le=100),
    current_user: User = Depends(get_current_user),
    track_service: TrackService = Depends(get_track_service),
):
    return await track_service.search(query=q, page=page, page_size=pageSize)


@tracks_router.get(
    "/{track_id}",
    response_model=Track,
)
async def get_track(
    track_id: str,
    current_user: User = Depends(get_current_user),
    track_service: TrackService = Depends(get_track_service),
):
    return await track_service.get_detail(track_id)


@tracks_router.get(
    "/{track_id}/stream",
)
async def get_track_stream(
    track_id: str,
    current_user: User = Depends(get_current_user),
    track_service: TrackService = Depends(get_track_service),
    history_service: HistoryService = Depends(get_history_service),
    db: AsyncSession = Depends(get_db),
):
    track = await track_service.get_detail(track_id)
    
    await history_service.record(
        db=db,
        user_id=current_user.id,
        track_id=track.id,
        track_metadata=track.model_dump(),
    )
    
    return {"audio_url": track.audio_url}

@tracks_router.get(
    "/{track_id}/similar",
    response_model=PaginatedResponse[Track],
)
async def get_similar_tracks(
    track_id: str,
    limit: int = Query(10, ge=1, le=50),
    current_user: User = Depends(get_current_user),
    track_service: TrackService = Depends(get_track_service),
):
    return await track_service.get_similar(track_id, limit)

@tracks_router.get(
    "/{track_id}/lyrics",
    response_model=TrackLyrics,
)
async def get_track_lyrics(
    track_id: str,
    current_user: User = Depends(get_current_user),
    track_service: TrackService = Depends(get_track_service),
):
    return await track_service.get_lyrics(track_id)
