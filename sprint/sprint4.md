# Sprint 4: Playlist CRUD, Favorites, dan History

**Durasi:** Minggu 4  
**Goal:** User bisa membuat/edit/hapus playlist, menambah/hapus lagu ke playlist, menandai lagu favorit, dan riwayat putar tercatat otomatis. Semua data disimpan di database sendiri.  
**Dependency:** Sprint 3 (Track schema, auth, DB connection)

---

## Sprint Requirements

Sebelum sprint ini dianggap selesai, **SEMUA** kondisi berikut harus terpenuhi:

- [ ] Playlist CRUD lengkap: create, list, detail, update (rename), delete
- [ ] Playlist tracks: add track, remove track, list tracks with pagination
- [ ] Favorites: add, list (paginated), remove
- [ ] History: record play, list (paginated, newest first)
- [ ] User hanya bisa akses playlist/favorites/history milik sendiri
- [ ] Duplicate track di playlist/favorites → 409 Conflict
- [ ] `pytest tests/test_playlists.py tests/test_favorites.py tests/test_history.py` — pass
- [ ] `ruff check app/` — 0 error

---

## Task 4.1: Alembic Migration — Playlists, Favorites, History Tables

**Deskripsi:** Buat SQLAlchemy models untuk `playlists`, `playlist_tracks`, `favorites`, dan `history` (sesuai PRD §4.6), lalu generate dan apply migration.

**Acceptance Criteria:**
- [ ] `app/modules/playlists/models.py` — `Playlist` dan `PlaylistTrack` model
- [ ] `app/modules/favorites/models.py` — `Favorite` model
- [ ] `app/modules/history/models.py` — `History` model
- [ ] `UNIQUE(playlist_id, track_id)` constraint di `playlist_tracks`
- [ ] `UNIQUE(user_id, track_id)` constraint di `favorites`
- [ ] `position` field di `playlist_tracks` untuk urutan
- [ ] Semua index sesuai PRD §4.6 terbuat
- [ ] `alembic revision --autogenerate` + `alembic upgrade head` berhasil

**Verification:**
- [ ] `alembic upgrade head` → tabel baru terbuat
- [ ] `alembic downgrade -1` → tabel baru dihapus (reversible)
- [ ] Connect ke DB → semua 4 tabel baru ada + indexes ada
- [ ] `ruff check app/modules/` — 0 error

**Dependencies:** Sprint 3 (existing migration + models)

**Files:**
- `backend/app/modules/playlists/__init__.py`
- `backend/app/modules/playlists/models.py`
- `backend/app/modules/favorites/__init__.py`
- `backend/app/modules/favorites/models.py`
- `backend/app/modules/history/__init__.py`
- `backend/app/modules/history/models.py`
- `backend/alembic/versions/xxxx_create_playlists_favorites_history.py`

**Scope:** M (4 model files + 1 migration)

---

## Task 4.2: Playlist Service, Schemas & Router (Full CRUD)

**Deskripsi:** Implementasi seluruh playlist feature: schemas (PRD §4.4 Playlist Schemas), service layer, dan router dengan 7 endpoint (PRD §4.2 Playlists).

**Acceptance Criteria:**
- [ ] Schemas: `CreatePlaylistInput`, `UpdatePlaylistInput`, `AddTrackToPlaylistInput`, `Playlist`, `PlaylistDetail`
- [ ] Service methods:
  - `create(db, user_id, input)` → Playlist
  - `list_by_user(db, user_id, page, page_size)` → PaginatedResponse[Playlist]
  - `get_detail(db, user_id, playlist_id)` → PlaylistDetail (with tracks)
  - `update(db, user_id, playlist_id, input)` → Playlist
  - `delete(db, user_id, playlist_id)` → None
  - `add_track(db, user_id, playlist_id, input)` → None
  - `remove_track(db, user_id, playlist_id, track_id)` → None
- [ ] Authorization: service verifikasi `playlist.user_id == current_user.id`
- [ ] Playlist milik user lain → raise `AUTHORIZATION_ERROR` (403)
- [ ] Playlist not found → raise `NOT_FOUND` (404)
- [ ] Duplicate track → raise `CONFLICT` (409)
- [ ] 7 endpoint di router sesuai PRD §4.2 Playlists

**Verification:**
- [ ] Integration test: create playlist → 201
- [ ] Integration test: list playlists → paginated (hanya milik user sendiri)
- [ ] Integration test: get detail → playlist + tracks
- [ ] Integration test: rename playlist (PATCH) → 200
- [ ] Integration test: delete playlist → 200, GET setelahnya → 404
- [ ] Integration test: add track → 200, add duplicate → 409
- [ ] Integration test: remove track → 200
- [ ] Integration test: akses playlist user lain → 403
- [ ] `pytest tests/test_playlists.py -v` — semua PASSED
- [ ] `ruff check app/modules/playlists/` — 0 error

**Dependencies:** Task 4.1

**Files:**
- `backend/app/modules/playlists/schemas.py`
- `backend/app/modules/playlists/service.py`
- `backend/app/modules/playlists/router.py`
- `backend/app/api/v1/router.py` (update)
- `backend/tests/test_playlists.py`

**Scope:** M (5 files)

---

## Task 4.3: Favorites Service, Schemas & Router

**Deskripsi:** Implementasi favorites feature: schemas, service, dan router dengan 3 endpoint (PRD §4.2 Favorites).

**Acceptance Criteria:**
- [ ] Schemas: `AddFavoriteInput` (PRD §4.4)
- [ ] Service methods:
  - `add(db, user_id, input)` → None
  - `list_by_user(db, user_id, page, page_size)` → PaginatedResponse[Track] (dari stored metadata)
  - `remove(db, user_id, track_id)` → None
- [ ] Duplicate favorite → raise `CONFLICT` (409)
- [ ] Remove non-existent → raise `NOT_FOUND` (404)
- [ ] 3 endpoint di router sesuai PRD §4.2 Favorites

**Verification:**
- [ ] Integration test: add favorite → 201
- [ ] Integration test: list favorites → paginated
- [ ] Integration test: add duplicate → 409
- [ ] Integration test: remove favorite → 200
- [ ] Integration test: remove non-existent → 404
- [ ] `pytest tests/test_favorites.py -v` — semua PASSED
- [ ] `ruff check app/modules/favorites/` — 0 error

**Dependencies:** Task 4.1

**Files:**
- `backend/app/modules/favorites/schemas.py`
- `backend/app/modules/favorites/service.py`
- `backend/app/modules/favorites/router.py`
- `backend/app/api/v1/router.py` (update)
- `backend/tests/test_favorites.py`

**Scope:** S (4 files)

---

## Task 4.4: History Service, Schemas & Router

**Deskripsi:** Implementasi history feature: schemas, service, dan router. History di-record saat user memutar lagu (called by track stream endpoint) dan bisa di-list (paginated, newest first).

**Acceptance Criteria:**
- [ ] Service methods:
  - `record(db, user_id, track_id, track_metadata)` → None (tidak perlu unique — bisa putar berkali-kali)
  - `list_by_user(db, user_id, page, page_size)` → PaginatedResponse[HistoryEntry]
- [ ] `HistoryEntry` schema: Track data + `played_at` timestamp
- [ ] List sorted by `played_at DESC` (newest first)
- [ ] 1 GET endpoint di router sesuai PRD §4.2 History
- [ ] Track stream endpoint (`GET /api/tracks/{id}/stream`) diperbarui: setelah return stream URL, record ke history

**Verification:**
- [ ] Integration test: list history (empty) → paginated, 0 items
- [ ] Integration test: stream track → cek history terecord
- [ ] Integration test: stream 3 kali → history punya 3 entry
- [ ] Integration test: list sorted newest first
- [ ] `pytest tests/test_history.py -v` — semua PASSED
- [ ] `ruff check app/modules/history/` — 0 error

**Dependencies:** Task 4.1, Sprint 3 (track stream endpoint)

**Files:**
- `backend/app/modules/history/schemas.py`
- `backend/app/modules/history/service.py`
- `backend/app/modules/history/router.py`
- `backend/app/modules/tracks/router.py` (update: record history on stream)
- `backend/app/api/v1/router.py` (update)
- `backend/tests/test_history.py`

**Scope:** M (5 files)

---

## Checkpoint: Sprint 4

Setelah semua task selesai, verifikasi:

- [ ] **Vertical slice berfungsi:** Login → Search → Stream → History tercatat → Add to playlist → Add to favorites
- [ ] Playlist full CRUD: create, list, detail, rename, delete, add/remove tracks
- [ ] Favorites: add, list, remove
- [ ] History: auto-record on stream, list newest first
- [ ] Authorization: user hanya akses milik sendiri
- [ ] `pytest tests/ -v` → semua test PASSED (auth + tracks + playlists + favorites + history)
- [ ] `ruff check app/ tests/` — 0 error
- [ ] Swagger docs menampilkan semua endpoint
- [ ] Semua kode sudah di-commit
- [ ] **Sistem dalam keadaan working** — siap untuk Sprint 5 (Rekomendasi & Lirik)
