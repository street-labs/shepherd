#!/usr/bin/env bash
#
# Generates README.md from project specs and current state.
# Deterministic: same inputs → same output. Only updates if content changes.
#
# Usage:
#   ./scripts/generate-readme.sh           # Generate and write if changed
#   ./scripts/generate-readme.sh --check   # Exit 1 if README is stale (for CI)
#
# Called by:
#   - Pre-commit hook (auto-stages if changed)
#   - /readme slash command

set -uo pipefail

ROOT="$(git rev-parse --show-toplevel 2>/dev/null || dirname "$(dirname "$0")")"
README="$ROOT/README.md"
WEB_APP="$ROOT/engineering/apps/web"
DEMOS_DIR="$ROOT/docs/demos"
CHECK_ONLY=false

if [[ "${1:-}" == "--check" ]]; then
  CHECK_ONLY=true
fi

# ─── Extract data from project ────────────────────────────────────

# Count features from product specs (FR- slugs)
feature_count=$(grep -rho '`FR-[a-z0-9-]*`' "$ROOT/product/"*.md 2>/dev/null | sort -u | wc -l | tr -d ' ')

# Count requirement slugs in index
slug_count=$(grep -c '^### `' "$ROOT/index.md" 2>/dev/null || echo 0)

# Count test files and tests
unit_test_count=0
e2e_test_count=0
if [ -d "$WEB_APP/src" ]; then
  # Get actual test count from vitest
  test_output=$(cd "$WEB_APP" && npm run test 2>&1 || true)
  unit_test_count=$(echo "$test_output" | grep 'Tests' | grep -o '[0-9]* passed' | grep -o '[0-9]*' || echo 0)

  # Count E2E tests by counting test() calls in spec files
  if [ -d "$WEB_APP/e2e" ]; then
    e2e_test_count=$(grep -r "test(" "$WEB_APP/e2e/"*.spec.ts 2>/dev/null | wc -l | tr -d ' ')
  fi
fi

# Detect available screenshots
screenshots=""
if [ -d "$DEMOS_DIR" ]; then
  screenshots=$(ls "$DEMOS_DIR"/*.png 2>/dev/null | sort || true)
fi

# Get languages from languageDetect.ts
languages=""
if [ -f "$WEB_APP/src/lib/languageDetect.ts" ]; then
  languages=$(grep -o "'[a-z]*'" "$WEB_APP/src/lib/languageDetect.ts" 2>/dev/null | tr -d "'" | sort -u | paste -sd, - | sed 's/,/, /g')
fi

# ─── Generate README content ──────────────────────────────────────

generate_readme() {
cat << 'HEADER'
# Shepherd

A multi-agent coordination framework for building software through structured, spec-driven development. Markdown specs are the source of truth; code is derived from them.

HEADER

# Demo screenshots section
if [ -n "$screenshots" ]; then
cat << 'DEMO_HEADER'
## Demo

DEMO_HEADER
  for img in $screenshots; do
    local basename_file
    basename_file=$(basename "$img" .png)
    # Convert filename to title: "01-empty-state" -> "Empty State"
    local title
    title=$(echo "$basename_file" | sed 's/^[0-9]*-//' | sed 's/-/ /g' | awk '{for(i=1;i<=NF;i++) $i=toupper(substr($i,1,1)) tolower(substr($i,2))}1')
    echo "### $title"
    echo ""
    echo "![${title}](docs/demos/$(basename "$img"))"
    echo ""
  done
fi

cat << FEATURES
## What It Does

**Shepherd** orchestrates work across four functional areas — Product, Design, Engineering, and QA — using slug-based requirement IDs and a traceability index that maps every requirement to its design spec, implementation, and test cases.

The first app built with Shepherd is the **Code Review Prompt Generator (CRPG)**, a client-side web app that lets you annotate source code with inline comments and generate structured prompts for AI code review.

### CRPG Features

- **File loading** — Paste, upload, or drag-and-drop source files
- **Syntax highlighting** — ${languages:-13+ languages} via Shiki
- **Inline comments** — Click line numbers to annotate single lines or ranges
- **Prompt generation** — Structured output with code snippets paired with your comments
- **Diff view** — Compare working copy vs git HEAD, comment on changes
- **Clipboard copy** — One-click copy of generated prompts
- **Performance** — Virtualized scrolling for files up to 10,000 lines
- **Privacy** — Fully client-side, no data leaves the browser

### Slash Command

Launch the CRPG directly from Claude Code:

\`\`\`
/shepherd path/to/file.ts
\`\`\`

Opens the CRPG in your browser with the file already loaded. Supports diff view against git HEAD.

## Install

### Quick install (via \`sq run\`)

\`\`\`bash
sq run personal-lstreet-shepherd install --full-clone
\`\`\`

This clones the repo, installs dependencies, and symlinks the \`/shepherd\` and \`/shepherd-review\` slash commands into \`~/.claude/commands/\` so they're available in any repo.

### Manual install

\`\`\`bash
# Clone the repo
git clone <repo-url>
cd shepherd

# Install dependencies
cd engineering/apps/web
npm install

# Start dev server
npm run dev
\`\`\`

### Install the Claude Code slash command

\`\`\`bash
# Available automatically when working inside this repo.
# To install globally:
./scripts/install-command.sh
\`\`\`

## Testing

\`\`\`bash
cd engineering/apps/web

# Unit and integration tests (${unit_test_count} tests)
npm run test

# E2E tests (Playwright, ${e2e_test_count} tests)
npm run test:e2e

# Traceability audit
../../scripts/audit-traceability.sh
\`\`\`

## Project Structure

\`\`\`
shepherd/
├── product/          # PRDs, requirements, acceptance criteria
├── design/           # UI/UX specs, screen definitions
├── engineering/      # Tech specs, architecture, source code
│   └── apps/web/     # CRPG web application (React + Vite)
├── qa/               # Test plans, test cases, coverage matrices
├── scripts/          # Automation (traceability audit, test runner, demos)
├── docs/demos/       # README screenshots (captured via Playwright)
├── index.md          # Traceability index (slug → all references)
├── glossary.md       # Shared vocabulary
└── decisions.md      # Append-only decision log
\`\`\`

## How It Works

1. **Product** defines requirements with slug-based IDs (\`FR-\`, \`NFR-\`, \`AC-\`)
2. **Design** creates specs that satisfy those requirements
3. **Engineering** implements the design (specs first, then code)
4. **QA** writes and executes test plans covering acceptance criteria
5. The **traceability index** maps every slug to everywhere it's referenced
6. A **pre-commit hook** enforces index integrity and runs tests

Changes always flow: **markdown → code**, never code → markdown.

## Stats

| Metric | Count |
|--------|-------|
| Requirement slugs | ${slug_count} |
| Unit/integration tests | ${unit_test_count} |
| E2E tests | ${e2e_test_count} |
| Product features | ${feature_count} |
FEATURES
}

# ─── Compare and write ────────────────────────────────────────────

new_content=$(generate_readme)

if [ -f "$README" ]; then
  existing_content=$(cat "$README")
  if [ "$new_content" = "$existing_content" ]; then
    echo "README.md is up to date."
    exit 0
  fi
fi

if $CHECK_ONLY; then
  echo "README.md is stale. Run ./scripts/generate-readme.sh to update."
  exit 1
fi

echo "$new_content" > "$README"
echo "README.md updated."
