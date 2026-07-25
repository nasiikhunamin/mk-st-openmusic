from unittest.mock import AsyncMock

import httpx
import pytest
from httpx import Response

from app.core.exceptions import AppError
from app.services.lastfm import LastfmClient


@pytest.fixture
def mock_cache():
    cache = AsyncMock()
    cache.get.return_value = None
    return cache


@pytest.fixture
def lastfm_client(mock_cache, monkeypatch):
    client = LastfmClient()
    client.cache = mock_cache
    client.http = AsyncMock()
    return client


@pytest.mark.asyncio
async def test_get_similar_tracks_success(lastfm_client, mock_cache):
    # Mock HTTP response
    lastfm_client.http.get.return_value = Response(
        200,
        json={
            "similartracks": {
                "track": [
                    {
                        "name": "Similar Song",
                        "artist": {"name": "Similar Artist"},
                        "image": [{"size": "medium", "#text": "http://img"}],
                        "mbid": "123-abc",
                    }
                ]
            }
        },
        request=AsyncMock(),
    )

    tracks = await lastfm_client.get_similar_tracks("Artist", "Song")
    assert len(tracks) == 1
    assert tracks[0].title == "Similar Song"
    assert tracks[0].artist == "Similar Artist"
    assert tracks[0].cover_url == "http://img"
    assert tracks[0].id == "123-abc"
    assert tracks[0].source == "lastfm"

    # Verify cache set
    mock_cache.set.assert_called_once()


@pytest.mark.asyncio
async def test_get_similar_tracks_cache_hit(lastfm_client, mock_cache):
    mock_cache.get.return_value = [
        {
            "id": "123",
            "title": "Cached Song",
            "artist": "Cached Artist",
            "cover_url": "url",
            "source": "lastfm",
            "audio_url": None,
            "duration": None,
            "album": None,
        }
    ]

    tracks = await lastfm_client.get_similar_tracks("Artist", "Song")
    assert len(tracks) == 1
    assert tracks[0].title == "Cached Song"

    # Verify no HTTP call
    lastfm_client.http.get.assert_not_called()


@pytest.mark.asyncio
async def test_get_similar_tracks_lastfm_error(lastfm_client):
    lastfm_client.http.get.return_value = Response(
        200, json={"error": 6, "message": "Track not found"}, request=AsyncMock()
    )

    tracks = await lastfm_client.get_similar_tracks("Unknown", "Unknown")
    assert tracks == []


@pytest.mark.asyncio
async def test_get_similar_tracks_500(lastfm_client):
    lastfm_client.http.get.side_effect = httpx.HTTPError("API Down")

    with pytest.raises(AppError) as exc:
        await lastfm_client.get_similar_tracks("Artist", "Song")

    assert exc.value.status_code == 502
    assert exc.value.code.value == "EXTERNAL_API_ERROR"
