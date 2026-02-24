#!/usr/bin/env bash
# Implements: FR-sc-launch, FR-sc-validate, FR-sc-server, FR-sc-browser
#
# Launches the Code Review Prompt Generator (CRPG) for one or more files.
# Validates each file, ensures the Vite dev server is running, and opens
# the browser with the file paths as query parameters.
#
# Usage: shepherd-launch.sh [--fresh] <filepath> [filepath...]
# Exit codes: 0 success, 1 validation error, 2 server startup failure

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
WEB_DIR="$REPO_ROOT/engineering/apps/web"

# --- Session ID derivation ---

PROJECT_DIR=$(git rev-parse --show-toplevel 2>/dev/null || pwd)
SESSION_ID=$(basename "$PROJECT_DIR" | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9-]/-/g; s/--*/-/g; s/^-//; s/-$//')

# --- Lock file infrastructure ---

SHEPHERD_DIR="$HOME/.shepherd"
SERVERS_DIR="$SHEPHERD_DIR/servers"
mkdir -p "$SERVERS_DIR"
PROJECT_HASH=$(printf '%s' "$PROJECT_DIR" | shasum -a 256 | head -c 16)
LOCK_FILE="$SERVERS_DIR/$PROJECT_HASH.lock"

# --- Parse flags ---

FRESH=false
POSITIONAL=()

while [ $# -gt 0 ]; do
  case "$1" in
    --fresh) FRESH=true; shift ;;
    *) POSITIONAL+=("$1"); shift ;;
  esac
done

set -- "${POSITIONAL[@]+"${POSITIONAL[@]}"}"

if [ $# -eq 0 ] || [ -z "${1:-}" ]; then
  echo "Usage: shepherd-launch.sh [--fresh] <filepath> [filepath...]" >&2
  exit 1
fi

# --- Resolve path helper ---

resolve_path() {
  if command -v realpath &>/dev/null; then
    realpath "$1" 2>/dev/null && return 0
  fi
  # Fallback for older macOS without realpath, or if realpath failed
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

  # Binary detection: check for null bytes in first 8192 bytes
  # LC_ALL=C avoids "Illegal byte sequence" errors on macOS with non-UTF8 data
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

# --- Check / start dev server ---

PORT=""

check_server() {
  # Read port and PID from lock file; verify the process is alive and the server responds
  if [ ! -f "$LOCK_FILE" ]; then
    return 1
  fi
  local lock_port lock_pid
  lock_port=$(sed -n '1p' "$LOCK_FILE")
  lock_pid=$(sed -n '2p' "$LOCK_FILE")
  if [ -z "$lock_port" ] || [ -z "$lock_pid" ]; then
    rm -f "$LOCK_FILE"
    return 1
  fi
  # Check if the PID is still alive
  if ! kill -0 "$lock_pid" 2>/dev/null; then
    rm -f "$LOCK_FILE"
    return 1
  fi
  # Verify HTTP response
  local code
  code=$(curl -s -o /dev/null -w '%{http_code}' --connect-timeout 1 "http://localhost:$lock_port" 2>/dev/null) || true
  if [ "$code" = "200" ]; then
    PORT="$lock_port"
    return 0
  fi
  return 1
}

kill_server() {
  if [ ! -f "$LOCK_FILE" ]; then
    return
  fi
  local lock_pid
  lock_pid=$(sed -n '2p' "$LOCK_FILE")
  if [ -n "$lock_pid" ]; then
    kill "$lock_pid" 2>/dev/null || true
    # Wait briefly for process to exit
    local i=0
    while [ $i -lt 10 ] && kill -0 "$lock_pid" 2>/dev/null; do
      sleep 0.2
      i=$((i+1))
    done
  fi
  rm -f "$LOCK_FILE"
}

SERVER_REUSED=false

# --fresh: kill existing server so a new one starts with latest code
if [ "$FRESH" = true ] && check_server; then
  kill_server
fi

if check_server; then
  SERVER_REUSED=true
else
  if [ ! -d "$WEB_DIR" ]; then
    echo "Error: web app directory not found: $WEB_DIR" >&2
    exit 2
  fi

  # Auto-install dependencies if missing
  if [ ! -d "$WEB_DIR/node_modules" ]; then
    echo "Installing dependencies (first run)..." >&2
    if ! (cd "$WEB_DIR" && pnpm install 2>&1) >&2; then
      echo "Error: failed to install dependencies. Run 'pnpm install' in $WEB_DIR manually." >&2
      exit 2
    fi
  fi

  # Find a free port
  PORT=$(python3 -c "import socket; s=socket.socket(); s.bind(('',0)); print(s.getsockname()[1]); s.close()")

  # Start dev server in background, capturing stderr for diagnostics
  SERVER_LOG=$(mktemp)
  (cd "$WEB_DIR" && pnpm dev --port "$PORT" 2>"$SERVER_LOG" &)
  SERVER_PID=$!

  # Write lock file: port on line 1, PID on line 2
  printf '%s\n%s\n' "$PORT" "$SERVER_PID" > "$LOCK_FILE"

  # Poll for up to 8 seconds (16 attempts at 0.5s)
  ATTEMPTS=0
  MAX_ATTEMPTS=16
  while [ $ATTEMPTS -lt $MAX_ATTEMPTS ]; do
    sleep 0.5
    local_code=$(curl -s -o /dev/null -w '%{http_code}' --connect-timeout 1 "http://localhost:$PORT" 2>/dev/null) || true
    if [ "$local_code" = "200" ]; then
      break
    fi
    ATTEMPTS=$((ATTEMPTS + 1))
  done

  if [ $ATTEMPTS -eq $MAX_ATTEMPTS ]; then
    echo "Error: dev server failed to start within 8 seconds" >&2
    if [ -s "$SERVER_LOG" ]; then
      echo "Server output:" >&2
      cat "$SERVER_LOG" >&2
    fi
    rm -f "$SERVER_LOG" "$LOCK_FILE"
    exit 2
  fi
  rm -f "$SERVER_LOG"
fi

SERVER_URL="http://localhost:$PORT"

# --- URL-encode helper ---

url_encode() {
  local string="$1"
  local length=${#string}
  local i c o
  for (( i = 0; i < length; i++ )); do
    c="${string:$i:1}"
    case "$c" in
      [A-Za-z0-9._~/-]) o="$c" ;;
      *) o=$(printf '%%%02X' "'$c") ;;
    esac
    printf '%s' "$o"
  done
}

# --- Build URL with session and file params ---

QUERY="session=$(url_encode "$SESSION_ID")"
for vpath in "${VALID_PATHS[@]}"; do
  encoded="$(url_encode "$vpath")"
  QUERY="${QUERY}&file=${encoded}"
done

OPEN_URL="${SERVER_URL}?${QUERY}"

# --- Open browser (prefer new window) ---

open_mac_browser() {
  local url="$1"
  # Detect the default browser's bundle ID from Launch Services
  local bid
  bid=$(defaults read com.apple.LaunchServices/com.apple.launchservices.secure LSHandlers 2>/dev/null \
    | grep -B1 'LSHandlerURLScheme.*http' \
    | head -1 \
    | sed 's/.*"\(.*\)".*/\1/' \
    | tr -d '[:space:]') || true

  # Use AppleScript to open a new window — `open --args` is silently ignored
  # when the browser is already running, so we must script it directly.
  case "$bid" in
    com.google.chrome*)
      osascript <<APPLESCRIPT 2>/dev/null && return
tell application "Google Chrome"
    make new window
    set URL of active tab of front window to "$url"
    activate
end tell
APPLESCRIPT
      ;;
    com.brave.browser*)
      osascript <<APPLESCRIPT 2>/dev/null && return
tell application "Brave Browser"
    make new window
    set URL of active tab of front window to "$url"
    activate
end tell
APPLESCRIPT
      ;;
    com.microsoft.edgemac*)
      osascript <<APPLESCRIPT 2>/dev/null && return
tell application "Microsoft Edge"
    make new window
    set URL of active tab of front window to "$url"
    activate
end tell
APPLESCRIPT
      ;;
    com.apple.Safari*)
      osascript <<APPLESCRIPT 2>/dev/null && return
tell application "Safari"
    make new document with properties {URL:"$url"}
    activate
end tell
APPLESCRIPT
      ;;
  esac

  # Fallback: default open behavior
  open "$url"
}

case "$(uname -s)" in
  Darwin)  open_mac_browser "$OPEN_URL" ;;
  Linux)   xdg-open "$OPEN_URL" ;;
  MINGW*|MSYS*|CYGWIN*)  cmd.exe /c start "" "$OPEN_URL" ;;
  *)
    echo "Warning: unknown platform, cannot open browser automatically" >&2
    echo "Open manually: $OPEN_URL" >&2
    ;;
esac

# --- Print summary ---

REUSE_LABEL=""
if [ "$SERVER_REUSED" = true ]; then
  REUSE_LABEL=" (reusing server)"
fi

echo "Session: $SESSION_ID"

FILE_COUNT=${#VALID_PATHS[@]}
if [ "$FILE_COUNT" -eq 1 ]; then
  # Single file: backward-compatible summary with name and line count
  FILENAME="$(basename "${VALID_PATHS[0]}")"
  LINE_COUNT=$(wc -l < "${VALID_PATHS[0]}" | tr -d ' ')
  if [ "$LINE_COUNT" -gt 10000 ]; then
    echo "Warning: $FILENAME has $LINE_COUNT lines — large files may be slow to review" >&2
  fi
  echo "Opened CRPG at $SERVER_URL — loaded $FILENAME ($LINE_COUNT lines)$REUSE_LABEL"
else
  echo "Opened CRPG at $SERVER_URL — loaded $FILE_COUNT files$REUSE_LABEL"
fi
