from unittest.mock import AsyncMock

import pytest
from httpx import AsyncClient

from app.main import app
from app.modules.tracks.dependencies import get_jamendo_client
from app.modules.tracks.schemas import Track


@pytest.fixture
def mock_jamendo():
    mock = AsyncMock()
    app.dependency_overrides[get_jamendo_client] = lambda: mock
    yield mock
    app.dependency_overrides.pop(get_jamendo_client, None)


@pytest.mark.asyncio
async def test_search_tracks_success(client: AsyncClient, auth_headers, mock_jamendo):
    mock_jamendo.search.return_value = (
        [
            Track(
                id="1",
                title="Test Track",
                artist="Test Artist",
                audio_url="http://audio",
                duration=120,
            )
        ],
        1,
    )

    resp = await client.get("/api/tracks?q=rock", headers=auth_headers)
    assert resp.status_code == 200
    data = resp.json()
    assert data["meta"]["total"] == 1
    assert data["meta"]["page"] == 1
    assert data["meta"]["page_size"] == 20
    assert len(data["data"]) == 1
    assert data["data"][0]["title"] == "Test Track"


@pytest.mark.asyncio
async def test_search_tracks_no_auth(client: AsyncClient, mock_jamendo):
    resp = await client.get("/api/tracks?q=rock")
    assert resp.status_code == 401


@pytest.mark.asyncio
async def test_search_tracks_no_query(client: AsyncClient, auth_headers, mock_jamendo):
    resp = await client.get("/api/tracks", headers=auth_headers)
    assert resp.status_code == 422


@pytest.mark.asyncio
async def test_get_track_detail_success(
    client: AsyncClient, auth_headers, mock_jamendo
):
    mock_jamendo.get_track.return_value = Track(
        id="1",
        title="Test Track",
        artist="Test Artist",
        audio_url="http://audio",
        duration=120,
    )

    resp = await client.get("/api/tracks/1", headers=auth_headers)
    assert resp.status_code == 200
    data = resp.json()
    assert data["id"] == "1"
    assert data["title"] == "Test Track"


@pytest.mark.asyncio
async def test_get_track_detail_not_found(
    client: AsyncClient, auth_headers, mock_jamendo
):
    from app.core.exceptions import AppError, ErrorCode

    mock_jamendo.get_track.side_effect = AppError(
        ErrorCode.NOT_FOUND, "Track tidak ditemukan di Jamendo", 404
    )

    resp = await client.get("/api/tracks/999", headers=auth_headers)
    assert resp.status_code == 404
    assert resp.json()["error"]["code"] == "NOT_FOUND"


@pytest.mark.asyncio
async def test_get_track_stream_success(
    client: AsyncClient, auth_headers, mock_jamendo
):
    mock_jamendo.get_track.return_value = Track(
        id="1",
        title="Test Track",
        artist="Test Artist",
        audio_url="https://audio.com/stream",
        duration=120,
    )
    mock_jamendo.get_stream_url.return_value = "https://audio.com/stream"

    resp = await client.get("/api/tracks/1/stream", headers=auth_headers)
    assert resp.status_code == 200
    assert resp.json()["audio_url"] == "https://audio.com/stream"
