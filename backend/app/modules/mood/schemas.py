from pydantic import BaseModel


class TrackMood(BaseModel):
    track_id: str
    mood: str
    tags: dict[str, str]


class CocktailPairing(BaseModel):
    mood: str
    cocktail_name: str
    cocktail_image: str | None = None
    ingredients: list[str]
    instructions: str | None = None
