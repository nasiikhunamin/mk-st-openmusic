import uuid

from fastapi import APIRouter, Depends, Query, status
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.dependencies import get_db
from app.modules.auth.dependencies import get_current_user
from app.modules.auth.models import User
from app.modules.playlists.dependencies import get_playlist_service
from app.modules.playlists.schemas import (
    AddTrackToPlaylistInput,
    CreatePlaylistInput,
    Playlist,
    PlaylistDetail,
    UpdatePlaylistInput,
)
from app.modules.playlists.service import PlaylistService
from app.modules.tracks.schemas import PaginatedResponse

playlists_router = APIRouter()


@playlists_router.post(
    "",
    response_model=Playlist,
    status_code=status.HTTP_201_CREATED,
)
async def create_playlist(
    input_data: CreatePlaylistInput,
    current_user: User = Depends(get_current_user),
    playlist_service: PlaylistService = Depends(get_playlist_service),
    db: AsyncSession = Depends(get_db),
):
    return await playlist_service.create(db, current_user.id, input_data)


@playlists_router.get(
    "",
    response_model=PaginatedResponse[Playlist],
)
async def list_playlists(
    page: int = Query(1, ge=1),
    pageSize: int = Query(20, ge=1, le=100),
    current_user: User = Depends(get_current_user),
    playlist_service: PlaylistService = Depends(get_playlist_service),
    db: AsyncSession = Depends(get_db),
):
    return await playlist_service.list_by_user(db, current_user.id, page, pageSize)


@playlists_router.get(
    "/{playlist_id}",
    response_model=PlaylistDetail,
)
async def get_playlist(
    playlist_id: uuid.UUID,
    current_user: User = Depends(get_current_user),
    playlist_service: PlaylistService = Depends(get_playlist_service),
    db: AsyncSession = Depends(get_db),
):
    return await playlist_service.get_detail(db, current_user.id, playlist_id)


@playlists_router.patch(
    "/{playlist_id}",
    response_model=Playlist,
)
async def update_playlist(
    playlist_id: uuid.UUID,
    input_data: UpdatePlaylistInput,
    current_user: User = Depends(get_current_user),
    playlist_service: PlaylistService = Depends(get_playlist_service),
    db: AsyncSession = Depends(get_db),
):
    return await playlist_service.update(db, current_user.id, playlist_id, input_data)


@playlists_router.delete(
    "/{playlist_id}",
    status_code=status.HTTP_204_NO_CONTENT,
)
async def delete_playlist(
    playlist_id: uuid.UUID,
    current_user: User = Depends(get_current_user),
    playlist_service: PlaylistService = Depends(get_playlist_service),
    db: AsyncSession = Depends(get_db),
):
    await playlist_service.delete(db, current_user.id, playlist_id)


@playlists_router.post(
    "/{playlist_id}/tracks",
    status_code=status.HTTP_204_NO_CONTENT,
)
async def add_track(
    playlist_id: uuid.UUID,
    input_data: AddTrackToPlaylistInput,
    current_user: User = Depends(get_current_user),
    playlist_service: PlaylistService = Depends(get_playlist_service),
    db: AsyncSession = Depends(get_db),
):
    await playlist_service.add_track(db, current_user.id, playlist_id, input_data)


@playlists_router.delete(
    "/{playlist_id}/tracks/{track_id}",
    status_code=status.HTTP_204_NO_CONTENT,
)
async def remove_track(
    playlist_id: uuid.UUID,
    track_id: str,
    current_user: User = Depends(get_current_user),
    playlist_service: PlaylistService = Depends(get_playlist_service),
    db: AsyncSession = Depends(get_db),
):
    await playlist_service.remove_track(db, current_user.id, playlist_id, track_id)
