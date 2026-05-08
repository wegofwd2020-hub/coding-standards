# Coding Rules — WeGoFwd2020

> Universal coding standards that apply to **all** WeGoFwd2020 projects.
> These are loaded into Claude Code via `~/.claude/CLAUDE.md` and apply
> automatically regardless of which project you're working in.
>
> Last updated: 2026-05-08

---

## 1. Money Is Never a Float

All monetary values use precise decimal types. Never floating point.

| Language | Type | DB Column |
|---|---|---|
| Go | `decimal.Decimal` (shopspring) | `NUMERIC(14,2)` |
| Python | `Decimal` (stdlib) | `NUMERIC(14,2)` |
| TypeScript | `string` (with 2dp) | `NUMERIC(14,2)` |

API responses serialize money as **strings** (`"150000.00"`).

---

## 2. Secrets — Tiered by Classification

Not all secrets are equal. The source mechanism depends on data classification tier.
No hardcoded defaults. Fail fast at startup if a required secret is missing.
**Never log secrets, tokens, passwords, or API keys.**

| Tier | Examples | Source |
|---|---|---|
| **T1** | JWT signing keys, DB master passwords, API master keys | HashiCorp Vault (KV v2) via `pkg/secrets.VaultSource` |
| **T2** | Third-party API keys (SendGrid, Twilio, FCM) | Vault KV v2 or Kubernetes Secret → env var |
| **T3** | Service endpoints, ports, feature flags | Environment variable (`os.Getenv`) |
| **T4** | Log level, timeout values, non-sensitive config | Environment variable or config map |

### T1 secrets — always from Vault, never from env vars

T1 secrets must **not** appear in environment variables. Env vars are visible in
`/proc/<pid>/environ`, `docker inspect` output, container orchestrator audit logs,
and shell history. JWT signing keys exposed this way allow token forgery.

**Correct production pattern:**
```go
// AppRole credentials are T3 — acceptable as env vars.
vault := secrets.NewVaultSource(secrets.VaultConfig{
    Address:  os.Getenv("VAULT_ADDR"),
    RoleID:   os.Getenv("VAULT_ROLE_ID"),
    SecretID: os.Getenv("VAULT_SECRET_ID"),
})
// T1 secret fetched from Vault, held in memory, never re-serialised.
jwtKey, err := vault.GetSecret(ctx, "iam/jwt-private-key")
```

**Correct local dev pattern:**
```
# Env var carries only a FILE PATH (not the secret):
IAM_KEY_DIR=./keys
```
```go
src := secrets.NewFileSource(os.Getenv("IAM_KEY_DIR"))
jwtKey, err := src.GetSecret(ctx, "jwt_private.pem")  // file is gitignored
```

### Startup check

Services that depend on T1 secrets must register a `/readyz` health check that
verifies Vault connectivity before serving traffic. See `pkg/secrets.VaultSource`
which implements `observability.HealthChecker`.

Go implementation: `pkg/secrets` — `VaultSource` (production) and `FileSource` (dev).

---

## 3. Cache by Default, Not as Optimization

Design every read path with a caching strategy from day one.

- **L1**: In-process TTL cache (60s) — per worker, no network hop
- **L2**: Redis (5 min TTL) — shared across workers
- **L3**: Database — source of truth

Cache invalidation is explicit. Never rely on TTL expiry alone for correctness-critical data.

---

## 4. Interfaces for All External Dependencies

Business logic never calls external services directly. Every dependency is accessed
through an interface defined in the consuming package. This enables testing with
mocks — no external services required for unit tests.

---

## 5. Idempotency Everywhere

Every write operation must be safe to retry without side effects.

- SQL: `INSERT ... ON CONFLICT DO NOTHING/UPDATE`
- Events: Deduplication via `event_id`
- APIs: `Idempotency-Key` header support on POST endpoints

---

## 6. Writes Never Block Reads

Non-critical writes (progress tracking, analytics events, cache population) use
background tasks. Return success to the caller before processing completes.

---

## 7. Audit Everything That Matters

Append-only audit logs for authentication events, financial operations, administrative
actions, and impersonation. Each entry includes: `actor_id`, `action`, `target_type`,
`target_id`, `timestamp`, `old_state`, `new_state`. Never update or delete audit rows.

---

## 8. Conventional Commits

```
<type>(<scope>): <summary>

Co-Authored-By: Claude <model> <noreply@anthropic.com>
```

Types: `feat`, `fix`, `chore`, `docs`, `refactor`, `test`, `ci`, `security`

---

## 9. Test Isolation

- **Deterministic IDs**: Fixed UUIDs in fixtures, never random
- **Fixed timestamps**: Never `time.Now()` or `datetime.now()` in assertions
- **Transaction rollback**: Each test rolls back, no data leaks
- **Mock external services**: No live API calls in unit tests
- **Parallel safe**: All unit tests must run concurrently

---

## 10. Document the WHY, Not the WHAT

Code shows what happens. Comments explain why. ADRs for architecture decisions.
Inline comments only for non-obvious business rules.

---

## 11. Validate at the Boundary, Trust Internally

Validate all external input at the service boundary (handlers, interceptors, API
gateway). Internal function calls between packages trust their callers.

---

## 12. Structured Logging, Never print()

All logging uses structured JSON output with correlation IDs.
Never log PII (emails only in auth context at INFO level).
Every log entry includes: `service`, `method`, `tenant_id`, `request_id`, `level`.

---

## 13. Observability Is a First-Class Concern

Every service exposes:
- `/healthz` — liveness
- `/readyz` — readiness (dependencies connected)
- `/metrics` — Prometheus metrics

Request duration, error rate, and cache hit ratio must be measurable from day one.

---

## 14. Consistent Project Structure

Every service follows a consistent file layout within its language ecosystem.
When adding a new service, replicate the existing pattern exactly.

---

## 15. Separate Documentation Repository

Architecture docs, API specs, ADRs, and service docs live in a dedicated docs repo.
Application code lives in its own repo. Cross-reference with links.

---

## 16. Guard Against Documentation Drift

When modifying structs, function signatures, or service methods, check whether the
change is reflected in documentation. CI validates that exported identifiers
referenced inside ` ```go ` blocks in the docs repo still exist in the application
source — enforced by `tools/check-doc-drift` on every PR in both repos.

To mark a code block as intentional pseudocode (exempt from the check), place
`<!-- drift:ignore -->` on the line immediately before the opening fence.

---

## 17. Standard Architecture Diagrams

Every project with 2+ services or significant backend complexity must maintain
these 11 architecture diagrams in the docs repo. The canonical location is
`docs/architecture/`, though a project may nest it under an audience-scoped
path (e.g., Thittam uses `docs/developers/architecture/`); the set of
diagrams and the discipline are what matters, not the exact parent path.

| # | Diagram | What It Shows | Audience |
|---|---|---|---|
| 1 | **System Design** | High-level services, databases, message brokers, gateways | Everyone |
| 2 | **Package/Component** | Shared packages/modules, usage matrix, interceptor/middleware chain | Developers |
| 3 | **Service Dependencies** | Sync (gRPC/HTTP) and async (events) calls between services with SLAs | Developers, SRE |
| 4 | **Deployment** | K8s namespaces, pods, replicas, HPA, resources, PVCs, env progression | DevOps, SRE |
| 5 | **Network & Security** | Security zones, TLS termination, network policies, RBAC layers, SOC-2 mapping | Security, Compliance |
| 6 | **Database ER** | All tables, foreign keys, tenant isolation, design decisions | Developers, DBA |
| 7 | **Sequence Diagrams** | Key business flows end-to-end (3-5 critical paths) | Developers, Product |
| 8 | **Logical/Domain (DDD)** | Bounded contexts, aggregates, context map, domain events | Architects, Developers |
| 9 | **CI/CD Pipeline** | Build stages, quality gates, deployment strategy, rollback | DevOps, Developers |
| 10 | **Event Schemas** | Event catalogue, envelope format, delivery guarantees, DLQ | Developers, SRE |
| 11 | **API/Proto Index** | Endpoint inventory, RPC counts, proto-to-service mapping | Developers, API consumers |

**When to create:** Diagrams 1-3 at project inception. Diagrams 4-6 before first
deployment. Diagrams 7-11 before first production release.

**When to update:** Any diagram affected by a code change must be updated in the
same PR. Use the documentation drift check (Rule #16) to enforce this.

**Format:** Mermaid in Markdown code fences is the default — GitHub renders it
natively, it stays text-diffable, and no plugins are required. ASCII art remains
permitted for simple box-and-line diagrams where Mermaid adds no clarity.
System-level diagrams (context / container / component) should follow the C4
model structure as a recommendation. See
[`thittam_docs` ADR-017](https://github.com/wegofwd2020-hub/thittam_docs/blob/main/docs/developers/adr/ADR-017-mermaid-architecture-diagrams.md)
for rationale.

---

## 18. Typography & Accessibility Standards

Every project with a web frontend must implement this 3-font typography system
plus dyslexia-friendly accessibility mode.

### Font Stack (all SIL Open Font License — free, no restrictions)

| Usage | Font | CSS Variable | Apply To |
|---|---|---|---|
| **Headings & labels** | Inter (sans-serif) | `--font-heading` | h1-h6, labels, buttons, nav, sidebar |
| **Body text & messages** | Merriweather (serif) | `--font-body` | Paragraphs, descriptions, tooltips, form inputs |
| **Numbers & codes** | JetBrains Mono (monospace) | `--font-mono` | Amounts, dates, IDs, account codes, table numbers |

### Rules

- **Never hardcode font families in components.** All fonts flow through CSS variables.
- **Monetary values use `font-mono` with `tabular-nums`** for decimal alignment.
- **Self-host fonts** via `next/font` or `@fontsource` — no external CDN calls.
- **Form labels use heading font**, form input text uses body font.
- **Table headers use heading font**, numeric cells use mono font.

### Dyslexia Accessibility Mode

Every project must support an **OpenDyslexic** toggle (SIL OFL, free):

- When enabled, all 3 font families switch to OpenDyslexic / OpenDyslexic Mono.
- Increase letter-spacing (+0.05em), line-height (1.8), word-spacing (+0.1em).
- Persisted in user preferences (localStorage + API backup).
- Accessible from: Settings page + topbar accessibility menu + keyboard shortcut.

### Per-Vertical Icon Sets

Projects using the vertical plugin pattern must group icons by project type:

- Each vertical gets its own curated icon subset (8-12 industry-relevant icons).
- Shared icons (dashboard, wallet, settings, etc.) are common across all verticals.
- Icon names stored in the vertical theme config, resolved to components at runtime.
- Use a single icon library (lucide-react preferred) — no mixing icon libraries.

---

## 19. US English Everywhere

All text the team writes defaults to **US English** spelling. This
applies uniformly to code identifiers we create, comments, commit
messages, documentation, log and error messages, and user-facing UI
copy.

**Common examples:**

| Use | Not |
|---|---|
| `color` | `colour` |
| `initialize` | `initialise` |
| `organization` | `organisation` |
| `behavior` | `behaviour` |
| `authorize`, `authorization` | `authorise`, `authorisation` |
| `analyze`, `analyzer` | `analyse`, `analyser` |
| `license` (noun and verb) | `licence` |
| `catalog` | `catalogue` |
| `industrialized` | `industrialised` |

### Exceptions — do not "fix" these

These are the cases that would otherwise produce false positives on
variable or field names, and are explicitly out of scope:

- **Third-party identifiers.** Library names, package imports, API
  response fields, framework-mandated names. If an upstream SDK
  exposes `authoriseRequest`, our code keeps `authoriseRequest`.
- **Shipped identifiers.** Existing DB columns, protobuf field names,
  public API fields, event-schema keys. Renaming is a breaking
  change — leave them as-is; apply US English only to *new*
  additions alongside.
- **Proper nouns.** Company names, person names, product names, place
  names. "Harbour Brewing Co." stays.
- **Direct quotes.** Quoted speech, quoted regulation, quoted
  customer or partner copy preserves the source spelling.
- **Localized content.** Tamil script, translation bundles,
  locale-specific message files (`messages_en_GB.properties` etc.).

### Why US English

Picking one dictionary removes mixed-spelling churn (e.g. `color` and
`colour` in the same file), makes `grep` predictable, and gives docs
a single voice. US English matches the dialect of most frameworks,
open-source tooling, and cloud-provider documentation we depend on —
less friction at every integration boundary.

### Enforcement

Convention-only for now — caught in code review. If drift recurs,
add a CI spellchecker (`cspell` for code, `markdownlint` /
`aspell` for docs) with a project-local exceptions dictionary for
the unavoidable third-party terms.

---

## 20. Bind-Mount Source Into Dev Containers — Never `docker cp`

Operator scripts (seeders, batch jobs, eval runners, ad-hoc CLIs) must
read source from a read-only bind mount, not from a `docker cp` step
into the container.

**Wrong:**
```bash
docker cp scripts/* my-worker:/tmp/seed/
docker compose exec my-worker python /tmp/seed/seed.py
```

**Right:**
```yaml
# docker-compose.yml
services:
  my-worker:
    volumes:
      - ./scripts:/app/scripts-repo:ro
      - ./sample_content:/app/sample_content:ro
```
```bash
docker compose exec -T my-worker python /app/scripts-repo/seed.py
```

**Why.** `docker cp` is invisible state — the container holds whatever
was copied into it, not what's on disk. Subsequent runs forget what's
been copied; stale files accumulate; reproducing a bug from someone
else's terminal becomes guesswork. A read-only bind mount is
self-healing: every run sees the current source, no copy step, no
forgotten state. If the script needs writable scratch space, mount a
named volume for that — never the source dir.

**Exception.** Production images bake source at build time (correct).
This rule covers *dev/test/CI containers* that exist to run operator
scripts against the live source tree.

---

## 21. Migration Safety — Round-Trip on a Fresh DB Before Commit

Every database migration (Alembic, sqlc/golang-migrate, raw SQL) must
be tested with a full `downgrade → upgrade` cycle against a fresh
database before it lands on `main`.

Iterative drafts of a single migration are the high-risk case. While
the migration is being shaped, intermediate states — RLS policies,
ENUMs, CHECK constraints, indexes, materialized views — can be
created on the dev DB and never get cleaned up by the shipped
migration. Production replay then succeeds, but the table is in a
state the shipped migration never modelled.

**Required check before commit:**
```bash
# Python / Alembic
alembic downgrade -1 && alembic upgrade head

# Go / golang-migrate
migrate -path db/migrations -database $DSN down 1 && \
  migrate -path db/migrations -database $DSN up
```

If the migration involves RLS, run the round-trip against a database
that already has rows in the affected table — empty-table migrations
hide policy-ordering bugs.

**Why.** Bugs caught here: orphan RLS policies on the wrong table,
ENUM values that won't drop because columns still reference them,
CHECK constraints leftover from a draft schema, materialized views
holding indexes the new schema renamed. The canonical example is
StudyBuddy migration 0046 (Epic 10 L-1): a debug draft enabled RLS
on `curriculum_units` and `content_subject_versions` before being
rewritten to `curricula`-only; the shipped migration didn't drop the
orphans, requiring hotfix 0048.
