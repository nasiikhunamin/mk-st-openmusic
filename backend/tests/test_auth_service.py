import uuid
from datetime import datetime, timedelta, timezone
from unittest.mock import AsyncMock

import pytest

from app.core.exceptions import AppError
from app.core.security import hash_password, hash_token
from app.modules.auth.models import RefreshToken, User
from app.modules.auth.schemas import LoginInput, RegisterInput
from app.modules.auth.service import auth_service


@pytest.fixture
def db_mock():
    return AsyncMock()


@pytest.mark.asyncio
async def test_register_success(db_mock):
    # Mock no duplicate email or username
    db_mock.scalar.return_value = None

    input_data = RegisterInput(
        username="testuser", email="test@example.com", password="password123"
    )
    tokens = await auth_service.register(db_mock, input_data)

    assert tokens.access_token is not None
    assert tokens.refresh_token is not None
    assert tokens.token_type == "bearer"
    assert db_mock.add.called
    assert db_mock.flush.called
    assert db_mock.commit.called


@pytest.mark.asyncio
async def test_register_duplicate_email(db_mock):
    db_mock.scalar.return_value = User(email="test@example.com")

    input_data = RegisterInput(
        username="testuser", email="test@example.com", password="password123"
    )
    with pytest.raises(AppError) as exc:
        await auth_service.register(db_mock, input_data)

    assert exc.value.status_code == 409
    assert "Email" in exc.value.message


@pytest.mark.asyncio
async def test_login_success(db_mock):
    user_id = uuid.uuid4()
    mock_user = User(
        id=user_id,
        email="test@example.com",
        password_hash=hash_password("password123"),
    )
    db_mock.scalar.return_value = mock_user

    input_data = LoginInput(email="test@example.com", password="password123")
    tokens = await auth_service.login(db_mock, input_data)

    assert tokens.access_token is not None
    assert tokens.refresh_token is not None


@pytest.mark.asyncio
async def test_login_wrong_password(db_mock):
    mock_user = User(
        email="test@example.com", password_hash=hash_password("password123")
    )
    db_mock.scalar.return_value = mock_user

    input_data = LoginInput(email="test@example.com", password="wrongpassword")
    with pytest.raises(AppError) as exc:
        await auth_service.login(db_mock, input_data)

    assert exc.value.status_code == 401
    assert exc.value.message == "Email atau password salah"


@pytest.mark.asyncio
async def test_refresh_success(db_mock):
    plain_token = "my_refresh_token"
    token_hash_val = hash_token(plain_token)
    user_id = uuid.uuid4()

    mock_db_token = RefreshToken(
        token_hash=token_hash_val,
        user_id=user_id,
        expires_at=datetime.now(timezone.utc) + timedelta(days=1),
        revoked_at=None,
    )
    db_mock.scalar.return_value = mock_db_token

    tokens = await auth_service.refresh(db_mock, plain_token)

    assert tokens.access_token is not None
    assert tokens.refresh_token is not None
    assert db_mock.delete.called  # Token rotation


@pytest.mark.asyncio
async def test_refresh_expired(db_mock):
    plain_token = "my_refresh_token"
    mock_db_token = RefreshToken(
        expires_at=datetime.now(timezone.utc) - timedelta(days=1),
        revoked_at=None,
    )
    db_mock.scalar.return_value = mock_db_token

    with pytest.raises(AppError) as exc:
        await auth_service.refresh(db_mock, plain_token)

    assert exc.value.status_code == 401
    assert "kadaluarsa" in exc.value.message
