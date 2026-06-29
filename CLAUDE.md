@.pdeq/CLAUDE.md

# Shepherd — Project-Specific Overrides

The framework above (imported from `.pdeq/CLAUDE.md`) defines the coordinator agent. Below are Shepherd-specific additions.

## Platforms

This project targets one platform (registered in `pdeq.json`):

| Platform ID | Description | Status |
|---|---|---|
| `macos` | Native macOS app (SwiftUI + TCA) | Active — all features |

Source code lives at `engineering/apps/macos/`. (The browser-based `web` platform was removed; Shepherd is now macOS-only.)

## Project-Specific Slash Commands

These extend the framework commands (`/kickoff`, `/impact`, `/status`, `/bootstrap`, `/migrate`):

- **`/shepherd <file>`** — Open the macOS Code Review Prompt Generator (CRPG) with the specified file.
- **`/shepherd-review`** — Orchestrate a guided, multi-file code review of uncommitted changes using the macOS CRPG.
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
