MOOD_RULES = [
    (
        {
            "speed": "high",
            "acousticelectric": "electric",
            "vocalinstrumental": "instrumental",
        },
        "Party",
    ),
    (
        {
            "speed": "low",
            "acousticelectric": "acoustic",
            "vocalinstrumental": "vocal",
        },
        "Chill",
    ),
    (
        {
            "speed": "low",
            "acousticelectric": "acoustic",
            "vocalinstrumental": "instrumental",
        },
        "Mellow",
    ),
    ({"speed": "high", "acousticelectric": "electric"}, "Energetic"),
]


class MoodService:

    def classify(self, tags: dict[str, str]) -> str:
        for rule_tags, mood in MOOD_RULES:
            if all(tags.get(k) == v for k, v in rule_tags.items()):
                return mood
        return "Neutral"


def get_mood_service() -> MoodService:
    return MoodService()
