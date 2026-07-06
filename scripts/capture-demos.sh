#!/usr/bin/env bash
#
# Capture README demo screenshots from the running SwiftUI views.
#
# Renders AppView in a few representative states (see
# engineering/apps/macos/Tests/DemoCaptureTests) and copies the resulting PNGs
# into docs/demos/, where the README's Demo section references them.
#
# Requires macOS + the Swift toolchain. The capture tests are gated by
# CAPTURE_DEMOS=1, so a normal `swift test` / CI never runs them.
#
# Usage:  ./scripts/capture-demos.sh

set -uo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
APP="$ROOT/engineering/apps/macos"
OUT="$ROOT/docs/demos"
KEYS=(annotate shepherd-review)

mkdir -p "$OUT"

echo "→ Recording demo snapshots (CAPTURE_DEMOS=1)…"
# The capture tests record in `record: .all` mode, which SnapshotTesting reports
# as a test "failure" (it wrote a new reference rather than matching one). That
# is expected here — we harvest the PNGs regardless of the test exit status.
( cd "$APP" && CAPTURE_DEMOS=1 swift test --filter DemoCapture 2>&1 ) | tail -20 || true

SNAP_DIR="$APP/Tests/DemoCaptureTests/__Snapshots__"
if [ ! -d "$SNAP_DIR" ]; then
  echo "✗ No snapshots were produced ($SNAP_DIR missing)."
  echo "  Check the capture test output above — the off-screen code viewer can"
  echo "  need a size tweak in DemoCaptureTests.swift."
  exit 1
fi

echo "→ Copying into docs/demos/…"
copied=0
for key in "${KEYS[@]}"; do
  # Match the recorded PNG whose filename contains this demo key, regardless of
  # SnapshotTesting's exact <testName>.<named> convention.
  src="$(find "$SNAP_DIR" -type f -name "*.png" | grep -iE "/[^/]*${key}[^/]*\.png$" | head -1)"
  if [ -n "$src" ]; then
    cp "$src" "$OUT/$key.png"
    echo "  ✓ docs/demos/$key.png"
    copied=$((copied + 1))
  else
    echo "  ⚠ no snapshot found for '$key'"
  fi
done

echo ""
if [ "$copied" -gt 0 ]; then
  echo "Done — $copied screenshot(s) in docs/demos/."
  echo "Next: review them, uncomment the image block in README.md's Demo section, and commit."
else
  echo "No screenshots copied — inspect $SNAP_DIR and the test output above."
  exit 1
fi
