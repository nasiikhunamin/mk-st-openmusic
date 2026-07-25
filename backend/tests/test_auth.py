import pytest
from httpx import AsyncClient


@pytest.mark.asyncio
async def test_register_success(client: AsyncClient):
    resp = await client.post(
        "/api/auth/register",
        json={
            "username": "newuser",
            "email": "newuser@example.com",
            "password": "password123",
        },
    )
    assert resp.status_code == 201
    data = resp.json()
    assert "access_token" in data
    assert "refresh_token" in data
    assert data["token_type"] == "bearer"


@pytest.mark.asyncio
async def test_register_duplicate_email(client: AsyncClient, auth_headers):
    # auth_headers creates "testuser" / "test@example.com"
    resp = await client.post(
        "/api/auth/register",
        json={
            "username": "anotheruser",
            "email": "test@example.com",
            "password": "password123",
        },
    )
    assert resp.status_code == 409
    assert resp.json()["error"]["code"] == "CONFLICT"


@pytest.mark.asyncio
async def test_register_password_too_short(client: AsyncClient):
    resp = await client.post(
        "/api/auth/register",
        json={
            "username": "validuser",
            "email": "valid@example.com",
            "password": "short",
        },
    )
    assert resp.status_code == 422
    assert resp.json()["error"]["code"] == "VALIDATION_ERROR"


@pytest.mark.asyncio
async def test_login_success(client: AsyncClient, auth_headers):
    resp = await client.post(
        "/api/auth/login",
        json={
            "email": "test@example.com",
            "password": "securepass123",
        },
    )
    assert resp.status_code == 200
    assert "access_token" in resp.json()


@pytest.mark.asyncio
async def test_login_wrong_email(client: AsyncClient, auth_headers):
    resp = await client.post(
        "/api/auth/login",
        json={
            "email": "wrong@example.com",
            "password": "securepass123",
        },
    )
    assert resp.status_code == 401
    assert resp.json()["error"]["code"] == "AUTHENTICATION_ERROR"


@pytest.mark.asyncio
async def test_login_wrong_password(client: AsyncClient, auth_headers):
    resp = await client.post(
        "/api/auth/login",
        json={
            "email": "test@example.com",
            "password": "wrongpassword",
        },
    )
    assert resp.status_code == 401
    assert resp.json()["error"]["code"] == "AUTHENTICATION_ERROR"


@pytest.mark.asyncio
async def test_get_me_success(client: AsyncClient, auth_headers):
    resp = await client.get("/api/auth/me", headers=auth_headers)
    assert resp.status_code == 200
    data = resp.json()
    assert data["username"] == "testuser"
    assert data["email"] == "test@example.com"
    assert "id" in data


@pytest.mark.asyncio
async def test_get_me_no_token(client: AsyncClient):
    resp = await client.get("/api/auth/me")
    assert resp.status_code == 401


@pytest.mark.asyncio
async def test_refresh_success(client: AsyncClient, auth_headers):
    # Get initial refresh token
    login_resp = await client.post(
        "/api/auth/login",
        json={"email": "test@example.com", "password": "securepass123"},
    )
    refresh_token = login_resp.json()["refresh_token"]

    # Refresh
    refresh_resp = await client.post(
        "/api/auth/refresh",
        json={"refresh_token": refresh_token},
    )
    assert refresh_resp.status_code == 200
    new_refresh_token = refresh_resp.json()["refresh_token"]
    assert new_refresh_token != refresh_token

    # Attempt to refresh with old token again (should fail)
    bad_refresh_resp = await client.post(
        "/api/auth/refresh",
        json={"refresh_token": refresh_token},
    )
    assert bad_refresh_resp.status_code == 401


@pytest.mark.asyncio
async def test_logout(client: AsyncClient, auth_headers):
    # Login to get refresh token
    login_resp = await client.post(
        "/api/auth/login",
        json={"email": "test@example.com", "password": "securepass123"},
    )
    refresh_token = login_resp.json()["refresh_token"]

    # Logout
    logout_resp = await client.post(
        "/api/auth/logout",
        json={"refresh_token": refresh_token},
    )
    assert logout_resp.status_code == 200

    # Refresh should now fail because it's revoked
    refresh_resp = await client.post(
        "/api/auth/refresh",
        json={"refresh_token": refresh_token},
    )
    assert refresh_resp.status_code == 401
