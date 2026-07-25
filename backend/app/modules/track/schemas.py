from typing import Optional
from pydantic import BaseModel


class Track(BaseModel):
    id: str
    title: str
    artist: str
    album: Optional[str] = None
    cover_url: Optional[str] = None
    audio_url: str
    duration: int
    source: str = "jamendo"
