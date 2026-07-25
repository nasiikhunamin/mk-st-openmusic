# Sprint 3: Jamendo Integration — Search, Detail, Streaming

**Durasi:** Minggu 3  
**Goal:** User yang sudah login bisa mencari lagu dari Jamendo, melihat detail lagu, dan mendapatkan URL streaming. Hasil pencarian di-cache di Redis.  
**Dependency:** Sprint 2 (auth flow, get_current_user dependency)

---

## Sprint Requirements

Sebelum sprint ini dianggap selesai, **SEMUA** kondisi berikut harus terpenuhi:

- [ ] `GET /api/tracks?q={query}&page=1&pageSize=20` — mencari lagu dari Jamendo, return paginated response
- [ ] `GET /api/tracks/{id}` — detail satu lagu dari Jamendo
- [ ] `GET /api/tracks/{id}/stream` — URL streaming lagu dari Jamendo
- [ ] Semua endpoint memerlukan auth (JWT Bearer token)
- [ ] Hasil pencarian di-cache di Redis (TTL 5 menit)
- [ ] Detail lagu di-cache di Redis (TTL 1 jam)
- [ ] Response sesuai `Track` schema (PRD §4.4)
- [ ] Jamendo down → return 502 dengan Error Contract format
- [ ] `pytest tests/test_tracks.py` — semua test pass (mock Jamendo API)
- [ ] `ruff check app/` — 0 error

---

## Task 3.1: Jamendo API Client

**Deskripsi:** Implementasi `app/services/jamendo.py` — HTTP client untuk Jamendo API v3.0. Client menggunakan `httpx.AsyncClient`, memanfaatkan `CacheService` untuk cache, dan memetakan response Jamendo ke `Track` schema internal.

**Acceptance Criteria:**
- [ ] `JamendoClient` class dengan methods:
  - `search(query, page, page_size)` → list[Track] + total count
  - `get_track(track_id)` → Track
  - `get_stream_url(track_id)` → str (audio URL)
- [ ] Menggunakan `httpx.AsyncClient` (bukan requests)
- [ ] `client_id` diambil dari config (bukan hardcode)
- [ ] Response Jamendo divalidasi sebelum digunakan (untrusted data)
- [ ] Jamendo API error → raise `AppError(EXTERNAL_API_ERROR, ..., 502)`
- [ ] Mapping Jamendo response → internal `Track` schema:
  - `results[].id` → `id` (string)
  - `results[].name` → `title`
  - `results[].artist_name` → `artist`
  - `results[].album_name` → `album`
  - `results[].image` → `cover_url`
  - `results[].audio` → `audio_url`
  - `results[].duration` → `duration`

**Detail Implementasi:**

```python
# app/services/jamendo.py
class JamendoClient:
    BASE_URL = "https://api.jamendo.com/v3.0"

    def __init__(self, client_id: str, http_client: httpx.AsyncClient, cache: CacheService):
        self.client_id = client_id
        self.http = http_client
        self.cache = cache

    async def search(self, query: str, page: int = 1, page_size: int = 20) -> tuple[list[Track], int]:
        cache_key = f"search:{hashlib.md5(f'{query}:{page}:{page_size}'.encode()).hexdigest()}"
        cached = await self.cache.get(cache_key)
        if cached:
            return [Track(**t) for t in cached["tracks"]], cached["total"]

        resp = await self.http.get(f"{self.BASE_URL}/tracks", params={
            "client_id": self.client_id,
            "search": query,
            "limit": page_size,
            "offset": (page - 1) * page_size,
            "format": "json",
            "include": "musicinfo",
        })
        # validate, map, cache, return
```

**Verification:**
- [ ] Unit test: search dengan mock HTTP → return list[Track]
- [ ] Unit test: search cache hit → tidak call HTTP
- [ ] Unit test: get_track → return Track
- [ ] Unit test: Jamendo 500 → raise EXTERNAL_API_ERROR
- [ ] `ruff check app/services/jamendo.py` — 0 error

**Dependencies:** Sprint 2 (CacheService dari Sprint 1)

**Files:**
- `backend/app/services/jamendo.py`
- `backend/tests/test_jamendo_client.py`

**Scope:** S (2 files)

---

## Task 3.2: Track Schemas & Service Layer

**Deskripsi:** Implementasi `app/modules/tracks/schemas.py` (Track, PaginatedResponse sesuai PRD §4.4) dan `app/modules/tracks/service.py` yang mengorkestrasi Jamendo client + cache.

**Acceptance Criteria:**
- [ ] `schemas.py` mengimplementasikan `Track`, `PaginationMeta`, `PaginatedResponse[Track]`
- [ ] `TrackService` class dengan methods:
  - `search(query, page, page_size)` → PaginatedResponse[Track]
  - `get_detail(track_id)` → Track
  - `get_stream_url(track_id)` → dict with `audio_url`
- [ ] Service memanggil JamendoClient, bukan langsung ke HTTP
- [ ] Pagination math benar: `total_pages = ceil(total / page_size)`

**Verification:**
- [ ] Unit test: search → return PaginatedResponse dengan pagination metadata
- [ ] Unit test: pagination math edge cases (0 results, exact multiple)
- [ ] `ruff check app/modules/tracks/` — 0 error

**Dependencies:** Task 3.1

**Files:**
- `backend/app/modules/tracks/__init__.py`
- `backend/app/modules/tracks/schemas.py`
- `backend/app/modules/tracks/service.py`

**Scope:** S (3 files)

---

## Task 3.3: Track Router — Search, Detail, Stream Endpoints

**Deskripsi:** Implementasi 3 endpoint track di router, register ke API v1 router, dan pastikan semua endpoint di-protect oleh `get_current_user`.

**Acceptance Criteria:**
- [ ] `GET /api/tracks?q={query}&page=1&pageSize=20` → PaginatedResponse[Track]
- [ ] `GET /api/tracks/{id}` → Track
- [ ] `GET /api/tracks/{id}/stream` → `{"audio_url": "https://..."}`
- [ ] Tanpa query param `q` → return 422 validation error
- [ ] Tanpa auth → return 401
- [ ] Track not found → return 404
- [ ] Router di-register: `api_router.include_router(tracks_router, prefix="/tracks", tags=["Tracks"])`

**Verification:**
- [ ] Integration test: search "rock" → paginated tracks
- [ ] Integration test: get track detail → track object
- [ ] Integration test: get stream → audio_url
- [ ] Integration test: tanpa auth → 401
- [ ] Manual: `curl -H "Authorization: Bearer {token}" "http://localhost:8000/api/tracks?q=jazz"` → JSON response
- [ ] `ruff check app/` — 0 error

**Dependencies:** Task 3.2

**Files:**
- `backend/app/modules/tracks/router.py`
- `backend/app/api/v1/router.py` (update: include tracks_router)
- `backend/tests/test_tracks.py`

**Scope:** S (3 files)

---

## Checkpoint: Sprint 3

Setelah semua task selesai, verifikasi:

- [ ] **Vertical slice berfungsi end-to-end:** Login → Search lagu → Lihat detail → Dapatkan stream URL
- [ ] Caching bekerja: request pertama hit Jamendo, request kedua dari cache
- [ ] Swagger docs (`/docs`) menampilkan auth + tracks endpoints
- [ ] `pytest tests/ -v` → semua test PASSED (auth + tracks)
- [ ] `ruff check app/ tests/` — 0 error
- [ ] Semua kode sudah di-commit
- [ ] **Sistem dalam keadaan working** — siap untuk Sprint 4 (Playlist & Favorites)

---

## Context untuk Sprint Berikutnya

Sprint 4 akan membangun di atas tracks:
- Playlists menyimpan `track_id` yang merujuk ke ID dari Jamendo
- `track_metadata` (JSONB) menyimpan snapshot Track untuk offline access
- Favorites menggunakan pattern yang sama
