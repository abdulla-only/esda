---
name: add-vocabulary
description: >-
  Add vocabulary (decks and cards) to esda. Use when asked to add/create decks
  or cards, import a word list, or seed a user's study content. Content is
  per-user — there is no shared catalog.
---

# add-vocabulary

Every deck and card belongs to a **user** (no shared catalog). `Language`
(English/Russian) is the only shared reference data, created by `make seed`.

## In the app (normal way)

Sign in, open the **Decks** tab → create a deck (name + language) → open it →
**Add card** (front, back, part of speech, example). Edit/delete inline.

## Via the API (scripted import)

All under `/api/v1`, JWT required; responses use the `{success,data}` envelope.

```bash
API=http://localhost:8000/api/v1
TOK=...   # from POST /auth/token
H="Authorization: Bearer $TOK"
LANG=$(curl -fsS "$API/languages" -H "$H" | python3 -c "import sys,json;print(json.load(sys.stdin)['data']['results'][0]['id'])")

# create a deck (owner is the caller; slug is generated server-side)
DECK=$(curl -fsS -X POST "$API/decks" -H "$H" -H 'Content-Type: application/json' \
  -d "{\"language\":$LANG,\"name\":\"Travel\"}" \
  | python3 -c "import sys,json;print(json.load(sys.stdin)['data']['id'])")

# add a card
curl -fsS -X POST "$API/cards" -H "$H" -H 'Content-Type: application/json' \
  -d "{\"deck\":$DECK,\"front\":\"airport\",\"back\":\"aeroport\",\"part_of_speech\":\"noun\",\"example\":\"We met at the airport.\"}"
```

## Rules

- **`part_of_speech`** ∈ `noun, verb, adjective, adverb, phrase, other`.
- A user can only add cards to **their own** decks (server rejects others'/
  nonexistent decks with 400/404). `front` = term, `back` = translation;
  `description`/`example` optional.
- Decks are flat (no `parent` needed); `slug`/`owner` are server-managed — don't
  send them.
- `make seed` only creates the **languages**, not decks/cards.

After importing, run the `smoke-test` skill or check `GET /api/v1/decks` /
`GET /api/v1/cards?deck=<id>` to confirm.
