#!/bin/sh
# ci_post_clone.sh — runs after Xcode Cloud clones the repo.
#
# Shepherd's iOS app depends on the local Shepherd SPM package, which pulls in
# swift-secp256k1. That package ships a build-tool plugin (SharedSourcesPlugin)
# that generates shared sources at build time. Xcode Cloud can't answer the
# interactive "Trust & Enable" prompt for package plugins, so we skip plugin
# and macro fingerprint validation non-interactively via Xcode defaults.
#
# Same mechanism coffee-shop uses (engineering/apps/ios/ci_scripts). The
# ShepherdiOS.xcodeproj is committed (XcodeGen output), so no regeneration or
# artifact provisioning is needed here.

set -e

defaults write com.apple.dt.Xcode IDESkipPackagePluginFingerprintValidation -bool YES
defaults write com.apple.dt.Xcode IDESkipMacroFingerprintValidation -bool YES

echo "ci_post_clone: Disabled package plugin + macro fingerprint validation. Done."
