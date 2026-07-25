from app.modules.favorites.service import FavoriteService


def get_favorite_service() -> FavoriteService:
    return FavoriteService()
