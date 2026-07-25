from unittest.mock import AsyncMock

import pytest

from app.modules.tracks.schemas import Track
from app.modules.tracks.service import TrackService
from app.services.jamendo import JamendoClient


@pytest.fixture
def mock_jamendo():
    mock = AsyncMock(spec=JamendoClient)
    return mock


@pytest.fixture
def track_service(mock_jamendo):
    return TrackService(jamendo_client=mock_jamendo)


@pytest.mark.asyncio
async def test_search_returns_paginated_response(track_service, mock_jamendo):
    mock_tracks = [
        Track(
            id="1",
            title="Song",
            artist="Artist",
            audio_url="http://audio",
            duration=100,
        )
    ]
    mock_jamendo.search.return_value = (mock_tracks, 50)

    result = await track_service.search("query", page=2, page_size=10)

    assert result.meta.total == 50
    assert result.meta.page == 2
    assert result.meta.page_size == 10
    assert result.meta.total_pages == 5  # ceil(50/10)
    assert len(result.data) == 1
    assert result.data[0].id == "1"


@pytest.mark.asyncio
async def test_pagination_math_edge_cases(track_service, mock_jamendo):
    # 0 results
    mock_jamendo.search.return_value = ([], 0)
    result = await track_service.search("q", page=1, page_size=20)
    assert result.meta.total_pages == 0

    # Exact multiple
    mock_jamendo.search.return_value = ([], 40)
    result = await track_service.search("q", page=1, page_size=20)
    assert result.meta.total_pages == 2

    # Not exact multiple
    mock_jamendo.search.return_value = ([], 41)
    result = await track_service.search("q", page=1, page_size=20)
    assert result.meta.total_pages == 3


@pytest.mark.asyncio
async def test_get_detail(track_service, mock_jamendo):
    mock_track = Track(
        id="1", title="Song", artist="Artist", audio_url="http://audio", duration=100
    )
    mock_jamendo.get_track.return_value = mock_track

    result = await track_service.get_detail("1")
    assert result == mock_track
    mock_jamendo.get_track.assert_called_once_with("1")


@pytest.mark.asyncio
async def test_get_stream_url(track_service, mock_jamendo):
    mock_jamendo.get_stream_url.return_value = "http://audio/stream"

    result = await track_service.get_stream_url("1")
    assert result == {"audio_url": "http://audio/stream"}
    mock_jamendo.get_stream_url.assert_called_once_with("1")
