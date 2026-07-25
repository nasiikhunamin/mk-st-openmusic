from fastapi import APIRouter

from app.modules.auth.router import auth_router
from app.modules.playlists.router import playlists_router
from app.modules.tracks.router import tracks_router

api_router = APIRouter(prefix="/api")
api_router.include_router(auth_router, prefix="/auth", tags=["Auth"])
api_router.include_router(tracks_router, prefix="/tracks", tags=["Tracks"])
api_router.include_router(playlists_router, prefix="/playlists", tags=["Playlists"])
