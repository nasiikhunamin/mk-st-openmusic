# OpenMusic 🎵

**OpenMusic** adalah aplikasi web dan mobile *full-stack* pemutar musik dengan fitur rekomendasi cerdas. Aplikasi ini terdiri dari *Backend* (FastAPI) dan *Frontend* (Flutter), serta mengintegrasikan berbagai API publik secara gratis seperti Jamendo (lagu), Last.fm (rekomendasi), LRCLIB (lirik sinkron), dan TheCocktailDB (rekomendasi minuman berdasarkan *mood*).

---

## 🚀 Persiapan dan Prasyarat

Pastikan komputer Anda telah terinstal:
- **Python 3.10+** (untuk backend)
- **Flutter SDK** (untuk frontend mobile)
- **Git**
- *(Opsional)* **Docker** untuk menjalankan Redis jika Anda ingin mengaktifkan fitur *caching* tingkat lanjut.

---

## 🛠️ 1. Menjalankan Backend (FastAPI)

Backend OpenMusic dibangun dari nol menggunakan Python (FastAPI). Secara bawaan, backend sudah dikonfigurasi untuk menggunakan SQLite sehingga tidak memerlukan instalasi database tambahan.

Buka terminal Anda dan jalankan langkah-langkah berikut:

### Langkah 1: Masuk ke folder backend
```bash
cd backend
```

### Langkah 2: Buat & aktifkan Virtual Environment (Lingkungan Virtual)
**Linux / macOS:**
```bash
python3 -m venv .venv
source .venv/bin/activate
```
**Windows:**
```cmd
python -m venv .venv
.venv\Scripts\activate
```

### Langkah 3: Instal dependensi proyek
```bash
pip install --upgrade pip
pip install -e ".[dev]"
```

### Langkah 4: Konfigurasi `.env`
Salin pengaturan bawaan (template) ke file `.env` asli:
```bash
cp .env.example .env
```
*(Opsional: Buka `.env` dan tambahkan Client ID Jamendo atau Last.fm API Key Anda jika ingin fitur eksternal bekerja optimal).*

### Langkah 5: Migrasi Database
Jalankan migrasi agar tabel-tabel SQLite dibuat secara otomatis:
```bash
alembic upgrade head
```

### Langkah 6: Jalankan Server Lokal
```bash
uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
```
✅ **Berhasil!** Backend sekarang berjalan di `http://localhost:8000`. Anda bisa melihat dokumentasi interaktif API (Swagger UI) di `http://localhost:8000/docs`.

---

## 📱 2. Menjalankan Frontend Mobile (Flutter)

Aplikasi klien (Frontend) dibangun menggunakan **Flutter** dan menargetkan *platform* Android.

Buka terminal **baru** (biarkan terminal backend tetap berjalan), lalu ikuti langkah ini:

### Langkah 1: Masuk ke folder frontend
```bash
cd frontend
```

### Langkah 2: Unduh dependensi (packages) Flutter
```bash
flutter pub get
```

### Langkah 3: Siapkan Emulator atau Device
Pastikan Anda sudah menjalankan emulator Android atau telah menyambungkan perangkat Android fisik yang sudah mengaktifkan *USB Debugging*.
Cek daftar perangkat dengan perintah:
```bash
flutter devices
```

### Langkah 4: Jalankan Aplikasi
```bash
flutter run
```
> **Catatan:** Secara bawaan (*default*), aplikasi Flutter sudah diatur agar mengambil URL backend dari `http://10.0.2.2:8000` (alamat localhost khusus untuk Emulator Android). Jika Anda menggunakan *device* fisik, pastikan perangkat berada di jaringan Wi-Fi yang sama dan ubah IP di pengaturan `api_client.dart` menjadi IP lokal komputer Anda (contoh: `http://192.168.1.5:8000`).

---

## 🐋 3. (Opsional) Menggunakan Docker untuk Redis / Postgres
Jika Anda ingin menggunakan Redis sebagai *caching layer* atau PostgreSQL sebagai pengganti SQLite, Anda dapat langsung menjalankan file `docker-compose.yml` di folder *root*.

Kembali ke folder utama (root) lalu jalankan:
```bash
docker compose up -d
```
Lalu pastikan Anda mengubah pengaturan di file `backend/.env` sesuai dengan konfigurasi Docker (misal mengubah `DATABASE_URL` ke konfigurasi postgres dan menyalakan `REDIS_URL`).

---

## 🧪 Menjalankan Pengujian (Testing)
Untuk menjalankan *unit test* di backend, aktifkan virtual environment di folder `backend/` lalu ketik:
```bash
pytest tests/ -v
```

Untuk menjalankan tes UI/Widget di frontend, buka folder `frontend/` lalu ketik:
```bash
flutter test
```

🎉 **Selamat Menjelajahi OpenMusic!** 🎧
