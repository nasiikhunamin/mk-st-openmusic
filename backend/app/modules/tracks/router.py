from fastapi import APIRouter, Depends, Query

from app.modules.auth.dependencies import get_current_user
from app.modules.auth.models import User
from app.modules.tracks.dependencies import get_track_service
from app.modules.tracks.schemas import PaginatedResponse, Track
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
):
    return await track_service.get_stream_url(track_id)
