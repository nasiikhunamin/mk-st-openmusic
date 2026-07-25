from unittest.mock import AsyncMock

import httpx
import pytest
from httpx import Response

from app.services.lrclib import LrclibClient


@pytest.fixture
def mock_cache():
    cache = AsyncMock()
    cache.get.return_value = None
    return cache


@pytest.fixture
def lrclib_client(mock_cache, monkeypatch):
    client = LrclibClient()
    client.cache = mock_cache
    client.http = AsyncMock()
    return client


@pytest.mark.asyncio
async def test_get_lyrics_found(lrclib_client, mock_cache):
    lrclib_client.http.get.return_value = Response(
        200,
        json={
            "plainLyrics": "Plain Lyrics here",
            "syncedLyrics": "[00:12.00] Synced Lyrics here",
        },
        request=AsyncMock(),
    )

    lyrics = await lrclib_client.get_lyrics("Artist", "Title")
    assert lyrics is not None
    assert lyrics.plain_lyrics == "Plain Lyrics here"
    assert lyrics.synced_lyrics == "[00:12.00] Synced Lyrics here"

    # Verify cache set
    mock_cache.set.assert_called_once()


@pytest.mark.asyncio
async def test_get_lyrics_not_found(lrclib_client):
    lrclib_client.http.get.side_effect = [
        Response(404, request=AsyncMock()),
        Response(200, json=[], request=AsyncMock()),
    ]

    lyrics = await lrclib_client.get_lyrics("Unknown", "Unknown")
    assert lyrics is None


@pytest.mark.asyncio
async def test_get_lyrics_cache_hit(lrclib_client, mock_cache):
    mock_cache.get.return_value = {
        "plain_lyrics": "Cached plain",
        "synced_lyrics": "Cached synced",
    }

    lyrics = await lrclib_client.get_lyrics("Artist", "Title")
    assert lyrics is not None
    assert lyrics.plain_lyrics == "Cached plain"

    lrclib_client.http.get.assert_not_called()


@pytest.mark.asyncio
async def test_get_lyrics_lrclib_down(lrclib_client):
    lrclib_client.http.get.side_effect = httpx.HTTPError("API Down")

    lyrics = await lrclib_client.get_lyrics("Artist", "Title")
    assert lyrics is None


@pytest.mark.asyncio
async def test_get_lyrics_search_fallback(lrclib_client, mock_cache):
    lrclib_client.http.get.side_effect = [
        Response(404, request=AsyncMock()),
        Response(
            200,
            json=[
                {
                    "plainLyrics": "Fallback plain",
                    "syncedLyrics": "Fallback synced",
                }
            ],
            request=AsyncMock(),
        ),
    ]

    lyrics = await lrclib_client.get_lyrics("Artist", "Title")
    assert lyrics is not None
    assert lyrics.plain_lyrics == "Fallback plain"
    assert lyrics.synced_lyrics == "Fallback synced"

    mock_cache.set.assert_called_once()
