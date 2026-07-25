import httpx

from app.modules.tracks.schemas import TrackLyrics
from app.services.cache import cache_service


class LrclibClient:
    BASE_URL = "https://lrclib.net/api"

    def __init__(self):
        self.headers = {"User-Agent": "OpenMusic/1.0 (https://github.com/openmusic/openmusic)"}
        self.cache = cache_service
        self.http = httpx.AsyncClient(timeout=10.0, headers=self.headers)

    async def close(self):
        await self.http.aclose()

    async def get_lyrics(self, artist: str, title: str) -> TrackLyrics | None:
        cache_key = f"lyrics:{artist.lower()}:{title.lower()}"
        cached = await self.cache.get(cache_key)
        if cached:
            return TrackLyrics(**cached)

        try:
            resp = await self.http.get(
                f"{self.BASE_URL}/get",
                params={
                    "artist_name": artist,
                    "track_name": title,
                },
            )

            if resp.status_code == 404:
                # Try search fallback
                search_resp = await self.http.get(
                    f"{self.BASE_URL}/search",
                    params={
                        "artist_name": artist,
                        "track_name": title,
                    },
                )
                if search_resp.status_code == 200:
                    results = search_resp.json()
                    if results and isinstance(results, list) and len(results) > 0:
                        data = results[0]
                    else:
                        return None
                else:
                    return None
            else:
                resp.raise_for_status()
                data = resp.json()

            lyrics = TrackLyrics(
                plain_lyrics=data.get("plainLyrics"),
                synced_lyrics=data.get("syncedLyrics"),
            )

            # Cache for 24 hours (86400 seconds)
            await self.cache.set(cache_key, lyrics.model_dump(), 86400)
            return lyrics

        except httpx.HTTPError:
            return None  # graceful degradation


def get_lrclib_client() -> LrclibClient:
    return LrclibClient()
