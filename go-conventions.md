# Go Conventions — WeGoFwd2020

> Go-specific coding standards. Supplements the universal CODING_RULES.md.

---

## Service Structure

```
services/<name>/
  models.go        ← Domain types (structs with json tags)
  errors.go        ← Sentinel errors (var Err... = errors.New("pkg: message"))
  repository.go    ← Repository interface (data access contract)
  service.go       ← Business logic (vertical config via context)
  service_test.go  ← Unit tests (mock repo + injected config)
  handler.go       ← gRPC handler (wraps service)
```

## Error Handling

- Sentinel errors with package prefix: `var ErrNotFound = errors.New("budget: not found")`
- Wrap at package boundaries: `fmt.Errorf("approve expense %s: %w", id, err)`
- Check with `errors.Is()` / `errors.As()`, never `==`
- Log once at the handler, not at every layer
- Never expose internal details in gRPC `INTERNAL` status messages

## Monetary Values

- Always `github.com/shopspring/decimal` — never `float64`
- Database: `NUMERIC(14,2)`
- JSON: string with 2 decimal places

## Testing

- Table-driven tests with `t.Parallel()`
- Hand-written mocks (function field pattern), not testify/mock
- `vertical.WithConfig(ctx, fixture)` for vertical-aware tests
- Deterministic UUIDs: `uuid.MustParse("d1000000-...")`
- `testify/assert` + `testify/require`

## Dependencies

- UUID: `github.com/google/uuid`
- Decimal: `github.com/shopspring/decimal`
- gRPC: `google.golang.org/grpc`
- Redis: `github.com/redis/go-redis/v9`
- Testing: `github.com/stretchr/testify`
- YAML: `gopkg.in/yaml.v3`

## SQL

- All queries parameterized via sqlc or pgx named params
- No string interpolation in SQL — ever
- `ON CONFLICT` for idempotent writes
- `NUMERIC(14,2)` for money, `UUID` for IDs, `TIMESTAMPTZ` for times
