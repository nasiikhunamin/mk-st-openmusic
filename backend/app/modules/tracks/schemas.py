from typing import Generic, TypeVar

from pydantic import BaseModel

T = TypeVar("T")

class Track(BaseModel):
    id: str
    title: str
    artist: str
    album: str | None = None
    cover_url: str | None = None
    audio_url: str | None = None
    duration: int | None = None
    source: str = "jamendo"

class PaginationMeta(BaseModel):
    total: int
    page: int
    page_size: int
    total_pages: int

class PaginatedResponse(BaseModel, Generic[T]):
    data: list[T]
    meta: PaginationMeta


class TrackLyrics(BaseModel):
    plain_lyrics: str | None = None
    synced_lyrics: str | None = None
