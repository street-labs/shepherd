#!/usr/bin/env bash
#
# Run unit and integration tests for the web app.
# Used by the pre-commit hook and available for manual use.
#
# Exit codes:
#   0 — all tests pass
#   1 — one or more tests failed

set -euo pipefail

ROOT="$(git rev-parse --show-toplevel 2>/dev/null || dirname "$(dirname "$0")")"
WEB_APP="$ROOT/engineering/apps/web"

if [ ! -d "$WEB_APP" ]; then
  echo "Web app directory not found at $WEB_APP"
  exit 1
fi

echo "Running unit and integration tests..."
echo ""

cd "$WEB_APP"
npm run test
