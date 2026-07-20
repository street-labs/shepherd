# Shepherd

## What this is
Shepherd is a native macOS app for giving your AI coding agent precise, in-context feedback on its work. You annotate source code with inline comments and export a structured review prompt handed back to the agent — so feedback lands as exact instructions paired with the code they refer to, not vague prose.

## Platforms
- **`macos`** — Native macOS app (SwiftUI + TCA). Active — all features. Source code lives at `engineering/apps/macos/`. (The browser-based `web` platform was removed; Shepherd is macOS-only.)

## Tech stack
Swift, SwiftUI, and the Composable Architecture (TCA) for app logic. Syntax highlighting via TreeSitter (13+ languages). Built and tested with the Swift Package Manager (`swift build` / `swift test` in `engineering/apps/macos/`). Targets macOS 14+.

## Standing specs
Cross-cutting specs every builder MUST respect, regardless of feature.

| Spec | Lane / Path | Governs |
|---|---|---|

## How to operate
- **Build a feature:** `/pdeq-kickoff <description>` — product → design → engineering → QA, one lane at a time.
- **Cardinal rule:** markdown first, code second. Change the spec, then the code — never the reverse.
- **Decisions:** append to `decisions-pending.md`; the pre-commit hook merges into `decisions.md` at commit time.
- **Traceability:** update `index.md` when you create or reference a requirement slug.
- **Audits:** `./scripts/audit-traceability.sh` (and lane/structure/temporal/coverage audits). The pre-commit hook runs the blocking ones.
- **Project commands:** `/shepherd <file>` (open one file in the CRPG), `/shepherd-review` (guided multi-file review of the current changeset), `/land` (land changes on main, push, rebase), `/readme` (regenerate README with fresh demo screenshots).
- **Update pdeq:** `/pdeq-update` advances the pinned `.pdeq` submodule, reconciles symlinks, and chains into `/pdeq-migrate` for any pending migrations.
