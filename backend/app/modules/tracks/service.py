import math

from app.core.exceptions import AppError, ErrorCode
from app.modules.tracks.schemas import (
    PaginatedResponse,
    PaginationMeta,
    Track,
    TrackLyrics,
)
from app.services.jamendo import JamendoClient
from app.services.lastfm import LastfmClient
from app.services.lrclib import LrclibClient


class TrackService:
    def __init__(self, jamendo_client: JamendoClient, lastfm_client: LastfmClient = None, lrclib_client: LrclibClient = None):
        self.jamendo = jamendo_client
        self.lastfm = lastfm_client
        self.lrclib = lrclib_client

    async def search(
        self, query: str, page: int = 1, page_size: int = 20
    ) -> PaginatedResponse[Track]:
        tracks, total = await self.jamendo.search(query, page, page_size)

        total_pages = math.ceil(total / page_size) if page_size > 0 else 0

        meta = PaginationMeta(
            total=total,
            page=page,
            page_size=page_size,
            total_pages=total_pages,
        )
        return PaginatedResponse(data=tracks, meta=meta)

    async def get_detail(self, track_id: str) -> Track:
        return await self.jamendo.get_track(track_id)

    async def get_stream_url(self, track_id: str) -> dict:
        url = await self.jamendo.get_stream_url(track_id)
        if not url:
            raise AppError(
                ErrorCode.NOT_FOUND, "Stream URL tidak ditemukan untuk track ini", 404
            )
        return {"audio_url": url}

    async def get_similar(self, track_id: str, limit: int = 10) -> PaginatedResponse[Track]:
        track = await self.get_detail(track_id)
        
        similar_tracks = []
        if self.lastfm:
            similar_tracks = await self.lastfm.get_similar_tracks(
                artist=track.artist, track=track.title, limit=limit
            )
        
        return PaginatedResponse(
            data=similar_tracks,
            meta=PaginationMeta(
                total=len(similar_tracks),
                page=1,
                page_size=limit,
                total_pages=1 if similar_tracks else 0,
            ),
        )

    async def get_lyrics(self, track_id: str) -> TrackLyrics:
        track = await self.get_detail(track_id)
        
        if self.lrclib:
            lyrics = await self.lrclib.get_lyrics(artist=track.artist, title=track.title)
            if lyrics:
                return lyrics
        
        return TrackLyrics(plain_lyrics=None, synced_lyrics=None)
