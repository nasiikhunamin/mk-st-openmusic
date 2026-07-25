# Sprint 6: Fitur "Wow" — Mood Detection & Cocktail Pairing

**Durasi:** Minggu 6  
**Goal:** User bisa melihat mood lagu (berdasarkan Jamendo tags) dan mendapat rekomendasi koktail berdasarkan mood. Fitur fun facts artis juga tersedia.  
**Dependency:** Sprint 3 (Jamendo client), Sprint 5 (Last.fm client)

---

## Sprint Requirements

Sebelum sprint ini dianggap selesai, **SEMUA** kondisi berikut harus terpenuhi:

- [ ] `GET /api/tracks/{id}/mood` — return mood detection berdasarkan Jamendo tags
- [ ] `GET /api/tracks/{id}/cocktail` — return mood + cocktail pairing
- [ ] Mood classification berfungsi (Energetic, Chill, Party, Mellow, dll)
- [ ] Cocktail dari TheCocktailDB sesuai mood mapping
- [ ] Semua fitur di-cache
- [ ] `pytest tests/test_mood.py` — semua test pass
- [ ] `ruff check app/` — 0 error

---

## Task 6.1: Mood Classification Service

**Deskripsi:** Implementasi `app/modules/mood/service.py` dengan logika mood classification berdasarkan Jamendo track metadata (tags seperti speed, acousticelectric, vocalinstrumental, genre). Ini pure business logic — tidak ada API call.

**Acceptance Criteria:**
- [ ] `MoodService.classify(tags: dict)` → `TrackMood`
- [ ] Mood categories sesuai PRD §10.2:
  - fast + electric + rock → `"Energetic"`
  - slow + acoustic + vocal → `"Chill"`
  - fast + electronic + instrumental → `"Party"`
  - slow + acoustic + instrumental → `"Mellow"`
  - Default fallback → `"Neutral"`
- [ ] Tags diambil dari Jamendo `musicinfo` field:
  - `speed`: `"low"` / `"medium"` / `"high"`
  - `acousticelectric`: `"acoustic"` / `"electric"`
  - `vocalinstrumental`: `"vocal"` / `"instrumental"`
- [ ] Pure function — bisa di-test tanpa DB atau API

**Detail Implementasi:**

```python
# app/modules/mood/service.py
MOOD_RULES = [
    ({"speed": "high", "acousticelectric": "electric"}, "Energetic"),
    ({"speed": "low", "acousticelectric": "acoustic", "vocalinstrumental": "vocal"}, "Chill"),
    ({"speed": "high", "acousticelectric": "electric", "vocalinstrumental": "instrumental"}, "Party"),
    ({"speed": "low", "acousticelectric": "acoustic", "vocalinstrumental": "instrumental"}, "Mellow"),
]

class MoodService:
    def classify(self, tags: dict[str, str]) -> str:
        for rule_tags, mood in MOOD_RULES:
            if all(tags.get(k) == v for k, v in rule_tags.items()):
                return mood
        return "Neutral"
```

**Verification:**
- [ ] Unit test: high speed + electric → "Energetic"
- [ ] Unit test: low speed + acoustic + vocal → "Chill"
- [ ] Unit test: unknown combination → "Neutral"
- [ ] Unit test: empty tags → "Neutral"
- [ ] `ruff check app/modules/mood/` — 0 error

**Dependencies:** Tidak ada (pure logic)

**Files:**
- `backend/app/modules/mood/__init__.py`
- `backend/app/modules/mood/service.py`
- `backend/app/modules/mood/schemas.py`
- `backend/tests/test_mood.py`

**Scope:** S (3 files + test)

---

## Task 6.2: TheCocktailDB API Client

**Deskripsi:** Implementasi `app/services/cocktaildb.py` — HTTP client untuk TheCocktailDB API. Mengambil koktail berdasarkan mood mapping (mood → cocktail category → random cocktail).

**Acceptance Criteria:**
- [ ] `CocktailDBClient` class dengan method:
  - `get_cocktail_by_mood(mood: str)` → `CocktailPairing`
- [ ] Mood → cocktail category mapping:
  - `"Energetic"` → alcoholic cocktails (category: "Cocktail")
  - `"Chill"` → non-alcoholic/refreshing (category: "Ordinary_Drink")
  - `"Party"` → shot (category: "Shot")
  - `"Mellow"` → coffee/cocoa (category: "Coffee_/_Tea")
  - `"Neutral"` → random popular cocktail
- [ ] TheCocktailDB endpoint: `https://www.thecocktaildb.com/api/json/v1/1/filter.php?c={category}`
- [ ] Detail endpoint: `https://www.thecocktaildb.com/api/json/v1/1/lookup.php?i={id}`
- [ ] Caching: cocktail per mood di-cache 1 jam (`cocktail:{mood}`)
- [ ] Response mapping → `CocktailPairing` schema (PRD §4.4)

**Verification:**
- [ ] Unit test: get_cocktail_by_mood("Energetic") → CocktailPairing
- [ ] Unit test: cache hit → no HTTP call
- [ ] Unit test: unknown mood → fallback random cocktail
- [ ] Unit test: API down → graceful (AppError atau None)
- [ ] `ruff check app/services/cocktaildb.py` — 0 error

**Dependencies:** Sprint 1 (CacheService, httpx)

**Files:**
- `backend/app/services/cocktaildb.py`
- `backend/tests/test_cocktaildb_client.py`

**Scope:** S (2 files)

---

## Task 6.3: Mood & Cocktail Router + Integration with Track

**Deskripsi:** Buat endpoint `/api/tracks/{id}/mood` dan `/api/tracks/{id}/cocktail` yang mengorkestrasi: ambil track dari Jamendo → classify mood → fetch cocktail.

**Acceptance Criteria:**
- [ ] `GET /api/tracks/{id}/mood` → `TrackMood` (mood + tags)
- [ ] `GET /api/tracks/{id}/cocktail` → `CocktailPairing` (mood + cocktail name + ingredients)
- [ ] Flow mood:
  1. Fetch track dari Jamendo (include musicinfo)
  2. Extract tags
  3. Classify mood
  4. Return TrackMood
- [ ] Flow cocktail:
  1. Get mood (reuse step di atas)
  2. Fetch cocktail by mood dari TheCocktailDB
  3. Return CocktailPairing
- [ ] Mood + cocktail di-cache
- [ ] Track tanpa musicinfo tags → return mood "Neutral"

**Verification:**
- [ ] Integration test: `GET /api/tracks/{id}/mood` → mood object
- [ ] Integration test: `GET /api/tracks/{id}/cocktail` → cocktail pairing
- [ ] Integration test: tanpa auth → 401
- [ ] Manual test: coba dengan real Jamendo track ID
- [ ] `pytest tests/test_mood.py -v` — semua PASSED
- [ ] `ruff check app/` — 0 error

**Dependencies:** Task 6.1, Task 6.2

**Files:**
- `backend/app/modules/mood/router.py`
- `backend/app/modules/tracks/router.py` (update: include mood endpoints)
- `backend/app/api/v1/router.py` (update if needed)
- `backend/tests/test_mood.py` (update: integration tests)

**Scope:** S (3 files)

---

## Checkpoint: Sprint 6

Setelah semua task selesai, verifikasi:

- [ ] **Fitur "Wow" berfungsi:** Play track → Lihat mood → Dapatkan cocktail recommendation
- [ ] Mood classification: 4 mood categories + Neutral fallback
- [ ] Cocktail pairing: mood → kategori koktail → detail koktail
- [ ] Graceful degradation jika TheCocktailDB down
- [ ] `pytest tests/ -v` → semua test PASSED
- [ ] `ruff check app/ tests/` — 0 error
- [ ] Semua kode sudah di-commit
- [ ] **Backend LENGKAP** — semua endpoint PRD sudah diimplementasi
- [ ] **Siap untuk Sprint 7 (Frontend Flutter)**
