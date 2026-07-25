# Sprint 1: Foundation — Project Scaffolding & Database Setup

**Durasi:** Minggu 1  
**Goal:** Project skeleton berjalan (`uvicorn` start tanpa error), database terhubung, migration pertama berhasil, dan health-check endpoint merespons.  
**Dependency:** Tidak ada (sprint pertama)

---

## Sprint Requirements

Sebelum sprint ini dianggap selesai, **SEMUA** kondisi berikut harus terpenuhi:

- [ ] `uvicorn app.main:app --reload` berjalan tanpa error
- [ ] `GET /api/health` mengembalikan `{"status": "ok"}` dengan HTTP 200
- [ ] PostgreSQL terhubung via `AsyncSession` (bisa query `SELECT 1`)
- [ ] Redis terhubung via `redis.asyncio` (bisa `PING`)
- [ ] `alembic upgrade head` berhasil membuat tabel `users` dan `refresh_tokens`
- [ ] `.env.example` terdokumentasi lengkap
- [ ] `docker-compose up -d` menjalankan PostgreSQL + Redis
- [ ] `ruff check app/` dan `ruff format app/` bersih (0 error)
- [ ] Semua API key (Jamendo, Last.fm) sudah di-register dan dicatat di `.env.example`

---

## Task 1.1: Inisialisasi Project & Dependency Management

**Deskripsi:** Buat folder `backend/` dengan `pyproject.toml`, install semua core dependencies, setup `ruff` sebagai linter/formatter, dan buat `.env.example`.

**Acceptance Criteria:**
- [ ] `backend/pyproject.toml` ada dengan semua dependency tercantum
- [ ] Virtual environment bisa dibuat dan semua dependency ter-install
- [ ] `ruff check app/` bisa dijalankan (meski belum ada kode)
- [ ] `.env.example` berisi semua env var yang dibutuhkan (dengan komentar penjelasan)
- [ ] `.gitignore` mengabaikan `.env`, `__pycache__`, `.venv`, `*.pyc`

**Detail Implementasi:**

```toml
# pyproject.toml — dependencies yang diperlukan
[project]
dependencies = [
    "fastapi>=0.115",
    "uvicorn[standard]>=0.30",
    "sqlalchemy[asyncio]>=2.0",
    "asyncpg>=0.30",
    "alembic>=1.14",
    "pydantic[email]>=2.0",
    "pydantic-settings>=2.0",
    "python-jose[cryptography]>=3.3",
    "passlib[bcrypt]>=1.7",
    "redis>=5.0",
    "httpx>=0.27",
]

[project.optional-dependencies]
dev = [
    "pytest>=8.0",
    "pytest-asyncio>=0.24",
    "pytest-cov>=5.0",
    "ruff>=0.8",
    "factory-boy>=3.3",
]
```

```bash
# .env.example
DATABASE_URL=postgresql+asyncpg://openmusic:openmusic@localhost:5432/openmusic
REDIS_URL=redis://localhost:6379/0
SECRET_KEY=your-secret-key-here-change-in-production
JAMENDO_CLIENT_ID=your-jamendo-client-id
LASTFM_API_KEY=your-lastfm-api-key
ACCESS_TOKEN_EXPIRE_MINUTES=15
REFRESH_TOKEN_EXPIRE_DAYS=7
```

**Verification:**
- [ ] `cd backend && pip install -e ".[dev]"` berhasil
- [ ] `ruff --version` mengembalikan versi
- [ ] File `.env.example` lengkap dan terdokumentasi

**Files:**
- `backend/pyproject.toml`
- `backend/.env.example`
- `backend/.gitignore`

**Scope:** S (1-2 files)

---

## Task 1.2: FastAPI App Factory & Core Config

**Deskripsi:** Buat `app/main.py` dengan FastAPI app factory menggunakan `lifespan` context manager, `app/core/config.py` dengan `pydantic-settings` untuk load `.env`, dan `app/core/exceptions.py` untuk custom error handler sesuai Error Contract di PRD §4.3.

**Acceptance Criteria:**
- [ ] `app/main.py` mendefinisikan FastAPI app dengan `lifespan` (bukan `@app.on_event`)
- [ ] `app/core/config.py` menggunakan `pydantic-settings.BaseSettings` untuk load env vars
- [ ] `app/core/exceptions.py` mendefinisikan `AppError` base class + `ErrorCode` enum
- [ ] Error handler terpasang: semua `AppError` di-catch dan di-return sesuai Error Contract
- [ ] `GET /api/health` mengembalikan `{"status": "ok"}`
- [ ] CORS middleware terpasang (origins configurable via env)

**Detail Implementasi:**

```python
# app/core/config.py
class Settings(BaseSettings):
    database_url: str
    redis_url: str = "redis://localhost:6379/0"
    secret_key: str
    jamendo_client_id: str
    lastfm_api_key: str
    access_token_expire_minutes: int = 15
    refresh_token_expire_days: int = 7
    cors_origins: list[str] = ["*"]

    model_config = SettingsConfigDict(env_file=".env")
```

```python
# app/core/exceptions.py — sesuai PRD §4.3 Error Contract
class ErrorCode(str, Enum):
    VALIDATION_ERROR = "VALIDATION_ERROR"
    AUTHENTICATION_ERROR = "AUTHENTICATION_ERROR"
    AUTHORIZATION_ERROR = "AUTHORIZATION_ERROR"
    NOT_FOUND = "NOT_FOUND"
    CONFLICT = "CONFLICT"
    RATE_LIMIT_EXCEEDED = "RATE_LIMIT_EXCEEDED"
    INTERNAL_ERROR = "INTERNAL_ERROR"
    EXTERNAL_API_ERROR = "EXTERNAL_API_ERROR"

class AppError(Exception):
    def __init__(self, code: ErrorCode, message: str, status_code: int, details=None):
        ...
```

**Verification:**
- [ ] `uvicorn app.main:app --reload` start tanpa error
- [ ] `curl http://localhost:8000/api/health` → `{"status": "ok"}`
- [ ] `curl http://localhost:8000/api/nonexistent` → error contract JSON (404)
- [ ] `ruff check app/` — 0 error

**Dependencies:** Task 1.1

**Files:**
- `backend/app/__init__.py`
- `backend/app/main.py`
- `backend/app/core/__init__.py`
- `backend/app/core/config.py`
- `backend/app/core/exceptions.py`

**Scope:** M (3-5 files)

---

## Task 1.3: Database & Redis Connection + Docker Compose

**Deskripsi:** Setup koneksi database PostgreSQL async via SQLAlchemy 2.0 + `asyncpg`, koneksi Redis async, dan `docker-compose.yml` untuk menjalankan PostgreSQL + Redis secara lokal. Koneksi di-manage lewat `lifespan` di `main.py`.

**Acceptance Criteria:**
- [ ] `docker-compose.yml` mendefinisikan service `postgres` dan `redis`
- [ ] `app/db/session.py` membuat `async_sessionmaker` dengan `AsyncSession`
- [ ] `app/db/base.py` mendefinisikan `Base` class SQLAlchemy
- [ ] `app/services/cache.py` mengimplementasikan `CacheService` sesuai PRD §5.2
- [ ] `app/core/dependencies.py` mendefinisikan `get_db` dependency (yield session)
- [ ] Koneksi DB dan Redis di-init di `lifespan` startup, di-close di shutdown
- [ ] Health endpoint diperbarui: cek DB + Redis connectivity

**Detail Implementasi:**

```yaml
# docker-compose.yml
services:
  postgres:
    image: postgres:16-alpine
    environment:
      POSTGRES_USER: openmusic
      POSTGRES_PASSWORD: openmusic
      POSTGRES_DB: openmusic
    ports:
      - "5432:5432"
    volumes:
      - pgdata:/var/lib/postgresql/data

  redis:
    image: redis:7-alpine
    ports:
      - "6379:6379"

volumes:
  pgdata:
```

**Verification:**
- [ ] `docker-compose up -d` → kedua service running
- [ ] `curl http://localhost:8000/api/health` → `{"status": "ok", "db": "connected", "redis": "connected"}`
- [ ] Jika Postgres mati → health endpoint report `"db": "disconnected"`
- [ ] `ruff check app/` — 0 error

**Dependencies:** Task 1.2

**Files:**
- `docker-compose.yml`
- `backend/app/db/__init__.py`
- `backend/app/db/session.py`
- `backend/app/db/base.py`
- `backend/app/services/__init__.py`
- `backend/app/services/cache.py`
- `backend/app/core/dependencies.py` (update)
- `backend/app/main.py` (update lifespan)

**Scope:** M (5 files)

---

## Task 1.4: Alembic Setup + Initial Migration (users & refresh_tokens)

**Deskripsi:** Inisialisasi Alembic untuk async migration, buat SQLAlchemy models untuk `users` dan `refresh_tokens` (sesuai PRD §4.6), dan generate + apply migration pertama.

**Acceptance Criteria:**
- [ ] `alembic init --template async alembic` berhasil
- [ ] `alembic.ini` dan `alembic/env.py` dikonfigurasi untuk async + load `DATABASE_URL` dari `.env`
- [ ] `app/modules/auth/models.py` mendefinisikan `User` dan `RefreshToken` model sesuai PRD §4.6
- [ ] `alembic revision --autogenerate -m "create users and refresh_tokens"` generate migration
- [ ] `alembic upgrade head` berhasil — tabel `users` dan `refresh_tokens` ada di database
- [ ] Index `idx_refresh_tokens_user_id` dan `idx_refresh_tokens_token_hash` terbuat

**Detail Implementasi:**

```python
# app/modules/auth/models.py — sesuai PRD §4.6
class User(Base):
    __tablename__ = "users"
    id: Mapped[uuid.UUID] = mapped_column(primary_key=True, default=uuid.uuid4)
    username: Mapped[str] = mapped_column(String(50), unique=True, nullable=False)
    email: Mapped[str] = mapped_column(String(100), unique=True, nullable=False)
    password_hash: Mapped[str] = mapped_column(Text, nullable=False)
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), server_default=func.now())
    updated_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), server_default=func.now(), onupdate=func.now())

class RefreshToken(Base):
    __tablename__ = "refresh_tokens"
    id: Mapped[uuid.UUID] = mapped_column(primary_key=True, default=uuid.uuid4)
    user_id: Mapped[uuid.UUID] = mapped_column(ForeignKey("users.id", ondelete="CASCADE"))
    token_hash: Mapped[str] = mapped_column(Text, nullable=False)
    expires_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), nullable=False)
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), server_default=func.now())
    revoked_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), nullable=True)
```

**Verification:**
- [ ] `docker-compose up -d` (PostgreSQL running)
- [ ] `alembic upgrade head` berhasil tanpa error
- [ ] Connect ke DB → `\dt` → tabel `users` dan `refresh_tokens` ada
- [ ] `alembic downgrade -1` berhasil (migration reversible)
- [ ] `ruff check app/` — 0 error

**Dependencies:** Task 1.3

**Files:**
- `backend/alembic.ini`
- `backend/alembic/env.py`
- `backend/alembic/versions/xxxx_create_users_and_refresh_tokens.py` (auto-generated)
- `backend/app/modules/__init__.py`
- `backend/app/modules/auth/__init__.py`
- `backend/app/modules/auth/models.py`

**Scope:** M (4-5 files)

---

## Checkpoint: Sprint 1

Setelah semua task selesai, verifikasi:

- [ ] `docker-compose up -d` → PostgreSQL + Redis running
- [ ] `alembic upgrade head` → tabel `users` dan `refresh_tokens` terbuat
- [ ] `uvicorn app.main:app --reload` → server start tanpa error
- [ ] `curl /api/health` → `{"status": "ok", "db": "connected", "redis": "connected"}`
- [ ] `ruff check app/ && ruff format --check app/` → 0 error
- [ ] Semua kode sudah di-commit dengan pesan deskriptif
- [ ] **Sistem dalam keadaan working** — siap untuk Sprint 2 (Auth)

---

## Context untuk Sprint Berikutnya

Sprint 2 akan membangun di atas foundation ini:
- Menggunakan `User` dan `RefreshToken` model untuk auth endpoints
- Menggunakan `AsyncSession` dependency untuk database operations
- Menggunakan `CacheService` untuk caching
- Menggunakan `AppError` + `ErrorCode` untuk error handling
- Menggunakan `Settings` untuk config values (secret key, token TTL)
