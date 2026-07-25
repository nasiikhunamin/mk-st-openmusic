from collections.abc import AsyncGenerator

from sqlalchemy.ext.asyncio import AsyncSession

from app.db.session import get_async_session


async def get_db() -> AsyncGenerator[AsyncSession, None]:
    """Dependency to get the database session."""
    async for session in get_async_session():
        yield session
