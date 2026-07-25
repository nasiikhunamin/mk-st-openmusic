from datetime import datetime
from uuid import UUID

from pydantic import BaseModel, ConfigDict, Field

from app.modules.tracks.schemas import Track


class CreatePlaylistInput(BaseModel):
    name: str = Field(..., min_length=1, max_length=100)


class UpdatePlaylistInput(BaseModel):
    name: str | None = Field(None, min_length=1, max_length=100)


class AddTrackToPlaylistInput(BaseModel):
    track_id: str
    track_metadata: dict


class Playlist(BaseModel):
    id: UUID
    name: str
    track_count: int = 0
    created_at: datetime
    updated_at: datetime

    model_config = ConfigDict(from_attributes=True)


class PlaylistDetail(Playlist):
    tracks: list[Track] = []
