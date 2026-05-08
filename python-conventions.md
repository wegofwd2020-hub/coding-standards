# Python Conventions — WeGoFwd2020

> Python-specific coding standards. Supplements the universal CODING_RULES.md.

---

## Architecture

- FastAPI with async handlers
- asyncpg for PostgreSQL (never synchronous psycopg2 in async code)
- Pydantic for validation and settings
- Celery + Redis for background tasks
- structlog for structured logging

## Module Structure

```
src/<domain>/
  router.py        ← FastAPI endpoints
  service.py       ← Business logic
  schemas.py       ← Pydantic models (request/response)
  tasks.py         ← Celery async tasks (optional)
```

## Error Handling

- Custom exception classes inheriting from a base `AppException`
- Global exception handlers returning consistent JSON envelopes
- Correlation ID middleware for end-to-end traceability
- Never leak internal errors to API responses

## Monetary Values

- `Decimal` from stdlib, never `float`
- Pydantic fields: `condecimal(max_digits=14, decimal_places=2)`
- Database: `NUMERIC(14,2)`

## Testing

- pytest with async support (pytest-asyncio)
- Transaction isolation per test (asyncpg rollback)
- fakeredis instead of real Redis
- Mock external services (Stripe, Auth0, Anthropic) at module level
- Per-module tiered coverage thresholds enforced via a check script
  (e.g., `scripts/check_coverage_thresholds.py`):
    - Critical modules (auth, payment, secrets): **90%**
    - Sensitive modules (content, billing, subscription): **85%**
    - Default: **80%**
  A blanket 70% line is acceptable for early-stage projects but should
  graduate to tiered thresholds before production.
- Helper functions for repetitive test data setup

## Code Quality

- Ruff for linting and formatting (line length: 100, double quotes)
- Bandit for security scanning
- Type hints on all function signatures
- No `print()` — use `structlog.get_logger()`

## Settings

- pydantic-settings with environment variables
- No defaults for secrets — fail fast at startup
- Separate JWT secrets for admin vs. regular users

## Database — RLS-aware connections

Any asyncpg connection that touches RLS-protected tables **outside an
authenticated request handler** must stamp the tenant identity
immediately after `pool.acquire()`. Authenticated handlers stamp the
real tenant via `set_config`; unauthenticated paths (CLI scripts,
Celery jobs, pipeline workers, login flow, super-admin tooling) use
the bypass sentinel.

```python
# Authenticated handler — stamp the real tenant
async with pool.acquire() as conn:
    await conn.execute(
        "SELECT set_config('app.current_school_id', $1, false)",
        request.state.school_id,
    )
    rows = await conn.fetch(...)

# Unauthenticated path — explicit bypass
async with pool.acquire() as conn:
    await conn.execute(
        "SELECT set_config('app.current_school_id', 'bypass', false)"
    )
    rows = await conn.fetch(...)
```

Failing to stamp before a SELECT returns **zero rows silently** —
PostgreSQL does not error on RLS-hidden rows. Symptoms: empty admin
lists, login failing with "user not found" for known-good emails,
pipeline writing to the content store but no DB rows appearing.

When auditing existing code, grep for raw `pool.acquire()` and
`pool.fetchrow(` / `pool.fetch(` calls — those are the bug-prone
sites. The fix is always the same: acquire a connection explicitly,
`set_config` first, then query.

## FastAPI dependencies — never default an `Annotated[..., Depends(...)]` parameter

```python
# WRONG — FastAPI silently treats `student` as a query parameter; calls
# without `?student=...` fail with 422 Validation.
async def get_grade(
    student: Annotated[dict | None, Depends(get_current_student_optional)] = None,
):
    ...

# RIGHT — bare default with Depends() works as expected
async def get_grade(
    student: dict | None = Depends(get_current_student_optional),
):
    ...
```

Both forms parse without error at import time, but the
Annotated-with-default form is treated as a query parameter — there
is no warning, no log, just a 422 when the (non-existent) query
parameter is missing. Use the bare-default form for any optional
dependency. The Annotated form is fine for *required* dependencies
(no default value).
