# OpenMusic — Sprint Overview

**Total: 8 Sprint (8 Minggu)**  
**Pattern: Vertical Slicing — setiap sprint menghasilkan sistem yang working**

---

## Dependency Graph

```
Sprint 1: Foundation
    │
    └── Sprint 2: Auth
            │
            └── Sprint 3: Jamendo (Search + Stream)
                    │
                    ├── Sprint 4: Playlist + Favorites + History
                    │
                    └── Sprint 5: Last.fm (Rekomendasi) + LRCLIB (Lirik)
                            │
                            └── Sprint 6: Mood + Cocktail (Wow)
                                    │
                                    └── Sprint 7: Frontend Flutter
                                            │
                                            └── Sprint 8: Testing + Deploy
```

---

## Sprint Summary

| Sprint | Minggu | Judul | Tasks | Deliverable |
|--------|--------|-------|-------|-------------|
| [Sprint 1](sprint1.md) | 1 | Foundation — Scaffolding & DB | 4 | Project skeleton + DB + Redis + Health endpoint |
| [Sprint 2](sprint2.md) | 2 | Auth — Register, Login, Refresh | 4 | Full auth flow + JWT + Refresh token |
| [Sprint 3](sprint3.md) | 3 | Jamendo — Search, Detail, Stream | 3 | Cari lagu + detail + streaming URL |
| [Sprint 4](sprint4.md) | 4 | Data — Playlist, Favorites, History | 4 | Full CRUD playlist + favorites + history |
| [Sprint 5](sprint5.md) | 5 | API — Rekomendasi & Lirik | 3 | Last.fm similar + LRCLIB lyrics |
| [Sprint 6](sprint6.md) | 6 | Wow — Mood & Cocktail | 3 | Mood classification + cocktail pairing |
| [Sprint 7](sprint7.md) | 7 | Frontend — Flutter UI | 4 | Full UI + backend integration |
| [Sprint 8](sprint8.md) | 8 | Ship — Testing & Deploy | 4 | Coverage ≥ 70% + Docker + README |

**Total: 29 tasks**

---

## Progress Tracker

- [ ] Sprint 1: Foundation _(0/4 tasks)_
- [ ] Sprint 2: Auth _(0/4 tasks)_
- [ ] Sprint 3: Jamendo _(0/3 tasks)_
- [ ] Sprint 4: Data _(0/4 tasks)_
- [ ] Sprint 5: API _(0/3 tasks)_
- [ ] Sprint 6: Wow _(0/3 tasks)_
- [ ] Sprint 7: Frontend _(0/4 tasks)_
- [ ] Sprint 8: Ship _(0/4 tasks)_

---

## Cara Menggunakan Sprint Files

1. **Buka sprint file** yang sedang dikerjakan (e.g., `sprint/sprint1.md`)
2. **Baca Sprint Requirements** — ini adalah definisi "selesai" untuk sprint
3. **Kerjakan task secara berurutan** — setiap task punya dependencies
4. **Centang acceptance criteria** saat selesai
5. **Jalankan checkpoint** di akhir sprint sebelum lanjut
6. **Commit kode** setelah setiap task (bukan akhir sprint)

### Tips
- **Jangan skip sprint.** Dependency graph harus diikuti.
- **Jangan mulai task baru sebelum yang lama selesai.** Incremental implementation.
- **Jalankan `ruff check` dan `pytest` setelah setiap task.** Bukan hanya di checkpoint.
- **Jika stuck**, baca ulang PRD section yang relevan (sudah di-link di setiap task).
