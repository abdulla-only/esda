# esda

A spaced-repetition vocabulary learning app for **English & Russian**, organized
by **CEFR level** (A1, A2, …). One monorepo, four clients sharing one backend:

| Service     | Stack                                   | Role                                        |
|-------------|-----------------------------------------|---------------------------------------------|
| `api/`      | Django 5 + DRF + PostgreSQL + **FSRS**  | REST API, auth, scheduling                  |
| `web/`      | Vite + React + TypeScript               | Web app **and** Telegram Mini App           |
| `bot/`      | aiogram 3.x                             | Telegram bot (launches the Mini App)        |
| `mobile/`   | Flutter                                 | Mobile app (skeleton)                       |

Scheduling uses the [FSRS](https://github.com/open-spaced-repetition/py-fsrs)
algorithm (the `fsrs` package) to decide when each card is due.

---

## Architecture

```
                 ┌─────────────┐
                 │  Telegram   │
                 │   client    │
                 └──┬───────┬──┘
       /start + Mini│App     │initData
        button       │       ▼
   ┌──────────┐   ┌──┴───┐  ┌──────────────┐
   │  bot/    │   │ web/ │  │  mobile/     │
   │ aiogram  │   │React │  │  Flutter     │
   └────┬─────┘   └──┬───┘  └──────┬───────┘
        │            │ JWT         │ JWT
        │            ▼             ▼
        │      ┌────────────────────────────┐
        └─────▶│          api/ (DRF)         │
               │  /api/v1/auth/telegram      │
               │  /api/v1/auth/token         │
               │  /api/v1/decks, /cards      │
               │  /api/v1/study/queue,grade  │
               └────────┬───────────┬────────┘
                       │       │
                  ┌────▼──┐ ┌──▼────┐
                  │  db   │ │ redis │
                  │ pg16  │ │  7    │
                  └───────┘ └───────┘
```

- **Telegram Mini App login**: the web app reads Telegram `initData`, POSTs it
  to `/api/v1/auth/telegram`; the server validates it with HMAC-SHA256 over
  `BOT_TOKEN` and returns a JWT.
- **Plain-web login**: email + password via `/api/v1/auth/token` (simplejwt).
- Content (languages, decks, cards) is curated through the **Django admin**.

### API conventions

- **Versioned** under `/api/v1`. No trailing slashes.
- **One response envelope** for everything:
  - success → `{"success": true, "data": <payload>}`
  - error → `{"success": false, "error": {"code": "...", "message": "...", "details": ...}}`
- **List endpoints are paginated** (`PageNumberPagination`, `PAGE_SIZE=20`): the
  `data` holds `{count, next, previous, results}`. (The study queue is a bounded
  custom payload, not a generic list.)
- **Public endpoints are throttled** (scoped rate limits, backed by Redis).
- Every endpoint declares its permission explicitly; default is authenticated.

### Endpoints (all JSON, JWT-protected unless noted)

| Method | Path                         | Auth   | Description                          |
|--------|------------------------------|--------|--------------------------------------|
| GET    | `/api/v1/health`             | public | Liveness + DB check (throttled)      |
| POST   | `/api/v1/auth/telegram`      | public | Validate Telegram initData → JWT     |
| POST   | `/api/v1/auth/token`         | public | Email + password → JWT pair          |
| POST   | `/api/v1/auth/token/refresh` | public | Refresh access token                 |
| GET    | `/api/v1/auth/me`            | JWT    | Current user                         |
| GET    | `/api/v1/languages`          | JWT    | Languages                            |
| GET    | `/api/v1/decks`              | JWT    | Flat deck list (`?language=en`)      |
| GET    | `/api/v1/decks/tree`         | JWT    | Nested deck tree                     |
| GET    | `/api/v1/cards`              | JWT    | List cards (`?deck=<id>`)            |
| POST/PUT/DELETE | `/api/v1/cards`     | admin  | Card writes (content is curated)     |
| GET    | `/api/v1/study/queue`        | JWT    | Due + new cards (`?deck=&limit=`)    |
| POST   | `/api/v1/study/grade`        | JWT    | Grade a card (`{card, rating 1-4}`)  |

---

## Repository layout

```
esda/
├── api/        # Django 5 + DRF + FSRS  (Python 3.12+)
│   ├── config/         # split settings: base/local/development/production
│   ├── accounts/       # custom User (email login, telegram_id) + Telegram auth
│   ├── catalog/        # Language, Deck (tree), Card + seed command
│   └── srs/            # Review, ReviewLog, FSRS grading service
├── web/        # Vite + React + TS (web + Telegram Mini App)
├── bot/        # aiogram 3.x
├── mobile/     # Flutter
├── docs/
├── docker-compose.yml
├── Makefile
├── .env.example
└── README.md
```

---

## Prerequisites

- **Docker** + **Docker Compose v2** (for `make dev`)
- For host (`*-local`) runs: **Python 3.12+**, **Node 20+**, **Flutter 3.x**
- A Telegram **bot token** from [@BotFather](https://t.me/BotFather) (for the bot
  and Telegram login; the rest of the app works without one)

---

## Quickstart

First, create your env files from the template:

```bash
cp .env.example .env.development   # used by docker (make dev)
cp .env.example .env.local         # used by host (make *-local)
```

Then edit each (at minimum set a real `SECRET_KEY`; set `BOT_TOKEN`/`MINI_APP_URL`
to use Telegram features). The two files differ mainly in `DATABASE_URL`:

| File               | Used by        | `DATABASE_URL` host         |
|--------------------|----------------|-----------------------------|
| `.env.development` | docker (`dev`) | `db:5432` (compose network) |
| `.env.local`       | host (`local`) | `localhost:5433` (published)|

> The dockerized Postgres is published on host port **5433** to avoid clashing
> with a Postgres you may already run on 5432.

### Option A — Docker (everything in containers)

```bash
make dev          # build + start db, redis, api, bot, web
# api  → http://localhost:8000   (/api/v1/health, /admin)
# web  → http://localhost:5173
```

The `api` container waits for Postgres, **auto-runs migrations**, and (when
`AUTO_SEED=1`, the default in `.env.development`) seeds sample data on startup.

```bash
make superuser    # create an admin to manage content at /admin
make dev-logs     # tail logs
make dev-down     # stop everything
```

### Option B — Local on the host (DB still in Docker)

```bash
make dev          # (or: docker compose up -d db redis) just for the database
make install      # api venv + deps, web npm install, bot venv + deps
make migrate      # apply migrations
make seed         # sample languages/decks/cards

make api-local    # Django runserver on http://localhost:8000
make web-local    # Vite dev server on http://localhost:5173
make bot-local    # aiogram bot
make mobile-local # flutter run
```

**Local vs Dev in one sentence:** `*-local` runs a service straight on your
machine using **`.env.local`**, while `*-dev` (and `make dev`) runs it inside
Docker using **`.env.development`**. Both talk to the same dockerized Postgres,
so `make migrate` / `make seed` (which run in the api container) affect either
workflow.

---

## Makefile reference

```
Local (host; loads .env.local):
  make install        api venv+deps, web npm install, bot venv+deps
  make api-local      Django runserver on the host
  make web-local      Vite dev server on the host
  make bot-local      run the aiogram bot on the host
  make mobile-local   flutter run

Development (Docker; loads .env.development):
  make dev            docker compose up (db, redis, api, bot, web)
  make dev-build      docker compose build
  make dev-down       docker compose down
  make dev-logs       tail logs
  make api-dev        run only api in docker
  make web-dev        run only web in docker
  make bot-dev        run only bot in docker

DB & utils (run in the api container against the compose db):
  make migrate        apply migrations
  make makemigrations create migrations
  make superuser      create a Django admin user
  make seed           seed languages/decks/cards
  make shell          Django shell
  make test           run api tests
  make lint           ruff check
  make format         ruff format
```

---

## Telegram Mini App notes

Telegram only loads Mini Apps over **HTTPS**. For local testing, expose the web
dev server with a tunnel (e.g. `ngrok http 5173`) and set that URL as the Mini
App URL in BotFather and as `MINI_APP_URL`. In a plain browser the web app mocks
the Telegram environment so you can develop without Telegram.

## License

Private project scaffold.
