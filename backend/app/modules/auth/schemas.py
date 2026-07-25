from datetime import datetime

from pydantic import BaseModel, EmailStr, Field


class RegisterInput(BaseModel):
    username: str = Field(..., min_length=3, max_length=50, pattern=r"^[a-zA-Z0-9_]+$")
    email: EmailStr
    password: str = Field(..., min_length=8, max_length=128)


class LoginInput(BaseModel):
    email: EmailStr
    password: str


class AuthTokens(BaseModel):
    access_token: str
    refresh_token: str
    token_type: str = "bearer"
    expires_in: int


class RefreshInput(BaseModel):
    refresh_token: str


class UserProfile(BaseModel):
    id: str
    username: str
    email: str
    created_at: datetime
