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
