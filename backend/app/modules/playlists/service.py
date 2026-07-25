import math
import uuid

from sqlalchemy import func, select
from sqlalchemy.exc import IntegrityError
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.exceptions import AppError, ErrorCode
from app.modules.playlists.models import Playlist as PlaylistModel
from app.modules.playlists.models import PlaylistTrack as PlaylistTrackModel
from app.modules.playlists.schemas import (
    AddTrackToPlaylistInput,
    CreatePlaylistInput,
    Playlist,
    PlaylistDetail,
    UpdatePlaylistInput,
)
from app.modules.tracks.schemas import PaginatedResponse, PaginationMeta, Track


class PlaylistService:
    async def create(self, db: AsyncSession, user_id: uuid.UUID, input_data: CreatePlaylistInput) -> Playlist:
        new_playlist = PlaylistModel(user_id=user_id, name=input_data.name)
        db.add(new_playlist)
        await db.commit()
        await db.refresh(new_playlist)

        return Playlist(
            id=new_playlist.id,
            name=new_playlist.name,
            track_count=0,
            created_at=new_playlist.created_at,
            updated_at=new_playlist.updated_at,
        )

    async def _get_playlist(self, db: AsyncSession, user_id: uuid.UUID, playlist_id: uuid.UUID) -> PlaylistModel:
        stmt = select(PlaylistModel).where(PlaylistModel.id == playlist_id)
        result = await db.execute(stmt)
        playlist = result.scalar_one_or_none()

        if not playlist:
            raise AppError(ErrorCode.NOT_FOUND, "Playlist tidak ditemukan", 404)
        if playlist.user_id != user_id:
            raise AppError(ErrorCode.AUTHORIZATION_ERROR, "Anda tidak memiliki akses ke playlist ini", 403)

        return playlist

    async def list_by_user(
        self, db: AsyncSession, user_id: uuid.UUID, page: int = 1, page_size: int = 20
    ) -> PaginatedResponse[Playlist]:
        # Count total items
        count_stmt = select(func.count()).where(PlaylistModel.user_id == user_id)
        total = await db.scalar(count_stmt) or 0

        # Get items with track count
        stmt = (
            select(PlaylistModel, func.count(PlaylistTrackModel.id).label("track_count"))
            .outerjoin(PlaylistTrackModel, PlaylistModel.id == PlaylistTrackModel.playlist_id)
            .where(PlaylistModel.user_id == user_id)
            .group_by(PlaylistModel.id)
            .order_by(PlaylistModel.created_at.desc())
            .offset((page - 1) * page_size)
            .limit(page_size)
        )

        result = await db.execute(stmt)
        rows = result.all()

        data = [
            Playlist(
                id=row.Playlist.id,
                name=row.Playlist.name,
                track_count=row.track_count,
                created_at=row.Playlist.created_at,
                updated_at=row.Playlist.updated_at,
            )
            for row in rows
        ]

        total_pages = math.ceil(total / page_size) if page_size > 0 else 0

        return PaginatedResponse(
            data=data,
            meta=PaginationMeta(total=total, page=page, page_size=page_size, total_pages=total_pages),
        )

    async def get_detail(self, db: AsyncSession, user_id: uuid.UUID, playlist_id: uuid.UUID) -> PlaylistDetail:
        playlist = await self._get_playlist(db, user_id, playlist_id)

        # Get tracks
        stmt = (
            select(PlaylistTrackModel)
            .where(PlaylistTrackModel.playlist_id == playlist_id)
            .order_by(PlaylistTrackModel.position.asc(), PlaylistTrackModel.added_at.desc())
        )
        result = await db.execute(stmt)
        playlist_tracks = result.scalars().all()

        tracks = [Track.model_validate(pt.track_metadata) for pt in playlist_tracks]

        return PlaylistDetail(
            id=playlist.id,
            name=playlist.name,
            track_count=len(tracks),
            created_at=playlist.created_at,
            updated_at=playlist.updated_at,
            tracks=tracks,
        )

    async def update(
        self, db: AsyncSession, user_id: uuid.UUID, playlist_id: uuid.UUID, input_data: UpdatePlaylistInput
    ) -> Playlist:
        playlist = await self._get_playlist(db, user_id, playlist_id)

        if input_data.name is not None:
            playlist.name = input_data.name

        await db.commit()
        await db.refresh(playlist)

        # Get track count to return
        count_stmt = select(func.count()).where(PlaylistTrackModel.playlist_id == playlist_id)
        track_count = await db.scalar(count_stmt) or 0

        return Playlist(
            id=playlist.id,
            name=playlist.name,
            track_count=track_count,
            created_at=playlist.created_at,
            updated_at=playlist.updated_at,
        )

    async def delete(self, db: AsyncSession, user_id: uuid.UUID, playlist_id: uuid.UUID) -> None:
        playlist = await self._get_playlist(db, user_id, playlist_id)
        await db.delete(playlist)
        await db.commit()

    async def add_track(
        self, db: AsyncSession, user_id: uuid.UUID, playlist_id: uuid.UUID, input_data: AddTrackToPlaylistInput
    ) -> None:
        # Validate ownership
        await self._get_playlist(db, user_id, playlist_id)

        # Get current max position
        max_pos_stmt = select(func.max(PlaylistTrackModel.position)).where(
            PlaylistTrackModel.playlist_id == playlist_id
        )
        max_pos = await db.scalar(max_pos_stmt) or 0

        new_track = PlaylistTrackModel(
            playlist_id=playlist_id,
            track_id=input_data.track_id,
            track_metadata=input_data.track_metadata,
            position=max_pos + 1,
        )

        db.add(new_track)
        try:
            await db.commit()
        except IntegrityError:
            await db.rollback()
            raise AppError(ErrorCode.CONFLICT, "Lagu sudah ada di playlist ini", 409)

    async def remove_track(self, db: AsyncSession, user_id: uuid.UUID, playlist_id: uuid.UUID, track_id: str) -> None:
        # Validate ownership
        await self._get_playlist(db, user_id, playlist_id)

        stmt = select(PlaylistTrackModel).where(
            PlaylistTrackModel.playlist_id == playlist_id, PlaylistTrackModel.track_id == track_id
        )
        result = await db.execute(stmt)
        track = result.scalar_one_or_none()

        if not track:
            raise AppError(ErrorCode.NOT_FOUND, "Lagu tidak ditemukan di playlist ini", 404)

        await db.delete(track)
        await db.commit()
