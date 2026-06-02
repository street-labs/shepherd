# shepherd - see README.md (source of truth). pdeq-framework project; agent
# coordinator config lives in CLAUDE.md (imports .pdeq/CLAUDE.md). Two platforms:
# web (engineering/apps/web, pnpm/vite) and macos (engineering/apps/macos, Swift/TCA).

# Default: list recipes
default:
    @just --list

# Install toolchain + deps (called by the street-labs bootstrap).
setup:
    ./scripts/bootstrap.sh

# Run the web app locally (vite dev server).
dev:
    cd engineering/apps/web && pnpm dev

# Run the web test suite (vitest). macOS app tests run from Xcode/swift.
test:
    cd engineering/apps/web && pnpm test
