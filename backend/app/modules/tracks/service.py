import math

from app.modules.tracks.schemas import PaginatedResponse, PaginationMeta, Track
from app.services.jamendo import JamendoClient


class TrackService:
    def __init__(self, jamendo_client: JamendoClient):
        self.jamendo = jamendo_client

    async def search(
        self, query: str, page: int = 1, page_size: int = 20
    ) -> PaginatedResponse[Track]:
        tracks, total = await self.jamendo.search(query, page, page_size)

        total_pages = math.ceil(total / page_size) if page_size > 0 else 0

        meta = PaginationMeta(
            total=total,
            page=page,
            page_size=page_size,
            total_pages=total_pages,
        )
        return PaginatedResponse(data=tracks, meta=meta)

    async def get_detail(self, track_id: str) -> Track:
        return await self.jamendo.get_track(track_id)

    async def get_stream_url(self, track_id: str) -> dict:
        url = await self.jamendo.get_stream_url(track_id)
        return {"audio_url": url}
