from datetime import timedelta

import pytest
from jose import JWTError

from app.core.security import (
    create_access_token,
    create_refresh_token,
    decode_access_token,
    hash_password,
    hash_token,
    verify_password,
)

SECRET_KEY = "test_secret_key"


def test_password_hashing():
    password = "supersecretpassword123"
    hashed = hash_password(password)
    assert hashed != password
    assert verify_password(password, hashed) is True
    assert verify_password("wrongpassword", hashed) is False


def test_access_token():
    subject = "user123"
    expires_delta = timedelta(minutes=15)
    token = create_access_token(subject, expires_delta, SECRET_KEY)

    payload = decode_access_token(token, SECRET_KEY)
    assert payload["sub"] == subject
    assert "exp" in payload
    assert "iat" in payload


def test_access_token_expired():
    subject = "user123"
    # Create an expired token (negative delta)
    expires_delta = timedelta(minutes=-1)
    token = create_access_token(subject, expires_delta, SECRET_KEY)

    with pytest.raises(JWTError):
        decode_access_token(token, SECRET_KEY)


def test_refresh_token():
    token1 = create_refresh_token()
    token2 = create_refresh_token()
    assert len(token1) >= 64
    assert token1 != token2


def test_hash_token():
    token = "my_refresh_token_123"
    hashed = hash_token(token)
    assert hashed != token
    assert hash_token(token) == hashed  # Consistent hashing
