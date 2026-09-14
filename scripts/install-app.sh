#!/usr/bin/env bash
#
# Installs the prebuilt ShepherdApp binary as ~/Applications/Shepherd.app, the one app
# every /shepherd session opens a window in. Refreshes the installed copy when the build
# is newer, unless Shepherd is running (swapping the executable under open review windows
# would strand them on a stale binary anyway). Prints the bundle path.
#
# Exit codes: 0 installed (or already current), 2 no build and nothing installed.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
BINARY="$REPO_ROOT/engineering/apps/macos/.build/release/ShepherdApp"
APP_BUNDLE="$HOME/Applications/Shepherd.app"
APP_EXEC="$APP_BUNDLE/Contents/MacOS/ShepherdApp"

# Implements: FR-sc-mac-prebuild
if [ ! -x "$BINARY" ]; then
  if [ -x "$APP_EXEC" ]; then
    echo "$APP_BUNDLE"
    exit 0
  fi
  echo "Error: macOS app binary not found at $BINARY" >&2
  echo "Re-run ./scripts/install-command.sh from the Shepherd repo to build it." >&2
  exit 2
fi

if cmp -s "$BINARY" "$APP_EXEC"; then
  echo "$APP_BUNDLE"
  exit 0
fi

if pgrep -xq ShepherdApp; then
  if [ -x "$APP_EXEC" ]; then
    echo "Note: Shepherd is running an older build; quit it to pick up the new one." >&2
    echo "$APP_BUNDLE"
    exit 0
  fi
fi

# A bare Mach-O SwiftUI executable does not reliably render its content on macOS: the
# window chrome draws but the SwiftUI body stays blank. A minimal .app bundle gives it
# full app treatment and registers the shepherd:// scheme the launcher hands sessions over.
mkdir -p "$APP_BUNDLE/Contents/MacOS"
# Unlink before copying: SwiftPM emits an ad-hoc linker-signed binary and macOS caches
# a code-signature blob per vnode. Overwriting the executable in place (cp -f truncates
# the same inode) leaves that blob stale, and the next launch is SIGKILLed by AMFI with
# "Code Signature Invalid". A fresh inode per refresh avoids it.
rm -f "$APP_EXEC"
cp "$BINARY" "$APP_EXEC"
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
echo "$APP_BUNDLE"
