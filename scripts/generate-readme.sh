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

A native macOS app for giving your AI coding agent feedback on its work. Annotate source code with inline comments, then generate a structured review prompt you hand back to the agent — so your feedback lands as precise, in-context instructions instead of vague prose.

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

AI coding agents produce a lot of code, fast. The bottleneck is *feedback* — telling the agent what to change, precisely, in context. Shepherd makes that loop tight: open the files the agent touched, mark them up like a code review, and export a structured prompt the agent can act on directly.

### Features

- **Load the work** — Paste, upload, or drag files in
- **Syntax highlighting** — ${languages:-13+ languages}
- **Inline comments** — Annotate single lines or ranges, right where the issue is
- **Rendered markdown** — Review docs and specs as formatted output, not raw source
- **Diff view** — Compare the working copy against git HEAD and comment on what changed
- **Structured prompt** — Export your comments paired with the exact code they refer to, ready to hand back to the agent
- **Local** — A native macOS app; your code stays on your machine

### Slash command

Open a file straight from Claude Code:

\`\`\`
/shepherd path/to/file.ts
\`\`\`

Opens the file in Shepherd, ready to annotate. Supports diff view against git HEAD. \`/shepherd-review\` opens the whole changeset of the current branch.

## Install

Requires macOS and the Swift toolchain (Xcode or the Swift command-line tools).

\`\`\`bash
git clone <repo-url>
cd shepherd
./scripts/install-command.sh
\`\`\`

\`install-command.sh\` builds the native \`ShepherdApp\` release binary and installs the \`/shepherd\` and \`/shepherd-review\` slash commands for Claude Code (\`~/.claude/commands/\`), opencode (\`~/.config/opencode/skills/\`), and pi (\`~/.pi/agent/prompts/\`). Updates propagate via \`git pull\`.

## Testing

\`\`\`bash
# App unit/logic tests (Swift)
cd engineering/apps/macos && swift test

# Spec traceability + lane-discipline audits
./scripts/audit-traceability.sh --check
./scripts/audit-lanes.sh
./scripts/audit-structure.sh
\`\`\`

## Project Structure

\`\`\`
shepherd/
├── product/          # PRDs, requirements, acceptance criteria
├── design/           # UI/UX specs, screen definitions
├── engineering/      # Tech specs, architecture, source code
│   └── apps/macos/   # the Shepherd macOS app (SwiftUI + TCA)
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
