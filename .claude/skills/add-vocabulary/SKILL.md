---
name: add-vocabulary
description: >-
  Add languages, CEFR decks, and vocabulary cards to esda the right way. Use
  when asked to add/seed content, create a new CEFR level (A1/A2/B1…), import a
  word list, or extend the seed data.
---

# add-vocabulary

Content lives in the `catalog` app: `Language` → `Deck` (a per-language tree via
`parent`) → `Card`. There are two correct ways to add content.

## Option A — Django admin (curated, one-off)

Content is meant to be managed in the admin. Create an admin user and use the UI:

```bash
make superuser            # then open http://localhost:8000/admin
```

`Language`, `Deck`, and `Card` are registered. Decks form a tree (`parent`); a
deck's `slug` is unique within its parent (`unique_together = (parent, slug)`).

## Option B — extend the seed command (reproducible / version-controlled)

Edit `api/catalog/management/commands/seed.py` — it's idempotent
(`get_or_create`). The `SEED` dict maps language code → decks → cards. Each card
is `(front, back, part_of_speech, example)`.

```python
SEED = {
    "en": {"name": "English", "decks": {
        "A1": [("hello", "привет", "noun", "Hello, how are you?"), ...],
        "B1": [ ... ],   # add a new CEFR level here
    }},
}
```

Then apply:

```bash
make seed       # runs `python manage.py seed` in the api container
```

## Rules to follow

- **`part_of_speech`** must be one of the `Card.PartOfSpeech` choices:
  `noun, verb, adjective, adverb, phrase, other`.
- **CEFR decks** are top-level decks per language (A1, A2, …). For sub-topics,
  create child decks (set `parent`); keep `slug` unique within the parent.
- Use `order` to control display order within a deck/level.
- `front` = the term being learned, `back` = its translation; `description` and
  `example` are optional but improve study quality.
- Keep the seed idempotent — always `get_or_create`, never blind `create`.

After adding content, run the `smoke-test` skill (or `make seed` + check
`/api/v1/decks/tree`) to confirm it shows up.
