---
product-hash: 4d299d7c5ee2df52aa23e260c53010af4520ba647a834ebf37da560ffd5ea957
product-slugs: [AC-sr-all-filtered, AC-sr-auto-open, AC-sr-batch-open, AC-sr-completion-summary, AC-sr-context-in-crpg, AC-sr-excludes-deleted, AC-sr-filters-binary, AC-sr-filters-generated, AC-sr-filters-lockfiles, AC-sr-happy-path, AC-sr-includes-config, AC-sr-install-global, AC-sr-interactive-prompt, AC-sr-invokes-shepherd, AC-sr-list-command, AC-sr-no-changes, AC-sr-not-git-repo, AC-sr-quit-early, AC-sr-skip-file, AC-sr-sorted-file-list, AC-sr-unified-prompt, FR-sr-changeset-detection, FR-sr-changeset-overview, FR-sr-command-file, FR-sr-completion-summary, FR-sr-context-handoff, FR-sr-feedback-collection, FR-sr-file-filtering, FR-sr-file-list-display, FR-sr-git-required, FR-sr-install, FR-sr-iteration-loop, FR-sr-multi-file-launch, FR-sr-per-file-context, FR-sr-priority-ordering, FR-sr-scope-argument, NFR-sr-agent-native, NFR-sr-cross-platform, NFR-sr-no-dependencies, NFR-sr-startup-speed]
---

# Shepherd Review — macOS Technical Spec

> Based on requirements in `../../product/shepherd-review.md`
> See also `../../product/macos/shepherd-review.md` for macOS-specific requirements.
> Based on design in `../../design/macos/shepherd-review.md`

## Technical Approach

`/shepherd-mac-review` is a thin orchestration layer on top of infrastructure that already exists. There is no new application code, no new Swift target, no new model, and no new service. The macOS variant differs from the web variant in only two places:

1. **Command file** — A new `.claude/commands/shepherd-mac-review.md` (and peer opencode skill) that mirrors the web `shepherd-review.md` prompt but invokes `scripts/shepherd-launch-macos.sh` instead of `scripts/shepherd-launch.sh`, and writes the structured review context to a temp JSON file passed via `--context` instead of writing to a session-scoped path served by Vite.
2. **Launcher extension** — `scripts/shepherd-launch-macos.sh` gains an optional `--context <path>` flag. When provided, the launcher reads the file's JSON contents and substitutes them for the existing hard-coded `"reviewContext": null` value in the generated `session.json`.

Everything else is reused unchanged:

- The native binary (`ShepherdApp`) already supports `--session <id>` and already reads `session.json` via `SessionClient.loadSession`.
- `SessionData` and `ReviewContext` Codable models already encode the overall + per-file neutral/review structure (`engineering/apps/macos/Sources/SharedModels/SessionData.swift`, `.../ReviewContext.swift`).
- The multi-file three-column layout, ReviewContextSection (overall), and ReviewContextPanel (per-file) are all implemented for `code-review-prompt` on macOS.
- The Done-writes-`prompt-output.md` round-trip is unchanged from `/shepherd-mac`.
- Session ID derivation (project-root basename) is unchanged.

The agent prompt itself — changeset detection, filtering, priority ordering, neutral/review context generation, brief conversation summary, `AskUserQuestion` interactive prompt, completion summary, feedback action menu — is identical to the web variant in `engineering/web/shepherd-review.md`. **This spec does not duplicate that content; it documents only the macOS-specific delta.**

> Implements: `FR-srm-command-file`, `FR-srm-multi-file-launch`, `FR-srm-context-handoff`, `NFR-srm-no-server`

---

## Components / Files Touched

| File | Change | Purpose |
|---|---|---|
| `.claude/commands/shepherd-mac-review.md` | **MODIFIED** | Claude Code prompt that orchestrates the review and invokes the macOS launcher with `--context`. Extended with the commit-scoped modes (`--branch`/`--commit`/`--range`) and the empty-changeset guard. |
| `.config/opencode/skills/shepherd-mac-review/SKILL.md` | **MODIFIED** | Opencode mirror of the Claude command (kept byte-aligned, including the new scope modes). |
| `scripts/shepherd-launch-macos.sh` | **MODIFIED** | Accept optional `--context <path>` before positional file args; inline its JSON into `session.json.reviewContext`. |
| `scripts/install-command.sh` | **MODIFIED** | Append `"shepherd-mac-review"` to the `COMMANDS` array; update help text and final summary. |
| `engineering/apps/macos/Sources/SharedModels/SessionData.swift` | **UNCHANGED** | Already declares `reviewContext: ReviewContext?`. |
| `engineering/apps/macos/Sources/SharedModels/ReviewContext.swift` | **UNCHANGED** | Already declares `overall` and `files` with neutral/review fields. |
| `engineering/apps/macos/Sources/Dependencies/SessionClient.swift` | **UNCHANGED** | Already loads `session.json` and writes `prompt-output.md`. |
| Native app feature reducers (CodeReview, MultiFile, etc.) | **UNCHANGED** | Already handle multi-file `files[]` and render `reviewContext` in ReviewContextSection / ReviewContextPanel. |

The change footprint is intentionally minimal: two new prompt files, one bash flag, and one array entry. No Swift code is touched.

---

## Why session.json instead of a separate context file

The web variant writes `~/.shepherd/sessions/<id>/review-context.json` and exposes it via a Vite plugin endpoint (`GET /api/review-context?session=<id>`). That indirection exists because the browser can only load same-origin HTTP resources — the dev server has to serve the file.

The macOS app has no server. It already reads everything it needs from a single `session.json` payload at startup, including a `reviewContext: ReviewContext?` field that the existing launcher hard-codes to `null`. Inlining the context into that payload:

- Eliminates a second file read on the native side and a second async load in the UI's startup path.
- Keeps the handoff atomic — the binary either has full context or none, no mid-load race.
- Reuses the `ReviewContext` Codable model that already exists for future expansion.
- Avoids inventing a new file format or a second IPC mechanism.

### Path-key convention

`reviewContext.files` is a string-keyed map. The keys MUST be the same absolute path strings that appear in the corresponding `files[].path` entries of the same `session.json` payload — i.e., whatever `realpath` produced for each positional argument to the launcher. Any other key form (repo-relative, basename, lowercased) is unsupported. The native side matches per-file context to its tab by exact string equality on this key, so QA fixtures (`TC-srm-launcher-context-flag`) and the agent's context generator must both emit absolute paths.

The cost is that the launcher must inline the agent-supplied context into the JSON it generates. That cost is one bash flag and a substring substitution; see Implementation Plan step 1.

---

## Why `--context <file>` rather than a JSON string argv

Two pragmatic reasons:

1. **Argv length and quoting.** A typical multi-file changeset's structured context (overall + per-file neutral + review for, say, 10 files) is several KB of JSON. macOS's `ARG_MAX` is generous (~256KB), but shells in between (zsh quoting, the agent's `Bash` tool, opencode's command runner) all have edge cases with embedded newlines, double quotes, and backslashes. A file path is one argv slot, no escaping required.
2. **Compatibility with the existing single-file launcher contract.** `/shepherd-mac` invokes the launcher as `shepherd-launch-macos.sh <path>` with positional file args only. Putting `--context <path>` ahead of those positional args (parsed by a small `getopts`-style loop) preserves the existing invocation shape — `/shepherd-mac` does not pass `--context` and continues to work unchanged.

The agent writes the context to a temp file (e.g. `mktemp -t shepherd-review-context.XXXXXX.json`) and passes its path to the launcher. The launcher reads the file, validates it parses (best-effort: a quick `python3 -c 'import json,sys; json.load(open(sys.argv[1]))'` or equivalent — on failure we fall back to embedding the raw bytes and let Swift's `Codable` decoder reject it on load), and substitutes its content for the literal `null` in the generated `session.json`. The agent deletes the temp file after launch returns.

---

## Review Scope Modes — git command mapping

`FR-srm-scope-modes` and its sub-requirements are realized entirely in the command prompt (`.claude/commands/shepherd-mac-review.md` and the opencode mirror) — no Swift or launcher change. The agent parses `$ARGUMENTS`, selects a `SCOPE`, and runs the matching git commands. All commands use `git -C "$REPO_ROOT"` per the CWD rule. The changed-file list each mode produces then flows unchanged through filtering, ordering, and context generation.

Argument parsing precedence (first match wins):

1. empty/blank → `working`
2. `--staged` → `staged`
3. `--unstaged` → `unstaged`
4. `--branch [base]` → `branch`, `BASE="${base:-main}"`
5. `--commit [ref]` → `commit`, `REF="${ref:-HEAD}"`
6. `--range <range>` → `range`, `RANGE="<range>"` (must contain `..`)
7. otherwise treat the token as a ref; if `git rev-parse --verify` succeeds → `ref`, else print usage and stop

### Changed-file detection per scope

| SCOPE | Name-status command(s) | Untracked appended? |
|---|---|---|
| `working` | `git diff HEAD --name-status` + `git diff --cached --name-status` | yes (`git ls-files --others --exclude-standard`) |
| `staged` | `git diff --cached --name-status` | no |
| `unstaged` | `git diff --name-status` | yes |
| `ref` | `git diff "$DIFF_REF" --name-status` | yes |
| `branch` | `git diff --name-status "$BASE"...HEAD` | **no** (`FR-srm-commit-mode-no-untracked`) |
| `commit` | `git diff --name-status "$PARENT" "$REF"` | **no** |
| `range` | `git diff --name-status "$RANGE"` | **no** |

### Diff-base command per scope (Step "read all diffs")

The per-file diff command must use the same base as detection so the diffs match the file list:

| SCOPE | Diff command |
|---|---|
| `working` | `git diff HEAD -- <paths>` |
| `staged` | `git diff --cached -- <paths>` |
| `unstaged` | `git diff -- <paths>` |
| `ref` | `git diff "$DIFF_REF" -- <paths>` |
| `branch` | `git diff "$BASE"...HEAD -- <paths>` |
| `commit` | `git diff "$PARENT" "$REF" -- <paths>` |
| `range` | `git diff "$RANGE" -- <paths>` |

### Validation and edge cases

- **`--branch` base resolution** — `git rev-parse --verify "$BASE"` must succeed; otherwise usage/error + stop. The three-dot form (`"$BASE"...HEAD`) diffs from the merge base, so commits landed on `base` after divergence are excluded (`FR-srm-branch-scope`). `git merge-base --is-ancestor`/empty-output is handled by the empty-changeset guard, not a special case.
- **`--commit` parent / root commit** — resolve `REF` (default `HEAD`) via `git rev-parse --verify`. Determine the parent: if `git rev-parse --verify "$REF^" ` succeeds, `PARENT="$REF^"`; if it fails (root commit, no parent), use the canonical empty-tree object `PARENT=4b825dc642cb6eb9a060e54bf8d69288fbee4904` so every line counts as an addition (`FR-srm-commit-scope`). The short-sha and subject for the scope label come from `git show -s --format='%h — %s' "$REF"`.
- **`--range` validation** — the argument must contain `..`. Split on `..`/`...`, `git rev-parse --verify` each endpoint; any failure → usage/error + stop. The range string is then passed verbatim to `git diff` (`FR-srm-range-scope`).
- **Untracked exclusion** — only `working`, `unstaged`, and `ref` append `git ls-files --others --exclude-standard`. The commit scopes and `staged` never do (`FR-srm-commit-mode-no-untracked`).

### Empty-changeset guard and fresh session (`FR-srm-no-blank-window`)

After detection + filtering, the command computes the reviewable-file count. **If it is zero, the command prints the scope-specific message (see design spec "Nothing to Review") and stops — it does not write `session.json`, does not invoke `shepherd-launch-macos.sh`, and no window opens.** This is the deterministic fix for the blank-window symptom: a blank window can only appear if the launcher is invoked with no files or with stale state, and this guard removes the first case.

For the non-empty path, before invoking the launcher the command removes any stale `~/.shepherd/sessions/$SESSION_ID/prompt-output.md` (already done today) and the launcher overwrites `session.json` for the session ID (existing behavior). Together these satisfy clause 2 of `FR-srm-no-blank-window`: a reused window (same project-root basename) always reflects the current invocation.

> Note (operational): the prebuilt `ShepherdApp` binary is produced at install time (`FR-srm-install`). Editing Swift sources without re-running `./scripts/install-command.sh` leaves a stale binary — a separate cause of "the app looks wrong" that is not a `/shepherd-mac-review` behavior bug. The empty-changeset guard above addresses the changeset-driven blank window; binary staleness is resolved by rebuilding.

## Coexistence and Concurrency

Per `FR-srm-coexists` and `AC-srm-coexists`: `/shepherd`, `/shepherd-mac`, `/shepherd-review`, and `/shepherd-mac-review` are independent slash commands installed as separate symlinks. Invoking one has no effect on the others. The user picks per-invocation.

Per `AC-srm-session-isolation`: each invocation derives `SESSION_ID` inside the launcher from the project-root basename (existing logic at `scripts/shepherd-launch-macos.sh:20`). Two concurrent invocations from different working directories produce different session IDs, write to different `~/.shepherd/sessions/<id>/` directories, and open independent native windows. Two concurrent invocations from the **same** working directory share a session ID and follow the existing window-deduplication behavior from `/shepherd-mac` (`AC-crp-macos-window-deduplicate`); the second invocation overwrites the first's `session.json` (including `reviewContext`) and brings the existing window to front.

---

## Implementation Plan

### Step 1: Extend `scripts/shepherd-launch-macos.sh` to accept `--context`

Insert an option-parser ahead of the existing positional-argument loop. Pseudocode:

```bash
CONTEXT_FILE=""
while [ $# -gt 0 ]; do
  case "$1" in
    --context)
      CONTEXT_FILE="$2"
      shift 2
      ;;
    --) shift; break ;;
    -*) echo "Unknown option: $1" >&2; exit 1 ;;
    *) break ;;
  esac
done
```

After validating files and building the `files[]` array, replace the literal `"reviewContext": null` line with:

```bash
if [ -n "$CONTEXT_FILE" ] && [ -r "$CONTEXT_FILE" ]; then
  # Read the file and use it directly as the reviewContext value.
  CONTEXT_JSON=$(cat "$CONTEXT_FILE")
  printf '  "reviewContext": %s\n' "$CONTEXT_JSON"
else
  printf '  "reviewContext": null\n'
fi
```

Validation is best-effort — if the file is missing or unreadable, fall back to `null` and emit a warning to stderr. If the JSON is malformed, the native side's `JSONDecoder` will fail; the existing `SessionClient` error path surfaces that to the agent's stdout-watcher.

The existing `/shepherd-mac` invocation (no `--context` flag) is unaffected: the parser sees no `--context`, leaves `CONTEXT_FILE=""`, and the launcher produces the same `"reviewContext": null` payload it does today.

**Slug coverage**: `FR-srm-multi-file-launch`, `FR-srm-context-handoff`

### Step 2: Create `.claude/commands/shepherd-mac-review.md`

Mirror `.claude/commands/shepherd-review.md` (the web variant) with the following diffs:

1. **Brief summary wording** — replace "Opening N files for review." with "Opening N files in the macOS app for review." per the design spec's Conversation Surface section.
2. **Launcher path and arguments** — instead of `bash "$REPO/scripts/shepherd-launch.sh" <file1> <file2> ...`, invoke:
   ```bash
   CTX=$(mktemp -t shepherd-review-context.XXXXXX.json)
   # ... agent uses Write tool to populate $CTX with the structured review context JSON
   bash "$REPO/scripts/shepherd-launch-macos.sh" --context "$CTX" "<file1>" "<file2>" ...
   rm -f "$CTX"
   ```
   Writing to a temp file path the agent already knows (rather than to `~/.shepherd/sessions/<id>/review-context.json`) avoids the chicken-and-egg of needing the session ID before it's been generated by the launcher. The launcher inlines the JSON into `session.json` at launch time, so the temp file is no longer needed afterward.
3. **No Vite endpoint** — remove any reference to `GET /api/review-context` or the `~/.shepherd/sessions/<id>/review-context.json` path. The macOS native binary reads the context directly from `session.json` via `SessionClient.loadSession`.
4. **Cancel branch** — note that selecting "Cancel" in the `AskUserQuestion` does not close the native window (per `AC-srm-cancel` and `AC-crp-macos-close-last-window`); the user retains the window via standard macOS chrome.

All other prompt content (Step 1 git-repo check, Step 2 repo-root, Step 3 changeset detection, Step 4 filtering, Step 5 priority sort, Step 6 context generation, Step 7 brief summary, Step 8 `AskUserQuestion`, Step 9 completion summary + feedback menu, error-message wording) is copied verbatim from the web variant.

**Slug coverage**: `FR-srm-command-file`, plus inheritance of every shared `FR-sr-*` / `AC-sr-*` slug listed in the macOS product variant's "Apply as-is" section.

### Step 3: Create `.config/opencode/skills/shepherd-mac-review/SKILL.md`

Byte-for-byte mirror of the Claude command file from Step 2, formatted as an opencode skill (matching the structure of the existing `.config/opencode/skills/shepherd-mac/SKILL.md`).

**Slug coverage**: `FR-srm-command-file`

### Step 4: Update `scripts/install-command.sh`

One-line change to the `COMMANDS` array (currently at line 18):

```bash
COMMANDS=("shepherd" "shepherd-review" "shepherd-mac" "shepherd-mac-review")
```

The existing for-loop at lines 94–100 already handles both Claude Code and opencode symlinks for every entry in the array — no other changes to the symlink logic are needed.

**Slug coverage**: `FR-srm-install`, `AC-srm-install-symlink`, `AC-srm-install-git-pull`

### Step 5: Update help text and final summary in `install-command.sh`

The `--help` block (lines 25–35) and the final "Installed:" summary (lines 134–140) currently mention `/shepherd, /shepherd-review, /shepherd-mac`. Add `/shepherd-mac-review` to both. The `AC-srm-install-degraded` branch — when Swift is missing, both `/shepherd-mac` and `/shepherd-mac-review` are unavailable but the web commands still install — is already handled by the existing `MAC_APP_DIR` block at lines 115–131; the new command transparently inherits that degraded-install behavior because it depends on the same prebuilt binary.

**Symlink behavior on degraded install.** The symlinks for `/shepherd-mac` and `/shepherd-mac-review` are still created when the toolchain is missing — only the prebuild step is skipped, with a stderr warning. At runtime, the launcher's existing missing-binary check (`shepherd-launch-macos.sh:82–86`) surfaces a clear "binary not found" error and exits non-zero, which the slash command surfaces to the user. This is the path exercised by `TC-srm-binary-missing-error` and is the implementation answer to QA's `TC-srm-install-degraded-no-swift` step 4 (the symlink IS present; the binary is what's missing).

**Slug coverage**: `FR-srm-install`, `AC-srm-install-degraded`

### Step 6: Manual smoke test

On a branch with several modified files of mixed types (a TS source file, a config file, a lockfile, a `.png`):

1. Run `./scripts/install-command.sh --force` to refresh symlinks.
2. Confirm `~/.claude/commands/shepherd-mac-review.md` and `~/.config/opencode/skills/shepherd-mac-review/SKILL.md` exist as symlinks.
3. From a Claude Code or opencode session, invoke `/shepherd-mac-review`.
4. Verify: brief summary mentions the macOS app and correct file count; lockfile and PNG are excluded; the native window opens with one tab per reviewable file in priority order; the inspector shows the overall neutral + review sections; switching tabs swaps the per-file ReviewContextPanel; no browser opens; no Vite server starts.
5. Click Done in the native window with comments on 1–2 files; select "Added comments" in the agent's `AskUserQuestion`; verify the agent reads `~/.shepherd/sessions/<id>/prompt-output.md` and presents the standard apply/discuss/save/nothing menu.
6. Repeat with no comments and "Reviewed, no comments"; repeat with "Cancel"; repeat from a non-git directory and a branch with no diffs to confirm error messages match the web variant.

---

## Code Map

Only macOS-specific functional requirements appear here. Shared `FR-sr-*` slugs are covered by the prompt content inherited from `.claude/commands/shepherd-review.md` and tracked in `engineering/web/shepherd-review.md`'s Code Map; this spec does not duplicate them.

| Slug | Planned location | Status |
|---|---|---|
| `FR-srm-coexists` | scripts/install-command.sh | implemented |
| `FR-srm-command-file` | .claude/commands/shepherd-mac-review.md; .config/opencode/skills/shepherd-mac-review/SKILL.md | implemented |
| `FR-srm-multi-file-launch` | scripts/shepherd-launch-macos.sh; .claude/commands/shepherd-mac-review.md | implemented |
| `FR-srm-context-handoff` | scripts/shepherd-launch-macos.sh; .claude/commands/shepherd-mac-review.md | implemented |
| `FR-srm-install` | scripts/install-command.sh | implemented |
| `FR-srm-scope-modes` | .claude/commands/shepherd-mac-review.md; .config/opencode/skills/shepherd-mac-review/SKILL.md | implemented |
| `FR-srm-branch-scope` | .claude/commands/shepherd-mac-review.md; .config/opencode/skills/shepherd-mac-review/SKILL.md | implemented |
| `FR-srm-commit-scope` | .claude/commands/shepherd-mac-review.md; .config/opencode/skills/shepherd-mac-review/SKILL.md | implemented |
| `FR-srm-range-scope` | .claude/commands/shepherd-mac-review.md; .config/opencode/skills/shepherd-mac-review/SKILL.md | implemented |
| `FR-srm-commit-mode-no-untracked` | .claude/commands/shepherd-mac-review.md; .config/opencode/skills/shepherd-mac-review/SKILL.md | implemented |
| `FR-srm-no-blank-window` | .claude/commands/shepherd-mac-review.md; .config/opencode/skills/shepherd-mac-review/SKILL.md | implemented |

All rows are `implemented`: the launcher's `--context` flag, both prompt files (including the scope-mode parsing, git command mapping, and empty-changeset guard), and the install-script `COMMANDS` array entry are in place, with inline `Implements:` markers citing the macOS-specific FR slugs. The scope-mode FRs live in the command prompt files only — no Swift or launcher change.

---

## Performance

`NFR-srm-launch-budget` constrains end-to-end startup to the existing macOS launch budget plus agent context-generation time. Breakdown:

| Phase | Expected time | Notes |
|---|---|---|
| Git repo / changeset / filter / sort | < 100 ms | Identical to web variant; same git commands. |
| Agent context generation | Bounded by agent reasoning | Dominant term for 5–20 files; outside this command's control. Same as web variant. |
| Temp context file write | ~5 ms | Single `Write` tool call; KB-scale JSON. |
| Launcher: validate + build session.json | ~50 ms | One `cat` per file plus the new `cat $CONTEXT_FILE` substitution. |
| Native binary cold launch | ≤ 1 s | Per `NFR-crp-macos-launch-time` (existing `/shepherd-mac` budget). |
| Native binary warm launch | ~200 ms | Existing window-deduplicate path. |
| **Total to window-on-screen** | Well under `NFR-srm-launch-budget` | The macOS path avoids both the Vite server startup (~1–3 s warm, longer cold) and the browser launch the web variant pays for. |

The `--context` flag adds a single file read in the launcher and a single substring substitution; the cost is dominated by the existing `cat | json_escape` pass over each file's contents.

---

## Out of Scope

- **Code-signing and notarization.** Inherited from `/shepherd-mac`'s deferred items. The binary continues to run unsigned; first-launch Gatekeeper prompt is acceptable.
- **Auto-rebuild on `git pull`.** Users re-run `./scripts/install-command.sh` to refresh the prebuilt binary; same policy as `/shepherd-mac`.
- **Web ↔ native fallback.** Per the macOS product variant's Open Question #3, no silent fallback if the binary is missing. The launcher emits its existing "binary not found" error and the agent stops; the user runs `/shepherd-review` (web) explicitly if they want the browser path.
- **Resumable sessions** and **custom exclusion patterns** — both deferred at the shared product level; no macOS-specific behavior here.

---

## Requirement Traceability

### macOS-specific (from `product/macos/shepherd-review.md`)

| Slug | Engineering coverage |
|---|---|
| `FR-srm-coexists` | Coexistence and Concurrency; install-command.sh `COMMANDS` array entry |
| `FR-srm-command-file` | Components / Files Touched; Implementation Plan steps 2–3 |
| `FR-srm-multi-file-launch` | Technical Approach; Why session.json; Implementation Plan step 1 |
| `FR-srm-context-handoff` | Technical Approach; Why session.json; Why `--context <file>`; Implementation Plan step 1 |
| `FR-srm-install` | Components / Files Touched; Implementation Plan steps 4–5 |
| `FR-srm-scope-modes` | Review Scope Modes — git command mapping (argument parsing precedence; detection table) |
| `FR-srm-branch-scope` | Review Scope Modes (`branch` row; `"$BASE"...HEAD`; base resolution) |
| `FR-srm-commit-scope` | Review Scope Modes (`commit` row; parent / root-commit empty-tree handling) |
| `FR-srm-range-scope` | Review Scope Modes (`range` row; `..` validation) |
| `FR-srm-commit-mode-no-untracked` | Review Scope Modes (untracked-append column / exclusion note) |
| `FR-srm-no-blank-window` | Review Scope Modes (empty-changeset guard and fresh session) |
| `NFR-srm-launch-budget` | Performance |
| `NFR-srm-no-server` | Technical Approach; Why session.json (no Vite endpoint) |
| `NFR-srm-platform-restriction` | Out of Scope (no fallback); install script Swift-toolchain check inherits the degraded branch |
| `AC-srm-coexists` | Coexistence and Concurrency |
| `AC-srm-batch-open-native` | Implementation Plan steps 1–2; Performance (no browser, no Vite) |
| `AC-srm-no-server` | Technical Approach; Why session.json |
| `AC-srm-context-in-app` | Why session.json (inlined into `session.json.reviewContext` for native rendering) |
| `AC-srm-session-isolation` | Coexistence and Concurrency |
| `AC-srm-prompt-roundtrip` | Implementation Plan step 6; existing SessionClient round-trip unchanged |
| `AC-srm-cancel` | Implementation Plan step 2 (Cancel branch note) |
| `AC-srm-install-symlink` | Implementation Plan step 4 |
| `AC-srm-install-degraded` | Implementation Plan step 5; existing toolchain check inherited |
| `AC-srm-install-git-pull` | Implementation Plan step 4 (symlink-based install) |

### Shared (from `product/shepherd-review.md`) — applied as-is on macOS

These slugs are covered by the prompt content inherited from the web variant. The macOS engineering work does not modify their behavior; it only changes the launcher invoked at the end of the prompt and how context is delivered.

| Slug | Coverage on macOS |
|---|---|
| `FR-sr-changeset-detection`, `FR-sr-file-filtering`, `FR-sr-priority-ordering`, `FR-sr-changeset-overview`, `FR-sr-per-file-context`, `FR-sr-file-list-display`, `FR-sr-iteration-loop`, `FR-sr-feedback-collection`, `FR-sr-completion-summary`, `FR-sr-scope-argument`, `FR-sr-git-required` | Inherited verbatim by the new `.claude/commands/shepherd-mac-review.md` from the web command's prompt content. See `engineering/web/shepherd-review.md` Code Map for primary coverage. |
| `FR-sr-command-file` | Supplanted by `FR-srm-command-file`; the macOS variant uses a separate command file. |
| `FR-sr-multi-file-launch` | Supplanted by `FR-srm-multi-file-launch`; the macOS variant launches via `session.json` rather than URL parameters. |
| `FR-sr-context-handoff` | Supplanted by `FR-srm-context-handoff`; context is embedded in `session.json` rather than served via Vite. |
| `FR-sr-install` | Supplanted by `FR-srm-install`; same install script extended with one more entry. |
| `NFR-sr-startup-speed` | Performance section (well within budget). |
| `NFR-sr-no-dependencies` | No new packages, no new binaries — only the existing prebuilt `ShepherdApp` and standard shell tools. |
| `NFR-sr-agent-native` | The launcher invocation is a standard `Bash` tool call; no new process model. |
| `NFR-sr-cross-platform` | Not a constraint here — the macOS variant is macOS-only by design (`NFR-srm-platform-restriction`). The git commands themselves remain cross-platform. |
| `AC-sr-happy-path`, `AC-sr-auto-open`, `AC-sr-interactive-prompt`, `AC-sr-completion-summary`, `AC-sr-skip-file`, `AC-sr-quit-early`, `AC-sr-no-changes`, `AC-sr-not-git-repo`, `AC-sr-all-filtered`, `AC-sr-list-command`, `AC-sr-sorted-file-list`, `AC-sr-unified-prompt`, `AC-sr-filters-lockfiles`, `AC-sr-filters-generated`, `AC-sr-filters-binary`, `AC-sr-includes-config`, `AC-sr-excludes-deleted` | Inherited by the new command file's prompt content. Covered via the smoke test in Implementation Plan step 6. |
| `AC-sr-batch-open` | Supplanted by `AC-srm-batch-open-native` (native window with tabs, no browser). |
| `AC-sr-context-in-crpg` | Supplanted by `AC-srm-context-in-app`. |
| `AC-sr-invokes-shepherd` | Implementation Plan step 2: single `shepherd-launch-macos.sh` invocation with all paths plus `--context`. |
| `AC-sr-install-global` | Supplanted by `AC-srm-install-symlink` and `AC-srm-install-git-pull`. |
