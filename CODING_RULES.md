# Coding Rules — WeGoFwd2020

> Universal coding standards that apply to **all** WeGoFwd2020 projects.
> These are loaded into Claude Code via `~/.claude/CLAUDE.md` and apply
> automatically regardless of which project you're working in.
>
> Last updated: 2026-04-04

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

## 2. Secrets From Environment Only

All secrets come from environment variables. No hardcoded defaults. Fail fast at
startup if a required secret is missing. Never log secrets, tokens, passwords, or
API keys.

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
change is reflected in documentation. CI should validate that key identifiers
mentioned in docs still exist in code.

---

## 17. Standard Architecture Diagrams

Every project with 2+ services or significant backend complexity must maintain
these 11 architecture diagrams in the docs repo under `docs/architecture/`:

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

**Format:** ASCII art in markdown (no external diagram tools required). This ensures
diagrams are version-controlled, diffable, and renderable without plugins.

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
