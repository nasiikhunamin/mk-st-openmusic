from app.modules.mood.service import MoodService


def test_mood_energetic():
    service = MoodService()
    tags = {"speed": "high", "acousticelectric": "electric"}
    assert service.classify(tags) == "Energetic"


def test_mood_party():
    service = MoodService()
    tags = {
        "speed": "high",
        "acousticelectric": "electric",
        "vocalinstrumental": "instrumental",
    }
    assert service.classify(tags) == "Party"


def test_mood_chill():
    service = MoodService()
    tags = {
        "speed": "low",
        "acousticelectric": "acoustic",
        "vocalinstrumental": "vocal",
    }
    assert service.classify(tags) == "Chill"


def test_mood_mellow():
    service = MoodService()
    tags = {
        "speed": "low",
        "acousticelectric": "acoustic",
        "vocalinstrumental": "instrumental",
    }
    assert service.classify(tags) == "Mellow"


def test_mood_neutral_fallback():
    service = MoodService()
    # Unknown combinations
    assert service.classify({"speed": "medium"}) == "Neutral"
    # Empty tags
    assert service.classify({}) == "Neutral"
