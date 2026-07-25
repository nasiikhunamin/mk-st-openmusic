from unittest.mock import AsyncMock

import httpx
import pytest
from httpx import Response

from app.services.cocktaildb import CocktailDBClient


@pytest.fixture
def mock_cache():
    cache = AsyncMock()
    cache.get.return_value = None
    return cache


@pytest.fixture
def cocktail_client(mock_cache):
    client = CocktailDBClient()
    client.cache = mock_cache
    client.http = AsyncMock()
    return client


@pytest.mark.asyncio
async def test_get_cocktail_by_mood_success(cocktail_client, mock_cache):
    # Mock category filter response
    cocktail_client.http.get.side_effect = [
        Response(
            200,
            json={"drinks": [{"strDrink": "Margarita", "idDrink": "11007"}]},
            request=AsyncMock(),
        ),
        Response(
            200,
            json={
                "drinks": [
                    {
                        "strDrink": "Margarita",
                        "strDrinkThumb": "http://image",
                        "strInstructions": "Mix it",
                        "strIngredient1": "Tequila",
                        "strMeasure1": "1.5 oz",
                        "strIngredient2": "Lime juice",
                        "strMeasure2": None,
                    }
                ]
            },
            request=AsyncMock(),
        ),
    ]

    pairing = await cocktail_client.get_cocktail_by_mood("Energetic")
    assert pairing is not None
    assert pairing.mood == "Energetic"
    assert pairing.cocktail_name == "Margarita"
    assert pairing.cocktail_image == "http://image"
    assert pairing.ingredients == ["1.5 oz Tequila", "Lime juice"]
    assert pairing.instructions == "Mix it"

    # Verify cache set
    mock_cache.set.assert_called_once()


@pytest.mark.asyncio
async def test_get_cocktail_by_mood_cache_hit(cocktail_client, mock_cache):
    mock_cache.get.return_value = {
        "mood": "Energetic",
        "cocktail_name": "Cached Margarita",
        "cocktail_image": "http://cached",
        "ingredients": ["Tequila"],
        "instructions": "Drink it",
    }

    pairing = await cocktail_client.get_cocktail_by_mood("Energetic")
    assert pairing is not None
    assert pairing.cocktail_name == "Cached Margarita"

    cocktail_client.http.get.assert_not_called()


@pytest.mark.asyncio
async def test_get_cocktail_by_mood_unknown_mood_fallback(cocktail_client):
    # Unknown mood "Neutral" doesn't map to a category, so it should call /random.php
    cocktail_client.http.get.side_effect = [
        Response(
            200,
            json={"drinks": [{"idDrink": "99999"}]},
            request=AsyncMock(),
        ),
        Response(
            200,
            json={
                "drinks": [
                    {
                        "strDrink": "Random Cocktail",
                        "strIngredient1": "Water",
                    }
                ]
            },
            request=AsyncMock(),
        ),
    ]

    pairing = await cocktail_client.get_cocktail_by_mood("Neutral")
    assert pairing is not None
    assert pairing.cocktail_name == "Random Cocktail"
    assert pairing.ingredients == ["Water"]


@pytest.mark.asyncio
async def test_get_cocktail_by_mood_api_down(cocktail_client):
    cocktail_client.http.get.side_effect = httpx.HTTPError("API Down")

    pairing = await cocktail_client.get_cocktail_by_mood("Chill")
    assert pairing is None
