# esda — monorepo task runner
#
# Two ways to run each service:
#   *-local : runs on the HOST (venv / npm / flutter). Loads .env.local.
#             The database still runs in Docker (`make dev` brings up db+redis).
#   *-dev   : runs inside Docker via docker-compose. Loads .env.development.
#
# Run `make help` for the full list.

SHELL := /bin/bash
.ONESHELL:
.DEFAULT_GOAL := help

# docker compose, pinned to the development env file for variable substitution.
DC := docker compose --env-file .env.development

# Load host env vars from .env.local into a recipe's environment.
LOAD_LOCAL := set -a; [ -f .env.local ] && . ./.env.local; set +a

.PHONY: help install \
        api-local web-local bot-local mobile-local \
        dev dev-build dev-down dev-logs api-dev web-dev bot-dev \
        migrate makemigrations superuser seed shell test lint format

help:
	@echo "esda — make targets"
	@echo ""
	@echo "Local (host; DB in Docker, uses .env.local):"
	@echo "  make install        install api venv+deps, web npm deps, bot venv+deps"
	@echo "  make api-local       Django runserver on the host"
	@echo "  make web-local       Vite dev server on the host"
	@echo "  make bot-local       run the aiogram bot on the host"
	@echo "  make mobile-local    flutter run"
	@echo ""
	@echo "Development (Docker, uses .env.development):"
	@echo "  make dev             docker compose up (db, redis, api, bot, web)"
	@echo "  make dev-build       docker compose build"
	@echo "  make dev-down        docker compose down"
	@echo "  make dev-logs        tail logs"
	@echo "  make api-dev         run only api in docker"
	@echo "  make web-dev         run only web in docker"
	@echo "  make bot-dev         run only bot in docker"
	@echo ""
	@echo "DB & utils (run in docker against the compose db):"
	@echo "  make migrate makemigrations superuser seed shell test lint format"

# ---------------------------------------------------------------------------
# Install (host)
# ---------------------------------------------------------------------------
install:
	@echo ">> api: creating venv + installing deps"
	cd api && python3 -m venv .venv && ./.venv/bin/pip install --upgrade pip && ./.venv/bin/pip install -r requirements.txt
	@echo ">> web: npm install"
	cd web && npm install
	@echo ">> bot: creating venv + installing deps"
	cd bot && python3 -m venv .venv && ./.venv/bin/pip install --upgrade pip && ./.venv/bin/pip install -r requirements.txt
	@echo ">> done. (mobile: run 'flutter pub get' in mobile/ if needed)"

# ---------------------------------------------------------------------------
# Local (host) run targets — use .env.local
# ---------------------------------------------------------------------------
api-local:
	cd api && $(LOAD_LOCAL); ./.venv/bin/python manage.py migrate && ./.venv/bin/python manage.py runserver 0.0.0.0:8001

web-local:
	cd web && $(LOAD_LOCAL); npm run dev -- --port 5174

bot-local:
	cd bot && $(LOAD_LOCAL); ./.venv/bin/python main.py

mobile-local:
	cd mobile && flutter run

# ---------------------------------------------------------------------------
# Development (Docker) — use .env.development
# ---------------------------------------------------------------------------
dev:
	$(DC) up

dev-build:
	$(DC) build

dev-down:
	$(DC) down

dev-logs:
	$(DC) logs -f

api-dev:
	$(DC) up api

web-dev:
	$(DC) up web

bot-dev:
	$(DC) up bot

# ---------------------------------------------------------------------------
# DB & utils — run inside the api container against the compose db
# ---------------------------------------------------------------------------
migrate:
	$(DC) run --rm api python manage.py migrate

makemigrations:
	$(DC) run --rm api python manage.py makemigrations

superuser:
	$(DC) run --rm api python manage.py createsuperuser

seed:
	$(DC) run --rm api python manage.py seed

shell:
	$(DC) run --rm api python manage.py shell

test:
	$(DC) run --rm api python manage.py test

lint:
	$(DC) run --rm api ruff check .

format:
	$(DC) run --rm api ruff format .
