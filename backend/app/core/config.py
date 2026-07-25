from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    """
    Application settings.
    Loaded via pydantic-settings.
    Source: https://docs.pydantic.dev/latest/concepts/pydantic_settings/#usage
    """

    database_url: str
    redis_url: str = "redis://localhost:6379/0"
    secret_key: str
    jamendo_client_id: str
    lastfm_api_key: str
    access_token_expire_minutes: int = 15
    refresh_token_expire_days: int = 7
    cors_origins: list[str] = ["*"]

    model_config = SettingsConfigDict(env_file=".env", env_file_encoding="utf-8")


def get_settings() -> Settings:
    return Settings()
