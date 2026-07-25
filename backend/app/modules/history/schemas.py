from datetime import datetime
from uuid import UUID

from pydantic import BaseModel, ConfigDict

from app.modules.tracks.schemas import Track


class HistoryEntry(BaseModel):
    id: UUID
    track: Track
    played_at: datetime

    model_config = ConfigDict(from_attributes=True)
