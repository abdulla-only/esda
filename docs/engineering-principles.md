# Engineering Principles — esda

The rules every change to this repo follows. Listed in **priority order** — they
override personal preference and any default behavior. CLAUDE.md and the
`.claude/agents/*` point here; this file is the single source of truth.

### 1. Consistency over personal preference
Match existing conventions (naming, structure, error handling, patterns) even
when another approach is equally valid. One pattern per concern across the whole
stack:
- One API response envelope (`{success,data}` / `{success,error}`) — never raw
  or unstructured bodies. (`api/config/renderers.py`)
- One auth flow shared by web, mobile, and the Telegram Mini App
  (`/api/v1/auth/*`).
- One validation layer (DRF serializers), one error-handling layer (the
  renderer + raised DRF exceptions).

### 2. KISS — keep it simple
Prefer the simplest correct solution. No abstraction layers, base classes,
generic utilities, config flags, or patterns unless the duplication is real and
already present. Solve the problem in front of you.

### 3. YAGNI — build only what is asked
No features, endpoints, settings, packages, or future-proofing nobody requested.
No speculative interfaces, unused parameters, or half-wired toggles.

### 4. DRY — but not at the cost of clarity
Reuse existing services, serializers, API clients, and helpers before writing
new ones; search first. Three similar lines beat a premature, leaky abstraction.
Client contract types (web `src/shared/api/types.ts`, mobile
`features/*/data/*`) are duplicated only because there is no shared/generated
source yet — if that drift becomes painful, add OpenAPI (`drf-spectacular`) + a
generated client rather than hand-syncing.

### 5. Single Responsibility
- Models — persistence and invariants.
- Serializers — input validation and output shaping only.
- Views — orchestrate request → service → response. No business logic.
- Services (`*/services.py`) — all domain/business logic.
- UI components — presentation; lift data-fetching and logic out.
Business logic must NEVER live in a view, serializer, or UI component.

### 6. Clear layering across clients
One backend API is the source of truth; web, mobile, and the Mini App are thin
clients.
- No client re-implements server-enforced rules. Validate on the client for UX,
  enforce on the server for correctness.
- The bot / Mini App calls the same API as everyone else — not a privileged
  backdoor. Telegram `initData` is validated server-side; never trust
  client-sent identity.
- Shared contracts (types, enums, error codes) come from one place.

### 7. API & framework best practices
- Business logic in the service layer, out of views/serializers.
- Prevent N+1: eager-load (`select_related`/`prefetch_related`/`annotate`)
  anything you serialize.
- Wrap multi-write operations in a transaction.
- Never edit an existing migration — only add new ones; review every generated
  migration. Split add-nullable → backfill → make-required.
- Paginate every list endpoint that can grow (`PAGE_SIZE=20`). No unbounded lists.
- Version the API (`/api/v1`). Document every endpoint as you add it.

### 8. Security first
- Default to authenticated; every endpoint declares its permission explicitly.
- Public/anonymous endpoints ALWAYS carry throttling (`ScopedRateThrottle`,
  Redis-backed).
- Validate all file uploads: extension allowlist + size limit + magic-byte check.
- Never log or return secrets, tokens, OTP codes, or credentials.
- Validate/sanitize all client-supplied identifiers and headers (request ids,
  Telegram `initData`) against a strict pattern; constant-time compare HMACs.
- Don't weaken CORS, CSRF, or auth. Object-level authorization on every
  owner-scoped resource (no IDOR).

### 9. Testing discipline
- Add or update tests for every behavioral change.
- Cover permission boundaries, negative cases, and error/edge paths — not just
  the happy path.
- Follow the existing harness (`APITestCase`, `manage.py test`); don't introduce
  a new test style.

### 10. Performance awareness
- No queries or network calls inside loops.
- Cache expensive lookups per-request.
- No synchronous third-party HTTP inside request validation — move to a
  service/background job.
- Move slow/non-critical work (push, email, heavy aggregation) to background tasks.

### 11. Refactoring discipline
- Refactor only when it supports the requested change or removes real risk. Keep
  diffs small and reviewable. Separate refactor commits from feature commits.

### 0. Comments — terse, one line, only when they add "why"
No banner/section-divider comments or multi-line explanatory blocks. One line
max, stating the non-obvious *why*, never restating the code. If a comment needs
more than one line, refactor the code instead.

---

## Documentation Sync Rule (not optional)
When you add or change an API endpoint, a request/response field, an event type,
or a shared contract, in the **same change** you MUST:
1. Update the API client(s) / shared types (web `src/shared/api` +
   `features/*/api.ts`, mobile `features/*/data`).
2. Update the docs — this file, `README.md`, and `docs/architecture.md` — so they
   never drift from the code.
3. Update any client-facing integration/handoff doc.

---

## Client structure (feature-first)

Web and mobile are organized by **feature**, each feature keeping its own data,
logic, and ui. Cross-cutting transport lives in `shared/`. Logic never lives in
a component/widget.

```
web/src/                          mobile/lib/
  shared/api/{client,types}.ts      features/shared/{api_client,token_storage}.dart
  shared/telegram.ts                features/<feature>/
  features/<feature>/                 data/        (api + models)
    api.ts        (data)              controller/  (ChangeNotifier — logic)
    use*.ts       (logic — hook)      ui/          (widgets — presentation)
    *.tsx         (ui)              config.dart  main.dart
  app/App.tsx  main.tsx
```

Add a feature = add a folder; don't scatter its pieces across layer-wide
directories. Promote something to `shared/` only when a second feature needs it
(DRY, but not premature).
