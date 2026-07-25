import random

import httpx

from app.modules.mood.schemas import CocktailPairing
from app.services.cache import cache_service


class CocktailDBClient:
    BASE_URL = "https://www.thecocktaildb.com/api/json/v1/1"

    def __init__(self):
        self.mood_map = {
            "Energetic": "Cocktail",
            "Chill": "Ordinary_Drink",
            "Party": "Shot",
            "Mellow": "Coffee_/_Tea",
        }
        self.cache = cache_service
        self.http = httpx.AsyncClient(timeout=10.0)

    async def close(self):
        await self.http.aclose()

    async def get_cocktail_by_mood(self, mood: str) -> CocktailPairing | None:
        cache_key = f"cocktail:{mood.lower()}"
        cached = await self.cache.get(cache_key)
        if cached:
            return CocktailPairing(**cached)

        category = self.mood_map.get(mood)

        try:
            drink_id = None
            if category:
                # 1. Fetch list of drinks for category
                resp = await self.http.get(
                    f"{self.BASE_URL}/filter.php", params={"c": category}
                )
                resp.raise_for_status()
                data = resp.json()
                drinks = data.get("drinks")
                if drinks and isinstance(drinks, list):
                    # Pick a random drink
                    chosen_drink = random.choice(drinks)
                    drink_id = chosen_drink.get("idDrink")

            if not drink_id:
                # Fallback to random popular cocktail
                resp = await self.http.get(f"{self.BASE_URL}/random.php")
                resp.raise_for_status()
                data = resp.json()
                drinks = data.get("drinks")
                if drinks and isinstance(drinks, list):
                    drink_id = drinks[0].get("idDrink")

            if not drink_id:
                return None

            # 2. Fetch drink detail
            detail_resp = await self.http.get(
                f"{self.BASE_URL}/lookup.php", params={"i": drink_id}
            )
            detail_resp.raise_for_status()
            detail_data = detail_resp.json()

            detail_drinks = detail_data.get("drinks")
            if not detail_drinks or not isinstance(detail_drinks, list):
                return None

            drink = detail_drinks[0]

            # Extract ingredients
            ingredients = []
            for i in range(1, 16):
                ing = drink.get(f"strIngredient{i}")
                if ing:
                    meas = drink.get(f"strMeasure{i}")
                    if meas:
                        ingredients.append(f"{meas.strip()} {ing.strip()}")
                    else:
                        ingredients.append(ing.strip())

            pairing = CocktailPairing(
                mood=mood,
                cocktail_name=drink.get("strDrink", "Unknown Cocktail"),
                cocktail_image=drink.get("strDrinkThumb"),
                ingredients=ingredients,
                instructions=drink.get("strInstructions"),
            )

            # Cache for 1 hour
            await self.cache.set(cache_key, pairing.model_dump(), ttl_seconds=3600)
            return pairing

        except httpx.HTTPError:
            return None


def get_cocktaildb_client() -> CocktailDBClient:
    return CocktailDBClient()
