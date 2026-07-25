from collections.abc import AsyncGenerator

import httpx
from fastapi import Depends

from app.core.config import Settings, get_settings
from app.modules.tracks.service import TrackService
from app.services.cache import cache_service
from app.services.jamendo import JamendoClient


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
    jamendo: JamendoClient = Depends(get_jamendo_client),
) -> TrackService:
    return TrackService(jamendo)
