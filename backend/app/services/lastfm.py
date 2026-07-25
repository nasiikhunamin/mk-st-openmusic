import httpx

from app.core.config import get_settings
from app.core.exceptions import AppError, ErrorCode
from app.modules.tracks.schemas import Track
from app.services.cache import cache_service


class LastfmClient:
    BASE_URL = "https://ws.audioscrobbler.com/2.0/"

    def __init__(self):
        self.settings = get_settings()
        self.api_key = self.settings.lastfm_api_key
        self.cache = cache_service
        self.http = httpx.AsyncClient(timeout=10.0)

    async def close(self):
        await self.http.aclose()

    async def get_similar_tracks(
        self, artist: str, track: str, limit: int = 10
    ) -> list[Track]:
        cache_key = f"similar:{artist.lower()}:{track.lower()}"
        cached = await self.cache.get(cache_key)
        if cached:
            return [Track(**t) for t in cached]

        try:
            resp = await self.http.get(
                self.BASE_URL,
                params={
                    "method": "track.getsimilar",
                    "artist": artist,
                    "track": track,
                    "limit": limit,
                    "api_key": self.api_key,
                    "format": "json",
                },
            )
            resp.raise_for_status()
        except httpx.HTTPError:
            raise AppError(
                ErrorCode.EXTERNAL_API_ERROR,
                "Gagal menghubungi Last.fm API",
                502,
            )

        data = resp.json()
        if "error" in data:
            return []

        similar_tracks_data = data.get("similartracks", {})
        if not similar_tracks_data:
            return []

        tracks_data = similar_tracks_data.get("track", [])
        if isinstance(tracks_data, dict):
            tracks_data = [tracks_data]

        results = []
        for t in tracks_data:
            artist_name = t.get("artist", {}).get("name", "")
            title = t.get("name", "")

            # images
            images = t.get("image", [])
            cover_url = None
            for img in images:
                if img.get("size") == "medium":
                    cover_url = img.get("#text")
                    break
            if not cover_url and images:
                cover_url = images[-1].get("#text")

            track_id = t.get("mbid") or f"lastfm-{artist_name}-{title}".lower().replace(
                " ", "-"
            )

            results.append(
                Track(
                    id=track_id,
                    title=title,
                    artist=artist_name,
                    cover_url=cover_url,
                    source="lastfm",
                )
            )

        # Cache for 30 minutes (1800 seconds)
        await self.cache.set(cache_key, [t.model_dump() for t in results], 1800)
        return results

    async def get_artist_info(self, artist: str) -> dict:
        try:
            resp = await self.http.get(
                self.BASE_URL,
                params={
                    "method": "artist.getinfo",
                    "artist": artist,
                    "api_key": self.api_key,
                    "format": "json",
                },
            )
            resp.raise_for_status()
        except httpx.HTTPError:
            raise AppError(
                ErrorCode.EXTERNAL_API_ERROR,
                "Gagal menghubungi Last.fm API",
                502,
            )

        data = resp.json()
        if "error" in data:
            return {}

        return data.get("artist", {})


def get_lastfm_client() -> LastfmClient:
    return LastfmClient()
