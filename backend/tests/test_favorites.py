import pytest
from httpx import AsyncClient


@pytest.mark.asyncio
async def test_add_favorite(client: AsyncClient, auth_headers):
    track_data = {
        "track_id": "jam123",
        "track_metadata": {
            "id": "jam123",
            "title": "Song",
            "artist": "Artist",
            "audio_url": "url",
            "duration": 100,
            "source": "jamendo",
        },
    }

    resp = await client.post("/api/favorites", json=track_data, headers=auth_headers)
    assert resp.status_code == 201


@pytest.mark.asyncio
async def test_add_duplicate_favorite(client: AsyncClient, auth_headers):
    track_data = {
        "track_id": "jam123",
        "track_metadata": {
            "id": "jam123",
            "title": "Song",
            "artist": "Artist",
            "audio_url": "url",
            "duration": 100,
            "source": "jamendo",
        },
    }
    # Add first time
    await client.post("/api/favorites", json=track_data, headers=auth_headers)
    # Add second time -> 409
    resp = await client.post("/api/favorites", json=track_data, headers=auth_headers)
    assert resp.status_code == 409


@pytest.mark.asyncio
async def test_list_favorites(client: AsyncClient, auth_headers):
    track_data_1 = {
        "track_id": "jam123",
        "track_metadata": {
            "id": "jam123",
            "title": "Song 1",
            "artist": "Artist",
            "audio_url": "url",
            "duration": 100,
            "source": "jamendo",
        },
    }
    track_data_2 = {
        "track_id": "jam456",
        "track_metadata": {
            "id": "jam456",
            "title": "Song 2",
            "artist": "Artist",
            "audio_url": "url",
            "duration": 100,
            "source": "jamendo",
        },
    }
    await client.post("/api/favorites", json=track_data_1, headers=auth_headers)
    await client.post("/api/favorites", json=track_data_2, headers=auth_headers)

    resp = await client.get("/api/favorites", headers=auth_headers)
    assert resp.status_code == 200
    data = resp.json()
    assert data["meta"]["total"] >= 2
    assert len(data["data"]) >= 2
    # Verify both are present (order might be same due to 1-second timestamp resolution)
    ids = [d["id"] for d in data["data"]]
    assert "jam123" in ids
    assert "jam456" in ids


@pytest.mark.asyncio
async def test_remove_favorite(client: AsyncClient, auth_headers):
    track_data = {
        "track_id": "jam123",
        "track_metadata": {
            "id": "jam123",
            "title": "Song",
            "artist": "Artist",
            "audio_url": "url",
            "duration": 100,
            "source": "jamendo",
        },
    }
    await client.post("/api/favorites", json=track_data, headers=auth_headers)

    resp = await client.delete("/api/favorites/jam123", headers=auth_headers)
    assert resp.status_code == 204

    # Verify removed
    resp_list = await client.get("/api/favorites", headers=auth_headers)
    assert resp_list.json()["meta"]["total"] == 0


@pytest.mark.asyncio
async def test_remove_non_existent_favorite(client: AsyncClient, auth_headers):
    resp = await client.delete("/api/favorites/unknown123", headers=auth_headers)
    assert resp.status_code == 404
