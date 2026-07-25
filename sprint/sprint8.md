# Sprint 8: Testing, Polish & Deployment

**Durasi:** Minggu 8  
**Goal:** Coverage ≥ 70%, Dockerfile production-ready, docker-compose full stack, README lengkap, dan aplikasi siap presentasi.  
**Dependency:** Sprint 7 (semua fitur selesai)

---

## Sprint Requirements

Sebelum sprint ini dianggap selesai, **SEMUA** kondisi berikut harus terpenuhi:

- [ ] `pytest --cov=app` → overall coverage ≥ 70%
- [ ] Auth + playlist path → coverage ≥ 90%
- [ ] `Dockerfile` backend production-ready (multi-stage build)
- [ ] `docker-compose.yml` bisa start full stack: Postgres + Redis + Backend
- [ ] `README.md` lengkap: deskripsi, setup, env vars, API docs link
- [ ] Swagger docs (`/docs`) menampilkan semua endpoint dengan contoh
- [ ] Tidak ada hardcoded secrets di source code
- [ ] `ruff check app/ tests/` — 0 error
- [ ] Aplikasi bisa di-demo: register → search → play → playlist → mood/cocktail

---

## Task 8.1: Complete Test Coverage

**Deskripsi:** Audit test coverage, tambahkan test yang kurang untuk mencapai target 70% overall dan 90% pada critical paths (auth, playlists). Fokus pada edge cases dan error paths yang belum tercover.

**Acceptance Criteria:**
- [ ] `pytest --cov=app --cov-report=term-missing` → identifikasi gap
- [ ] Tambahkan test untuk:
  - Edge cases pagination (page 0, page > total, page_size 0)
  - Error paths: external API timeout, malformed response
  - Auth edge cases: expired refresh token, concurrent refresh
  - Playlist edge cases: empty playlist, max tracks
- [ ] Coverage results:
  - Overall: ≥ 70%
  - `modules/auth/`: ≥ 90%
  - `modules/playlists/`: ≥ 90%
  - `services/` (external API clients): 100% (semua mocked)
- [ ] Tidak ada test yang hit external API asli

**Verification:**
- [ ] `pytest --cov=app --cov-report=html` → buka htmlcov/index.html
- [ ] Semua test pass
- [ ] Coverage threshold terpenuhi
- [ ] `ruff check tests/` — 0 error

**Dependencies:** Sprint 7 (semua fitur selesai)

**Files:**
- `backend/tests/test_auth.py` (update: edge cases)
- `backend/tests/test_tracks.py` (update: edge cases)
- `backend/tests/test_playlists.py` (update: edge cases)
- `backend/tests/test_favorites.py` (update: edge cases)
- `backend/tests/test_mood.py` (update: edge cases)

**Scope:** M (5 files update)

---

## Task 8.2: Dockerfile & Docker Compose Production

**Deskripsi:** Buat production-ready `Dockerfile` (multi-stage build, non-root user) dan perbarui `docker-compose.yml` agar bisa menjalankan full stack (Postgres + Redis + Backend) dengan satu command.

**Acceptance Criteria:**
- [ ] `backend/Dockerfile`:
  - Multi-stage build (builder → runtime)
  - Python 3.11+ slim image
  - Non-root user
  - Healthcheck endpoint
  - `.dockerignore` ada (ignore `.venv`, `tests/`, `__pycache__`)
- [ ] `docker-compose.yml` diperbarui:
  - Service `backend` build dari `./backend`
  - Depends on `postgres` + `redis`
  - Auto-run `alembic upgrade head` saat start
  - Environment variables dari `.env`
  - Port mapping: `8000:8000`
- [ ] `docker-compose up --build` → full stack running
- [ ] Backend healthcheck pass di dalam Docker

**Detail Implementasi:**

```dockerfile
# backend/Dockerfile
FROM python:3.11-slim AS builder
WORKDIR /app
COPY pyproject.toml .
RUN pip install --no-cache-dir .

FROM python:3.11-slim AS runtime
RUN useradd -m appuser
WORKDIR /app
COPY --from=builder /usr/local/lib/python3.11/site-packages /usr/local/lib/python3.11/site-packages
COPY --from=builder /usr/local/bin /usr/local/bin
COPY . .
USER appuser
EXPOSE 8000
HEALTHCHECK CMD python -c "import httpx; httpx.get('http://localhost:8000/api/health')" || exit 1
CMD ["sh", "-c", "alembic upgrade head && uvicorn app.main:app --host 0.0.0.0 --port 8000"]
```

**Verification:**
- [ ] `docker-compose up --build -d` → semua service running
- [ ] `curl http://localhost:8000/api/health` → `{"status": "ok", ...}`
- [ ] `curl http://localhost:8000/docs` → Swagger UI
- [ ] `docker-compose down` → semua service stop clean

**Dependencies:** Task 8.1 (agar image include tested code)

**Files:**
- `backend/Dockerfile`
- `backend/.dockerignore`
- `docker-compose.yml` (update)

**Scope:** S (3 files)

---

## Task 8.3: README & Dokumentasi

**Deskripsi:** Tulis README.md yang comprehensive: deskripsi project, tech stack, setup instructions, environment variables, API documentation link, dan screenshots/demo.

**Acceptance Criteria:**
- [ ] `README.md` berisi:
  - Project description (apa itu OpenMusic)
  - Tech stack summary (FastAPI, Flutter, PostgreSQL, Redis)
  - Prerequisites (Docker, Python 3.11+, Flutter)
  - Quick Start (docker-compose up)
  - Manual Setup (step-by-step untuk development)
  - Environment Variables table (dari `.env.example`)
  - API Documentation link (`/docs`)
  - Project Structure overview
  - Testing instructions
  - Daftar fitur (dengan checklist ✅)
  - API yang digunakan (Jamendo, Last.fm, LRCLIB, TheCocktailDB)
  - License
- [ ] `.env.example` up-to-date dengan semua env vars
- [ ] Swagger docs di `/docs` menampilkan semua endpoint terorganisir

**Verification:**
- [ ] Orang baru bisa clone repo → baca README → `docker-compose up` → app running
- [ ] Semua link di README valid
- [ ] `.env.example` tidak berisi value asli (hanya placeholder)
- [ ] Swagger docs accessible dan menampilkan semua endpoint

**Dependencies:** Task 8.2

**Files:**
- `README.md` (rewrite)
- `backend/.env.example` (update jika perlu)

**Scope:** S (2 files)

---

## Task 8.4: Final Verification & Demo Preparation

**Deskripsi:** Lakukan end-to-end verification: jalankan full stack via Docker, test semua user journey, fix bug terakhir, dan persiapkan demo script.

**Acceptance Criteria:**
- [ ] Full stack berjalan via `docker-compose up`
- [ ] Demo flow berhasil dijalankan tanpa error:
  1. Register user baru
  2. Login
  3. Search lagu ("jazz")
  4. Play lagu pertama → audio terdengar
  5. Lihat lirik → tampil (atau "tidak tersedia")
  6. Lihat rekomendasi → tampil daftar lagu serupa
  7. Lihat mood → tampil mood + cocktail pairing
  8. Create playlist "My Jazz"
  9. Add lagu ke playlist
  10. Add lagu ke favorites
  11. Cek history → lagu yang diputar tercatat
  12. Logout → kembali ke login
- [ ] Tidak ada error 500 di log backend selama demo
- [ ] Swagger docs bisa digunakan untuk demo API langsung
- [ ] Security check: tidak ada hardcoded secrets di source code

**Verification:**
- [ ] Full demo flow berhasil (checklist di atas)
- [ ] `grep -r "JAMENDO_CLIENT_ID\|LASTFM_API_KEY" app/ --include="*.py"` → hanya referensi ke config
- [ ] `pytest tests/ -v` → semua PASSED (final run)
- [ ] `ruff check app/ tests/` → 0 error (final run)
- [ ] Git status clean, semua kode committed

**Dependencies:** Task 8.1, 8.2, 8.3

**Files:**
- Bug fixes (jika ada)
- Tidak ada file baru yang planned

**Scope:** S (verification, bukan coding)

---

## Checkpoint: Sprint 8 (FINAL)

Setelah semua task selesai, verifikasi **FINAL**:

- [ ] ✅ **Backend** — Semua 20+ endpoint berfungsi sesuai PRD
- [ ] ✅ **Auth** — Register, login, refresh, logout, me
- [ ] ✅ **Tracks** — Search, detail, stream, lyrics, similar, mood, cocktail
- [ ] ✅ **Playlists** — Full CRUD + add/remove tracks
- [ ] ✅ **Favorites** — Add, list, remove
- [ ] ✅ **History** — Auto-record, list
- [ ] ✅ **Frontend** — Flutter app terhubung dan fungsional
- [ ] ✅ **Testing** — Coverage ≥ 70%, auth+playlist ≥ 90%
- [ ] ✅ **Docker** — Full stack bisa jalan dengan satu command
- [ ] ✅ **Documentation** — README + Swagger docs lengkap
- [ ] ✅ **Security** — Tidak ada hardcoded secrets
- [ ] ✅ **Kode** — Semua di-commit, ruff clean

**🎉 Proyek OpenMusic siap untuk presentasi!**
