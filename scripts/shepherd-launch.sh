#!/usr/bin/env bash
#
# Launches the macOS Code Review Prompt Generator (CRPG) for one or more files.
# Validates each file, writes a session.json staging file, then opens the
# prebuilt ShepherdApp binary with --session <id>.
#
# Usage: shepherd-launch.sh [--diff <git-diff-args>] [--context <file>] <filepath> [filepath...]
#
# With --diff, each file is staged as a unified diff instead of its whole content,
# so the reviewer sees what changed. The argument is whatever goes between
# `git diff` and `-- <path>` for the review's scope, and may be empty:
#   --diff HEAD          working tree vs the last commit
#   --diff ""            unstaged changes only
#   --diff --cached      staged changes only
#   --diff "main...HEAD" the current branch's commits
#   --diff "abc123^ abc123"  a single commit
# Untracked files render as all-added; a file with no change against the base falls
# back to its full content.
# Exit codes: 0 success, 1 validation error, 2 launch failure (binary missing, etc.)

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
MAC_APP_DIR="$REPO_ROOT/engineering/apps/macos"
BINARY="$MAC_APP_DIR/.build/release/ShepherdApp"

# --- Session ID derivation (matches shepherd-launch.sh) ---

PROJECT_DIR=$(git rev-parse --show-toplevel 2>/dev/null || pwd)
SESSION_ID=$(basename "$PROJECT_DIR" | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9-]/-/g; s/--*/-/g; s/^-//; s/-$//')
PROJECT_NAME=$(basename "$PROJECT_DIR")

# --- Parse options ---
CONTEXT_FILE=""
DIFF_BASE=""
DIFF_MODE=0
while [ $# -gt 0 ]; do
  case "$1" in
    --diff)
      if [ $# -lt 2 ]; then
        echo "Error: --diff requires an argument (may be empty)" >&2
        exit 1
      fi
      DIFF_BASE="$2"
      DIFF_MODE=1
      shift 2
      ;;
    --context)
      if [ $# -lt 2 ]; then
        echo "Error: --context requires a file path argument" >&2
        exit 1
      fi
      CONTEXT_FILE="$2"
      shift 2
      ;;
    --) shift; break ;;
    -*)
      echo "Unknown option: $1" >&2
      exit 1
      ;;
    *) break ;;
  esac
done

if [ $# -eq 0 ] || [ -z "${1:-}" ]; then
  echo "Usage: shepherd-launch.sh [--diff <git-diff-args>] [--context <file>] <filepath> [filepath...]" >&2
  exit 1
fi

# --- Resolve path helper ---

# Implements: FR-sc-mac-launch, FR-sc-mac-session-handoff, FR-sc-mac-invoke-command
resolve_path() {
  if command -v realpath &>/dev/null; then
    realpath "$1" 2>/dev/null && return 0
  fi
  local dir base
  dir="$(cd "$(dirname "$1")" 2>/dev/null && pwd -P)" || return 1
  base="$(basename "$1")"
  echo "$dir/$base"
}

# --- Validate all files ---

VALID_PATHS=()

for arg in "$@"; do
  filepath="$(resolve_path "$arg" 2>/dev/null)" || {
    echo "Warning: skipping — file not found: $arg" >&2
    continue
  }

  if [ ! -e "$filepath" ]; then
    echo "Warning: skipping — file not found: $arg" >&2
    continue
  fi

  if [ -d "$filepath" ]; then
    echo "Warning: skipping — path is a directory: $arg" >&2
    continue
  fi

  if [ ! -r "$filepath" ]; then
    echo "Warning: skipping — file is not readable: $arg" >&2
    continue
  fi

  NULL_COUNT=$(LC_ALL=C head -c 8192 "$filepath" | LC_ALL=C tr -cd '\0' | wc -c | tr -d ' ')
  if [ "$NULL_COUNT" -gt 0 ]; then
    echo "Warning: skipping — file appears to be binary: $arg" >&2
    continue
  fi

  VALID_PATHS+=("$filepath")
done

if [ ${#VALID_PATHS[@]} -eq 0 ]; then
  echo "Error: no valid files to open" >&2
  exit 1
fi

# --- Diff staging ---

# Emit the review content for one file: the unified diff for the review's scope
# when --diff is set, otherwise the file's whole content. $DIFF_BASE is expanded
# unquoted on purpose -- it carries the scope's `git diff` arguments, which may be
# a rev, a rev pair, a flag, or nothing at all. An untracked file has no base to
# diff against, so it is rendered all-added via `--no-index` against /dev/null. A
# tracked file that is unchanged against the base has an empty diff, which would
# open a blank tab -- fall back to its full content instead.
# Implements: FR-diff-baseline-ref, FR-diff-compute, FR-diff-empty-state
review_content() {
  local filepath="$1"
  if [ "$DIFF_MODE" -eq 0 ]; then
    cat "$filepath"
    return 0
  fi
  local out rel
  # Repo-relative so the diff headers read `a/src/foo.swift`, not an absolute path.
  rel="${filepath#$PROJECT_DIR/}"
  if git -C "$PROJECT_DIR" ls-files --error-unmatch -- "$rel" >/dev/null 2>&1; then
    # shellcheck disable=SC2086
    out=$(git -C "$PROJECT_DIR" diff --no-color $DIFF_BASE -- "$rel" 2>/dev/null || true)
  else
    # --no-index exits 1 when the inputs differ, which is the normal case here.
    out=$(git -C "$PROJECT_DIR" diff --no-color --no-index -- /dev/null "$rel" 2>/dev/null || true)
  fi
  if [ -z "$out" ]; then
    echo "Note: no changes in scope — showing full file: $(basename "$filepath")" >&2
    cat "$filepath"
    return 0
  fi
  printf '%s\n' "$out"
}

# --- Verify prebuilt binary ---

if [ ! -x "$BINARY" ]; then
  echo "Error: macOS app binary not found at $BINARY" >&2
  echo "Re-run ./scripts/install-command.sh from the Shepherd repo to build it." >&2
  exit 2
fi

# --- Build session.json ---

SESSION_DIR="$HOME/.shepherd/sessions/$SESSION_ID"
mkdir -p "$SESSION_DIR"
SESSION_FILE="$SESSION_DIR/session.json"

# JSON-escape a string read from stdin (escape \, ", control chars).
json_escape() {
  python3 -c 'import json,sys; sys.stdout.write(json.dumps(sys.stdin.read()))'
}

# Build files[] array
# Implements: FR-srm-multi-file-launch, FR-srm-context-handoff
{
  printf '{\n'
  printf '  "sessionID": %s,\n' "$(printf '%s' "$SESSION_ID" | json_escape)"
  printf '  "workingDirectory": %s,\n' "$(printf '%s' "$PROJECT_DIR" | json_escape)"
  printf '  "projectName": %s,\n' "$(printf '%s' "$PROJECT_NAME" | json_escape)"
  printf '  "files": ['
  first=1
  for vpath in "${VALID_PATHS[@]}"; do
    if [ $first -eq 0 ]; then
      printf ','
    fi
    first=0
    printf '\n    {\n'
    printf '      "path": %s,\n' "$(printf '%s' "$vpath" | json_escape)"
    printf '      "content": %s\n' "$(review_content "$vpath" | json_escape)"
    printf '    }'
  done
  printf '\n  ],\n'
  if [ -n "$CONTEXT_FILE" ]; then
    if [ -r "$CONTEXT_FILE" ]; then
      printf '  "reviewContext": '
      cat "$CONTEXT_FILE"
      printf '\n'
    else
      echo "Warning: --context file not readable: $CONTEXT_FILE — falling back to null" >&2
      printf '  "reviewContext": null\n'
    fi
  else
    printf '  "reviewContext": null\n'
  fi
  printf '}\n'
} > "$SESSION_FILE"

# --- Wrap the binary in a .app bundle and launch it ---
#
# A bare Mach-O SwiftUI executable does not reliably render its content on macOS:
# the window chrome (toolbar/title) draws but the SwiftUI body stays blank. Wrapping
# the binary in a minimal .app bundle and launching via `open -n` gives it full app
# treatment (proper activation + render-server connection), which renders reliably.
# The bundle is refreshed from the current binary on every launch.
# Implements: FR-sc-mac-launch, FR-sc-mac-session-handoff
APP_BUNDLE="$MAC_APP_DIR/.build/Shepherd.app"
mkdir -p "$APP_BUNDLE/Contents/MacOS"
# Unlink before copying: SwiftPM emits an ad-hoc linker-signed binary and macOS caches
# a code-signature blob per vnode. Overwriting the executable in place (cp -f truncates
# the same inode) leaves that blob stale, and the next `open` is SIGKILLed by AMFI with
# "Code Signature Invalid". A fresh inode per refresh avoids it.
rm -f "$APP_BUNDLE/Contents/MacOS/ShepherdApp"
cp "$BINARY" "$APP_BUNDLE/Contents/MacOS/ShepherdApp"
cat > "$APP_BUNDLE/Contents/Info.plist" <<'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>CFBundleExecutable</key><string>ShepherdApp</string>
  <key>CFBundleIdentifier</key><string>com.shepherd.app</string>
  <key>CFBundleName</key><string>Shepherd</string>
  <key>CFBundlePackageType</key><string>APPL</string>
  <key>CFBundleShortVersionString</key><string>1.0</string>
  <key>CFBundleVersion</key><string>1</string>
  <key>LSMinimumSystemVersion</key><string>14.0</string>
  <key>NSHighResolutionCapable</key><true/>
  <key>NSPrincipalClass</key><string>NSApplication</string>
  <key>CFBundleURLTypes</key>
  <array><dict>
    <key>CFBundleURLSchemes</key><array><string>shepherd</string></array>
    <key>CFBundleURLName</key><string>com.shepherd.app</string>
  </dict></array>
</dict>
</plist>
PLIST

# -n: new instance per launch (mirrors the previous detached-process behavior).
open -n "$APP_BUNDLE" --args --session "$SESSION_ID"

# --- Print summary (matches shepherd-launch.sh contract) ---

echo "Session: $SESSION_ID"

FILE_COUNT=${#VALID_PATHS[@]}
if [ "$FILE_COUNT" -eq 1 ]; then
  FILENAME="$(basename "${VALID_PATHS[0]}")"
  LINE_COUNT=$(wc -l < "${VALID_PATHS[0]}" | tr -d ' ')
  if [ "$LINE_COUNT" -gt 10000 ]; then
    echo "Warning: $FILENAME has $LINE_COUNT lines — large files may be slow to review" >&2
  fi
  echo "Opened macOS CRPG — loaded $FILENAME ($LINE_COUNT lines)"
else
  echo "Opened macOS CRPG — loaded $FILE_COUNT files"
fi
