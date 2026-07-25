from collections.abc import AsyncGenerator

import httpx
from fastapi import Depends

from app.core.config import Settings, get_settings
from app.modules.mood.service import MoodService, get_mood_service
from app.modules.tracks.service import TrackService
from app.services.cache import cache_service
from app.services.cocktaildb import CocktailDBClient, get_cocktaildb_client
from app.services.jamendo import JamendoClient
from app.services.lastfm import LastfmClient, get_lastfm_client
from app.services.lrclib import LrclibClient, get_lrclib_client


async def get_http_client() -> AsyncGenerator[httpx.AsyncClient, None]:
    async with httpx.AsyncClient() as client:
        yield client


def get_jamendo_client(
    http_client: httpx.AsyncClient = Depends(get_http_client),
    settings: Settings = Depends(get_settings),
) -> JamendoClient:
    return JamendoClient(
        client_id=settings.jamendo_client_id,
        http_client=http_client,
        cache=cache_service,
    )


def get_track_service(
    jamendo_client: JamendoClient = Depends(get_jamendo_client),
    lastfm_client: LastfmClient = Depends(get_lastfm_client),
    lrclib_client: LrclibClient = Depends(get_lrclib_client),
    mood_service: MoodService = Depends(get_mood_service),
    cocktaildb_client: CocktailDBClient = Depends(get_cocktaildb_client),
) -> TrackService:
    return TrackService(
        jamendo_client=jamendo_client,
        lastfm_client=lastfm_client,
        lrclib_client=lrclib_client,
        mood_service=mood_service,
        cocktaildb_client=cocktaildb_client,
    )
