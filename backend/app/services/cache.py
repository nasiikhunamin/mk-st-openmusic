import time
from typing import Any

import redis.asyncio as redis

from app.core.config import get_settings

settings = get_settings()


class CacheService:
    """
    Redis-based caching service.
    Currently implements an in-memory fallback per PRD §5.2 for initial implementation,
    but can connect to Redis.
    Source for redis-py async: https://redis.readthedocs.io/en/stable/examples/asyncio_examples.html
    """

    def __init__(self, use_redis: bool = False):
        self._store: dict[str, tuple[Any, float]] = {}
        self.use_redis = use_redis
        self.redis_client = None

    async def connect(self):
        """Connect to Redis if enabled."""
        if self.use_redis:
            self.redis_client = redis.from_url(
                settings.redis_url, decode_responses=True
            )
            # Test connection
            await self.redis_client.ping()

    async def disconnect(self):
        """Disconnect from Redis if enabled."""
        if self.use_redis and self.redis_client:
            await self.redis_client.close()

    async def set(self, key: str, value: Any, ttl_seconds: int = 300) -> None:
        if self.use_redis and self.redis_client:
            import json

            await self.redis_client.setex(key, ttl_seconds, json.dumps(value))
        else:
            self._store[key] = (value, time.time() + ttl_seconds)

    async def get(self, key: str) -> Any | None:
        if self.use_redis and self.redis_client:
            import json

            data = await self.redis_client.get(key)
            return json.loads(data) if data else None
        else:
            if key not in self._store:
                return None
            value, expiry = self._store[key]
            if time.time() > expiry:
                del self._store[key]
                return None
            return value

    async def delete(self, key: str) -> None:
        if self.use_redis and self.redis_client:
            await self.redis_client.delete(key)
        else:
            self._store.pop(key, None)


# Global cache service instance
cache_service = CacheService(use_redis=False)  # Switch to True when redis is available
