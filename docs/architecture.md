# Architecture notes

See the top-level [README](../README.md) for the diagram and endpoint table.
This file collects deeper notes per subsystem.

## API conventions

- **Versioning:** all endpoints under `/api/v1`, no trailing slashes.
- **Response envelope** (single shape, enforced by
  `config.renderers.EnvelopeJSONRenderer`):
  - success: `{"success": true, "data": <payload>}`
  - error: `{"success": false, "error": {"code", "message", "details"?}}`
  Errors come from raised DRF exceptions; the renderer maps status → `code`.
- **Pagination:** `PageNumberPagination`, `PAGE_SIZE=20`. `data` for list
  endpoints is `{count, next, previous, results}`. The study queue is a bounded
  custom payload, not a generic list.
- **Throttling:** public endpoints use `ScopedRateThrottle`
  (`telegram_auth`, `token`, `health` rates in settings), backed by the Redis
  cache so limits hold across gunicorn workers.
- **Layering:** views orchestrate only; domain logic lives in `*/services.py`.
- **Permissions:** declared explicitly per endpoint; card writes are admin-only.

## Auth

Three ways to obtain a JWT (djangorestframework-simplejwt):

0. **Register** — `POST /api/v1/auth/register` with `{ "email", "password" }`.
   `RegisterSerializer` enforces a unique email and Django's password validators;
   `register_user` (service) creates the account and the view returns a JWT pair
   (201). Public + throttled (`register` scope).

1. **Telegram** — `POST /api/v1/auth/telegram` with `{ "init_data": "<raw initData>" }`.
   The server (`accounts/telegram.py`) validates the data:
   - splits the query string, pulls out `hash`;
   - builds the data-check-string (remaining pairs sorted, `k=v`, `\n`-joined);
   - `secret_key = HMAC_SHA256(key="WebAppData", msg=BOT_TOKEN)`;
   - compares `HMAC_SHA256(data_check_string, secret_key)` to `hash`
     (constant-time);
   - rejects if `auth_date` is older than `TELEGRAM_AUTH_TTL`.
   On success it `get_or_create`s a user by `telegram_id` and returns a JWT pair.

2. **Email/password** — `POST /api/v1/auth/token` (the custom user uses email as
   `USERNAME_FIELD`).

## Content ownership (shared catalog + personal decks)

`Deck` has a nullable `owner`:
- `owner = NULL` → the shared, curated English/Russian CEFR catalog (managed in
  the Django admin / `seed`).
- `owner = <user>` → that user's personal decks. `Card` ownership derives from
  its `deck.owner`.

`unique_together = (owner, parent, slug)` so each user has an independent slug
namespace. Enforcement (no IDOR):
- **Reads** return shared (`owner IS NULL`) + the requester's own decks/cards.
  `?owner=me` narrows decks to the user's own.
- **Writes** are allowed only on owned objects: `DeckViewSet` forces
  `owner = request.user` on create and `IsDeckOwnerOrReadOnly` blocks editing
  shared/others' decks; `CardSerializer.validate_deck` + `IsCardDeckOwnerOrReadOnly`
  ensure cards are only created/edited in the user's own decks.
- The **study queue** offers shared + own new cards, never another user's
  personal cards.

## Scheduling (FSRS)

`srs/services.py` bridges our `Review` rows and the `fsrs` package:

- A `Review` stores the schedule in plain columns (`due`, `stability`,
  `difficulty`, `state`, `step`, `reps`, `lapses`, `last_review`).
- `grade_review(review, rating)` hydrates an `fsrs.Card`, calls
  `Scheduler.review_card(card, Rating)`, writes the result back, bumps `reps`
  (and `lapses` on *Again*), and appends a `ReviewLog`.
- `state` adds a `NEW` value (0) on top of FSRS's Learning/Review/Relearning for
  cards the user has never graded. `reps`/`lapses` are tracked by us because
  py-fsrs does not keep them on its `Card`.

## Study queue

`GET /api/v1/study/queue` returns **due** reviews (`due <= now`) first, then **new**
cards (no review yet) up to a per-day limit (`DAILY_NEW_LIMIT`, minus reviews
already created today). Filter by `?deck=<id>`; cap with `?limit=`.
