import pytest
from httpx import AsyncClient


@pytest.mark.asyncio
async def test_create_playlist(client: AsyncClient, auth_headers):
    resp = await client.post(
        "/api/playlists", json={"name": "My Rock List"}, headers=auth_headers
    )
    assert resp.status_code == 201
    data = resp.json()
    assert data["name"] == "My Rock List"
    assert data["track_count"] == 0
    assert "id" in data


@pytest.mark.asyncio
async def test_list_playlists(client: AsyncClient, auth_headers):
    await client.post(
        "/api/playlists", json={"name": "List 1"}, headers=auth_headers
    )
    await client.post(
        "/api/playlists", json={"name": "List 2"}, headers=auth_headers
    )

    resp = await client.get("/api/playlists", headers=auth_headers)
    assert resp.status_code == 200
    data = resp.json()
    assert data["meta"]["total"] >= 2
    assert len(data["data"]) >= 2


@pytest.mark.asyncio
async def test_get_detail_playlist(client: AsyncClient, auth_headers):
    create_resp = await client.post(
        "/api/playlists", json={"name": "Detail List"}, headers=auth_headers
    )
    pid = create_resp.json()["id"]

    resp = await client.get(f"/api/playlists/{pid}", headers=auth_headers)
    assert resp.status_code == 200
    data = resp.json()
    assert data["name"] == "Detail List"
    assert isinstance(data["tracks"], list)


@pytest.mark.asyncio
async def test_rename_playlist(client: AsyncClient, auth_headers):
    create_resp = await client.post(
        "/api/playlists", json={"name": "Old Name"}, headers=auth_headers
    )
    pid = create_resp.json()["id"]

    resp = await client.patch(
        f"/api/playlists/{pid}", json={"name": "New Name"}, headers=auth_headers
    )
    assert resp.status_code == 200
    assert resp.json()["name"] == "New Name"


@pytest.mark.asyncio
async def test_delete_playlist(client: AsyncClient, auth_headers):
    create_resp = await client.post(
        "/api/playlists", json={"name": "Delete Me"}, headers=auth_headers
    )
    pid = create_resp.json()["id"]

    resp = await client.delete(f"/api/playlists/{pid}", headers=auth_headers)
    assert resp.status_code == 204

    resp_get = await client.get(f"/api/playlists/{pid}", headers=auth_headers)
    assert resp_get.status_code == 404


@pytest.mark.asyncio
async def test_add_remove_track_from_playlist(client: AsyncClient, auth_headers):
    create_resp = await client.post(
        "/api/playlists", json={"name": "Track List"}, headers=auth_headers
    )
    pid = create_resp.json()["id"]

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

    # Add track
    resp_add = await client.post(
        f"/api/playlists/{pid}/tracks", json=track_data, headers=auth_headers
    )
    assert resp_add.status_code == 204

    # Verify track added
    resp_detail = await client.get(f"/api/playlists/{pid}", headers=auth_headers)
    assert resp_detail.json()["track_count"] == 1
    assert len(resp_detail.json()["tracks"]) == 1

    # Add duplicate track -> 409
    resp_add_dup = await client.post(
        f"/api/playlists/{pid}/tracks", json=track_data, headers=auth_headers
    )
    assert resp_add_dup.status_code == 409

    # Remove track
    resp_rm = await client.delete(
        f"/api/playlists/{pid}/tracks/jam123", headers=auth_headers
    )
    assert resp_rm.status_code == 204

    # Verify track removed
    resp_detail_after = await client.get(
        f"/api/playlists/{pid}", headers=auth_headers
    )
    assert resp_detail_after.json()["track_count"] == 0


@pytest.mark.asyncio
async def test_access_playlist_other_user(
    client: AsyncClient, auth_headers, auth_headers_user2
):
    create_resp = await client.post(
        "/api/playlists", json={"name": "User 1 List"}, headers=auth_headers
    )
    pid = create_resp.json()["id"]

    # Try getting with User 2
    resp = await client.get(
        f"/api/playlists/{pid}", headers=auth_headers_user2
    )
    assert resp.status_code == 403
