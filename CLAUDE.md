@.pdeq/CLAUDE.md

# Shepherd — Project-Specific Overrides

The framework above (imported from `.pdeq/CLAUDE.md`) defines the coordinator agent. Below are Shepherd-specific additions.

## Platforms

This project targets two platforms (registered in `pdeq.json`):

| Platform ID | Description | Status |
|---|---|---|
| `web` | Browser-based SPA (React/Vite/TypeScript) | Active — all features |
| `macos` | Native macOS app (SwiftUI + TCA) | Active — core CRPG feature |

Source code lives at `engineering/apps/web/` and `engineering/apps/macos/`. Each platform owns its build system, dependencies, and test infrastructure.

## Project-Specific Slash Commands

These extend the framework commands (`/kickoff`, `/impact`, `/status`, `/bootstrap`, `/migrate`):

- **`/shepherd <file>`** — Open the web Code Review Prompt Generator (CRPG) with the specified file.
- **`/shepherd-mac <file>`** — Open the macOS CRPG with the specified file.
- **`/shepherd-review`** — Orchestrate a guided, multi-file code review of uncommitted changes using the CRPG.
- **`/land`** — Land current changes on main, push, return to branch, and rebase.
- **`/readme`** — Regenerate the project README with fresh demo screenshots.

## Updating PDEQ

The PDEQ framework is pinned via the `.pdeq` git submodule. To update:

```bash
git submodule update --remote .pdeq
git add .pdeq
git commit -m "Bump pdeq submodule"
```

Always read `.pdeq/migrations/` for any breaking changes before bumping.

@FP_CLAUDE.md
