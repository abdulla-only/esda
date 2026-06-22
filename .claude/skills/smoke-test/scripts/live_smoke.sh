#!/usr/bin/env bash
# End-to-end smoke test for the esda API against a running stack.
# Usage: bash .claude/skills/smoke-test/scripts/live_smoke.sh
# Per-user model: each user owns their decks/cards (no shared catalog).
# All responses use the envelope {success, data} / {success, error}.
set -euo pipefail

API="${API_URL:-http://localhost:8000}/api/v1"
DC="docker compose --env-file .env.development"
EMAIL="demo@esda.app"
PASS="demopass123"

echo "==> health"
curl -fsS "$API/health"; echo

echo "==> ensure demo user ($EMAIL)"
$DC exec -T api python manage.py shell -c "
from django.contrib.auth import get_user_model
U = get_user_model()
u, created = U.objects.get_or_create(email='$EMAIL')
u.set_password('$PASS'); u.save()
print('created' if created else 'exists')
"

echo "==> login (email/JWT)"
TOK=$(curl -fsS -X POST "$API/auth/token" \
  -H 'Content-Type: application/json' \
  -d "{\"email\":\"$EMAIL\",\"password\":\"$PASS\"}" \
  | python3 -c "import sys,json;print(json.load(sys.stdin)['data']['access'])")
H="Authorization: Bearer $TOK"
echo "   access token length: ${#TOK}"

LANG=$(curl -fsS "$API/languages" -H "$H" | python3 -c "import sys,json;print(json.load(sys.stdin)['data']['results'][0]['id'])")

echo "==> create a deck"
DECK=$(curl -fsS -X POST "$API/decks" -H "$H" -H 'Content-Type: application/json' \
  -d "{\"language\":$LANG,\"name\":\"Smoke Deck\"}" \
  | python3 -c "import sys,json;d=json.load(sys.stdin)['data'];print(d['id'])")
echo "   deck id: $DECK"

echo "==> add a card"
curl -fsS -X POST "$API/cards" -H "$H" -H 'Content-Type: application/json' \
  -d "{\"deck\":$DECK,\"front\":\"hello\",\"back\":\"salom\",\"part_of_speech\":\"noun\"}" >/dev/null

echo "==> study queue"
CARD=$(curl -fsS "$API/study/queue?limit=5" -H "$H" \
  | python3 -c "import sys,json;print(json.load(sys.stdin)['data']['results'][0]['id'])")
echo "   first card id: $CARD"

echo "==> grade card $CARD (Good=3)"
curl -fsS -X POST "$API/study/grade" -H "$H" -H 'Content-Type: application/json' \
  -d "{\"card\":$CARD,\"rating\":3}" \
  | python3 -c "import sys,json;d=json.load(sys.stdin)['data'];print('   state',d['state'],'reps',d['reps'])"

echo "==> cleanup (delete deck)"
curl -fsS -X DELETE "$API/decks/$DECK" -H "$H" -o /dev/null -w '   delete -> HTTP %{http_code}\n'

echo "==> unauthorized check (expect 401)"
CODE=$(curl -s -o /dev/null -w '%{http_code}' "$API/study/queue")
[ "$CODE" = "401" ] && echo "   OK: 401" || { echo "   FAIL: got $CODE"; exit 1; }

echo "==> smoke test passed ✅"
