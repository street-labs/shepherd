#!/usr/bin/env bash
#
# Fetches and maps NIP-34 patch-thread replies (kind:1 root replies) for a patch
# event, printing a PatchReply JSON array to stdout. Used by the
# /shepherd-review command prompt for the initial reply snapshot baked into
# session.json. Implements the shell side of FR-sr-patch-replies-display.
#
# The live path is in-app: the macOS app's RelayClient (URLSessionWebSocketTask)
# subscribes to relays directly for ongoing updates (FR-sr-patch-replies-live).
#
# Usage:
#   shepherd-patch-poll.sh --once <event-id>
#   shepherd-patch-poll.sh <event-id>
# The leading `--once` flag is accepted for back-compat with earlier command-prompt
# invocations and is a no-op (this script only ever does a single fetch). Relay configuration (same precedence as the command prompt):
#   1. NOSTR_RELAYS env var (comma-separated)
#   2. ~/.config/nostr/relays.txt (one URL per line)
#   3. Default: wss://relay.damus.io,wss://nos.lol,wss://relay.nostr.band
#
# Requires: nak (https://github.com/fiatjaf/nak) and python3. If either is
# missing, prints "[]" and exits 0 (best-effort: no replies).

set -euo pipefail

# Accept an optional leading `--once` flag (no-op; single fetch is all this
# script does). Keeps the command-prompt invocation `--once <event-id>` working.
if [[ "${1:-}" == "--once" ]]; then shift; fi

EVENT_ID="${1:-}"
if [[ -z "$EVENT_ID" ]]; then
  echo "Usage: $0 [--once] <event-id>" >&2
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

if ! command -v nak >/dev/null 2>&1 || ! command -v python3 >/dev/null 2>&1; then
  echo "[]"
  exit 0
fi

# --- Mapper script (written to a temp file so nak's output pipes to its stdin) ---
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

# nak req -k 1 -e <id> <relays...> : filter on the e tag (root + replies).
nak req -k 1 -e "$EVENT_ID" $RELAY_LIST 2>/dev/null | python3 "$MAPPER" "$EVENT_ID"
