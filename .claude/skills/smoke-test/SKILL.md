---
name: smoke-test
description: >-
  Run an end-to-end smoke test against a running esda stack: email-JWT login →
  deck tree → study queue → FSRS grade → unauthorized check. Use to confirm the
  backend works after changes, before a demo, or when debugging the auth/study
  flow.
---

# smoke-test

Confirms the core API contract end-to-end. Requires the stack to be up
(`make dev` — see the `dev-stack` skill) and the api reachable on
`http://localhost:8000`.

## Run it

```bash
bash .claude/skills/smoke-test/scripts/live_smoke.sh
```

The script (see `scripts/live_smoke.sh`) — all paths under `/api/v1`, all
responses unwrapped from the `{success,data}` envelope:
1. ensures a demo user exists (creates `demo@esda.app` in the api container),
2. logs in via `POST /api/v1/auth/token` and captures `data.access`,
3. fetches `GET /api/v1/decks/tree` and prints deck/card counts,
4. fetches `GET /api/v1/study/queue`, grabs a card, and `POST /api/v1/study/grade`s
   it (rating 3 = Good), printing the updated FSRS state,
5. asserts an unauthenticated `GET /api/v1/study/queue` returns **401**.

Any non-2xx (other than the intentional 401) means a regression — read the
output, then check `docker compose --env-file .env.development logs api`.

## Notes

- Endpoints are under **`/api/v1`, no trailing slash**, and **enveloped**; the
  script relies on both.
- Login field is **`email`** (not username).
- This does not test Telegram auth (that needs a real `BOT_TOKEN` + a valid HMAC
  over real initData). The initData validator is covered by the api unit path in
  `accounts/telegram.py`; add a `manage.py test` case there if you change it.
