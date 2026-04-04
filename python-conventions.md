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
- 70% minimum coverage enforced in CI
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
