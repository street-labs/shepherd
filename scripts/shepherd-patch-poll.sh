#!/usr/bin/env bash
#
# Fetches and maps NIP-34 patch-thread replies (kind:1 root replies) for a patch
# event, and (in loop mode) refreshes a sidecar the macOS app reads on a timer so
# the inspector + inline reply surfaces update live during a review.
# Implements: FR-sr-patch-replies-live (poll-and-reload).
#
# Usage:
#   shepherd-patch-poll.sh --once <event-id>
#       Fetch + map once, print a JSON array of PatchReply to stdout. Used by the
#       /shepherd-review command prompt for the initial reply snapshot.
#
#   shepherd-patch-poll.sh <session-id> <event-id> [interval-secs] [max-minutes]
#       Loop: fetch + map, atomically write
#       ~/.shepherd/sessions/<session-id>/patch-replies.json, sleep <interval>
#       (default 30s), repeat. Exits when the session's prompt-output.md appears
#       (review done) or after <max-minutes> (default 60) to avoid orphaning.
#
# Relay configuration (same precedence as the command prompt):
#   1. NOSTR_RELAYS env var (comma-separated)
#   2. ~/.config/nostr/relays.txt (one URL per line)
#   3. Default: wss://relay.damus.io,wss://nos.lol,wss://relay.nostr.band
#
# Requires: nak (https://github.com/fiatjaf/nak) and python3. If nak is missing,
# --once prints "[]" and loop mode exits 0 immediately (best-effort: no replies).

set -euo pipefail

MODE=""
EVENT_ID=""
SESSION_ID=""
INTERVAL=30
MAX_MINUTES=60

if [[ "${1:-}" == "--once" ]]; then
  MODE="once"
  EVENT_ID="${2:-}"
  if [[ -z "$EVENT_ID" ]]; then
    echo "Usage: $0 --once <event-id>" >&2
    exit 1
  fi
elif [[ $# -ge 2 ]]; then
  MODE="loop"
  SESSION_ID="$1"
  EVENT_ID="$2"
  INTERVAL="${3:-30}"
  MAX_MINUTES="${4:-60}"
else
  echo "Usage: $0 --once <event-id> | $0 <session-id> <event-id> [interval-secs] [max-minutes]" >&2
  exit 1
fi

# --- Relays ---
if [[ -n "${NOSTR_RELAYS:-}" ]]; then
  RELAYS="$NOSTR_RELAYS"
elif [[ -r "$HOME/.config/nostr/relays.txt" ]]; then
  RELAYS=$(grep -vE '^\s*(#|$)' "$HOME/.config/nostr/relays.txt" | paste -sd ',' -)
else
  RELAYS="wss://relay.damus.io,wss://nos.lol,wss://relay.nostr.band"
fi
RELAY_LIST=$(echo "$RELAYS" | tr ',' ' ')

if ! command -v nak >/dev/null 2>&1; then
  if [[ "$MODE" == "once" ]]; then echo "[]"; fi
  exit 0
fi
if ! command -v python3 >/dev/null 2>&1; then
  if [[ "$MODE" == "once" ]]; then echo "[]"; fi
  exit 0
fi

# --- Mapper script (written once so nak's output can be piped to its stdin) ---
MAPPER=$(mktemp -t shepherd-patch-mapper.XXXXXX.py)
trap 'rm -f "$MAPPER"' EXIT
cat > "$MAPPER" <<'PY'
import json, os, sys

patch_id = sys.argv[1]
roster = {}
rp = os.path.expanduser("~/.config/nostr/roster.json")
try:
    with open(rp) as f: roster = json.load(f)
except Exception:
    pass

def root_match(tags):
    for t in tags:
        if len(t) >= 2 and t[0] == "e" and t[1] == patch_id:
            return True
    return False

def parse_anchor(tags):
    # ponytail: only the ["range", file, start, end] convention is parsed.
    # Other anchoring schemes (q/r tags) fall back to inspector-only rendering.
    for t in tags:
        if len(t) >= 4 and t[0] == "range":
            try:
                return {"filePath": str(t[1]), "startLine": int(t[2]), "endLine": int(t[3])}
            except Exception:
                return None
    return None

out = []
for line in sys.stdin:
    line = line.strip()
    if not line: continue
    try:
        ev = json.loads(line)
    except Exception:
        continue
    if not isinstance(ev, dict) or "kind" not in ev: continue
    kind = ev.get("kind")
    if kind != 1: continue  # exclude 1630-1633 status transitions and the patch event
    if ev.get("id") == patch_id: continue
    tags = ev.get("tags", []) or []
    if not root_match(tags): continue
    pk = ev.get("pubkey", "")
    entry = roster.get(pk, {}) if isinstance(roster, dict) else {}
    name = entry.get("name") if isinstance(entry, dict) else None
    is_bot = bool(entry.get("bot")) if isinstance(entry, dict) else False
    # ponytail: no live NIP-05 fetch in the poller; bot detection is roster-only.
    if not name:
        name = (pk[:16] + "…") if pk else "unknown"
    out.append({
        "id": ev.get("id", pk + str(ev.get("created_at", 0))),
        "author": name,
        "authorPubkey": pk,
        "isBot": is_bot,
        "content": ev.get("content", ""),
        "timestamp": int(ev.get("created_at", 0) or 0),
        "lineAnchor": parse_anchor(tags),
    })
print(json.dumps(out))
PY

# --- Fetch + map (nak's event JSON piped into the mapper) ---
fetch_replies() {
  # nak req -k 1 -e <id> <relays...> : filter on the e tag (root + replies).
  nak req -k 1 -e "$EVENT_ID" $RELAY_LIST 2>/dev/null | python3 "$MAPPER" "$EVENT_ID"
}

if [[ "$MODE" == "once" ]]; then
  fetch_replies
  exit 0
fi

# --- Loop mode: refresh sidecar until the review ends or timeout ---
SESSION_DIR="$HOME/.shepherd/sessions/$SESSION_ID"
SIDECAR="$SESSION_DIR/patch-replies.json"
mkdir -p "$SESSION_DIR"
END=$(( $(date +%s) + MAX_MINUTES * 60 ))
while true; do
  if [[ -f "$SESSION_DIR/prompt-output.md" ]]; then break; fi
  if [[ $(date +%s) -ge $END ]]; then break; fi
  TMP=$(mktemp "$SESSION_DIR/patch-replies.XXXXXX.json")
  if fetch_replies > "$TMP"; then
    mv "$TMP" "$SIDECAR"
  else
    rm -f "$TMP"
  fi
  sleep "$INTERVAL"
done
exit 0
