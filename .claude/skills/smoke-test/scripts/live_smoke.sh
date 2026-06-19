#!/usr/bin/env bash
# End-to-end smoke test for the esda API against a running stack.
# Usage: bash .claude/skills/smoke-test/scripts/live_smoke.sh
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
echo "   access token length: ${#TOK}"

echo "==> deck tree"
curl -fsS "$API/decks/tree" -H "Authorization: Bearer $TOK" \
  | python3 -c "import sys,json;[print('   ', d['name'], '·', d['card_count'],'cards') for d in json.load(sys.stdin)['data']]"

echo "==> study queue"
CARD=$(curl -fsS "$API/study/queue?limit=1" -H "Authorization: Bearer $TOK" \
  | python3 -c "import sys,json;c=json.load(sys.stdin)['data']['results'][0];print(c['id'])")
echo "   first card id: $CARD"

echo "==> grade card $CARD (Good=3)"
curl -fsS -X POST "$API/study/grade" -H "Authorization: Bearer $TOK" \
  -H 'Content-Type: application/json' -d "{\"card\":$CARD,\"rating\":3}" \
  | python3 -c "import sys,json;d=json.load(sys.stdin)['data'];print('   state',d['state'],'due',d['due'][:10],'reps',d['reps'])"

echo "==> unauthorized check (expect 401)"
CODE=$(curl -s -o /dev/null -w '%{http_code}' "$API/study/queue")
[ "$CODE" = "401" ] && echo "   OK: 401" || { echo "   FAIL: got $CODE"; exit 1; }

echo "==> smoke test passed ✅"
