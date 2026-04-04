#!/usr/bin/env bash
# setup.sh — Links coding-standards to ~/.claude/ for global Claude Code access.
# Run this once on each machine after cloning the repo.
#
# Usage:
#   git clone https://github.com/wegofwd2020-hub/coding-standards ~/coding-standards
#   cd ~/coding-standards && ./setup.sh

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CLAUDE_DIR="$HOME/.claude"

echo "=== WeGoFwd2020 Coding Standards Setup ==="
echo ""
echo "Source:  $SCRIPT_DIR"
echo "Target:  $CLAUDE_DIR"
echo ""

# Ensure ~/.claude/ exists
mkdir -p "$CLAUDE_DIR/rules"

# Create global CLAUDE.md that imports the coding rules
cat > "$CLAUDE_DIR/CLAUDE.md" << EOF
# WeGoFwd2020 — Global Coding Standards

These rules apply to all projects. They are imported from ~/coding-standards/
which is a version-controlled repository.

See @~/coding-standards/CODING_RULES.md for universal coding rules.
See @~/coding-standards/go-conventions.md for Go-specific conventions.
See @~/coding-standards/python-conventions.md for Python-specific conventions.
EOF

echo "✓ Created $CLAUDE_DIR/CLAUDE.md (imports from ~/coding-standards/)"

# Symlink rules directory for path-scoped rules
if [ -L "$CLAUDE_DIR/rules/coding-standards" ]; then
    rm "$CLAUDE_DIR/rules/coding-standards"
fi
ln -sf "$SCRIPT_DIR" "$CLAUDE_DIR/rules/coding-standards"

echo "✓ Symlinked $CLAUDE_DIR/rules/coding-standards → $SCRIPT_DIR"

echo ""
echo "=== Setup Complete ==="
echo ""
echo "Your coding rules will now apply to ALL Claude Code sessions."
echo "To update rules: edit files in ~/coding-standards/ and git push."
echo "To apply on a new machine: git clone + ./setup.sh"
