# OpenMusic Backend API Documentation

Welcome to the backend of **OpenMusic**, a premium modular music streaming and exploration service. This backend is built using **FastAPI** with a clean, modular structure, asynchronous database queries, caching, and integrations with multiple third-party music APIs.

---

## Table of Contents
1. [Tech Stack](#tech-stack)
2. [Getting Started](#getting-started)
3. [Project Structure](#project-structure)
4. [Architecture Overview](#architecture-overview)
5. [Database Migrations](#database-migrations)
6. [API Specifications](#api-specifications)
7. [Third-Party Integrations & Caching](#third-party-integrations--caching)
8. [Testing & Quality Assurance](#testing--quality-assurance)

---

## Tech Stack
* **Framework**: FastAPI (Python 3.14 compatible)
* **ORM & Database**: SQLAlchemy (asyncio) + SQLite (for development/testing compatibility)
* **Migrations**: Alembic
* **Caching**: Redis (with memory fallback)
* **Linter & Formatter**: Ruff
* **HTTP Client**: HTTPX (async)

---

## Getting Started

### 1. Requirements
* Python 3.10+ (Recommended Python 3.14)
* Virtual Environment manager (`venv`)

### 2. Installation
Navigate to the `backend` directory and set up the dependencies:
```bash
cd backend
python -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt # or setup using pyproject.toml
```

### 3. Environment Variables Configuration
Copy the `.env.example` file to `.env` and fill in the values:
```bash
cp .env.example .env
```
Ensure you provide proper keys:
```env
DATABASE_URL=sqlite+aiosqlite:///./openmusic.db
REDIS_URL=redis://localhost:6379/0
SECRET_KEY=your-super-secret-jwt-key
JAMENDO_CLIENT_ID=your-jamendo-client-id
LASTFM_API_KEY=your-lastfm-api-key
```

### 4. Apply Database Migrations
```bash
alembic upgrade head
```

### 5. Run the Server
```bash
uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
```
Swagger UI will be available at `http://localhost:8000/docs`.

---

## Project Structure
The backend follows a domain-driven modular structure:
```
backend/
├── alembic/                 # Alembic migration scripts
├── app/
│   ├── api/                 # API routing registration
│   │   └── v1/
│   ├── core/                # Global config, dependencies, exceptions
│   ├── db/                  # DB base & session declaration
│   ├── modules/             # Domain modules
│   │   ├── auth/            # Authentication logic & endpoints
│   │   ├── favorites/       # Favorite tracks management
│   │   ├── history/         # Play history tracking
│   │   ├── mood/            # Mood classification models/schemas
│   │   ├── playlists/       # Playlist management & tracks
│   │   └── tracks/          # Track search, stream, metadata routing
│   ├── services/            # Shared clients (Jamendo, Last.fm, LRCLIB, CocktailDB)
│   └── main.py              # Application entrypoint & global middleware
└── tests/                   # Full Pytest test suite
```

---

## Architecture Overview
* **Modularization**: Code is partitioned into distinct self-contained domains under `app/modules/`. Each module houses its models, schemas, routers, dependencies, and services.
* **Dependency Injection**: FastAPI’s `Depends` system is strictly utilized to inject database sessions, external clients, and business logic services.
* **Error Handling**: Implements a global error handler capturing custom `AppError` exceptions to enforce a strict standardized JSON error format conforming to:
  ```json
  {
    "error": {
      "code": "ERROR_CODE",
      "message": "Human readable message",
      "details": null
    }
  }
  ```

---

## Database Migrations
Migrations are managed using Alembic. 
* To apply migrations: `alembic upgrade head`
* To rollback migration: `alembic downgrade -1`
* Standard models created:
  * `User`: User registration and credentials
  * `RefreshToken`: Used for secure JWT refresh token rotation
  * `Playlist`: Custom playlists
  * `PlaylistTrack`: Association table linking playlists and tracks
  * `Favorite`: Track favorite flags per user
  * `History`: Track play counts and playback history logs

---

## API Specifications

### 1. Authentication
* **POST `/api/auth/register`**
  * Registers a new user.
  * Body: `{"email": "user@example.com", "password": "password123"}`
* **POST `/api/auth/login`**
  * Log in and retrieve JWT tokens.
  * Body: `{"email": "user@example.com", "password": "password123"}`
  * Returns access and refresh token.
* **POST `/api/auth/refresh`**
  * Rotate and get a new access token.
  * Body: `{"refresh_token": "token-string"}`

### 2. Music Tracks
All tracks endpoints (except search) require `Bearer` token auth.
* **GET `/api/tracks?q=query&page=1&pageSize=20`**
  * Search tracks in Jamendo.
* **GET `/api/tracks/{track_id}`**
  * Get track details by ID.
* **GET `/api/tracks/{track_id}/stream`**
  * Retrieve track stream URL and automatically log to play history.
* **GET `/api/tracks/{track_id}/similar`**
  * Get similar tracks recommended by Last.fm.
* **GET `/api/tracks/{track_id}/lyrics`**
  * Get plain & synced lyrics from LRCLIB.

### 3. Mood & Cocktail Pairing
Requires `Bearer` token auth.
* **GET `/api/tracks/{track_id}/mood`**
  * Analyze and return track mood based on speed, acousticelectric, and vocalinstrumental tags.
* **GET `/api/tracks/{track_id}/cocktail`**
  * Get a personalized cocktail recommendation pairing with the song's classified mood.

### 4. Playlists
Requires `Bearer` token auth.
* **GET `/api/playlists`**: List user's playlists (paginated).
* **POST `/api/playlists`**: Create a playlist (`{"name": "My playlist"}`).
* **GET `/api/playlists/{playlist_id}`**: Get playlist details and tracks.
* **PUT `/api/playlists/{playlist_id}`**: Rename playlist.
* **DELETE `/api/playlists/{playlist_id}`**: Delete playlist.
* **POST `/api/playlists/{playlist_id}/tracks`**: Add track to playlist (`{"track_id": "id", ...}`).
* **DELETE `/api/playlists/{playlist_id}/tracks/{track_id}`**: Remove track from playlist.

### 5. Favorites
Requires `Bearer` token auth.
* **GET `/api/favorites`**: List favorite tracks.
* **POST `/api/favorites`**: Favorite a track (`{"track_id": "id", ...}`).
* **DELETE `/api/favorites/{track_id}`**: Unfavorite a track.

### 6. Play History
Requires `Bearer` token auth.
* **GET `/api/history`**: Get user's listening history sorted by latest plays.

---

## Third-Party Integrations & Caching
To maintain responsiveness and conform to API rate limits, heavy caching is implemented:
1. **Jamendo API**: Searches and tracks are cached (5 minutes and 1 hour respectively).
2. **Last.fm**: Similar tracks are cached for **30 minutes**.
3. **LRCLIB**: Lyrics are cached for **24 hours**.
4. **TheCocktailDB**: Cocktail pairings are cached for **1 hour**.

All external service clients employ **graceful degradation** policies: if an external API goes down, the backend will return a default/fallback object or a clean error without crashing the server.

---

## Testing & Quality Assurance
Run the complete unit and integration test suite:
```bash
python -m pytest tests/ -v
```
To run the linter check:
```bash
ruff check app/ tests/
```
