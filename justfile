# shepherd - see README.md (source of truth). pdeq-framework project; agent
# coordinator config lives in CLAUDE.md (imports .pdeq/CLAUDE.md). Two platforms:
# macOS (SwiftPM at engineering/apps/macos) and iOS (XcodeGen at
# engineering/apps/ios, links the macOS package's feature modules).
#
# Standard Street Labs recipes (see projects/CONVENTIONS.md in the borg repo):
# setup, dev, test, fmt, editor - same five in every repo so muscle memory
# carries over and the brain's bootstrap can provision any of them the same way.

# Default: list recipes
default:
    @just --list

# Install toolchain + deps (called by the street-labs bootstrap).
setup:
    ./scripts/bootstrap.sh

# --- macOS (SwiftPM) -------------------------------------------------------

# Build the macOS app (release binary used by the slash commands).
dev:
    cd engineering/apps/macos && swift build -c release

# Build and run the macOS app (release binary).
run: dev
    engineering/apps/macos/.build/release/ShepherdApp

# Run the macOS app test suite.
test:
    ./scripts/run-tests.sh

# --- iOS (XcodeGen) --------------------------------------------------------

# Generate the iOS Xcode project from project.yml (idempotent).
gen-ios:
    cd engineering/apps/ios && xcodegen generate

# Build the iOS app for the simulator.
dev-ios: gen-ios
    xcodebuild -project engineering/apps/ios/ShepherdiOS.xcodeproj \
        -scheme ShepherdiOS \
        -destination 'generic/platform=iOS Simulator' \
        build

# NOTE: no `test-ios` yet. The iOS app is a thin shell reusing the macOS
# package's feature modules; its logic is tested by `just test` (swift test
# in engineering/apps/macos). Add test-ios when an iOS-specific test target
# exists (xcodebuild test ... -scheme ShepherdiOS).

# Build, archive, and upload the iOS app to TestFlight in one shot (runs on a
# host with Xcode + signing + asc authed; needs SHEPHERD_ASC_APP_ID,
# SHEPHERD_TEAM_ID, SHEPHERD_TF_GROUP env). See scripts/deploy-ios.sh.
deploy-ios:
    ./scripts/deploy-ios.sh

# --- format / editor -------------------------------------------------------

# Format all Swift sources (macOS package + iOS app).
fmt:
    swiftformat --config .swiftformat .

# Open the project in Xcode. Regenerates the iOS project first so a fresh
# clone always opens cleanly; the iOS project embeds the macOS package as a
# dependency, so both surfaces are visible in one workspace.
editor: gen-ios
    open engineering/apps/ios/ShepherdiOS.xcodeproj
