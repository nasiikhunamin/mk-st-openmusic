from app.modules.playlists.service import PlaylistService


def get_playlist_service() -> PlaylistService:
    return PlaylistService()
