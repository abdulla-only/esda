---
name: dev-stack
description: >-
  Bring up, verify, or tear down the esda docker development stack (db, redis,
  api, web, bot). Use when asked to start/run/restart the stack, check service
  health, or debug why a container won't come up. Knows the project's port and
  env-file specifics.
---

# dev-stack

The stack is defined in `docker-compose.yml` and driven by `.env.development`.
Always pass the env file so variable substitution matches the Makefile:
`docker compose --env-file .env.development …` (or just use the `make` targets).

## Bring it up

```bash
make dev-build      # build images (api, web, bot)
make dev            # up: db, redis, api(:8000), web(:5173), bot
# detached + verify instead of foreground:
docker compose --env-file .env.development up -d
```

The `api` container waits for Postgres, **auto-migrates**, and (when `AUTO_SEED=1`)
seeds sample data on startup.

## Verify

```bash
curl -fsS http://localhost:8000/api/v1/health       # -> {"success":true,"data":{"status":"ok","database":true}}
curl -s -o /dev/null -w '%{http_code}\n' http://localhost:5173/   # web -> 200
docker compose --env-file .env.development ps --format 'table {{.Service}}\t{{.Status}}'
docker compose --env-file .env.development logs bot | tail   # bot idles without a real token
```

## Common issues (and fixes)

- **`address already in use` on 5432** — the dockerized DB publishes on host
  **5433** on purpose (a local Postgres likely owns 5432). If 5433 also clashes,
  change `POSTGRES_PORT` in `.env.development`.
- **`/app/entrypoint.sh: permission denied`** — the bind mount shadows the
  image's chmod. Fix on the host: `chmod +x api/entrypoint.sh`.
- **bot crash-looping** — only happens if it's been changed to exit without a
  token; it should idle. Set a real `BOT_TOKEN` to actually run it.
- **web `node_modules` left root-owned** — Docker creates the mountpoint as root;
  remove with `docker run --rm -v "$PWD/web":/w -w /w alpine rm -rf node_modules`.

## Tear down

```bash
make dev-down                                        # keep volumes (db data)
docker compose --env-file .env.development down -v    # also drop the db volume
```
