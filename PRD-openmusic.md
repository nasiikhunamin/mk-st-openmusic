# Product Requirements Document (PRD)
## Proyek OpenMusic - Aplikasi Pemutar Musik dengan Rekomendasi Cerdas

**Versi:** 2.0  
**Tanggal:** 26 Juli 2026  
**Status:** Draft  
**Penulis:** [Nama Kamu]

---

## 1. Pendahuluan

### 1.1 Tujuan Proyek
OpenMusic adalah aplikasi web pemutar musik dengan fitur sosial dan rekomendasi cerdas yang dibangun sebagai tugas akhir mata kuliah. Aplikasi ini bertujuan untuk memberikan pengalaman mendengarkan musik yang unik dengan menggabungkan beberapa layanan API eksternal ke dalam satu antarmuka yang kohesif.

### 1.2 Lingkup
Proyek ini mencakup pembangunan:
- **Backend** dari nol (FastAPI)
- **Frontend** terpisah (Flutter)
- **Database** sendiri untuk menyimpan data pengguna dan playlist

### 1.3 Objective & Success Criteria

**Objective:** Membangun aplikasi pemutar musik full-stack yang mengintegrasikan minimal 3 API eksternal, dengan backend REST API yang dibangun dari nol, sebagai bukti pemahaman arsitektur sistem terdistribusi.

**Success Criteria:**
- User dapat mendaftar, login, mencari lagu, dan memutar musik full-length
- User dapat membuat playlist, menandai favorit, dan melihat riwayat
- Rekomendasi lagu ditampilkan berdasarkan preferensi user
- Lirik lagu ditampilkan saat pemutaran
- Minimal 2 fitur "Wow" berfungsi dengan baik
- Response time < 500ms untuk cached data (P95)
- Semua endpoint terdokumentasi di Swagger/OpenAPI

---

## 2. Arsitektur Sistem

### 2.1 Gambaran Umum

```
┌─────────────────────────────────────────────────────────┐
│                       Frontend                          │
│                       (Flutter)                         │
└─────────────────────┬───────────────────────────────────┘
                      │ REST API
┌─────────────────────▼───────────────────────────────────┐
│                  Backend (Dari Nol)                      │
│  ┌──────────────────────────────────────────────────┐   │
│  │  • Autentikasi (JWT + Refresh Token)             │   │
│  │  • Manajemen Playlist & Favorit                  │   │
│  │  • Orchestrator API Eksternal                    │   │
│  │  • Caching (Redis)                               │   │
│  └──────────────────────────────────────────────────┘   │
└──────────┬──────────┬──────────┬──────────┬─────────────┘
           │          │          │          │
    ┌──────▼─────┐ ┌──▼──────┐ ┌▼───────┐ ┌▼──────────┐
    │  Database  │ │ Jamendo │ │Last.fm │ │  LRCLIB   │
    │(PostgreSQL)│ │   API   │ │  API   │ │           │
    └────────────┘ └─────────┘ └────────┘ └───────────┘
```

### 2.2 Sumber Data Eksternal

| **API** | **Fungsi** | **Batasan** | **Strategi** |
|---------|------------|-------------|--------------|
| **Jamendo API** | Streaming lagu full-length, metadata, search, mood tags | 35.000 req/bulan | Cache 1 jam |
| **Last.fm API** | Rekomendasi (similar tracks/artists), metadata kaya | 5 req/detik | Cache 30 menit |
| **LRCLIB** | Lirik lagu (plain text & synchronized LRC) | Generous rate limit, no key | Cache 1 hari |
| **TheCocktailDB** (Opsional) | Rekomendasi koktail berdasarkan mood lagu | Gratis, no limit | Cache 1 jam |
| **TasteDive** (Opsional) | Rekomendasi lintas kategori | 300 req/jam | Fallback Last.fm |

> **Catatan:** Spotify Web API **tidak digunakan** karena endpoint `/recommendations`, `/audio-features`, dan `/audio-analysis` sudah di-deprecate sejak November 2024 untuk aplikasi baru (Development Mode mendapat 403 Forbidden). Last.fm dipilih sebagai pengganti karena gratis, stabil, dan menyediakan endpoint `track.getSimilar` serta `artist.getSimilar`.

> **Catatan:** Lyrics.ovh **tidak digunakan** karena sering mengalami downtime dan tidak di-maintain secara aktif. LRCLIB dipilih sebagai pengganti karena gratis, open-source, tanpa API key, dan mendukung synchronized lyrics (LRC format).

---

## 3. Fitur Fungsional

### 3.1 Fitur Utama (Wajib)

| **ID** | **Fitur** | **Deskripsi** | **Sumber Data** | **Prioritas** |
|--------|-----------|---------------|-----------------|---------------|
| F-01 | **Pencarian Musik** | Cari lagu berdasarkan judul, artis, atau album | Jamendo API | P0 |
| F-02 | **Pemutaran Musik** | Putar lagu full-length dengan kontrol pemutar | Jamendo API | P0 |
| F-03 | **Playlist** | Buat, edit, dan hapus playlist pribadi | Database sendiri | P0 |
| F-04 | **Favorit** | Tandai/hapus lagu sebagai favorit | Database sendiri | P0 |
| F-05 | **Lirik** | Tampilkan lirik lagu yang sedang diputar (plain text & synced) | LRCLIB | P1 |
| F-06 | **Rekomendasi** | Rekomendasi lagu serupa berdasarkan track/artist yang diputar | Last.fm API | P1 |
| F-07 | **Autentikasi** | Registrasi, login, logout, refresh token | Database sendiri (JWT) | P0 |

### 3.2 Fitur "Wow" (Nilai Tambah)

| **ID** | **Fitur** | **Deskripsi** | **Sumber Data** | **Prioritas** |
|--------|-----------|---------------|-----------------|---------------|
| F-08 | **Mood Detection** | Deteksi mood lagu berdasarkan tag Jamendo (speed, acousticelectric, vocalinstrumental) | Jamendo API (track metadata) | P2 |
| F-09 | **Cocktail Pairing** | Rekomendasi koktail berdasarkan mood lagu | TheCocktailDB | P2 |
| F-10 | **Musical Fun Facts** | Tampilkan fakta unik tentang artis/lagu | Last.fm artist.getInfo | P3 |
| F-11 | **History** | Riwayat putar lagu pengguna | Database sendiri | P2 |

---

## 4. Spesifikasi Teknis Backend

### 4.1 Teknologi yang Digunakan

| **Komponen** | **Pilihan** | **Alasan** |
|--------------|-------------|------------|
| **Runtime** | Python 3.11+ | Fleksibilitas & ekosistem kaya |
| **Framework** | FastAPI | Async, auto-docs (Swagger), type-safe dengan Pydantic |
| **Database** | PostgreSQL | Relasional untuk data user & playlist |
| **ORM** | SQLAlchemy 2.0 + Alembic | Async support, migration management |
| **Caching** | Redis (redis-py async) | Menghemat kuota API, high performance |
| **Auth** | JWT (access + refresh token) | Stateless & aman |
| **Validation** | Pydantic v2 | Input/output schema validation |
| **Dokumentasi** | Swagger/OpenAPI (built-in FastAPI) | Memudahkan testing & presentasi |
| **Linting** | Ruff | Fastest Python linter/formatter |

### 4.2 Struktur Endpoint (REST API)

#### Auth

| **Method** | **Endpoint** | **Fungsi** | **Auth** |
|------------|--------------|------------|----------|
| POST | `/api/auth/register` | Registrasi pengguna baru | No |
| POST | `/api/auth/login` | Login, mendapat access + refresh token | No |
| POST | `/api/auth/refresh` | Refresh access token menggunakan refresh token | No (refresh token di body) |
| POST | `/api/auth/logout` | Invalidasi refresh token | Yes |
| GET | `/api/auth/me` | Profil user yang sedang login | Yes |

#### Tracks

| **Method** | **Endpoint** | **Fungsi** | **Auth** |
|------------|--------------|------------|----------|
| GET | `/api/tracks?q={query}&page=1&pageSize=20` | Cari lagu (paginated) | Yes |
| GET | `/api/tracks/{id}` | Detail satu lagu | Yes |
| GET | `/api/tracks/{id}/stream` | URL streaming lagu | Yes |
| GET | `/api/tracks/{id}/lyrics` | Lirik lagu (plain text & synced) | Yes |
| GET | `/api/tracks/{id}/similar` | Lagu serupa (rekomendasi) | Yes |
| GET | `/api/tracks/{id}/mood` | Deteksi mood lagu | Yes |

#### Playlists

| **Method** | **Endpoint** | **Fungsi** | **Auth** |
|------------|--------------|------------|----------|
| POST | `/api/playlists` | Buat playlist baru | Yes |
| GET | `/api/playlists?page=1&pageSize=20` | Daftar playlist user (paginated) | Yes |
| GET | `/api/playlists/{id}` | Detail playlist + tracks | Yes |
| PATCH | `/api/playlists/{id}` | Edit playlist (rename, dll) | Yes |
| DELETE | `/api/playlists/{id}` | Hapus playlist | Yes |
| POST | `/api/playlists/{id}/tracks` | Tambah lagu ke playlist | Yes |
| DELETE | `/api/playlists/{id}/tracks/{trackId}` | Hapus lagu dari playlist | Yes |

#### Favorites

| **Method** | **Endpoint** | **Fungsi** | **Auth** |
|------------|--------------|------------|----------|
| POST | `/api/favorites` | Tambah lagu ke favorit | Yes |
| GET | `/api/favorites?page=1&pageSize=20` | Daftar favorit user (paginated) | Yes |
| DELETE | `/api/favorites/{trackId}` | Hapus lagu dari favorit | Yes |

#### History

| **Method** | **Endpoint** | **Fungsi** | **Auth** |
|------------|--------------|------------|----------|
| GET | `/api/history?page=1&pageSize=20` | Riwayat putar user (paginated) | Yes |

#### Mood & Cocktail (Fitur "Wow")

| **Method** | **Endpoint** | **Fungsi** | **Auth** |
|------------|--------------|------------|----------|
| GET | `/api/tracks/{id}/cocktail` | Rekomendasi koktail berdasarkan mood lagu | Yes |

### 4.3 Error Contract

Semua error response mengikuti format yang konsisten:

```json
{
  "error": {
    "code": "VALIDATION_ERROR",
    "message": "Email is required",
    "details": null
  }
}
```

**Mapping HTTP Status Code:**

| **Status Code** | **Arti** | **Contoh** |
|-----------------|----------|------------|
| 400 | Bad Request — data tidak valid | Body kosong, format salah |
| 401 | Unauthorized — belum login | Token expired, tidak ada token |
| 403 | Forbidden — tidak punya akses | Mengakses playlist user lain |
| 404 | Not Found — resource tidak ditemukan | Playlist ID tidak ada |
| 409 | Conflict — duplikat | Email sudah terdaftar |
| 422 | Validation Error — semantically invalid | Password terlalu pendek |
| 429 | Rate Limit — terlalu banyak request | API quota habis |
| 500 | Server Error — kesalahan internal | Tidak pernah expose detail internal |
| 502 | Bad Gateway — API eksternal gagal | Jamendo/Last.fm down |

**Error Code Enum:**

```python
class ErrorCode(str, Enum):
    VALIDATION_ERROR = "VALIDATION_ERROR"
    AUTHENTICATION_ERROR = "AUTHENTICATION_ERROR"
    AUTHORIZATION_ERROR = "AUTHORIZATION_ERROR"
    NOT_FOUND = "NOT_FOUND"
    CONFLICT = "CONFLICT"
    RATE_LIMIT_EXCEEDED = "RATE_LIMIT_EXCEEDED"
    INTERNAL_ERROR = "INTERNAL_ERROR"
    EXTERNAL_API_ERROR = "EXTERNAL_API_ERROR"
```

### 4.4 Validation Schemas (Pydantic)

#### Auth Schemas

```python
class RegisterInput(BaseModel):
    username: str = Field(..., min_length=3, max_length=50, pattern=r"^[a-zA-Z0-9_]+$")
    email: EmailStr
    password: str = Field(..., min_length=8, max_length=128)

class LoginInput(BaseModel):
    email: EmailStr
    password: str

class AuthTokens(BaseModel):
    access_token: str
    refresh_token: str
    token_type: str = "bearer"
    expires_in: int  # detik

class RefreshInput(BaseModel):
    refresh_token: str

class UserProfile(BaseModel):
    id: str  # UUID
    username: str
    email: str
    created_at: datetime
```

#### Track Schemas

```python
class Track(BaseModel):
    id: str
    title: str
    artist: str
    album: str | None = None
    cover_url: str | None = None
    audio_url: str | None = None
    duration: int  # detik
    source: str = "jamendo"  # jamendo | lastfm

class TrackLyrics(BaseModel):
    track_id: str
    plain_lyrics: str | None = None
    synced_lyrics: str | None = None  # LRC format
    source: str = "lrclib"

class TrackMood(BaseModel):
    track_id: str
    mood: str  # "Energetic", "Chill", "Dark", "Happy", dll
    tags: dict[str, str]  # speed, acousticelectric, dll

class CocktailPairing(BaseModel):
    mood: str
    cocktail_name: str
    cocktail_image: str | None = None
    ingredients: list[str]
    instructions: str | None = None
```

#### Playlist Schemas

```python
class CreatePlaylistInput(BaseModel):
    name: str = Field(..., min_length=1, max_length=100)

class UpdatePlaylistInput(BaseModel):
    name: str | None = Field(None, min_length=1, max_length=100)

class AddTrackToPlaylistInput(BaseModel):
    track_id: str
    track_metadata: dict  # metadata dari Jamendo, disimpan untuk offline access

class Playlist(BaseModel):
    id: str  # UUID
    name: str
    track_count: int
    created_at: datetime
    updated_at: datetime

class PlaylistDetail(Playlist):
    tracks: list[Track]
```

#### Favorite Schemas

```python
class AddFavoriteInput(BaseModel):
    track_id: str
    track_metadata: dict
```

#### Pagination

```python
class PaginationParams(BaseModel):
    page: int = Field(1, ge=1)
    page_size: int = Field(20, ge=1, le=100, alias="pageSize")

class PaginatedResponse[T](BaseModel):
    data: list[T]
    pagination: PaginationMeta

class PaginationMeta(BaseModel):
    page: int
    page_size: int
    total_items: int
    total_pages: int
```

### 4.5 Auth Token Strategy

| **Parameter** | **Value** | **Alasan** |
|---------------|-----------|------------|
| Access token TTL | 15 menit | Cukup pendek untuk keamanan |
| Refresh token TTL | 7 hari | Cukup panjang agar user tidak sering login ulang |
| Token algorithm | HS256 | Sederhana, cukup untuk single-server |
| Refresh token storage | Database (tabel `refresh_tokens`) | Bisa di-invalidasi saat logout |
| Token rotation | Ya — setiap refresh menghasilkan refresh token baru | Mencegah token reuse |

**Flow:**
```
1. User login → mendapat access_token (15 menit) + refresh_token (7 hari)
2. Frontend simpan access_token di memory, refresh_token di secure storage
3. Setiap request API → kirim access_token di header Authorization: Bearer {token}
4. Ketika access_token expired (401) → frontend POST /api/auth/refresh dengan refresh_token
5. Backend validasi refresh_token → invalidasi yang lama → kembalikan token baru
6. User logout → POST /api/auth/logout → invalidasi refresh_token di database
```

### 4.6 Skema Database

```sql
-- Tabel Users
CREATE TABLE users (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    username VARCHAR(50) UNIQUE NOT NULL,
    email VARCHAR(100) UNIQUE NOT NULL,
    password_hash TEXT NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Tabel Refresh Tokens
CREATE TABLE refresh_tokens (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    token_hash TEXT NOT NULL,  -- hash dari refresh token, bukan plaintext
    expires_at TIMESTAMP WITH TIME ZONE NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    revoked_at TIMESTAMP WITH TIME ZONE  -- NULL = aktif, NOT NULL = revoked
);

CREATE INDEX idx_refresh_tokens_user_id ON refresh_tokens(user_id);
CREATE INDEX idx_refresh_tokens_token_hash ON refresh_tokens(token_hash);

-- Tabel Playlists
CREATE TABLE playlists (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    name VARCHAR(100) NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX idx_playlists_user_id ON playlists(user_id);

-- Tabel Playlist Tracks (menyimpan metadata lagu dari API eksternal)
CREATE TABLE playlist_tracks (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    playlist_id UUID REFERENCES playlists(id) ON DELETE CASCADE,
    track_id VARCHAR(100) NOT NULL,  -- ID dari Jamendo
    track_metadata JSONB NOT NULL,   -- Simpan metadata lengkap untuk offline
    position INTEGER NOT NULL DEFAULT 0,  -- Urutan track dalam playlist
    added_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(playlist_id, track_id)
);

CREATE INDEX idx_playlist_tracks_playlist_id ON playlist_tracks(playlist_id);

-- Tabel Favorites
CREATE TABLE favorites (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    track_id VARCHAR(100) NOT NULL,
    track_metadata JSONB NOT NULL,
    added_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(user_id, track_id)
);

CREATE INDEX idx_favorites_user_id ON favorites(user_id);

-- Tabel History
CREATE TABLE history (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    track_id VARCHAR(100) NOT NULL,
    track_metadata JSONB NOT NULL,
    played_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX idx_history_user_id ON history(user_id);
CREATE INDEX idx_history_played_at ON history(played_at DESC);
```

---

## 5. Strategi Caching

### 5.1 Untuk Menghemat Kuota API

| Data | TTL | Key Pattern | Catatan |
|------|-----|-------------|---------|
| Hasil pencarian | 5 menit | `search:{query_hash}` | Query populer sering sama |
| Detail lagu | 1 jam | `track:{id}` | Data jarang berubah |
| Lirik | 24 jam | `lyrics:{artist}:{title}` | Lirik statis |
| Rekomendasi | 30 menit | `similar:{trackId}` | Per-track, bukan per-user |
| Mood tags | 1 jam | `mood:{trackId}` | Data statis dari Jamendo |
| Cocktail | 1 jam | `cocktail:{mood}` | Per-mood category |

### 5.2 Implementasi Caching (Redis + Python)

```python
import redis.asyncio as redis
import json
from typing import Any


class CacheService:
    """Redis-based caching service untuk menghemat kuota API."""

    def __init__(self, redis_url: str = "redis://localhost:6379"):
        self.redis = redis.from_url(redis_url, decode_responses=True)

    async def get(self, key: str) -> Any | None:
        """Ambil data dari cache. Return None jika tidak ada atau expired."""
        data = await self.redis.get(key)
        if data is None:
            return None
        return json.loads(data)

    async def set(self, key: str, value: Any, ttl_seconds: int = 3600) -> None:
        """Simpan data ke cache dengan TTL."""
        await self.redis.setex(key, ttl_seconds, json.dumps(value))

    async def delete(self, key: str) -> None:
        """Hapus data dari cache."""
        await self.redis.delete(key)

    async def close(self) -> None:
        """Tutup koneksi Redis."""
        await self.redis.close()
```

---

## 6. Project Structure

```
openmusic/
├── backend/
│   ├── alembic/                    # Database migrations
│   │   ├── versions/
│   │   └── env.py
│   ├── app/
│   │   ├── __init__.py
│   │   ├── main.py                 # FastAPI app factory, lifespan events
│   │   ├── core/                   # Global configs & utilities
│   │   │   ├── config.py           # Pydantic Settings (.env loader)
│   │   │   ├── security.py         # JWT encode/decode, password hashing
│   │   │   ├── exceptions.py       # Custom exception classes
│   │   │   └── dependencies.py     # Shared FastAPI dependencies (get_db, get_current_user)
│   │   ├── db/                     # Database setup
│   │   │   ├── session.py          # AsyncSession factory
│   │   │   └── base.py             # SQLAlchemy Base model
│   │   ├── modules/                # Domain-specific features
│   │   │   ├── auth/
│   │   │   │   ├── router.py       # Auth endpoints
│   │   │   │   ├── schemas.py      # Pydantic models (RegisterInput, LoginInput, etc.)
│   │   │   │   ├── models.py       # SQLAlchemy models (User, RefreshToken)
│   │   │   │   ├── service.py      # Business logic (register, login, refresh)
│   │   │   │   └── dependencies.py # get_current_user dependency
│   │   │   ├── tracks/
│   │   │   │   ├── router.py       # Track endpoints (search, detail, stream, lyrics, similar)
│   │   │   │   ├── schemas.py      # Pydantic models (Track, TrackLyrics, etc.)
│   │   │   │   └── service.py      # Orchestrator: Jamendo + Last.fm + LRCLIB
│   │   │   ├── playlists/
│   │   │   │   ├── router.py       # Playlist CRUD endpoints
│   │   │   │   ├── schemas.py
│   │   │   │   ├── models.py       # SQLAlchemy models (Playlist, PlaylistTrack)
│   │   │   │   └── service.py
│   │   │   ├── favorites/
│   │   │   │   ├── router.py
│   │   │   │   ├── schemas.py
│   │   │   │   ├── models.py
│   │   │   │   └── service.py
│   │   │   ├── history/
│   │   │   │   ├── router.py
│   │   │   │   ├── schemas.py
│   │   │   │   ├── models.py
│   │   │   │   └── service.py
│   │   │   └── mood/
│   │   │       ├── router.py       # Mood detection & cocktail pairing
│   │   │       ├── schemas.py
│   │   │       └── service.py
│   │   ├── services/               # External API clients
│   │   │   ├── jamendo.py          # Jamendo API client
│   │   │   ├── lastfm.py           # Last.fm API client
│   │   │   ├── lrclib.py           # LRCLIB API client
│   │   │   ├── cocktaildb.py       # TheCocktailDB API client
│   │   │   └── cache.py            # Redis cache service
│   │   └── api/
│   │       └── v1/
│   │           └── router.py       # Aggregates all module routers under /api
│   ├── tests/
│   │   ├── conftest.py             # Fixtures (TestClient, test DB, mock cache)
│   │   ├── test_auth.py
│   │   ├── test_tracks.py
│   │   ├── test_playlists.py
│   │   ├── test_favorites.py
│   │   └── test_history.py
│   ├── .env.example                # Template environment variables
│   ├── pyproject.toml              # Dependencies & project config
│   ├── alembic.ini
│   └── Dockerfile
├── frontend/                       # Flutter app (terpisah)
│   └── ...
├── docker-compose.yml              # PostgreSQL + Redis + Backend
├── PRD-openmusic.md
└── README.md
```

---

## 7. Code Style & Conventions

### 7.1 Naming Conventions

| **Konteks** | **Convention** | **Contoh** |
|-------------|----------------|------------|
| Python variables/functions | snake_case | `get_current_user`, `track_id` |
| Python classes | PascalCase | `UserProfile`, `CacheService` |
| REST endpoints | kebab-case nouns, plural | `/api/playlists`, `/api/favorites` |
| Query params | camelCase | `?pageSize=20&sortBy=createdAt` |
| JSON response fields | snake_case | `created_at`, `track_id`, `audio_url` |
| Database tables | snake_case, plural | `users`, `playlists`, `playlist_tracks` |
| Enum values | UPPER_SNAKE | `VALIDATION_ERROR`, `NOT_FOUND` |
| Boolean fields | is/has/can prefix | `is_active`, `has_lyrics` |

### 7.2 Contoh Code Pattern

```python
# Router — hanya handle HTTP concerns, delegasi ke service
@router.get("/", response_model=PaginatedResponse[Playlist])
async def list_playlists(
    pagination: PaginationParams = Depends(),
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
) -> PaginatedResponse[Playlist]:
    return await playlist_service.list_by_user(
        db=db,
        user_id=current_user.id,
        page=pagination.page,
        page_size=pagination.page_size,
    )


# Service — business logic, bisa di-test tanpa HTTP
class PlaylistService:
    async def list_by_user(
        self,
        db: AsyncSession,
        user_id: UUID,
        page: int = 1,
        page_size: int = 20,
    ) -> PaginatedResponse[Playlist]:
        query = select(PlaylistModel).where(
            PlaylistModel.user_id == user_id
        )
        total = await db.scalar(select(func.count()).select_from(query.subquery()))
        items = await db.scalars(
            query.offset((page - 1) * page_size).limit(page_size)
        )
        return PaginatedResponse(
            data=[Playlist.model_validate(item) for item in items],
            pagination=PaginationMeta(
                page=page,
                page_size=page_size,
                total_items=total,
                total_pages=ceil(total / page_size),
            ),
        )
```

### 7.3 Async First

Semua I/O operation menggunakan async:
- Database: `AsyncSession` dari SQLAlchemy 2.0 + `asyncpg`
- Redis: `redis.asyncio`
- External API: `httpx.AsyncClient`

---

## 8. Testing Strategy

### 8.1 Framework & Tools

| **Tool** | **Fungsi** |
|----------|------------|
| pytest | Test runner |
| pytest-asyncio | Async test support |
| httpx | AsyncClient untuk test endpoint |
| factory-boy | Test data factories |
| pytest-cov | Coverage reporting |

### 8.2 Test Levels

| **Level** | **Scope** | **Contoh** |
|-----------|-----------|------------|
| Unit Test | Service layer, utility functions | `test_password_hashing`, `test_mood_classification` |
| Integration Test | Router + DB + Cache | `test_create_playlist_endpoint`, `test_search_tracks` |
| External API Mock | Service + mocked HTTP | `test_jamendo_search_caching`, `test_lrclib_fallback` |

### 8.3 Coverage Target

- **Minimum:** 70% overall coverage
- **Critical paths:** 90%+ (auth, playlist CRUD)
- **External API services:** 100% (selalu mock, tidak boleh hit API asli di test)

### 8.4 Commands

```bash
# Run all tests
pytest

# Run with coverage
pytest --cov=app --cov-report=html

# Run specific module
pytest tests/test_auth.py -v

# Run single test
pytest tests/test_playlists.py::test_create_playlist -v
```

---

## 9. Boundaries

### 9.1 Always Do
- Run `pytest` sebelum commit
- Hash password dengan bcrypt (cost factor ≥ 12)
- Validasi semua input di boundary (router layer) menggunakan Pydantic
- Gunakan parameterized queries (SQLAlchemy) — tidak pernah string concatenation untuk SQL
- Simpan API keys di environment variables, bukan di source code
- Return error response dalam format konsisten (Error Contract)
- Log error dari external API calls
- Gunakan `TIMESTAMP WITH TIME ZONE` untuk semua kolom waktu

### 9.2 Ask First
- Menambah dependency baru ke `pyproject.toml`
- Mengubah database schema (buat migration dulu via Alembic)
- Mengubah format response API yang sudah ada (breaking change)
- Menambah external API baru
- Mengubah CI/CD config

### 9.3 Never Do
- Commit API key, secret, atau `.env` file ke repository
- Simpan password dalam plaintext
- Return raw SQLAlchemy model ke response (selalu map ke Pydantic schema)
- Hapus failing test tanpa approval
- Hit external API asli di automated tests
- Expose stack trace atau detail internal di error response produksi

---

## 10. User Flow

### 10.1 Skenario Utama: Pengguna Mendengarkan Musik

```
1. User register (username, email, password) → mendapat access + refresh token
2. Cari lagu → Backend fetch dari Jamendo API + cache
3. Pilih lagu → Backend ambil URL streaming dari Jamendo
4. Lagu diputar di frontend → Backend catat ke history
5. Secara paralel:
   a. Backend fetch lirik dari LRCLIB (by artist + title)
   b. Backend fetch similar tracks dari Last.fm (track.getSimilar)
6. Tampilkan lirik & rekomendasi di UI
7. User bisa:
   - Tambahkan ke favorit → simpan ke DB
   - Tambahkan ke playlist → simpan ke DB
   - Putar rekomendasi → loop ke step 4
```

### 10.2 Skenario "Wow": Mood-Based Cocktail Pairing

```
1. User memutar lagu
2. Backend ambil metadata lagu dari Jamendo, termasuk tags:
   - speed (slow/medium/fast)
   - acousticelectric (acoustic/electric)
   - vocalinstrumental (vocal/instrumental)
   - genre tags (rock, jazz, electronic, dll)
3. Tentukan mood berdasarkan kombinasi tags:
   - fast + electric + rock → "Energetic"
   - slow + acoustic + vocal → "Chill"
   - fast + electronic + instrumental → "Party"
   - slow + acoustic + instrumental → "Mellow"
4. Backend fetch rekomendasi koktail dari TheCocktailDB berdasarkan mood mapping
5. Tampilkan: "Untuk mood 'Chill', kami rekomendasikan Mojito! 🍹"
```

### 10.3 Skenario Token Refresh

```
1. Frontend mengirim request dengan access_token yang expired
2. Backend return 401 Unauthorized
3. Frontend kirim POST /api/auth/refresh dengan refresh_token
4. Backend validasi refresh_token:
   a. Jika valid → invalidasi token lama, kembalikan token baru
   b. Jika expired/revoked → return 401, user harus login ulang
5. Frontend simpan token baru dan retry request yang gagal
```

---

## 11. Non-Functional Requirements

| Aspek | Requirement | Metrik |
|-------|-------------|--------|
| Kinerja | Response time < 500ms untuk cached data | P95 < 500ms |
| Ketersediaan | API harus selalu bisa diakses (kecuali API eksternal down) | Uptime 99% |
| Keamanan | Password di-hash (bcrypt), JWT + refresh token, HTTPS | Tidak ada plaintext password |
| Skalabilitas | Bisa handle 100 user concurrent | Load test dengan k6 |
| Dokumentasi | Semua endpoint didokumentasikan | Swagger/OpenAPI auto-generated |
| Graceful Degradation | Jika external API down, fitur terkait gagal gracefully | Tampilkan pesan "tidak tersedia" |

---

## 12. Risks & Mitigasi

| Risiko | Dampak | Mitigasi |
|--------|--------|----------|
| Kuota Jamendo API habis (35k/bulan) | Pencarian & streaming gagal | Caching agresif, batasi search rate per user |
| Last.fm API down | Rekomendasi tidak muncul | Graceful degradation, tampilkan "Rekomendasi tidak tersedia" |
| LRCLIB tidak punya lirik untuk lagu tertentu | Fitur lirik kosong | Tampilkan "Lirik tidak tersedia untuk lagu ini" |
| Redis down | Cache tidak berfungsi | Fallback ke direct API call (tanpa cache) |
| CORS issues (Flutter ↔ FastAPI) | Frontend tidak bisa akses | Setup CORS middleware di FastAPI |
| Refresh token dicuri | Akun diambil alih | Token rotation + short TTL + revocation di DB |

---

## 13. Timeline Pengembangan (8 Minggu)

| Fase | Minggu | Aktivitas | Deliverable |
|------|--------|-----------|-------------|
| Persiapan | 1 | Setup environment, API key registration (Jamendo, Last.fm), database design, project scaffolding | ERD, API keys, project skeleton |
| Backend Core | 2-3 | Auth (register, login, refresh, logout), Jamendo integration (search, detail, stream), caching | Auth endpoints + search endpoint berfungsi |
| Database & Playlist | 4 | Playlist CRUD, favorites CRUD, history recording | Semua CRUD endpoint berfungsi |
| Integrasi API | 5 | Last.fm (rekomendasi), LRCLIB (lirik) | Fitur rekomendasi & lirik berfungsi |
| Fitur "Wow" | 6 | Mood detection (Jamendo tags), cocktail pairing (TheCocktailDB) | Endpoint mood & cocktail berfungsi |
| Frontend | 7 | Sinkronisasi backend-frontend, UI/UX Flutter | Aplikasi fungsional end-to-end |
| Testing & Deployment | 8 | Unit test, integration test, Docker, deploy | Aplikasi siap presentasi |

---

## 14. Success Metrics

| Metrik | Target |
|--------|--------|
| Jumlah lagu yang bisa dicari & diputar | ≥ 100.000 (dari katalog Jamendo) |
| Waktu response API (cached) | < 500ms (P95) |
| Fitur rekomendasi | Menampilkan ≥ 10 lagu serupa per request |
| User bisa register, login, dan simpan playlist | 100% fungsional |
| Fitur lirik | Menampilkan lirik untuk ≥ 60% lagu populer |
| Fitur "Wow" | Minimal 2 fitur tambahan berjalan lancar |
| Test coverage | ≥ 70% overall |

---

## 15. Commands

```bash
# Development
cd backend
uvicorn app.main:app --reload --port 8000     # Run dev server
alembic upgrade head                           # Apply migrations
alembic revision --autogenerate -m "desc"      # Generate migration

# Testing
pytest                                          # Run all tests
pytest --cov=app --cov-report=html              # Run with coverage

# Linting
ruff check app/                                 # Lint
ruff format app/                                # Format

# Docker
docker-compose up -d                            # Start PostgreSQL + Redis + Backend
docker-compose down                             # Stop all services
```

---

## 16. Referensi API

| API | Dokumentasi | Key Required | Status |
|-----|-------------|--------------|--------|
| Jamendo | https://developer.jamendo.com/v3.0 | Ya (client_id, gratis) | ✅ Aktif |
| Last.fm | https://www.last.fm/api | Ya (API key, gratis) | ✅ Aktif |
| LRCLIB | https://lrclib.net/docs | Tidak (hanya User-Agent header) | ✅ Aktif |
| TheCocktailDB | https://www.thecocktaildb.com/api.php | Tidak (gratis) | ✅ Aktif |
| TasteDive | https://tastedive.com/read/api | Ya (gratis, legacy) | ⚠️ Legacy |

---

## 17. Lampiran

### 17.1 Contoh Response API — Search Tracks

**Request:** `GET /api/tracks?q=bohemian&page=1&pageSize=2`

**Response (200 OK):**
```json
{
  "data": [
    {
      "id": "12345",
      "title": "Bohemian Rhapsody Cover",
      "artist": "Creative Commons Artist",
      "album": "Open Music Collection",
      "cover_url": "https://usercontent.jamendo.com/?type=album&id=12345&width=300",
      "audio_url": null,
      "duration": 354,
      "source": "jamendo"
    }
  ],
  "pagination": {
    "page": 1,
    "page_size": 2,
    "total_items": 42,
    "total_pages": 21
  }
}
```

### 17.2 Contoh Response API — Similar Tracks (Rekomendasi)

**Request:** `GET /api/tracks/12345/similar`

**Response (200 OK):**
```json
{
  "data": [
    {
      "id": "67890",
      "title": "Another Great Song",
      "artist": "Similar Artist",
      "album": null,
      "cover_url": "https://usercontent.jamendo.com/?type=album&id=67890&width=300",
      "audio_url": null,
      "duration": 280,
      "source": "lastfm"
    }
  ],
  "pagination": {
    "page": 1,
    "page_size": 10,
    "total_items": 10,
    "total_pages": 1
  }
}
```

### 17.3 Contoh Response API — Error

**Request:** `POST /api/auth/register` (dengan email yang sudah terdaftar)

**Response (409 Conflict):**
```json
{
  "error": {
    "code": "CONFLICT",
    "message": "Email sudah terdaftar",
    "details": null
  }
}
```

### 17.4 Contoh Response API — Validation Error

**Request:** `POST /api/auth/register` (dengan password terlalu pendek)

**Response (422 Unprocessable Entity):**
```json
{
  "error": {
    "code": "VALIDATION_ERROR",
    "message": "Input tidak valid",
    "details": [
      {
        "field": "password",
        "message": "Password minimal 8 karakter"
      }
    ]
  }
}
```

### 17.5 Contoh Response API — Mood & Cocktail

**Request:** `GET /api/tracks/12345/cocktail`

**Response (200 OK):**
```json
{
  "mood": "Chill",
  "cocktail_name": "Mojito",
  "cocktail_image": "https://www.thecocktaildb.com/images/media/drink/mojito.jpg",
  "ingredients": ["White Rum", "Lime Juice", "Sugar", "Mint", "Soda Water"],
  "instructions": "Muddle mint leaves with sugar and lime juice..."
}
```

---

## 18. Catatan Tambahan

- Semua data pengguna (playlist, favorit, history) disimpan di database sendiri, tidak bergantung pada API eksternal.
- Backend 100% dibangun dari nol sebagai bukti pemahaman arsitektur API.
- Frontend dan backend terpisah (sesuai syarat tugas).
- Kode akan di-push ke repository GitHub dengan dokumentasi lengkap.
- Semua external API response harus **divalidasi** sebelum digunakan (treat as untrusted data).
- Database migrations dikelola dengan Alembic — tidak ada manual SQL execution di production.