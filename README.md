# WeGoFwd2020 — Shared Coding Standards

Universal coding rules that apply to all WeGoFwd2020 projects via Claude Code's
global `~/.claude/CLAUDE.md` configuration.

## What's Inside

| File | Scope | Content |
|---|---|---|
| `CODING_RULES.md` | All projects | 21 universal rules (money, caching, idempotency, testing, US English, bind-mounts, migration safety, etc.) |
| `go-conventions.md` | Go projects | Service structure, error handling, decimal types, testing patterns |
| `python-conventions.md` | Python projects | FastAPI patterns, Pydantic, structlog, Celery, pytest |
| `setup.sh` | One-time setup | Links this repo to `~/.claude/` for automatic loading |

## Setup (per machine)

```bash
# 1. Clone this repo
git clone https://github.com/wegofwd2020-hub/coding-standards ~/coding-standards

# 2. Run setup
cd ~/coding-standards && ./setup.sh
```

That's it. Every Claude Code session on this machine will now load these rules.

## Updating Rules

```bash
cd ~/coding-standards
# Edit any .md file
git add -A && git commit -m "docs: update rule #3 — cache TTL guidance"
git push
```

On other machines, just `git pull` in `~/coding-standards/` to get the latest.

## How It Works

`setup.sh` creates `~/.claude/CLAUDE.md` which uses Claude Code's `@path` import
syntax to reference files in this repo:

```markdown
See @~/coding-standards/CODING_RULES.md for universal coding rules.
See @~/coding-standards/go-conventions.md for Go-specific conventions.
```

Claude Code loads `~/.claude/CLAUDE.md` at the start of every session, before any
project-specific CLAUDE.md files. The `@path` imports are expanded inline.

## Projects Using These Rules

- [Thittam](https://github.com/wegofwd2020-hub/thittam) — Multi-tenant production management SaaS (Go)
- [Thittam Docs](https://github.com/wegofwd2020-hub/thittam_docs) — Thittam documentation
- [StudyBuddy OnDemand](https://github.com/wegofwd2020-hub/StudyBuddy_OnDemand) — K-12 education platform (Python/FastAPI)
- [StudyBuddy Docs](https://github.com/wegofwd2020-hub/studybuddy-docs) — StudyBuddy documentation
