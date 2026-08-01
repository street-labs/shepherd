#!/bin/sh
# setup-deploy-ios.sh — interactive setup for `just deploy-ios` on this host.
#
# Detects what's already configured and only asks for what's missing:
#   - SHEPHERD_ASC_APP_ID / SHEPHERD_TEAM_ID / SHEPHERD_TF_GROUP (from env or
#     the shared creds store, `creds env shepherd`) — prompts only for unset ones
#     and stores answers back into the creds store (never a repo .env)
#   - asc CLI on PATH (offers `brew install asc` if missing)
#   - asc auth (runs `asc auth login` only if no credentials are stored)
#
# Safe to re-run: fully configured hosts print a summary and exit.

set -e -u

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"

# Load creds-store values as defaults (env vars already exported win).
if command -v creds >/dev/null 2>&1; then
  for v in SHEPHERD_ASC_APP_ID SHEPHERD_TEAM_ID SHEPHERD_TF_GROUP; do
    eval "cur=\${$v:-}"
    if [ -z "$cur" ]; then
      val="$(creds get shepherd "$v" 2>/dev/null || true)"
      [ -n "$val" ] && export "$v=$val"
    fi
  done
fi

prompt() {
  # prompt <var-name> <description>
  var="$1"; desc="$2"
  printf '%s\n  : ' "$desc" >&2
  read -r val
  [ -n "$val" ] || { echo "setup-deploy-ios: $var cannot be empty"; exit 2; }
  eval "$var=\"\$val\""
}

echo "Checking deploy-ios setup for this host..."

# --- 1. env vars ------------------------------------------------------------
changed=0

if [ -z "${SHEPHERD_ASC_APP_ID:-}" ]; then
  prompt SHEPHERD_ASC_APP_ID \
    "App Store Connect app numeric ID (App Store Connect > your app > App Information)"
  changed=1
fi
if [ -z "${SHEPHERD_TEAM_ID:-}" ]; then
  prompt SHEPHERD_TEAM_ID \
    "Apple Developer Team ID (10 chars, https://developer.apple.com/account > Membership)"
  changed=1
fi
if [ -z "${SHEPHERD_TF_GROUP:-}" ]; then
  prompt SHEPHERD_TF_GROUP \
    "TestFlight beta group name or ID to distribute to"
  changed=1
fi

if [ "$changed" = 1 ]; then
  if ! command -v creds >/dev/null 2>&1; then
    echo "setup-deploy-ios: the creds CLI is required to store these (internal tooling; see its docs)."
    exit 1
  fi
  {
    echo "SHEPHERD_ASC_APP_ID=$SHEPHERD_ASC_APP_ID"
    echo "SHEPHERD_TEAM_ID=$SHEPHERD_TEAM_ID"
    echo "SHEPHERD_TF_GROUP=$SHEPHERD_TF_GROUP"
  } | creds set shepherd
  echo "Stored in the shared creds store."
else
  echo "✓ env vars already set (creds: SHEPHERD_ASC_APP_ID, SHEPHERD_TEAM_ID, SHEPHERD_TF_GROUP)"
fi

# --- 2. asc CLI ---------------------------------------------------------------
if ! command -v asc >/dev/null 2>&1; then
  echo "asc (App Store Connect CLI) is not installed."
  if command -v brew >/dev/null 2>&1; then
    printf 'Install it now via Homebrew? [Y/n]: ' >&2
    read -r ans
    case "$ans" in
      n|N|no)
        echo "setup-deploy-ios: asc is required — install it from https://asccli.sh and re-run."
        exit 1
        ;;
      *) brew install asc ;;
    esac
  else
    echo "setup-deploy-ios: install asc from https://asccli.sh (Homebrew not found) and re-run."
    exit 1
  fi
else
  echo "✓ asc CLI installed"
fi

# --- 3. asc auth --------------------------------------------------------------
if asc auth status 2>/dev/null | grep -q '"credentials":\[\]'; then
  echo "No App Store Connect API credentials stored yet."
  printf 'Set up API key auth now? [Y/n]: ' >&2
  read -r ans || ans=n
  case "$ans" in
    n|N|no)
      echo "Skipped. Before your first deploy, create an API key at"
      echo "https://appstoreconnect.apple.com/access/integrations/api (App Manager role+)"
      echo "and re-run \`just setup-deploy-ios\`."
      ;;
    *)
      echo "You'll need an App Store Connect API key — create one at"
      echo "https://appstoreconnect.apple.com/access/integrations/api (App Manager role+)"
      echo "and download the .p8 private key (one-time download)."
      echo
      echo
      echo "Where to find these: log in at https://appstoreconnect.apple.com, then go to"
      echo "Users and Access > Integrations > App Store Connect API > Team Keys."
      echo "(Create a key there first with role App Manager or higher if none exists."
      echo "The .p8 private key can only be downloaded once, right after creating it.)"
      echo
      prompt ASC_KEY_NAME 'Friendly name for this key (e.g. "shepherd-deploy")'
      prompt ASC_KEY_ID "Key ID — 10-char code in the 'Key ID' column of your key's row in the Team Keys table"
      prompt ASC_ISSUER_ID "Issuer ID — long UUID labeled 'Issuer ID' at the top of the Team Keys page, above the table"
      while :; do
        prompt ASC_P8_PATH "Path to the downloaded .p8 file (e.g. ~/Downloads/AuthKey_XXXX.p8)"
        # Expand leading ~ (read doesn't do tilde expansion).
        ASC_P8_PATH="$(eval echo "$ASC_P8_PATH")"
        [ -f "$ASC_P8_PATH" ] && break
        echo "  File not found: $ASC_P8_PATH — try again." >&2
      done
      chmod 600 "$ASC_P8_PATH"
      asc auth login \
        --name "$ASC_KEY_NAME" \
        --key-id "$ASC_KEY_ID" \
        --issuer-id "$ASC_ISSUER_ID" \
        --private-key "$ASC_P8_PATH" \
        --network
      ;;
  esac
else
  echo "✓ asc auth already configured"
fi

echo
echo "Setup complete. Run \`just deploy-ios\` to ship a build."
