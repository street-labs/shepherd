#!/usr/bin/env bash
#
# Validates that demo screenshot tests still pass.
# Re-captures screenshots and stages any that changed.
#
# Called by:
#   - Pre-commit hook (when relevant files are staged)
#   - /readme slash command
#
# Exits 0 on success, 1 if tests fail.

set -uo pipefail

ROOT="$(git rev-parse --show-toplevel 2>/dev/null || dirname "$(dirname "$0")")"
WEB_APP="$ROOT/engineering/apps/web"

echo "Running demo screenshot tests..."
cd "$WEB_APP"
if ! npx playwright test --config "$ROOT/scripts/capture-demos.config.ts" 2>&1; then
  echo ""
  echo "✗ Demo screenshot tests failed. Fix the tests in scripts/capture-demos.ts"
  exit 1
fi

# Stage any screenshots that changed
changed_screenshots=$(git diff --name-only -- "$ROOT/docs/demos/" 2>/dev/null || true)
if [ -n "$changed_screenshots" ]; then
  echo "Screenshots updated:"
  echo "$changed_screenshots" | sed 's/^/  /'
  git add "$ROOT/docs/demos/"*.png
fi

echo "Demo screenshots OK."
