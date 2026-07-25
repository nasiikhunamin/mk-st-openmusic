from unittest.mock import AsyncMock

import pytest
from httpx import AsyncClient

from app.main import app
from app.modules.mood.schemas import CocktailPairing
from app.modules.mood.service import MoodService
from app.modules.tracks.dependencies import get_jamendo_client
from app.services.cocktaildb import get_cocktaildb_client

# ==================== UNIT TESTS ====================


def test_mood_energetic():
    service = MoodService()
    tags = {"speed": "high", "acousticelectric": "electric"}
    assert service.classify(tags) == "Energetic"


def test_mood_party():
    service = MoodService()
    tags = {
        "speed": "high",
        "acousticelectric": "electric",
        "vocalinstrumental": "instrumental",
    }
    assert service.classify(tags) == "Party"


def test_mood_chill():
    service = MoodService()
    tags = {
        "speed": "low",
        "acousticelectric": "acoustic",
        "vocalinstrumental": "vocal",
    }
    assert service.classify(tags) == "Chill"


def test_mood_mellow():
    service = MoodService()
    tags = {
        "speed": "low",
        "acousticelectric": "acoustic",
        "vocalinstrumental": "instrumental",
    }
    assert service.classify(tags) == "Mellow"


def test_mood_neutral_fallback():
    service = MoodService()
    # Unknown combinations
    assert service.classify({"speed": "medium"}) == "Neutral"
    # Empty tags
    assert service.classify({}) == "Neutral"


# ==================== INTEGRATION TESTS ====================


@pytest.fixture
def mock_jamendo():
    mock = AsyncMock()
    app.dependency_overrides[get_jamendo_client] = lambda: mock
    yield mock
    app.dependency_overrides.pop(get_jamendo_client, None)


@pytest.fixture
def mock_cocktaildb():
    mock = AsyncMock()
    app.dependency_overrides[get_cocktaildb_client] = lambda: mock
    yield mock
    app.dependency_overrides.pop(get_cocktaildb_client, None)


@pytest.mark.asyncio
async def test_get_track_mood_success(client: AsyncClient, auth_headers, mock_jamendo):
    # Mock Jamendo returning musicinfo tags
    mock_jamendo.get_track_musicinfo.return_value = {
        "speed": "high",
        "acousticelectric": "electric",
        "vocalinstrumental": "vocal",
    }

    resp = await client.get("/api/tracks/1/mood", headers=auth_headers)
    assert resp.status_code == 200
    data = resp.json()
    assert data["track_id"] == "1"
    assert data["mood"] == "Energetic"
    assert data["tags"] == {
        "speed": "high",
        "acousticelectric": "electric",
        "vocalinstrumental": "vocal",
    }


@pytest.mark.asyncio
async def test_get_track_mood_no_auth(client: AsyncClient):
    resp = await client.get("/api/tracks/1/mood")
    assert resp.status_code == 401


@pytest.mark.asyncio
async def test_get_track_cocktail_success(
    client: AsyncClient, auth_headers, mock_jamendo, mock_cocktaildb
):
    mock_jamendo.get_track_musicinfo.return_value = {
        "speed": "low",
        "acousticelectric": "acoustic",
        "vocalinstrumental": "vocal",
    }
    mock_cocktaildb.get_cocktail_by_mood.return_value = CocktailPairing(
        mood="Chill",
        cocktail_name="Mojito",
        cocktail_image="http://mojito",
        ingredients=["Rum", "Mint", "Lime"],
        instructions="Mix it",
    )

    resp = await client.get("/api/tracks/1/cocktail", headers=auth_headers)
    assert resp.status_code == 200
    data = resp.json()
    assert data["mood"] == "Chill"
    assert data["cocktail_name"] == "Mojito"
    assert data["ingredients"] == ["Rum", "Mint", "Lime"]


@pytest.mark.asyncio
async def test_get_track_cocktail_no_auth(client: AsyncClient):
    resp = await client.get("/api/tracks/1/cocktail")
    assert resp.status_code == 401
