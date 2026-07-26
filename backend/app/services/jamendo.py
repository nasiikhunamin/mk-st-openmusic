import hashlib

import httpx

from app.core.exceptions import AppError, ErrorCode
from app.modules.tracks.schemas import Track
from app.services.cache import CacheService


class JamendoClient:
    BASE_URL = "https://api.jamendo.com/v3.0"

    def __init__(
        self,
        client_id: str,
        http_client: httpx.AsyncClient,
        cache: CacheService,
    ):
        self.client_id = client_id
        self.http = http_client
        self.cache = cache

    def _generate_cache_key(self, query: str, page: int, page_size: int) -> str:
        raw_key = f"{query}:{page}:{page_size}"
        hashed_key = hashlib.md5(raw_key.encode()).hexdigest()
        return f"search:{hashed_key}"

    def _map_track(self, item: dict) -> Track:
        return Track(
            id=item.get("id", ""),
            title=item.get("name", ""),
            artist=item.get("artist_name", ""),
            album=item.get("album_name", ""),
            cover_url=item.get("image", ""),
            audio_url=item.get("audio", ""),
            duration=item.get("duration", 0),
            source="jamendo",
        )

    async def search(
        self, query: str, page: int = 1, page_size: int = 20
    ) -> tuple[list[Track], int]:
        cache_key = self._generate_cache_key(query, page, page_size)
        cached = await self.cache.get(cache_key)

        if cached:
            return [Track.model_validate(t) for t in cached["tracks"]], cached["total"]

        try:
            resp = await self.http.get(
                f"{self.BASE_URL}/tracks",
                params={
                    "client_id": self.client_id,
                    "search": query,
                    "limit": page_size,
                    "offset": (page - 1) * page_size,
                    "format": "json",
                    "include": "musicinfo",
                },
            )
            resp.raise_for_status()
        except httpx.HTTPError as exc:
            raise AppError(
                ErrorCode.EXTERNAL_API_ERROR, "Gagal terhubung ke Jamendo API", 502
            ) from exc

        data = resp.json()
        headers = data.get("headers", {})
        if headers.get("status") == "failed":
            raise AppError(
                ErrorCode.EXTERNAL_API_ERROR,
                f"Jamendo API Error: {headers.get('error_message', 'Unknown error')}",
                502,
            )
            
        total_count = headers.get("total_count", 0)
        tracks = [self._map_track(item) for item in data.get("results", [])]

        # Cache the result
        cache_data = {"total": total_count, "tracks": [t.model_dump() for t in tracks]}
        await self.cache.set(cache_key, cache_data, ttl_seconds=300)

        return tracks, total_count

    async def get_track(self, track_id: str) -> Track:
        cache_key = f"track:{track_id}"
        cached = await self.cache.get(cache_key)
        if cached:
            return Track.model_validate(cached)

        try:
            resp = await self.http.get(
                f"{self.BASE_URL}/tracks",
                params={
                    "client_id": self.client_id,
                    "id": track_id,
                    "format": "json",
                    "include": "musicinfo",
                },
            )
            resp.raise_for_status()
        except httpx.HTTPError as exc:
            raise AppError(
                ErrorCode.EXTERNAL_API_ERROR, "Gagal terhubung ke Jamendo API", 502
            ) from exc

        data = resp.json()
        headers = data.get("headers", {})
        if headers.get("status") == "failed":
            raise AppError(
                ErrorCode.EXTERNAL_API_ERROR,
                f"Jamendo API Error: {headers.get('error_message', 'Unknown error')}",
                502,
            )
            
        results = data.get("results", [])
        if not results:
            raise AppError(ErrorCode.NOT_FOUND, "Track tidak ditemukan di Jamendo", 404)

        track = self._map_track(results[0])
        await self.cache.set(cache_key, track.model_dump(), ttl_seconds=3600)
        return track

    async def get_stream_url(self, track_id: str) -> str:
        track = await self.get_track(track_id)
        return track.audio_url

    async def get_track_musicinfo(self, track_id: str) -> dict:
        cache_key = f"track:musicinfo:{track_id}"
        cached = await self.cache.get(cache_key)
        if cached:
            return cached

        try:
            resp = await self.http.get(
                f"{self.BASE_URL}/tracks",
                params={
                    "client_id": self.client_id,
                    "id": track_id,
                    "format": "json",
                    "include": "musicinfo",
                },
            )
            resp.raise_for_status()
        except httpx.HTTPError as exc:
            raise AppError(
                ErrorCode.EXTERNAL_API_ERROR, "Gagal terhubung ke Jamendo API", 502
            ) from exc

        data = resp.json()
        headers = data.get("headers", {})
        if headers.get("status") == "failed":
            raise AppError(
                ErrorCode.EXTERNAL_API_ERROR,
                f"Jamendo API Error: {headers.get('error_message', 'Unknown error')}",
                502,
            )
            
        results = data.get("results", [])
        if not results:
            raise AppError(ErrorCode.NOT_FOUND, "Track tidak ditemukan di Jamendo", 404)

        musicinfo = results[0].get("musicinfo", {})
        await self.cache.set(cache_key, musicinfo, ttl_seconds=3600)
        return musicinfo

