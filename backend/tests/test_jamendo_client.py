from unittest.mock import AsyncMock, MagicMock

import httpx
import pytest

from app.core.exceptions import AppError
from app.services.cache import CacheService

# We will create app.services.jamendo later. For now, it will fail to import if we run tests
try:
    from app.services.jamendo import JamendoClient
except ImportError:
    JamendoClient = None


@pytest.fixture
def cache_mock():
    mock = AsyncMock(spec=CacheService)
    mock.get.return_value = None
    return mock


@pytest.fixture
def http_client_mock():
    mock = AsyncMock(spec=httpx.AsyncClient)
    return mock


@pytest.fixture
def jamendo_client(http_client_mock, cache_mock):
    if JamendoClient is None:
        pytest.skip("JamendoClient not implemented yet")
    return JamendoClient(
        client_id="test_client_id", http_client=http_client_mock, cache=cache_mock
    )


@pytest.mark.asyncio
async def test_search_success(jamendo_client, http_client_mock, cache_mock):
    # Setup mock response
    mock_resp = MagicMock()
    mock_resp.status_code = 200
    mock_resp.json.return_value = {
        "headers": {"total_count": 1},
        "results": [
            {
                "id": "123",
                "name": "Test Track",
                "artist_name": "Test Artist",
                "album_name": "Test Album",
                "image": "http://img",
                "audio": "http://audio",
                "duration": 120,
            }
        ],
    }
    http_client_mock.get.return_value = mock_resp

    tracks, total = await jamendo_client.search("test")

    assert total == 1
    assert len(tracks) == 1
    assert tracks[0].id == "123"
    assert tracks[0].title == "Test Track"
    assert cache_mock.set.called


@pytest.mark.asyncio
async def test_search_cache_hit(jamendo_client, http_client_mock, cache_mock):
    # Setup cache hit
    cache_mock.get.return_value = {
        "total": 1,
        "tracks": [
            {
                "id": "123",
                "title": "Cached Track",
                "artist": "Cached Artist",
                "album": "Cached Album",
                "cover_url": "http://img",
                "audio_url": "http://audio",
                "duration": 120,
                "source": "jamendo",
            }
        ],
    }

    tracks, total = await jamendo_client.search("test")

    assert total == 1
    assert len(tracks) == 1
    assert tracks[0].title == "Cached Track"
    assert not http_client_mock.get.called


@pytest.mark.asyncio
async def test_get_track_success(jamendo_client, http_client_mock):
    # Setup mock response
    mock_resp = MagicMock()
    mock_resp.status_code = 200
    mock_resp.json.return_value = {
        "headers": {"total_count": 1},
        "results": [
            {
                "id": "123",
                "name": "Test Track",
                "artist_name": "Test Artist",
                "album_name": "Test Album",
                "image": "http://img",
                "audio": "http://audio",
                "duration": 120,
            }
        ],
    }
    http_client_mock.get.return_value = mock_resp

    track = await jamendo_client.get_track("123")

    assert track is not None
    assert track.id == "123"
    assert track.title == "Test Track"


@pytest.mark.asyncio
async def test_jamendo_500_error(jamendo_client, http_client_mock):
    mock_resp = MagicMock()
    mock_resp.status_code = 500
    mock_resp.raise_for_status.side_effect = httpx.HTTPStatusError(
        message="Server Error", request=MagicMock(), response=mock_resp
    )
    http_client_mock.get.return_value = mock_resp

    with pytest.raises(AppError) as exc:
        await jamendo_client.search("test")

    assert exc.value.status_code == 502
    assert exc.value.code == "EXTERNAL_API_ERROR"
