from app.modules.history.service import HistoryService


def get_history_service() -> HistoryService:
    return HistoryService()
