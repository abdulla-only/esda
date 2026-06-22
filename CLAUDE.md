# CLAUDE.md — esda

Spaced-repetition vocabulary app (English & Russian, by CEFR level). Monorepo
with four clients on one Django backend. Read this before editing; it captures
the non-obvious decisions that bite you otherwise.

## Engineering principles (read first)

All work follows **[docs/engineering-principles.md](docs/engineering-principles.md)**
— the governing rules, in priority order. In short: consistency > KISS > YAGNI >
DRY > SRP; one API envelope and one auth flow; business logic only in
`*/services.py`; security-first (explicit permissions, throttled public
endpoints, server-side `initData`); tests for every behavioral change; terse
one-line "why" comments only. **Documentation Sync Rule:** any endpoint/field/
contract change updates the clients AND the docs in the same change.

## Stack & layout

```
api/      Django 5.2 + DRF + PostgreSQL + FSRS (py-fsrs)   — Python 3.12
web/      Vite + React + TS  (web AND Telegram Mini App)
bot/      aiogram 3.x
mobile/   Flutter (skeleton)
docs/     architecture notes
docker-compose.yml · Makefile · .env.example
```

## Running it

- **Docker (all services):** `make dev` (loads `.env.development`). Brings up
  db, redis, api(:8000), web(:5173), bot. api auto-migrates and (when
  `AUTO_SEED=1`) seeds on startup.
- **Host (one service on the machine, db in Docker):** `make install` once, then
  `make api-local` / `make web-local` / `make bot-local` / `make mobile-local`
  (load `.env.local`).
- **DB & utils run in the api container:** `make migrate|makemigrations|superuser|seed|shell|test|lint|format`.

> Two env files on purpose: **`.env.development`** (docker; DB host = `db:5432`)
> vs **`.env.local`** (host; DB host = `localhost:5433`). Keep both in sync when
> you add a variable, and add it to `.env.example` too.

## Gotchas (learned the hard way)

- **Postgres is published on host port `5433`, not 5432** — to avoid clashing
  with a local Postgres. Inside the compose network it's still `5432`.
- **API is versioned `/api/v1` with NO trailing slashes.** The DRF router uses
  `DefaultRouter(trailing_slash=False)`. Keep new endpoints slash-less.
- **One response envelope** (`config.renderers.EnvelopeJSONRenderer`):
  `{"success":true,"data":…}` or `{"success":false,"error":{code,message,details?}}`.
  Never return raw/unstructured bodies; raise DRF exceptions for errors. List
  endpoints are paginated (`PAGE_SIZE=20`); public endpoints are throttled
  (scoped rates, Redis-backed cache). Business logic lives in `*/services.py`,
  not in views/serializers. Clients unwrap `data` (web axios interceptor; mobile
  `body['data']`). **Per the Documentation Sync Rule, any endpoint/field/contract
  change updates the clients AND the docs in the same change.**
- **Deck ownership (no shared catalog):** every `Deck` has a required `owner`;
  `Card` ownership derives from `deck.owner`. `Language` (EN/RU) is the only
  shared reference data. `unique_together=(owner,parent,slug)`. Reads/writes are
  owner-scoped (DeckViewSet forces owner; `IsDeckOwnerOrReadOnly` /
  `IsCardDeckOwnerOrReadOnly` + `CardSerializer.validate_deck` prevent IDOR).
  The study queue serves only the user's own cards.
- **Custom user logs in by email**, not username (`AUTH_USER_MODEL=accounts.User`,
  `USERNAME_FIELD="email"`, no `username` field). Telegram-only users get a
  synthetic `tg_<id>@telegram.local` email. Never add a migration that assumes a
  username field.
- **FSRS mapping** (`srs/services.py`): py-fsrs `State` has only Learning/Review/
  Relearning — our `Review.State` adds `NEW=0` for never-graded cards. py-fsrs
  does **not** track `reps`/`lapses`; we bump those ourselves (`lapses` on rating
  1=Again). Round-trip a card via `Card.from_dict`/`to_dict`; review datetimes
  must be tz-aware UTC.
- **`entrypoint.sh` must stay executable** (`chmod +x`) — the compose bind mount
  shadows the image's chmod, so the host file's mode is what runs.
- **Generating migrations without a host venv:** run one-off in the target image,
  then fix ownership, e.g.
  `docker compose --env-file .env.development run --rm api python manage.py makemigrations`.
- **The bot idles** (doesn't crash-loop) until `BOT_TOKEN` is a real BotFather
  token. Telegram login + Mini App also need an **HTTPS** `MINI_APP_URL`.

## Conventions

- **Python:** ruff (`make lint` / `make format`); settings split under
  `config/settings/{base,local,development,production}.py`, all config via
  `django-environ`. Business logic for grading lives in `srs/services.py`, not
  views.
- **Web & mobile are feature-first** (`features/<feature>/` with data + logic +
  ui per feature; cross-cutting transport in `shared/`). UI is presentation only
  — logic lives in **hooks** (web) and **ChangeNotifier controllers** (mobile),
  not in components/screens.
  - **Web** (`web/src/`): transport + envelope/JWT in `shared/api/client.ts`,
    contract types in `shared/api/types.ts`, Telegram bootstrap in
    `shared/telegram.ts` (`getRawInitData()` via the SDK with a
    `window.Telegram.WebApp.initData` fallback; null in a plain browser → email
    login). An `app/ErrorBoundary` guards against blank-page render crashes.
    Each feature has `api.ts` (data) + a `use*` hook (logic) + a component (ui).
    UI is a **custom design system** (no UI library) — tokens + components in
    `src/styles.css` (violet brand, light/dark, safe-area via `env()`). Verify a
    build with the node:22 image before claiming done.
  - **Mobile** (`lib/`): transport in `features/shared/api_client.dart`, JWT only
    in `features/shared/token_storage.dart`. Each feature has `data/`,
    `controller/`, `ui/`. `flutter analyze` must be clean.
- **Bot:** handlers on a `Router`; the Mini App button is `WebAppInfo(url=...)`.

## Specialized agents & skills

- Agents: `backend-engineer`, `frontend-tma-engineer`, `bot-engineer`,
  `mobile-engineer`, `monorepo-reviewer` (see `.claude/agents/`).
- Skills: `dev-stack`, `smoke-test`, `add-vocabulary` (see `.claude/skills/`).
