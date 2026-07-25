from pydantic import BaseModel


class AddFavoriteInput(BaseModel):
    track_id: str
    track_metadata: dict
