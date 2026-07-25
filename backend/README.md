# Dokumentasi API Backend OpenMusic

Selamat datang di backend **OpenMusic**, sebuah layanan streaming dan eksplorasi musik premium. Dokumentasi ini ditulis sepenuhnya dalam Bahasa Indonesia untuk memudahkan pemahaman arsitektur, proses instalasi, dan cara menjalankan server lokal dari nol sampai berjalan normal.

---

## Daftar Isi
1. [Prasyarat Sistem](#1-prasyarat-sistem)
2. [Langkah-Langkah Instalasi (Step-by-Step)](#2-langkah-langkah-instalasi-step-by-step)
3. [Struktur Folder](#3-struktur-folder)
4. [Arsitektur & Konsep Backend](#4-arsitektur--konsep-backend)
5. [Spesifikasi Endpoint API](#5-spesifikasi-endpoint-api)
6. [Integrasi Pihak Ketiga & Caching](#6-integrasi-pihak-ketiga--caching)
7. [Pengujian (Testing) & Kualitas Kode](#7-pengujian-testing--kualitas-kode)

---

## 1. Prasyarat Sistem

Sebelum memulai instalasi, pastikan sistem Anda telah memiliki komponen berikut:

* **Python 3.10 ke atas** (Disarankan menggunakan Python 3.14).
* **pip** (Python package installer) untuk menginstal paket dependensi.
* **Virtualenv** (`python3-venv`) untuk mengisolasi lingkungan dependensi projek.
* **Git** (Opsional, untuk kloning kode).
* **SQLite3** (Sudah bawaan dari instalasi Python, digunakan untuk database lokal).
* **Redis** (Opsional). Jika Redis tidak ada di komputer Anda, server akan secara otomatis mendeteksi dan beralih menggunakan *in-memory cache* lokal (RAM) tanpa membuat sistem Anda crash.

---

## 2. Langkah-Langkah Instalasi (Step-by-Step)

Ikuti langkah demi langkah di bawah ini untuk menginstal projek dari awal hingga siap digunakan:

### Langkah 1: Masuk ke Direktori Backend
Buka terminal Anda dan pastikan berada di dalam direktori `backend/` dari projek OpenMusic:
```bash
cd backend
```

### Langkah 2: Buat Lingkungan Virtual (Virtual Environment)
Buat lingkungan virtual untuk mengisolasi paket Python agar tidak bentrok dengan pustaka global komputer Anda:
```bash
python3 -m venv .venv
```

### Langkah 3: Aktifkan Lingkungan Virtual
Aktifkan virtual environment yang baru dibuat:
* **Linux / macOS**:
  ```bash
  source .venv/bin/activate
  ```
* **Windows (Command Prompt)**:
  ```cmd
  .venv\Scripts\activate
  ```
* **Windows (PowerShell)**:
  ```powershell
  .venv\Scripts\Activate.ps1
  ```

*(Setelah aktif, Anda akan melihat tanda `(.venv)` di awal baris terminal Anda).*

### Langkah 4: Perbarui PIP & Instal Dependensi Projek
Lakukan upgrade pada pip bawaan, lalu instal semua dependensi yang didefinisikan di dalam `pyproject.toml` (termasuk pustaka pengembangan):
```bash
pip install --upgrade pip
pip install -e ".[dev]"
```
Perintah di atas akan menginstal FastAPI, Uvicorn, SQLAlchemy, Alembic, Pydantic, HTTPX, Pytest, Ruff, dan pustaka lainnya.

### Langkah 5: Salin dan Konfigurasi Environment Variables (`.env`)
Salin file template `.env.example` menjadi `.env` asli:
```bash
cp .env.example .env
```
Buka file `.env` yang baru dibuat menggunakan teks editor (seperti VS Code, nano, dll) lalu isi variabel berikut:
```env
DATABASE_URL=sqlite+aiosqlite:///./openmusic.db
REDIS_URL=redis://localhost:6379/0
SECRET_KEY=kunci-jwt-rahasia-anda-bebas-diisi-apa-saja
JAMENDO_CLIENT_ID=isi-dengan-client-id-jamendo-anda
LASTFM_API_KEY=isi-dengan-api-key-lastfm-anda
```
> **Catatan**: Jika Anda tidak memiliki Redis yang sedang berjalan di komputer lokal, abaikan saja baris `REDIS_URL`. Sistem akan otomatis mendeteksi kegagalan koneksi ke Redis saat startup dan menggunakan *in-memory fallback cache*.

### Langkah 6: Jalankan Migrasi Database
Buat dan sinkronkan skema database SQLite lokal Anda menggunakan Alembic:
```bash
alembic upgrade head
```
Perintah ini akan membuat file database baru bernama `openmusic.db` di direktori backend dengan seluruh tabel yang diperlukan (users, playlists, favorites, history, dll).

### Langkah 7: Jalankan Server Uvicorn
Nyalakan server pengembangan lokal:
```bash
uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
```

### Langkah 8: Buka Dokumentasi Swagger API
Jika terminal menampilkan status `Started server process`, buka browser Anda dan kunjungi tautan berikut untuk melihat daftar endpoint interaktif:
* **Swagger UI**: [http://localhost:8000/docs](http://localhost:8000/docs)

---

## 3. Struktur Folder

Projek backend ini diorganisasi menggunakan struktur domain modular yang bersih:
```
backend/
├── alembic/                 # Skrip migrasi skema database
├── app/
│   ├── api/                 # Pendaftaran router utama API
│   │   └── v1/
│   ├── core/                # Konfigurasi global, dependensi, exception contract
│   ├── db/                  # Inisialisasi engine DB & sesi deklarasi
│   ├── modules/             # Modul domain bisnis mandiri
│   │   ├── auth/            # Logika login, registrasi, JWT & refresh token
│   │   ├── favorites/       # Fitur menyimpan lagu favorit
│   │   ├── history/         # Pencatatan riwayat pemutaran lagu
│   │   ├── mood/            # Logika klasifikasi mood lagu
│   │   ├── playlists/       # CRUD Playlist & manajemen track di dalamnya
│   │   └── tracks/          # Pencarian lagu, pemutaran, metadata Jamendo
│   ├── services/            # Integrasi API Client (Jamendo, Lastfm, Lrclib, CocktailDB)
│   └── main.py              # Titik masuk utama aplikasi (FastAPI & lifespan manager)
└── tests/                   # Kumpulan berkas pengujian otomatis (Pytest)
```

---

## 4. Arsitektur & Konsep Backend

* **Modularisasi**: Setiap domain fungsional diletakkan di bawah `app/modules/` dengan struktur mandiri (router, service, model, schema) untuk mempermudah skalabilitas dan pemeliharaan kode.
* **Dependency Injection**: Memanfaatkan fitur DI bawaan FastAPI (`Depends`) untuk menyuplai sesi database, client API eksternal, dan business logic service ke router secara dinamis.
* **Standarisasi Kontrak Error**: Semua error yang terjadi di backend (baik validasi input, kegagalan autentikasi, maupun kesalahan internal) diubah secara seragam melalui Exception Handler global menjadi format JSON berikut:
  ```json
  {
    "error": {
      "code": "ERROR_CODE",
      "message": "Pesan deskripsi kesalahan dalam bahasa manusia",
      "details": null
    }
  }
  ```

---

## 5. Spesifikasi Endpoint API

### 1. Autentikasi (`/api/auth`)
* **POST `/api/auth/register`**: Registrasi user baru.
  * Input: `{"email": "user@example.com", "password": "password123"}`
* **POST `/api/auth/login`**: Login user untuk mendapatkan JWT.
  * Input: `{"email": "user@example.com", "password": "password123"}`
  * Output: Token akses (`access_token`) dan token penyegar (`refresh_token`).
* **POST `/api/auth/refresh`**: Menyegarkan token akses yang kadaluarsa menggunakan token penyegar.
  * Input: `{"refresh_token": "token-string"}`

### 2. Eksplorasi Musik (`/api/tracks`)
*Semua endpoint di bawah ini (kecuali pencarian) membutuhkan header `Authorization: Bearer <access_token>`.*
* **GET `/api/tracks`**: Mencari musik di katalog Jamendo (paginated).
  * Parameter Query: `q=genre/judul`, `page=1`, `pageSize=20`.
* **GET `/api/tracks/{track_id}`**: Mengambil detail informasi lagu.
* **GET `/api/tracks/{track_id}/stream`**: Mendapatkan URL streaming audio (dan secara otomatis mencatat track ini ke riwayat putar/history).
* **GET `/api/tracks/{track_id}/similar`**: Menampilkan daftar lagu serupa hasil rekomendasi Last.fm.
* **GET `/api/tracks/{track_id}/lyrics`**: Menampilkan lirik teks murni & tersinkronisasi (.lrc) dari LRCLIB.

### 3. Deteksi Mood & Rekomendasi Minuman (`/api/tracks/{track_id}`)
*Memerlukan header token.*
* **GET `/api/tracks/{track_id}/mood`**: Menganalisis mood lagu berdasarkan tags Jamendo (speed, acousticelectric, vocalinstrumental). Mood yang dihasilkan meliputi: `Energetic`, `Chill`, `Party`, `Mellow`, atau `Neutral`.
* **GET `/api/tracks/{track_id}/cocktail`**: Menyajikan rekomendasi koktail unik dari TheCocktailDB berdasarkan hasil klasifikasi mood lagu tersebut.

### 4. Playlist Manajemen (`/api/playlists`)
*Memerlukan header token.*
* **GET `/api/playlists`**: Melihat seluruh daftar playlist milik user (paginated).
* **POST `/api/playlists`**: Membuat playlist baru (`{"name": "Nama Playlist"}`).
* **GET `/api/playlists/{playlist_id}`**: Melihat detail playlist beserta daftar lagu di dalamnya.
* **PUT `/api/playlists/{playlist_id}`**: Mengubah nama playlist.
* **DELETE `/api/playlists/{playlist_id}`**: Menghapus playlist.
* **POST `/api/playlists/{playlist_id}/tracks`**: Menambahkan lagu ke dalam playlist.
* **DELETE `/api/playlists/{playlist_id}/tracks/{track_id}`**: Menghapus lagu dari playlist.

### 5. Musik Favorit (`/api/favorites`)
*Memerlukan header token.*
* **GET `/api/favorites`**: Melihat semua lagu yang difavoritkan oleh user.
* **POST `/api/favorites`**: Memfavoritkan lagu.
* **DELETE `/api/favorites/{track_id}`**: Batal memfavoritkan lagu.

### 6. Riwayat Pemutaran (`/api/history`)
*Memerlukan header token.*
* **GET `/api/history`**: Melihat riwayat pemutaran lagu user, diurutkan dari yang paling baru diputar.

---

## 6. Integrasi Pihak Ketiga & Caching

Untuk menjaga performa aplikasi dan menghemat kuota pemanggilan API eksternal, backend OpenMusic mengimplementasikan sistem penyimpanan cache yang kuat dengan masa aktif (TTL) sebagai berikut:
1. **Jamendo API**: Informasi detail lagu di-cache **1 jam**, hasil pencarian di-cache **5 menit**.
2. **Last.fm API**: Daftar lagu serupa di-cache **30 menit**.
3. **LRCLIB API**: Data lirik lagu di-cache **24 jam**.
4. **TheCocktailDB API**: Rekomendasi koktail di-cache **1 jam**.

**Kebijakan Degradasi Anggun (Graceful Degradation)**: Jika API pihak ketiga mengalami kegagalan/down, sistem backend tidak akan crash. Backend akan secara otomatis mengembalikan respons kosong atau fallback yang aman untuk menjaga aplikasi klien tetap berjalan normal.

---

## 7. Pengujian (Testing) & Kualitas Kode

Backend OpenMusic dilengkapi dengan pengujian otomatis komprehensif (Unit dan Integration Tests). 

### Menjalankan Pengujian
Pastikan virtual environment telah aktif, lalu jalankan perintah berikut:
```bash
python -m pytest tests/ -v
```

### Memeriksa Kualitas dan Format Kode (Linter)
Kami menggunakan Ruff untuk menjaga standar kualitas penulisan kode Python:
```bash
ruff check app/ tests/
```
Jika terdapat kode yang tidak rapi, rapikan secara otomatis dengan:
```bash
ruff check --fix app/ tests/
```
