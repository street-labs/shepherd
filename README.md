# Shepherd

A multi-agent coordination framework for building software through structured, spec-driven development. Markdown specs are the source of truth; code is derived from them.

## Demo

### Empty State

![Empty State](docs/demos/01-empty-state.png)

### File Loaded

![File Loaded](docs/demos/02-file-loaded.png)

### With Comments

![With Comments](docs/demos/03-with-comments.png)

### Prompt Generated

![Prompt Generated](docs/demos/04-prompt-generated.png)

## What It Does

**Shepherd** orchestrates work across four functional areas — Product, Design, Engineering, and QA — using slug-based requirement IDs and a traceability index that maps every requirement to its design spec, implementation, and test cases.

The first app built with Shepherd is the **Code Review Prompt Generator (CRPG)**, a native macOS app (SwiftUI + TCA) that lets you annotate source code with inline comments and generate structured prompts for AI code review.

### CRPG Features

- **File loading** — Open one or more source files; multi-file review with a file browser
- **Syntax highlighting** — c, cpp, css, go, html, java, javascript, json, markdown, plaintext, python, rust, typescript, yaml via swift-tree-sitter
- **Inline comments** — Click line numbers to annotate single lines or ranges
- **Prompt generation** — Structured output with code snippets paired with your comments
- **Review context** — Per-file and overall context (neutral + agent review) shown alongside the diff
- **Clipboard copy** — One-click copy of generated prompts
- **Privacy** — Runs locally; no data leaves your machine

### Slash Commands

Launch the CRPG directly from Claude Code or opencode:

```
/shepherd-mac path/to/file.ts     # open a single file
/shepherd-mac-review              # guided multi-file review of your changes
```

Opens the native macOS app with the file(s) already loaded.

## Install

### Quick install (via `sq run`)

```bash
sq run personal-lstreet-shepherd install --full-clone
```

This clones the repo and symlinks the `/shepherd-mac` and `/shepherd-mac-review` slash commands into `~/.claude/commands/` (and the opencode skills) so they're available in any repo.

### Manual install

```bash
# Clone the repo
git clone <repo-url>
cd shepherd

# Symlink the slash commands and build the macOS app binary
./scripts/install-command.sh
```

`install-command.sh` builds the native `ShepherdApp` release binary (requires the Swift toolchain) and symlinks the slash commands for Claude Code and opencode. Updates propagate via `git pull`.

## Testing

```bash
# macOS app tests
./scripts/run-tests.sh        # or: just test

# Traceability audit
./scripts/audit-traceability.sh
```

## Project Structure

```
shepherd/
├── product/          # PRDs, requirements, acceptance criteria
├── design/           # UI/UX specs, screen definitions
├── engineering/      # Tech specs, architecture, source code
│   └── apps/macos/   # CRPG native macOS app (SwiftUI + TCA)
├── qa/               # Test plans, test cases, coverage matrices
├── scripts/          # Automation (traceability audit, test runner, demos)
├── docs/demos/       # README screenshots (captured via Playwright)
├── index.md          # Traceability index (slug → all references)
├── glossary.md       # Shared vocabulary
└── decisions.md      # Append-only decision log
```

## How It Works

1. **Product** defines requirements with slug-based IDs (`FR-`, `NFR-`, `AC-`)
2. **Design** creates specs that satisfy those requirements
3. **Engineering** implements the design (specs first, then code)
4. **QA** writes and executes test plans covering acceptance criteria
5. The **traceability index** maps every slug to everywhere it's referenced
6. A **pre-commit hook** enforces index integrity and runs tests

Changes always flow: **markdown → code**, never code → markdown.

## Stats

| Metric | Count |
|--------|-------|
| Requirement slugs | 298 |
| Unit/integration tests | 237 |
| E2E tests | 9 |
| Product features | 104 |
