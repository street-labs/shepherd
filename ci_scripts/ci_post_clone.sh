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
#   2. When this workflow targets the iOS project, regenerate it from
#      project.yml via XcodeGen (the .xcodeproj is gitignored on purpose).

set -e

: "${CI_PROJECT_FILE_PATH:=}"

# 1. Skip plugin/macro trust prompts for every Xcode Cloud workflow. Must be
#    set before package resolution, which is why this lives in ci_post_clone.
defaults write com.apple.dt.Xcode IDESkipPackagePluginFingerprintValidation -bool YES
defaults write com.apple.dt.Xcode IDESkipMacroFingerprintValidation -bool YES

# 2. Regenerate the iOS project only when this workflow targets it.
case "$CI_PROJECT_FILE_PATH" in
  */ShepherdiOS.xcodeproj)
    PROJECT_DIR="$(dirname "$CI_PROJECT_FILE_PATH")"
    echo "ci_post_clone: Generating iOS project at $PROJECT_DIR from project.yml..."

    # Self-contained: download the prebuilt XcodeGen binary from GitHub releases.
    # No package manager required (Xcode Cloud may not have Homebrew).
    # Pinned (not releases/latest) so CI is reproducible; bump deliberately.
    XCODEGEN_VERSION="2.46.0"
    cd /tmp
    curl -fsSL -o xcodegen.zip \
      "https://github.com/yonaskolb/XcodeGen/releases/download/${XCODEGEN_VERSION}/xcodegen.zip"
    unzip -o -q xcodegen.zip

    cd "$PROJECT_DIR"
    /tmp/xcodegen/bin/xcodegen generate
    ;;
esac

echo "ci_post_clone: Done."
