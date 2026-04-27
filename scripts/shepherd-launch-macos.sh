#!/usr/bin/env bash
#
# Launches the macOS Code Review Prompt Generator (CRPG) for one or more files.
# Validates each file, writes a session.json staging file, then opens the
# prebuilt ShepherdApp binary with --session <id>.
#
# Usage: shepherd-launch-macos.sh <filepath> [filepath...]
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
while [ $# -gt 0 ]; do
  case "$1" in
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
  echo "Usage: shepherd-launch-macos.sh [--context <file>] <filepath> [filepath...]" >&2
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
    printf '      "content": %s\n' "$(cat "$vpath" | json_escape)"
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

# --- Launch the binary detached ---

# nohup + & so the GUI process outlives this script.
nohup "$BINARY" --session "$SESSION_ID" >/dev/null 2>&1 &
disown || true

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
