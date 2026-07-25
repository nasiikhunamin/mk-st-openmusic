"""Tests for error handling contract."""

from fastapi import APIRouter
from fastapi.testclient import TestClient

from app.core.exceptions import AppError, ErrorCode
from app.main import app

# Add a test endpoint that raises AppError to verify the handler
router = APIRouter()


@router.get("/test-error")
def trigger_error():
    raise AppError(
        code=ErrorCode.VALIDATION_ERROR,
        message="Test validation error",
        status_code=422,
        details={"field": "test"},
    )


app.include_router(router)
client = TestClient(app)


def test_app_error_handler():
    response = client.get("/test-error")
    assert response.status_code == 422
    data = response.json()
    assert "error" in data
    assert data["error"]["code"] == "VALIDATION_ERROR"
    assert data["error"]["message"] == "Test validation error"
    assert data["error"]["details"] == {"field": "test"}


def test_404_not_found():
    response = client.get("/api/nonexistent")
    assert response.status_code == 404
    data = response.json()
    assert "error" in data
    assert data["error"]["code"] == "NOT_FOUND"


def test_405_method_not_allowed():
    response = client.post("/api/health")
    assert response.status_code == 405
    data = response.json()
    assert "error" in data
    # Ideally mapped to a known error code, or internal defaults
