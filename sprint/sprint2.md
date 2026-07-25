# Sprint 2: Autentikasi — Register, Login, Refresh, Logout

**Durasi:** Minggu 2  
**Goal:** User bisa register, login, mendapat JWT token pair, refresh token, dan logout. Semua auth endpoint berfungsi end-to-end dengan validasi, error handling, dan unit tests.  
**Dependency:** Sprint 1 (DB connection, User/RefreshToken models, config, error contract)

---

## Sprint Requirements

Sebelum sprint ini dianggap selesai, **SEMUA** kondisi berikut harus terpenuhi:

- [ ] `POST /api/auth/register` — bisa register user baru, return token pair
- [ ] `POST /api/auth/login` — bisa login dengan email + password, return token pair
- [ ] `POST /api/auth/refresh` — bisa refresh access token dengan refresh token
- [ ] `POST /api/auth/logout` — invalidasi refresh token
- [ ] `GET /api/auth/me` — return profil user yang sedang login
- [ ] Password di-hash dengan bcrypt (cost ≥ 12), **tidak ada plaintext**
- [ ] Refresh token di-hash sebelum simpan ke DB
- [ ] Token rotation: setiap refresh menghasilkan refresh token baru
- [ ] Semua error mengikuti Error Contract (PRD §4.3)
- [ ] `pytest tests/test_auth.py` — semua test pass
- [ ] `ruff check app/` — 0 error

---

## Task 2.1: Security Utilities — Password Hashing & JWT

**Deskripsi:** Implementasi `app/core/security.py` yang berisi fungsi untuk password hashing (bcrypt) dan JWT token creation/verification. Ini adalah utility yang digunakan oleh auth service.

**Acceptance Criteria:**
- [ ] `hash_password(plain)` → bcrypt hash string
- [ ] `verify_password(plain, hashed)` → bool
- [ ] `create_access_token(subject, expires_delta)` → JWT string (HS256)
- [ ] `create_refresh_token()` → random secure string (bukan JWT)
- [ ] `decode_access_token(token)` → payload dict atau raise error
- [ ] `hash_token(token)` → SHA-256 hash (untuk refresh token storage)
- [ ] Bcrypt cost factor ≥ 12
- [ ] Access token berisi: `sub` (user_id), `exp`, `iat`

**Detail Implementasi:**

```python
# app/core/security.py
from passlib.context import CryptContext
from jose import jwt, JWTError
import secrets, hashlib

pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto", bcrypt__rounds=12)

def hash_password(password: str) -> str:
    return pwd_context.hash(password)

def verify_password(plain: str, hashed: str) -> bool:
    return pwd_context.verify(plain, hashed)

def create_access_token(subject: str, expires_delta: timedelta, secret_key: str) -> str:
    payload = {"sub": subject, "exp": datetime.utcnow() + expires_delta, "iat": datetime.utcnow()}
    return jwt.encode(payload, secret_key, algorithm="HS256")

def create_refresh_token() -> str:
    return secrets.token_urlsafe(64)

def hash_token(token: str) -> str:
    return hashlib.sha256(token.encode()).hexdigest()

def decode_access_token(token: str, secret_key: str) -> dict:
    return jwt.decode(token, secret_key, algorithms=["HS256"])
```

**Verification:**
- [ ] Unit test: `hash_password` + `verify_password` roundtrip
- [ ] Unit test: `create_access_token` + `decode_access_token` roundtrip
- [ ] Unit test: expired token raises error
- [ ] Unit test: `hash_token` produces consistent SHA-256
- [ ] `ruff check app/core/security.py` — 0 error

**Dependencies:** Task 1.2 (config untuk secret_key)

**Files:**
- `backend/app/core/security.py`
- `backend/tests/test_security.py`

**Scope:** S (2 files)

---

## Task 2.2: Auth Schemas & Service Layer

**Deskripsi:** Implementasi Pydantic schemas untuk auth (PRD §4.4 Auth Schemas) dan `AuthService` yang berisi business logic untuk register, login, refresh, dan logout. Service layer terpisah dari router — bisa di-test tanpa HTTP.

**Acceptance Criteria:**
- [ ] `app/modules/auth/schemas.py` mengimplementasikan semua schema sesuai PRD §4.4
- [ ] `app/modules/auth/service.py` mengimplementasikan `AuthService` dengan methods:
  - `register(db, input)` → buat user + return tokens
  - `login(db, input)` → validasi credential + return tokens
  - `refresh(db, input)` → validasi refresh token + rotate + return tokens baru
  - `logout(db, refresh_token)` → revoke refresh token
  - `get_profile(db, user_id)` → return UserProfile
- [ ] Register: cek duplicate email/username → raise `CONFLICT`
- [ ] Login: email not found atau password salah → raise `AUTHENTICATION_ERROR` (pesan sama untuk keduanya — hindari user enumeration)
- [ ] Refresh: token expired/revoked → raise `AUTHENTICATION_ERROR`
- [ ] Token rotation: refresh selalu invalidasi token lama dan buat baru

**Detail Implementasi:**

```python
# app/modules/auth/service.py — contoh pattern
class AuthService:
    async def register(self, db: AsyncSession, input: RegisterInput) -> AuthTokens:
        # 1. Cek duplicate email
        existing = await db.scalar(select(User).where(User.email == input.email))
        if existing:
            raise AppError(ErrorCode.CONFLICT, "Email sudah terdaftar", 409)

        # 2. Cek duplicate username
        existing = await db.scalar(select(User).where(User.username == input.username))
        if existing:
            raise AppError(ErrorCode.CONFLICT, "Username sudah terdaftar", 409)

        # 3. Buat user
        user = User(
            username=input.username,
            email=input.email,
            password_hash=hash_password(input.password),
        )
        db.add(user)
        await db.flush()

        # 4. Buat token pair
        tokens = await self._create_token_pair(db, user.id)
        await db.commit()
        return tokens
```

**Verification:**
- [ ] Unit test: register → user tersimpan di DB + token pair dikembalikan
- [ ] Unit test: register duplicate email → `CONFLICT` error
- [ ] Unit test: login sukses → token pair dikembalikan
- [ ] Unit test: login email salah → `AUTHENTICATION_ERROR`
- [ ] Unit test: login password salah → `AUTHENTICATION_ERROR` (pesan sama)
- [ ] Unit test: refresh sukses → token lama revoked, token baru dikembalikan
- [ ] Unit test: refresh expired → `AUTHENTICATION_ERROR`
- [ ] `ruff check app/modules/auth/` — 0 error

**Dependencies:** Task 2.1 (security utilities)

**Files:**
- `backend/app/modules/auth/schemas.py`
- `backend/app/modules/auth/service.py`

**Scope:** S (2 files)

---

## Task 2.3: Auth Router & get_current_user Dependency

**Deskripsi:** Implementasi auth router (`POST register`, `POST login`, `POST refresh`, `POST logout`, `GET me`) dan `get_current_user` FastAPI dependency yang extract + validate JWT dari `Authorization: Bearer` header.

**Acceptance Criteria:**
- [ ] `app/modules/auth/router.py` mendefinisikan 5 endpoint sesuai PRD §4.2 Auth
- [ ] `app/modules/auth/dependencies.py` mendefinisikan `get_current_user` dependency
- [ ] `get_current_user`: extract Bearer token → decode JWT → query user dari DB → return User
- [ ] Jika token invalid/expired → raise 401 dengan Error Contract format
- [ ] Router di-register di `app/api/v1/router.py` → available di `/api/auth/*`
- [ ] Semua endpoint return response sesuai schema (Pydantic model serialization)

**Detail Implementasi:**

```python
# app/modules/auth/dependencies.py
async def get_current_user(
    authorization: str = Header(...),
    db: AsyncSession = Depends(get_db),
    settings: Settings = Depends(get_settings),
) -> User:
    # Extract "Bearer <token>"
    # Decode JWT
    # Query user by ID from JWT subject
    # Return user or raise 401
```

```python
# app/api/v1/router.py
api_router = APIRouter(prefix="/api")
api_router.include_router(auth_router, prefix="/auth", tags=["Auth"])
```

**Verification:**
- [ ] Integration test: `POST /api/auth/register` → 201 + token pair
- [ ] Integration test: `POST /api/auth/login` → 200 + token pair
- [ ] Integration test: `GET /api/auth/me` dengan valid token → 200 + user profile
- [ ] Integration test: `GET /api/auth/me` tanpa token → 401 Error Contract
- [ ] Integration test: `POST /api/auth/refresh` → 200 + new token pair
- [ ] Integration test: `POST /api/auth/logout` → 200
- [ ] `ruff check app/` — 0 error

**Dependencies:** Task 2.2 (auth service + schemas)

**Files:**
- `backend/app/modules/auth/router.py`
- `backend/app/modules/auth/dependencies.py`
- `backend/app/api/__init__.py`
- `backend/app/api/v1/__init__.py`
- `backend/app/api/v1/router.py`
- `backend/app/main.py` (update: include api_router)

**Scope:** M (5 files)

---

## Task 2.4: Auth Integration Tests & Test Infrastructure

**Deskripsi:** Setup test infrastructure (`conftest.py` dengan test database, test client, fixture helpers) dan tulis integration tests lengkap untuk semua 5 auth endpoint. Ini memvalidasi seluruh auth flow end-to-end.

**Acceptance Criteria:**
- [ ] `tests/conftest.py` mendefinisikan:
  - `test_db` fixture: buat test database, run migrations, cleanup setelah test
  - `client` fixture: `httpx.AsyncClient` yang connect ke test app
  - `auth_headers` fixture: register test user → return headers dengan valid token
- [ ] `tests/test_auth.py` berisi minimal test berikut:
  - Test register sukses (unique email + username)
  - Test register duplicate email → 409
  - Test register password terlalu pendek → 422
  - Test login sukses
  - Test login email salah → 401
  - Test login password salah → 401
  - Test me dengan valid token → 200
  - Test me tanpa token → 401
  - Test refresh sukses → token baru + token lama revoked
  - Test refresh dengan revoked token → 401
  - Test logout → refresh token revoked
- [ ] Semua test pass: `pytest tests/test_auth.py -v`
- [ ] Error response format sesuai Error Contract di semua test

**Detail Implementasi:**

```python
# tests/conftest.py
@pytest_asyncio.fixture
async def client():
    async with AsyncClient(app=app, base_url="http://test") as ac:
        yield ac

@pytest_asyncio.fixture
async def auth_headers(client: AsyncClient):
    resp = await client.post("/api/auth/register", json={
        "username": "testuser",
        "email": "test@example.com",
        "password": "securepass123",
    })
    tokens = resp.json()
    return {"Authorization": f"Bearer {tokens['access_token']}"}
```

**Verification:**
- [ ] `pytest tests/test_auth.py -v` → semua test PASSED
- [ ] `pytest tests/test_auth.py --cov=app/modules/auth` → coverage ≥ 90%
- [ ] Tidak ada test yang hit external API (semuanya lokal DB)
- [ ] `ruff check tests/` — 0 error

**Dependencies:** Task 2.3 (auth router complete)

**Files:**
- `backend/tests/__init__.py`
- `backend/tests/conftest.py`
- `backend/tests/test_auth.py`

**Scope:** S (3 files)

---

## Checkpoint: Sprint 2

Setelah semua task selesai, verifikasi:

- [ ] Full auth flow berfungsi: register → login → use token → refresh → logout
- [ ] Password hashed (bcrypt), refresh token hashed (SHA-256)
- [ ] Token rotation bekerja (refresh invalidasi lama, buat baru)
- [ ] Error responses konsisten sesuai Error Contract
- [ ] `pytest tests/ -v` → semua test PASSED
- [ ] `ruff check app/ tests/` — 0 error
- [ ] Semua kode sudah di-commit
- [ ] **Sistem dalam keadaan working** — siap untuk Sprint 3 (Jamendo + Search)

---

## Context untuk Sprint Berikutnya

Sprint 3 akan membangun di atas auth:
- Menggunakan `get_current_user` dependency di semua track/playlist endpoint
- Menggunakan `auth_headers` fixture untuk semua integration tests
- Endpoint baru akan diproteksi oleh JWT auth
