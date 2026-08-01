#!/bin/sh
# deploy-ios.sh — build, archive, export, and upload shepherd iOS to TestFlight.
#
# One command: `asc publish testflight` local-build mode runs xcodebuild archive
# + export to IPA + upload to App Store Connect + distribute to a TestFlight
# group. We just feed it the project, scheme, ExportOptions.plist, and the
# signing pass-throughs the build host owns.
#
# Run on a host with Xcode, signing certs/profiles, and asc authed via
# `asc auth login`. Invoke via `just deploy-ios` or directly.
#
# Required env (set on the build host, or run `just setup-deploy-ios` once to
# store them in the shared creds store — this script pulls from `creds`
# automatically; exported shell env vars take precedence over the store):
#   SHEPHERD_ASC_APP_ID  App Store Connect app numeric ID
#   SHEPHERD_TEAM_ID     Apple Developer Team ID (passed as DEVELOPMENT_TEAM)
#   SHEPHERD_TF_GROUP    TestFlight beta group name or ID to distribute to
#
# Auth: `asc auth login` must have been run once on this host so a keychain
# profile is active. See https://appstoreconnect.apple.com/access/integrations/api
# to create the API key (App Manager role minimum).
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

IOS_DIR="$REPO_ROOT/engineering/apps/ios"
PROJECT="$IOS_DIR/ShepherdiOS.xcodeproj"
EXPORT_OPTS="$IOS_DIR/export/ExportOptions.plist"
BUILD_DIR="$IOS_DIR/build"

# asc requires --version in local-build mode; source of truth is the
# hand-maintained Info.plist (project.yml sets GENERATE_INFOPLIST_FILE=NO).
INFO_PLIST="$IOS_DIR/ShepherdiOSApp/Resources/Info.plist"
VERSION="$(/usr/libexec/PlistBuddy -c 'Print :CFBundleShortVersionString' "$INFO_PLIST")"
[ -n "$VERSION" ] || { echo "deploy-ios: could not read CFBundleShortVersionString from $INFO_PLIST"; exit 2; }

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
