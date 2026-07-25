import uuid
from datetime import timedelta
from unittest.mock import AsyncMock

import pytest
from fastapi.testclient import TestClient

from app.core.config import get_settings
from app.core.dependencies import get_db
from app.core.security import create_access_token
from app.main import app
from app.modules.auth.models import User

client = TestClient(app)
settings = get_settings()


@pytest.fixture
def mock_db():
    mock_session = AsyncMock()
    # Configure mock session to return a valid User for get_profile / get_current_user by default
    from datetime import datetime, timezone
    mock_user = User(
        id=uuid.uuid4(),
        username="testuser",
        email="test@example.com",
        created_at=datetime.now(timezone.utc),
    )
    mock_session.scalar.return_value = mock_user

    async def _get_db():
        yield mock_session

    app.dependency_overrides[get_db] = _get_db
    yield mock_session
    app.dependency_overrides.clear()


def test_register_endpoint(mock_db):
    # For register, scalar needs to return None so it doesn't think email exists
    mock_db.scalar.return_value = None

    response = client.post(
        "/api/auth/register",
        json={
            "username": "newuser",
            "email": "new@example.com",
            "password": "password123",
        },
    )
    assert response.status_code == 201
    data = response.json()
    assert "access_token" in data
    assert "refresh_token" in data
    assert data["token_type"] == "bearer"


def test_login_endpoint(mock_db):
    # For login, scalar returns a valid User with hashed password
    from app.core.security import hash_password

    mock_db.scalar.return_value = User(
        id=uuid.uuid4(),
        email="existing@example.com",
        password_hash=hash_password("password123"),
    )

    response = client.post(
        "/api/auth/login",
        json={
            "email": "existing@example.com",
            "password": "password123",
        },
    )
    assert response.status_code == 200
    assert "access_token" in response.json()


def test_refresh_endpoint(mock_db):
    from datetime import datetime, timezone

    from app.core.security import hash_token
    from app.modules.auth.models import RefreshToken

    # For refresh, scalar returns a valid RefreshToken
    mock_db.scalar.return_value = RefreshToken(
        user_id=uuid.uuid4(),
        token_hash=hash_token("valid_refresh_token"),
        expires_at=datetime.now(timezone.utc) + timedelta(days=1),
        revoked_at=None,
    )

    response = client.post(
        "/api/auth/refresh",
        json={"refresh_token": "valid_refresh_token"},
    )
    assert response.status_code == 200
    assert "access_token" in response.json()


def test_logout_endpoint(mock_db):
    from app.core.security import hash_token
    from app.modules.auth.models import RefreshToken

    mock_db.scalar.return_value = RefreshToken(
        token_hash=hash_token("valid_refresh_token"),
    )

    response = client.post(
        "/api/auth/logout",
        json={"refresh_token": "valid_refresh_token"},
    )
    assert response.status_code == 200
    assert response.json()["message"] == "Berhasil logout"


def test_get_me_success(mock_db):
    from datetime import datetime, timezone
    user_id = uuid.uuid4()
    mock_user = User(
        id=user_id,
        username="testuser",
        email="test@example.com",
        created_at=datetime.now(timezone.utc),
    )
    # The get_current_user dependency calls db.scalar, then get_profile calls db.scalar
    # We configure side_effect to return mock_user for both queries
    mock_db.scalar.side_effect = [mock_user, mock_user]

    token = create_access_token(str(user_id), timedelta(minutes=15), settings.secret_key)

    response = client.get(
        "/api/auth/me",
        headers={"Authorization": f"Bearer {token}"},
    )
    assert response.status_code == 200
    assert response.json()["username"] == "testuser"
    assert response.json()["email"] == "test@example.com"


def test_get_me_no_token(mock_db):
    response = client.get("/api/auth/me")
    assert response.status_code == 401
    assert response.json()["error"]["code"] == "AUTHENTICATION_ERROR"
    assert "Token tidak ditemukan" in response.json()["error"]["message"]


def test_get_me_invalid_token(mock_db):
    response = client.get(
        "/api/auth/me",
        headers={"Authorization": "Bearer invalid.token.here"},
    )
    assert response.status_code == 401
    assert response.json()["error"]["code"] == "AUTHENTICATION_ERROR"
    assert "Token tidak valid" in response.json()["error"]["message"]
