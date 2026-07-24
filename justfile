# shepherd - see README.md (source of truth). pdeq-framework project; agent
# coordinator config lives in CLAUDE.md (imports .pdeq/CLAUDE.md). One platform:
# macos (engineering/apps/macos, Swift/TCA).

# Default: list recipes
default:
    @just --list

# Install toolchain + deps (called by the street-labs bootstrap).
setup:
    ./scripts/bootstrap.sh

# Build the macOS app (release binary used by the slash commands).
dev:
    cd engineering/apps/macos && swift build -c release

# Build and run the macOS app (release binary).
run: dev
    engineering/apps/macos/.build/release/ShepherdApp

# Run the macOS app test suite.
test:
    ./scripts/run-tests.sh
