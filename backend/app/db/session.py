import logging
from collections.abc import AsyncGenerator

from sqlalchemy.ext.asyncio import (
    AsyncEngine,
    AsyncSession,
    async_sessionmaker,
    create_async_engine,
)

from app.core.config import get_settings

logger = logging.getLogger(__name__)

settings = get_settings()

# Engine will be initialized in lifespan
engine: AsyncEngine | None = None
async_session_maker: async_sessionmaker[AsyncSession] | None = None


def init_db() -> None:
    """Initialize database engine and session maker."""
    global engine, async_session_maker
    if engine is None:
        logger.info("Initializing database engine.")
        # Create async engine. Source: https://docs.sqlalchemy.org/en/20/orm/extensions/asyncio.html
        engine = create_async_engine(
            settings.database_url,
            echo=False,
            future=True,
        )
        async_session_maker = async_sessionmaker(
            engine, class_=AsyncSession, expire_on_commit=False
        )


async def close_db() -> None:
    """Close database engine."""
    global engine, async_session_maker
    if engine is not None:
        logger.info("Disposing database engine.")
        await engine.dispose()
        engine = None
        async_session_maker = None


async def get_async_session() -> AsyncGenerator[AsyncSession, None]:
    """Dependency for getting async database session."""
    if async_session_maker is None:
        raise RuntimeError("Database not initialized")

    async with async_session_maker() as session:
        try:
            yield session
        finally:
            await session.close()
