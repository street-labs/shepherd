#!/usr/bin/env bash
#
# Run the test suite for the macOS app.
# Available for manual use and via `just test`.
#
# Exit codes:
#   0 — all tests pass (or Swift toolchain unavailable — skipped)
#   1 — one or more tests failed

set -euo pipefail

ROOT="$(git rev-parse --show-toplevel 2>/dev/null || dirname "$(dirname "$0")")"
MAC_APP="$ROOT/engineering/apps/macos"

if [ ! -d "$MAC_APP" ]; then
  echo "macOS app directory not found at $MAC_APP"
  exit 1
fi

if ! command -v swift >/dev/null 2>&1; then
  echo "Swift toolchain not found on PATH — skipping macOS tests."
  exit 0
fi

echo "Running macOS app tests (swift test)..."
echo ""

cd "$MAC_APP"
swift test
