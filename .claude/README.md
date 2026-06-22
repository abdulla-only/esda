# .claude/ — Claude Code workspace config for esda

Project-scoped configuration that makes Claude Code productive on this monorepo.
Everything here (except `settings.local.json`) is committed and shared.

All agents and contributors follow
[`docs/engineering-principles.md`](../docs/engineering-principles.md) — the
governing rules, in priority order. CLAUDE.md and every agent point to it.

```
.claude/
├── settings.json        # shared settings (currently: deny reading secret .env files)
├── agents/              # specialized subagents, one per service + a reviewer
└── skills/              # task playbooks Claude can invoke
```

## Subagents (`agents/`)

| Agent                   | Use for                                                        |
|-------------------------|----------------------------------------------------------------|
| `backend-engineer`      | `api/` — Django 5 / DRF / FSRS / migrations / auth             |
| `frontend-tma-engineer` | `web/` — React + TS + Vite + Telegram Mini App                 |
| `bot-engineer`          | `bot/` — aiogram 3.x                                           |
| `mobile-engineer`       | `mobile/` — Flutter client                                     |
| `monorepo-reviewer`     | read-only cross-cutting review before merge                    |

Invoke implicitly ("use the backend-engineer to…") or via the Agent tool with
`subagent_type`.

## Skills (`skills/`)

| Skill            | What it does                                                       |
|------------------|--------------------------------------------------------------------|
| `dev-stack`      | bring up / verify / tear down the docker stack, with the gotchas   |
| `smoke-test`     | end-to-end check: login → create deck/card → study queue → grade → 401 |
| `add-vocabulary` | add languages / CEFR decks / cards the right way                   |

## Recommended permission allowlist (opt-in)

Claude cannot grant itself permissions, so this is left for you to enable. To
cut down on approval prompts for routine, safe commands, either run the
`/fewer-permission-prompts` skill, or add this to **`.claude/settings.local.json`**
(personal) or merge into `settings.json` (shared):

```json
{
  "permissions": {
    "allow": [
      "Bash(make:*)",
      "Bash(docker compose:*)",
      "Bash(python manage.py:*)",
      "Bash(ruff:*)",
      "Bash(npm run:*)",
      "Bash(npx tsc:*)",
      "Bash(flutter analyze:*)",
      "Bash(flutter pub get:*)",
      "Bash(flutter test:*)",
      "Bash(curl:*)",
      "Bash(git status:*)",
      "Bash(git diff:*)",
      "Bash(git log:*)"
    ]
  }
}
```

These cover the day-to-day build/test/run loop without opening up destructive
operations.
