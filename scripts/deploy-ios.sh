#!/bin/sh
# deploy-ios.sh — build, archive, export, and upload shepherd iOS to TestFlight.
#
# One command: `asc publish testflight` local-build mode runs xcodebuild archive
# + export to IPA + upload to App Store Connect + distribute to a TestFlight
# group. We just feed it the project, scheme, ExportOptions.plist, and the
# signing pass-throughs the build host owns.
#
# Run on a host with Xcode and iOS signing certs/profiles. Invoke via
# `just deploy-ios` or directly.
#
# Required env (set on the build host, or run `just setup-deploy-ios` once to
# store them in the shared creds store — this script pulls from `creds`
# automatically; exported shell env vars take precedence over the store):
#   SHEPHERD_ASC_APP_ID  App Store Connect app numeric ID
#   SHEPHERD_TEAM_ID     Apple Developer Team ID (passed as DEVELOPMENT_TEAM)
#   SHEPHERD_TF_GROUP    TestFlight beta group name or ID to distribute to
#
# Auth: asc reads the App Store Connect API key from env vars sourced via
# `creds env asc` (the shared creds store / borg-asc-env blob). No
# `asc auth login` profile is required, though one coexists fine (env vars
# only fill missing fields). To populate the blob, create an API key at
# https://appstoreconnect.apple.com/access/integrations/api (App Manager
# role minimum) and `creds set asc`.
#
# Skipped (add when needed): --notify (tester notification), --test-notes,
#   --submit (beta app review). Ship the minimal upload-to-group flow first.

set -e -u

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"

# Fill unset vars from the shared creds store, but don't clobber vars already
# set in the environment (an exported shell var should win over the store).
if command -v creds >/dev/null 2>&1; then
  for v in SHEPHERD_ASC_APP_ID SHEPHERD_TEAM_ID SHEPHERD_TF_GROUP; do
    eval "cur=\${$v:-}"
    if [ -z "$cur" ]; then
      val="$(creds get shepherd "$v" 2>/dev/null || true)"
      [ -n "$val" ] && export "$v=$val"
    fi
  done
fi

for v in SHEPHERD_ASC_APP_ID SHEPHERD_TEAM_ID SHEPHERD_TF_GROUP; do
  eval "val=\${$v:-}"
  [ -n "$val" ] || { echo "deploy-ios: $v is required (run \`just setup-deploy-ios\` or set it on the host)"; exit 2; }
done

# App Store Connect API auth. asc reads env vars (ASC_KEY_ID / ASC_ISSUER_ID /
# ASC_PRIVATE_KEY) sourced from the shared creds store (borg-asc-env blob)
# when present, and also accepts a keychain profile created via
# `asc auth login`. Either source works; env vars only fill missing fields
# unless --strict-auth is set (this script does not set it).
if command -v creds >/dev/null 2>&1; then
  eval "$(creds env asc 2>/dev/null || true)"
fi
# Fail-fast auth preflight: `asc auth token` signs a JWT locally (no network)
# and succeeds only when asc has a usable auth source (env creds OR profile).
# Avoids a multi-minute archive + export only to die at the upload leg.
if ! asc auth token --confirm >/dev/null 2>&1; then
  echo "deploy-ios: asc not authenticated. Populate creds (creds set asc /"
  echo "  creds sync) or run \`asc auth login\` to create a keychain profile."
  exit 2
fi

IOS_DIR="$REPO_ROOT/engineering/apps/ios"
PROJECT="$IOS_DIR/ShepherdiOS.xcodeproj"
EXPORT_OPTS="$IOS_DIR/export/ExportOptions.plist"
BUILD_DIR="$IOS_DIR/build"

# Pre-flight signing check: fail in 1s with an actionable message instead of
# letting xcodebuild archive run for minutes then die on "No Accounts" / "No
# profiles". Requires an iOS Distribution or Development identity in the
# keychain (automatic signing with -allowProvisioningUpdates generates the
# profile, but only if a cert + Apple account already exist on this host).
# ponytail: matches name prefixes across old ("iPhone Distribution"/
# "iPhone Developer") and new ("Apple Distribution") Xcode cert naming; broad
# gate is fine since the archive itself errors precisely if the wrong type
# is present.
if ! security find-identity -v -p codesigning 2>/dev/null \
    | grep -qE '"(iPhone|Apple) (Distribution|Developer):'; then
  echo "deploy-ios: no iOS signing identity in keychain."
  echo "  Add the Apple Developer account in Xcode -> Settings -> Accounts,"
  echo "  then let automatic signing create the distribution cert + profile"
  echo "  (or import an existing .p12 + .mobileprovision). Re-run after."
  exit 2
fi

# asc requires --version in local-build mode; source of truth is the
# hand-maintained Info.plist (project.yml sets GENERATE_INFOPLIST_FILE=NO).
INFO_PLIST="$IOS_DIR/ShepherdiOSApp/Resources/Info.plist"
VERSION="$(/usr/libexec/PlistBuddy -c 'Print :CFBundleShortVersionString' "$INFO_PLIST")"
[ -n "$VERSION" ] || { echo "deploy-ios: could not read CFBundleShortVersionString from $INFO_PLIST"; exit 2; }

# Resolve the next free CFBundleVersion from App Store Connect and stamp it
# into Info.plist before archiving. asc publish testflight (local-build mode)
# archives whatever CFBundleVersion Info.plist carries — it does NOT auto-
# increment — so a stale build number makes the upload die at the create-
# upload-record step with "bundle version must be higher than the previously
# uploaded version". Querying ASC for next-build-number makes every deploy
# self-healing regardless of what the committed Info.plist holds. The
# committed CFBundleVersion is just a seed; this line overwrites it for the
# archive only (the working-tree edit is left in place as a record of what
# was shipped — commit it if you want to track that, or revert).
NEXT_BUILD_JSON="$(asc builds next-build-number --app "$SHEPHERD_ASC_APP_ID" --version "$VERSION" --platform IOS 2>/dev/null)"
NEXT_BUILD="$(printf '%s' "$NEXT_BUILD_JSON" | sed -n 's/.*"nextBuildNumber":"\([0-9]*\)".*/\1/p')"
[ -n "$NEXT_BUILD" ] || { echo "deploy-ios: could not resolve next build number from ASC; got: $NEXT_BUILD_JSON"; exit 2; }
echo "deploy-ios: stamping CFBundleVersion=$NEXT_BUILD (next free build for $VERSION) into $INFO_PLIST"
# sed (not PlistBuddy/plutil) so only the CFBundleVersion <string> value
# changes — PlistBuddy/plutil rewrite the whole plist, dropping the export-
# compliance XML comment and re-indenting. Find the CFBundleVersion key, on
# the next line replace the <string>…</string> value.
sed -i '' "/<key>CFBundleVersion<\/key>/{n;s/<string>[0-9][0-9]*<\/string>/<string>$NEXT_BUILD<\/string>/;}" "$INFO_PLIST"

# Materialize the gitignored .xcodeproj from project.yml first — same root cause
# as the Xcode Cloud "does not exist" failure; no point reproducing it here.
( cd "$IOS_DIR" && xcodegen generate )

# ponytail: known risk — an Xcode 26.5 JWT bug may block the upload leg.
# Archive + export to IPA still succeed; the IPA is left at --ipa-path and
# can be uploaded via Xcode Organizer until the bug clears.
mkdir -p "$BUILD_DIR"

# -skipPackagePluginValidation: swift-secp256k1 ships a build-tool plugin
# (SharedSourcesPlugin) and Xcode refuses to validate plugins from remote
# packages during device archives. Long-term fix is a secp256k1 release that
# drops the plugin; the flag unblocks TestFlight deploys meanwhile.
set -x
asc publish testflight \
  --app "$SHEPHERD_ASC_APP_ID" \
  --project "$PROJECT" \
  --scheme ShepherdiOS \
  --export-options "$EXPORT_OPTS" \
  --version "$VERSION" \
  --group "$SHEPHERD_TF_GROUP" \
  --archive-xcodebuild-flag -allowProvisioningUpdates \
  --archive-xcodebuild-flag "DEVELOPMENT_TEAM=$SHEPHERD_TEAM_ID" \
  --archive-xcodebuild-flag -skipPackagePluginValidation \
  --export-xcodebuild-flag -allowProvisioningUpdates \
  --export-xcodebuild-flag -skipPackagePluginValidation \
  --archive-path "$BUILD_DIR/ShepherdiOS.xcarchive" \
  --ipa-path "$BUILD_DIR/ShepherdiOS.ipa" \
  --wait
set +x

echo "deploy-ios: Done. IPA at $BUILD_DIR/ShepherdiOS.ipa"
