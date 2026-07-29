#!/bin/sh

# ci_post_clone.sh — runs after Xcode Cloud clones the repo.
#
# Lives at the REPOSITORY ROOT so Xcode Cloud always discovers it. A previous
# version nested this inside engineering/apps/ios/ci_scripts/, next to the iOS
# .xcodeproj — but that project is gitignored (XcodeGen-generated) and absent at
# clone time, so Xcode Cloud couldn't resolve "the directory containing the
# project" to find the nested ci_scripts. The script never ran, the skip-
# validation defaults never got set, and package resolution failed with:
#   Plugin "SharedSourcesPlugin" from package "swift-secp256k1" must be enabled
#   before it can be used
# Root location is Apple's canonical, always-discovered spot and fixes that.
#
# Two jobs:
#   1. Disable plugin + macro fingerprint validation globally. Build-tool
#      plugins (swift-secp256k1 SharedSourcesPlugin) and macros need a one-time
#      "Trust & Enable" prompt that Xcode Cloud can't show non-interactively;
#      these defaults opt the whole resolved package graph into running without
#      the prompt. Safe here because we control every package in the graph.
#   2. Regenerate the iOS project from project.yml via XcodeGen on every run
#      (the .xcodeproj is gitignored on purpose, so it's absent at clone time).

set -e -u

# Capture the repo root before any `cd`. Xcode Cloud clones into
# $CI_PRIMARY_REPOSITORY_PATH; fall back to the script's own location
# (it lives in ci_scripts/ at the repo root) so local runs work from any cwd.
: "${CI_PRIMARY_REPOSITORY_PATH:=$(cd "$(dirname "$0")/.." && pwd)}"
REPO_ROOT="$CI_PRIMARY_REPOSITORY_PATH"

# Echo the resolved inputs so a failing Cloud build's log shows exactly what
# we received and where generation will run. This is the single most useful
# diagnostic when "Project ... does not exist" fires: it reveals whether the
# env var came through, whether $0 resolved correctly, and what path we'll
# generate into - without it we're guessing from outside the Cloud sandbox.
PROJECT_DIR="engineering/apps/ios"
PROJECT_PATH="$REPO_ROOT/$PROJECT_DIR"
echo "ci_post_clone: CI_PRIMARY_REPOSITORY_PATH=${CI_PRIMARY_REPOSITORY_PATH:-<unset>}"
echo "ci_post_clone: CI_PROJECT_FILE_PATH=${CI_PROJECT_FILE_PATH:-<unset>}"
echo "ci_post_clone: REPO_ROOT=$REPO_ROOT"
echo "ci_post_clone: PROJECT_PATH=$PROJECT_PATH"
echo "ci_post_clone: Generating iOS project from project.yml..."

# Regenerate the iOS project unconditionally.
#
# The .xcodeproj is gitignored (XcodeGen-generated) and absent at clone time,
# so Xcode Cloud's Archive action fails with "Project ShepherdiOS.xcodeproj
# does not exist" unless we materialize it here, before the build action.
#
# This is the only XcodeGen project in the repo and every Xcode Cloud workflow
# targets it, so generate it on every run. Gating on CI_PROJECT_FILE_PATH is
# fragile: the env var may be empty, absolute, or carry a trailing slash on the
# .xcodeproj bundle, any of which silently skips generation and reproduces the
# "does not exist" failure. Unconditional generation is cheap and safe.

# Self-contained: download the prebuilt XcodeGen binary from GitHub releases.
# No package manager required (Xcode Cloud may not have Homebrew).
# Pinned (not releases/latest) so CI is reproducible; bump deliberately.
XCODEGEN_VERSION="2.46.0"
XCODEGEN_SHA256="4d9e34b62172d645eed6457cac13fc222569974098ef4ee9c3368bedf0196806"
cd /tmp
curl -fsSL -o xcodegen.zip \
  "https://github.com/yonaskolb/XcodeGen/releases/download/${XCODEGEN_VERSION}/xcodegen.zip"
# Verify the download so a compromised/re-tagged release can't run code in CI.
echo "${XCODEGEN_SHA256}  xcodegen.zip" | shasum -a 256 -c -
unzip -o -q xcodegen.zip

cd "$REPO_ROOT/$PROJECT_DIR"
/tmp/xcodegen/bin/xcodegen generate

# Verify the project actually landed where Xcode Cloud's build step will look
# for it. If this fails, `set -e` aborts here with a clear message instead of
# letting Cloud proceed to a build with no project and report a confusing
# "does not exist" upstream of the real cause.
if [ ! -d "$PROJECT_PATH/ShepherdiOS.xcodeproj" ]; then
  echo "ci_post_clone: ERROR - ShepherdiOS.xcodeproj missing at $PROJECT_PATH after generation"
  ls -la "$PROJECT_PATH" || true
  exit 1
fi
echo "ci_post_clone: Generated $PROJECT_PATH/ShepherdiOS.xcodeproj"

# Skip plugin/macro trust prompts for every Xcode Cloud workflow. Must be set
# before package resolution (the build action), which is why this runs in
# ci_post_clone - but it's NOT critical to generation, so it runs AFTER xcodegen
# and is guarded so a failure here can't abort the script and leave no project.
# A failed defaults write would otherwise reproduce the "does not exist" error.
if ! defaults write com.apple.dt.Xcode IDESkipPackagePluginFingerprintValidation -bool YES; then
  echo "ci_post_clone: WARN - IDESkipPackagePluginFingerprintValidation defaults write failed (build may prompt to trust plugins)"
fi
if ! defaults write com.apple.dt.Xcode IDESkipMacroFingerprintValidation -bool YES; then
  echo "ci_post_clone: WARN - IDESkipMacroFingerprintValidation defaults write failed (build may prompt to trust macros)"
fi

echo "ci_post_clone: Done."
