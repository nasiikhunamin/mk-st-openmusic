import math

from app.core.exceptions import AppError, ErrorCode
from app.modules.mood.schemas import CocktailPairing, TrackMood
from app.modules.mood.service import MoodService
from app.modules.tracks.schemas import (
    PaginatedResponse,
    PaginationMeta,
    Track,
    TrackLyrics,
)
from app.services.cocktaildb import CocktailDBClient
from app.services.jamendo import JamendoClient
from app.services.lastfm import LastfmClient
from app.services.lrclib import LrclibClient


class TrackService:
    def __init__(
        self,
        jamendo_client: JamendoClient,
        lastfm_client: LastfmClient = None,
        lrclib_client: LrclibClient = None,
        mood_service: MoodService = None,
        cocktaildb_client: CocktailDBClient = None,
    ):
        self.jamendo = jamendo_client
        self.lastfm = lastfm_client
        self.lrclib = lrclib_client
        self.mood_service = mood_service
        self.cocktaildb = cocktaildb_client

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

    async def get_mood(self, track_id: str) -> TrackMood:
        musicinfo = await self.jamendo.get_track_musicinfo(track_id)
        tags = {
            "speed": musicinfo.get("speed", ""),
            "acousticelectric": musicinfo.get("acousticelectric", ""),
            "vocalinstrumental": musicinfo.get("vocalinstrumental", ""),
        }
        
        mood = "Neutral"
        if self.mood_service:
            mood = self.mood_service.classify(tags)
            
        return TrackMood(track_id=track_id, mood=mood, tags=tags)

    async def get_cocktail(self, track_id: str) -> CocktailPairing:
        mood_info = await self.get_mood(track_id)
        if not self.cocktaildb:
            raise AppError(
                ErrorCode.EXTERNAL_API_ERROR,
                "Service CocktailDB tidak tersedia",
                502,
            )
            
        pairing = await self.cocktaildb.get_cocktail_by_mood(mood_info.mood)
        if not pairing:
            raise AppError(
                ErrorCode.EXTERNAL_API_ERROR,
                "Gagal menghubungi TheCocktailDB",
                502,
            )
            
        return pairing
