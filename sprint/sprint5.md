# Sprint 5: Integrasi API — Last.fm (Rekomendasi) & LRCLIB (Lirik)

**Durasi:** Minggu 5  
**Goal:** User bisa melihat rekomendasi lagu serupa (via Last.fm) dan lirik lagu (via LRCLIB) untuk track yang sedang diputar. Kedua fitur di-cache dan gracefully degrade jika API down.  
**Dependency:** Sprint 3 (Track schema, Jamendo client), Sprint 2 (auth)

---

## Sprint Requirements

Sebelum sprint ini dianggap selesai, **SEMUA** kondisi berikut harus terpenuhi:

- [ ] `GET /api/tracks/{id}/similar` — return list lagu serupa dari Last.fm (paginated)
- [ ] `GET /api/tracks/{id}/lyrics` — return lirik dari LRCLIB (plain text + synced LRC)
- [ ] Rekomendasi di-cache 30 menit, lirik di-cache 24 jam
- [ ] Last.fm down → return 502 atau empty list (graceful)
- [ ] LRCLIB tidak punya lirik → return `{"plain_lyrics": null, "synced_lyrics": null}` (bukan error)
- [ ] `pytest tests/test_tracks.py` — semua test pass (termasuk similar + lyrics)
- [ ] `ruff check app/` — 0 error

---

## Task 5.1: Last.fm API Client

**Deskripsi:** Implementasi `app/services/lastfm.py` — HTTP client untuk Last.fm API. Menggunakan endpoint `track.getSimilar` dan `artist.getSimilar` untuk mendapatkan rekomendasi.

**Acceptance Criteria:**
- [ ] `LastfmClient` class dengan methods:
  - `get_similar_tracks(artist, track_title, limit)` → list[Track]
  - `get_artist_info(artist)` → dict (untuk fitur fun facts nanti)
- [ ] `api_key` diambil dari config
- [ ] Response Last.fm divalidasi (untrusted data)
- [ ] Mapping Last.fm response → internal `Track` schema:
  - `track.name` → `title`
  - `track.artist.name` → `artist`
  - `track.image[2].#text` → `cover_url` (medium size)
  - `source` = `"lastfm"`
- [ ] Caching: similar tracks di-cache 30 menit (`similar:{artist}:{title}`)
- [ ] Last.fm error/down → raise `AppError(EXTERNAL_API_ERROR, ..., 502)`

**Detail Implementasi:**

```python
# app/services/lastfm.py
class LastfmClient:
    BASE_URL = "https://ws.audioscrobbler.com/2.0/"

    async def get_similar_tracks(self, artist: str, track: str, limit: int = 10) -> list[Track]:
        cache_key = f"similar:{artist.lower()}:{track.lower()}"
        cached = await self.cache.get(cache_key)
        if cached:
            return [Track(**t) for t in cached]

        resp = await self.http.get(self.BASE_URL, params={
            "method": "track.getsimilar",
            "artist": artist,
            "track": track,
            "limit": limit,
            "api_key": self.api_key,
            "format": "json",
        })
        # validate, map, cache, return
```

**Verification:**
- [ ] Unit test: get_similar_tracks (mock HTTP) → list[Track]
- [ ] Unit test: cache hit → no HTTP call
- [ ] Unit test: Last.fm returns empty → empty list (no error)
- [ ] Unit test: Last.fm 500 → raise EXTERNAL_API_ERROR
- [ ] `ruff check app/services/lastfm.py` — 0 error

**Dependencies:** Sprint 1 (CacheService, httpx)

**Files:**
- `backend/app/services/lastfm.py`
- `backend/tests/test_lastfm_client.py`

**Scope:** S (2 files)

---

## Task 5.2: LRCLIB API Client

**Deskripsi:** Implementasi `app/services/lrclib.py` — HTTP client untuk LRCLIB API. Mengambil lirik (plain text dan synchronized LRC) berdasarkan artist + title.

**Acceptance Criteria:**
- [ ] `LrclibClient` class dengan methods:
  - `get_lyrics(artist, title, album?, duration?)` → TrackLyrics | None
- [ ] Request ke `GET https://lrclib.net/api/get` dengan params `artist_name`, `track_name`
- [ ] Fallback ke `GET https://lrclib.net/api/search` jika exact match gagal
- [ ] `User-Agent` header wajib: `OpenMusic/1.0 (https://github.com/username/openmusic)`
- [ ] Response mapping:
  - `plainLyrics` → `plain_lyrics`
  - `syncedLyrics` → `synced_lyrics` (LRC format)
- [ ] Caching: lyrics di-cache 24 jam (`lyrics:{artist}:{title}`)
- [ ] Lirik tidak ditemukan → return `None` (bukan raise error)
- [ ] LRCLIB down → return `None` (graceful degradation)

**Detail Implementasi:**

```python
# app/services/lrclib.py
class LrclibClient:
    BASE_URL = "https://lrclib.net/api"
    HEADERS = {"User-Agent": "OpenMusic/1.0 (https://github.com/username/openmusic)"}

    async def get_lyrics(self, artist: str, title: str) -> TrackLyrics | None:
        cache_key = f"lyrics:{artist.lower()}:{title.lower()}"
        cached = await self.cache.get(cache_key)
        if cached:
            return TrackLyrics(**cached)

        try:
            resp = await self.http.get(f"{self.BASE_URL}/get", params={
                "artist_name": artist,
                "track_name": title,
            }, headers=self.HEADERS)
            if resp.status_code == 404:
                # Try search fallback
                ...
            # map response, cache, return
        except httpx.HTTPError:
            return None  # graceful degradation
```

**Verification:**
- [ ] Unit test: get_lyrics found → TrackLyrics with plain + synced
- [ ] Unit test: get_lyrics not found → None
- [ ] Unit test: cache hit → no HTTP call
- [ ] Unit test: LRCLIB down → None (no exception)
- [ ] Unit test: search fallback when exact match returns 404
- [ ] `ruff check app/services/lrclib.py` — 0 error

**Dependencies:** Sprint 1 (CacheService, httpx)

**Files:**
- `backend/app/services/lrclib.py`
- `backend/tests/test_lrclib_client.py`

**Scope:** S (2 files)

---

## Task 5.3: Track Service Update — Similar & Lyrics Endpoints

**Deskripsi:** Perbarui `TrackService` dan router untuk menambahkan endpoint `/similar` dan `/lyrics`. Service mengorkestrasi: pertama ambil track detail dari Jamendo (untuk mendapat artist + title), lalu panggil Last.fm/LRCLIB.

**Acceptance Criteria:**
- [ ] `TrackService` method baru:
  - `get_similar(track_id)` → PaginatedResponse[Track]
  - `get_lyrics(track_id)` → TrackLyrics
- [ ] Flow `get_similar`:
  1. Ambil track detail dari Jamendo (atau cache)
  2. Panggil `LastfmClient.get_similar_tracks(artist, title)`
  3. Return hasil
- [ ] Flow `get_lyrics`:
  1. Ambil track detail dari Jamendo (atau cache)
  2. Panggil `LrclibClient.get_lyrics(artist, title)`
  3. Return hasil (atau `null` lyrics jika tidak ditemukan)
- [ ] Endpoint `GET /api/tracks/{id}/similar` → PaginatedResponse[Track]
- [ ] Endpoint `GET /api/tracks/{id}/lyrics` → TrackLyrics
- [ ] Lirik null → return 200 dengan `plain_lyrics: null, synced_lyrics: null`

**Verification:**
- [ ] Integration test: `GET /api/tracks/{id}/similar` → paginated tracks
- [ ] Integration test: `GET /api/tracks/{id}/lyrics` → lyrics object
- [ ] Integration test: track tanpa lirik → 200, null lyrics
- [ ] Integration test: tanpa auth → 401
- [ ] `pytest tests/test_tracks.py -v` — semua PASSED
- [ ] `ruff check app/modules/tracks/` — 0 error

**Dependencies:** Task 5.1, Task 5.2

**Files:**
- `backend/app/modules/tracks/service.py` (update)
- `backend/app/modules/tracks/router.py` (update)
- `backend/app/modules/tracks/schemas.py` (update: add TrackLyrics)
- `backend/tests/test_tracks.py` (update)

**Scope:** M (4 files)

---

## Checkpoint: Sprint 5

Setelah semua task selesai, verifikasi:

- [ ] **Vertical slice berfungsi:** Login → Search → Play → Lihat lirik → Lihat rekomendasi
- [ ] Last.fm similar tracks berfungsi dan di-cache
- [ ] LRCLIB lyrics berfungsi dan di-cache
- [ ] Graceful degradation: API down → fitur tidak crash, return null/empty
- [ ] `pytest tests/ -v` → semua test PASSED
- [ ] `ruff check app/ tests/` — 0 error
- [ ] Swagger docs menampilkan `/similar` dan `/lyrics` endpoint
- [ ] Semua kode sudah di-commit
- [ ] **Sistem dalam keadaan working** — siap untuk Sprint 6 (Mood & Cocktail)
