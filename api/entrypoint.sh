#!/usr/bin/env bash
# Entrypoint for the api container.
#
# Waits for Postgres, then (in development) auto-applies migrations before
# handing off to the container command (gunicorn in prod, runserver in dev).
set -euo pipefail

: "${DJANGO_SETTINGS_MODULE:=config.settings.development}"
export DJANGO_SETTINGS_MODULE

echo "[entrypoint] Waiting for the database..."
python <<'PY'
import os, time, sys
import environ

env = environ.Env()
url = env("DATABASE_URL", default="postgres://esda:esda@db:5432/esda")
cfg = env.db_url_config(url)

import psycopg
dsn = (
    f"host={cfg['HOST']} port={cfg.get('PORT') or 5432} "
    f"dbname={cfg['NAME']} user={cfg['USER']} password={cfg['PASSWORD']}"
)
for attempt in range(60):
    try:
        with psycopg.connect(dsn, connect_timeout=2):
            print("[entrypoint] Database is up.")
            sys.exit(0)
    except Exception as exc:  # noqa: BLE001
        print(f"[entrypoint] DB not ready ({attempt+1}/60): {exc}")
        time.sleep(1)
print("[entrypoint] Database never became available.", file=sys.stderr)
sys.exit(1)
PY

# Auto-migrate outside of production.
if [ "${DJANGO_SETTINGS_MODULE}" != "config.settings.production" ]; then
    echo "[entrypoint] Applying migrations..."
    python manage.py migrate --noinput
fi

if [ "${AUTO_SEED:-0}" = "1" ]; then
    echo "[entrypoint] Seeding sample data..."
    python manage.py seed || true
fi

exec "$@"
