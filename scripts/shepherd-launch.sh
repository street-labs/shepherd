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
SERVER_URL="http://localhost:5173"

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

check_server() {
  local code
  code=$(curl -s -o /dev/null -w '%{http_code}' --connect-timeout 1 "$SERVER_URL" 2>/dev/null) || true
  [ "$code" = "200" ]
}

kill_server() {
  # Kill any process listening on port 5173
  local pid
  pid=$(lsof -ti tcp:5173 2>/dev/null) || true
  if [ -n "$pid" ]; then
    kill $pid 2>/dev/null || true
    # Wait briefly for port to free up
    local i=0
    while [ $i -lt 10 ] && lsof -ti tcp:5173 &>/dev/null; do
      sleep 0.2
      i=$((i+1))
    done
  fi
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

  # Start dev server in background, capturing stderr for diagnostics
  SERVER_LOG=$(mktemp)
  (cd "$WEB_DIR" && pnpm dev 2>"$SERVER_LOG" &)

  # Poll for up to 8 seconds (16 attempts at 0.5s)
  ATTEMPTS=0
  MAX_ATTEMPTS=16
  while [ $ATTEMPTS -lt $MAX_ATTEMPTS ]; do
    sleep 0.5
    if check_server; then
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
    rm -f "$SERVER_LOG"
    exit 2
  fi
  rm -f "$SERVER_LOG"
fi

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

# --- Build URL with multiple file params ---

QUERY=""
for vpath in "${VALID_PATHS[@]}"; do
  encoded="$(url_encode "$vpath")"
  if [ -z "$QUERY" ]; then
    QUERY="file=${encoded}"
  else
    QUERY="${QUERY}&file=${encoded}"
  fi
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
