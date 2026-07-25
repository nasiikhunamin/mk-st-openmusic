# Sprint 7: Frontend Flutter — UI & Backend Integration

**Durasi:** Minggu 7  
**Goal:** Aplikasi Flutter terhubung ke backend, user bisa melakukan semua flow utama: register/login, search, play, lihat lirik & rekomendasi, manage playlist & favorites.  
**Dependency:** Sprint 6 (semua backend endpoint lengkap)

> **Catatan:** Sprint ini fokus pada Flutter frontend. Detail task lebih high-level karena implementasi UI bervariasi tergantung design choices.

---

## Sprint Requirements

Sebelum sprint ini dianggap selesai, **SEMUA** kondisi berikut harus terpenuhi:

- [ ] Flutter app terhubung ke backend (base URL configurable)
- [ ] Auth flow berfungsi: register, login, token storage, auto-refresh, logout
- [ ] Search lagu dan tampilkan hasil (paginated)
- [ ] Music player berfungsi: play, pause, seek, next (dari audio URL Jamendo)
- [ ] Lirik dan rekomendasi tampil saat lagu diputar
- [ ] Playlist management: create, view, add/remove tracks
- [ ] Favorites: add/remove, lihat daftar
- [ ] History: lihat riwayat putar
- [ ] Error handling: tampilkan pesan jika request gagal

---

## Task 7.1: API Client Layer & Auth State Management

**Deskripsi:** Setup HTTP client di Flutter yang terhubung ke backend, dengan interceptor untuk auto-attach Bearer token dan auto-refresh token saat 401. Implementasi auth state management (register, login, logout, token persistence).

**Acceptance Criteria:**
- [ ] API client class dengan base URL configurable
- [ ] Auto-attach `Authorization: Bearer {token}` header ke semua request
- [ ] Interceptor: jika response 401 → coba refresh token → retry request
- [ ] Token storage: access token di memory, refresh token di secure storage
- [ ] Auth state: `isLoggedIn`, `currentUser`, `login()`, `register()`, `logout()`
- [ ] Login screen & Register screen berfungsi
- [ ] Setelah login, redirect ke home screen
- [ ] Setelah logout, redirect ke login screen

**Verification:**
- [ ] Register user baru → berhasil, masuk ke home
- [ ] Login → berhasil, masuk ke home
- [ ] Close app → buka lagi → masih login (token persisted)
- [ ] Logout → kembali ke login screen
- [ ] Token expired → auto-refresh → request tetap berhasil

**Dependencies:** Sprint 6 (backend running)

**Files:**
- `frontend/lib/services/api_client.dart`
- `frontend/lib/services/auth_service.dart`
- `frontend/lib/screens/login_screen.dart`
- `frontend/lib/screens/register_screen.dart`

**Scope:** M (4 files)

---

## Task 7.2: Search & Music Player

**Deskripsi:** Implementasi search screen (cari lagu, tampilkan hasil paginated) dan music player (play audio dari Jamendo URL dengan kontrol dasar).

**Acceptance Criteria:**
- [ ] Search bar dengan debounce (300ms)
- [ ] Hasil pencarian tampil sebagai list (cover, title, artist, duration)
- [ ] Pagination: load more saat scroll ke bawah (infinite scroll atau tombol "Load More")
- [ ] Tap lagu → mulai play audio dari stream URL
- [ ] Player controls: play/pause, seek bar, current time / duration
- [ ] Mini player tetap terlihat saat navigasi ke screen lain
- [ ] Now playing info: cover, title, artist

**Verification:**
- [ ] Search "jazz" → tampil daftar lagu
- [ ] Scroll → load halaman berikutnya
- [ ] Tap lagu → audio diputar, player muncul
- [ ] Play/pause berfungsi
- [ ] Navigate ke screen lain → mini player tetap ada
- [ ] Kembali ke player → state tetap (posisi, lagu)

**Dependencies:** Task 7.1 (auth + API client)

**Files:**
- `frontend/lib/screens/search_screen.dart`
- `frontend/lib/screens/player_screen.dart`
- `frontend/lib/widgets/mini_player.dart`
- `frontend/lib/services/player_service.dart`

**Scope:** M (4 files)

---

## Task 7.3: Lirik, Rekomendasi & Mood/Cocktail UI

**Deskripsi:** Tampilkan lirik (tab/section di player screen), rekomendasi lagu serupa, dan mood + cocktail pairing saat lagu diputar.

**Acceptance Criteria:**
- [ ] Player screen punya tab: "Lirik" | "Rekomendasi" | "Mood"
- [ ] Tab Lirik: tampilkan plain lyrics (synced lyrics jika ada)
- [ ] Tab Rekomendasi: list lagu serupa, tap untuk putar
- [ ] Tab Mood: tampilkan mood detection + cocktail pairing (nama, gambar, bahan)
- [ ] Loading state saat fetch data
- [ ] "Lirik tidak tersedia" jika null
- [ ] "Rekomendasi tidak tersedia" jika Last.fm gagal

**Verification:**
- [ ] Play lagu → tab "Lirik" tampil lirik (atau "tidak tersedia")
- [ ] Tab "Rekomendasi" tampil daftar lagu serupa
- [ ] Tap lagu rekomendasi → mulai play
- [ ] Tab "Mood" tampil mood + cocktail pairing
- [ ] Loading spinner saat data belum siap

**Dependencies:** Task 7.2 (player)

**Files:**
- `frontend/lib/screens/player_screen.dart` (update: tabs)
- `frontend/lib/widgets/lyrics_view.dart`
- `frontend/lib/widgets/recommendations_view.dart`
- `frontend/lib/widgets/mood_cocktail_view.dart`

**Scope:** M (4 files)

---

## Task 7.4: Playlist, Favorites & History UI

**Deskripsi:** Implementasi library screen yang menampilkan playlist user, favorites, dan history. User bisa create playlist, add/remove tracks, dan manage favorites.

**Acceptance Criteria:**
- [ ] Library screen dengan 3 tab: "Playlist" | "Favorit" | "Riwayat"
- [ ] Tab Playlist: list playlist, tap untuk detail, FAB untuk create
- [ ] Playlist detail: list tracks, swipe untuk hapus track
- [ ] Create playlist dialog: input nama
- [ ] Tab Favorit: list lagu favorit, swipe untuk hapus
- [ ] Tab Riwayat: list lagu yang pernah diputar (newest first)
- [ ] Dari search/player: tombol "Add to Playlist" dan "Add to Favorites"
- [ ] Bottom navigation: Search | Library | Profile

**Verification:**
- [ ] Create playlist → muncul di daftar
- [ ] Add track ke playlist → muncul di detail playlist
- [ ] Add to favorites → muncul di tab Favorit
- [ ] Putar lagu → muncul di tab Riwayat
- [ ] Delete playlist → hilang dari daftar
- [ ] Remove track dari playlist → hilang
- [ ] Remove dari favorites → hilang

**Dependencies:** Task 7.1, Task 7.2

**Files:**
- `frontend/lib/screens/library_screen.dart`
- `frontend/lib/screens/playlist_detail_screen.dart`
- `frontend/lib/widgets/add_to_playlist_dialog.dart`
- `frontend/lib/services/playlist_service.dart`
- `frontend/lib/services/favorites_service.dart`

**Scope:** L (5 files) — tetap 1 task karena UI saling terkait

---

## Checkpoint: Sprint 7

Setelah semua task selesai, verifikasi:

- [ ] **Full user journey berfungsi end-to-end:**
  Register → Login → Search → Play → Lihat lirik → Lihat rekomendasi → Mood/Cocktail → Add to playlist → Add to favorites → Lihat history → Logout
- [ ] Audio playback berfungsi (Jamendo stream)
- [ ] Token auto-refresh berfungsi
- [ ] Error states ditampilkan dengan baik (bukan crash)
- [ ] Bottom navigation berfungsi
- [ ] Semua kode sudah di-commit
- [ ] **Aplikasi fungsional end-to-end** — siap untuk Sprint 8 (Testing & Deployment)
