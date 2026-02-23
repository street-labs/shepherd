# Shepherd Review -- Technical Spec

> Based on requirements in `../product/shepherd-review.md`
> Based on design in `../design/shepherd-review.md`

## Technical Approach

The `/shepherd-review` command is a Claude Code custom command file -- a markdown prompt that instructs the AI agent to orchestrate a multi-file code review workflow. There is no compiled code, no new npm packages, no server-side logic, and no binaries. The core implementation is the prompt file at `.claude/commands/shepherd-review.md`, plus targeted updates to `scripts/shepherd-launch.sh` (multi-file support), `engineering/apps/web/src/hooks/useFileFromUrl.ts` (multi-file URL loading), and `scripts/install-command.sh` (global installation).

The agent executes the prompt by running git commands via `Bash` tool calls, applying filtering logic described in the prompt, reading diffs for context, presenting a changeset overview with per-file summaries, and invoking `shepherd-launch.sh` with all file paths to open a single CRPG session with one tab per file. The iteration loop is replaced with a batch-open + wait-for-done model: all files open at once, the user reviews freely in the CRPG, clicks "Done" to generate a unified multi-file prompt, and the prompt output is returned to the agent via the existing `~/.shepherd/prompt-output.md` file-watcher mechanism. Session state is minimal -- just the file list, counts, and the prompt output.

> Implements: `FR-sr-command-file`, `FR-sr-multi-file-launch`, `NFR-sr-no-dependencies`, `NFR-sr-agent-native`

### Key Technical Decisions

| Decision | Choice | Rationale |
|---|---|---|
| Implementation mechanism | Claude Code custom command (`.claude/commands/shepherd-review.md`) | Same pattern as the existing `/shepherd` command. Zero code, zero dependencies. The agent interprets the prompt and executes shell commands. |
| State management | Agent conversation context (minimal) | The session state is the file list, changeset/excluded/reviewable counts, and the prompt output from the CRPG. No iteration index, no reviewed/skipped counters. Each invocation starts fresh. |
| File filtering | Prompt-embedded pattern lists | The exclusion rules are written directly in the command file as lists of patterns. The agent applies them by evaluating file paths -- no regex engine or external tool needed. |
| Git operations | `git rev-parse`, `git merge-base`, `git diff --name-status` | Standard cross-platform git commands. No git libraries, no wrappers. The agent runs them via `Bash` and parses the output. |
| Batch file open | Invokes `shepherd-launch.sh` with all file paths | The agent calls `shepherd-launch.sh` with multiple absolute paths. The script constructs a URL with multiple `file` query parameters and opens a single CRPG session with one tab per file. Reuses all existing CRPG infrastructure. |
| Prompt return | File-watcher on `~/.shepherd/prompt-output.md` | After opening the browser, the agent cleans up stale prompt output and polls for `~/.shepherd/prompt-output.md` to appear. Same mechanism as `/shepherd`. |

---

## Command File Design

> Implements: `FR-sr-command-file`, `FR-sr-scope-argument`

### File: `.claude/commands/shepherd-review.md`

This is a Claude Code custom slash command file. When a user types `/shepherd-review` (optionally with `--staged` or `--unstaged`), Claude Code reads this file, substitutes `$ARGUMENTS`, and the agent follows the instructions as a prompt.

The command file is structured as a sequential set of instructions that the agent follows. The prompt must be precise enough that the agent produces the exact output formats defined in the design spec, runs the correct git commands, applies the correct filtering rules, and handles all user input variations.

### Scope Argument (`FR-sr-scope-argument`)

The command uses `$ARGUMENTS` to accept an optional scope flag:

| Argument | Git Commands | What it captures |
|---|---|---|
| _(none)_ | `git diff --name-status <MERGE_BASE>` + `git ls-files --others --exclude-standard` | Everything different from main: committed branch changes + staged + unstaged + untracked |
| `--staged` | `git diff --name-status --cached <MERGE_BASE>` | Only staged files (what will be committed) |
| `--unstaged` | `git diff --name-status HEAD` + `git ls-files --others --exclude-standard` | Only unstaged changes + untracked files (what's not yet staged) |

If an unrecognized argument is given, the agent displays a usage message and stops.

### Prompt Structure

The command file is organized into these sections:

1. **Header** -- Command name, allowed tools, argument handling.
2. **Step 1: Git repository check** -- Instructions to verify the working directory is a git repo.
3. **Step 2: Get repository root** -- Run `git rev-parse --show-toplevel`.
4. **Step 3: Parse scope argument and changeset detection** -- Determine which git commands to run based on `$ARGUMENTS`, find the merge base, run the appropriate `git diff`.
5. **Step 4: Filtering** -- The complete exclusion pattern list and instructions to apply them.
6. **Step 5: Read diffs for context** -- Read the diffs for all reviewable files to generate per-file summaries.
7. **Step 6: Changeset overview and file list** -- Present the changeset overview with per-file summaries, the prioritized file list, and ask to proceed ("go" or "quit").
8. **Step 7: Batch-open all files** -- Invoke `shepherd-launch.sh` with all file paths, clean up stale `~/.shepherd/prompt-output.md`, wait for the prompt-output file to appear (file-watcher pattern).
9. **Step 8: Completion summary and feedback handoff** -- Display summary (total opened, filtered, files with comments) and present the feedback action options (apply, discuss, save, nothing).
10. **Error messages** -- Exact wording for each error case.

### Allowed Tools

The command file declares `Allowed tools: Bash, Read` at the top. The agent needs `Bash` to run git commands and invoke `shepherd-launch.sh`. It needs `Read` to read file diffs for generating per-file context summaries in the changeset overview. It does not need `Write`, `Edit`, or any other tools.

---

## Git Commands

> Implements: `FR-sr-changeset-detection`, `FR-sr-git-required`, `NFR-sr-startup-speed`, `NFR-sr-cross-platform`

The command instructs the agent to run three git commands in sequence. Each command is specified exactly so the agent produces deterministic results.

### Command 1: Verify git repository

```bash
git rev-parse --is-inside-work-tree 2>/dev/null
```

- **Success**: Output is `true`. Proceed to the next command.
- **Failure**: Non-zero exit code. The agent outputs the error message: `Not a git repository. /shepherd-review must be run from within a git repo.` and stops.

> Implements: `FR-sr-git-required`, `AC-sr-not-git-repo`

### Command 2: Find the merge base

```bash
git merge-base HEAD main 2>/dev/null
```

- **Success**: Output is a commit SHA (e.g., `a1b2c3d4...`). Store this as `MERGE_BASE`.
- **Failure**: Non-zero exit code. This happens when:
  - The branch `main` does not exist.
  - HEAD is `main` with no divergence (though `merge-base` of `main` and `main` returns `main`'s HEAD, which is fine -- the subsequent diff will be empty).
  - There is no common ancestor.

If the merge-base command fails, the agent outputs: `No changes found relative to main.` and stops.

**Edge case -- HEAD is main**: If the user is on `main`, `git merge-base HEAD main` succeeds (it returns the HEAD commit). The subsequent `git diff` between HEAD and HEAD produces no output. The agent detects the empty diff and outputs: `No changes found relative to main.`

> Implements: `FR-sr-changeset-detection`, `AC-sr-no-changes`

### Command 3: Get changed files with status (working tree diff)

```bash
git diff --name-status <MERGE_BASE>
```

Note: this uses **no dots** (not `...HEAD`). The no-dots form compares the merge base commit directly to the working tree, which captures all changes: committed changes on the branch, staged changes, and unstaged modifications. This is the correct comparison for local code review — the developer wants to see everything that differs from main, including work-in-progress.

**Output format**: Each line is `<status-code>\t<path>` (or `<status-code>\t<old-path>\t<new-path>` for renames). Example:

```
M	src/app.tsx
A	src/utils/helpers.ts
D	old-file.ts
R100	src/helpers.ts	src/utils/helpers.ts
```

The agent parses this output line by line:

| Status Code | Meaning | Action |
|---|---|---|
| `M` | Modified | Include; change type = `modified` |
| `A` | Added | Include; change type = `added` |
| `D` | Deleted | Exclude entirely (`AC-sr-excludes-deleted`) |
| `R` (with score, e.g., `R100`) | Renamed | Include using new path; change type = `renamed from <old-path>` |
| `C` | Copied | Include; change type = `added` |
| `T` | Type changed | Include; change type = `modified` |

### Command 4: Get untracked new files

```bash
git ls-files --others --exclude-standard
```

This lists files that are new (not yet `git add`ed) but not gitignored. Each file is included with change type `added`. These are merged with the diff output from Command 3, deduplicating by path if needed.

**If both the diff output and untracked files list are empty**, the agent outputs: `No changes found relative to main.` and stops.

### Getting the repository root

The agent also needs the repository root to construct absolute paths for `shepherd-launch.sh` invocations:

```bash
git rev-parse --show-toplevel
```

This returns the absolute path to the repository root (e.g., `/Users/dev/my-project`). The agent stores this and uses it later to construct `<repo-root>/<relative-path>` for each file when invoking `shepherd-launch.sh`.

> Implements: `AC-sr-invokes-shepherd`

### Performance

All git commands are fast. `git rev-parse` and `git merge-base` are near-instant. `git diff --name-status` against a commit reads only tree objects. `git ls-files --others` scans the working directory but is optimized by git's filesystem cache. Total time is well under the 3-second budget for `NFR-sr-startup-speed`.

### Cross-platform compatibility

The git commands used (`rev-parse`, `merge-base`, `diff --name-status`) are standard git operations available on all platforms (macOS, Linux, Windows via Git Bash or WSL). No platform-specific flags or shell features are used. This satisfies `NFR-sr-cross-platform`.

---

## Filtering Logic

> Implements: `FR-sr-file-filtering`, `AC-sr-filters-lockfiles`, `AC-sr-filters-generated`, `AC-sr-filters-binary`, `AC-sr-includes-config`

After parsing the git diff output, the agent filters the file list by evaluating each file's relative path against exclusion patterns. The filtering is path-based only -- no file contents are read.

### Exclusion Rules

The following patterns are embedded in the command file prompt. A file is excluded if it matches **any** exclusion rule.

**Lockfiles** (exact filename match):

- `package-lock.json`
- `yarn.lock`
- `pnpm-lock.yaml`
- `Gemfile.lock`
- `Cargo.lock`
- `poetry.lock`
- `composer.lock`
- `go.sum`
- `flake.lock`
- `Pipfile.lock`

**Generated files** (directory or extension match):

- Files in directories: `dist/`, `build/`, `out/`, `.next/`, `coverage/`, `__generated__/`, `node_modules/`
  - Match rule: path contains `/<dirname>/` or starts with `<dirname>/`
- Extensions: `.min.js`, `.min.css`, `.map`, `.d.ts`
  - Match rule: path ends with the extension
- Filename patterns: `*.generated.*`, `*.auto.*`
  - Match rule: the filename (basename) contains `.generated.` or `.auto.`

**Binary files** (extension match):

- Images: `.png`, `.jpg`, `.jpeg`, `.gif`, `.ico`, `.svg`, `.webp`
- Fonts: `.woff`, `.woff2`, `.ttf`, `.eot`
- Media: `.mp3`, `.mp4`, `.webm`, `.avi`
- Archives: `.zip`, `.tar`, `.gz`, `.bz2`, `.7z`
- Documents: `.pdf`
- Executables: `.exe`, `.dll`, `.so`, `.dylib`

**IDE/editor files**:

- Files in `.idea/` directory
- `.vscode/settings.json`, `.vscode/launch.json`
- `.DS_Store`

**Snapshot files**:

- Extensions: `.snap`, `.snapshot`

### Inclusion Rules (Override)

The following files are **explicitly included** even if they might look like "config noise." These are NOT filtered out even though they could match a broad heuristic:

- Build config: `vite.config.*`, `webpack.config.*`, `tsconfig.json`, `tsconfig.*.json`, `jest.config.*`, `vitest.config.*`, `eslint.config.*`, `.eslintrc.*`, `babel.config.*`, `rollup.config.*`, `esbuild.config.*`
- Project config: `package.json`, `Cargo.toml`, `go.mod`, `pyproject.toml`, `Makefile`, `Dockerfile`, `docker-compose.*`, `.env.example`
- CI config: files in `.github/workflows/`, `.gitlab-ci.yml`, `Jenkinsfile`
- Command files: `.claude/commands/*.md`

In practice, these inclusion rules are only needed if a future exclusion rule might accidentally catch them. Currently, none of the exclusion rules match these files. The inclusion list is documented in the prompt as a safeguard and to make the agent's decision-making explicit.

### Filtering Implementation in the Prompt

The command file lists these rules as a reference table and instructs the agent to:

1. Start with the full list of non-deleted files from the git diff.
2. For each file, check if its path matches any exclusion rule.
3. If it matches, mark it as excluded and increment the exclusion counter.
4. If it does not match any exclusion rule, include it in the review list.
5. After filtering, if zero files remain, output the "all filtered" error message and stop.

The agent performs this filtering in its reasoning -- it does not execute shell commands for filtering. The prompt gives the agent the complete rule set, and the agent applies it to each file path.

### Counting

- `total_files` = all files from git diff (excluding deleted files)
- `excluded_files` = files that matched an exclusion rule
- `reviewable_files` = `total_files - excluded_files`

These counts are used in the file list display and the completion summary.

> Implements: `AC-sr-all-filtered`

---

## Sorting

> Implements: `AC-sr-sorted-file-list`, `FR-sr-priority-ordering`

After filtering, the agent sorts the file list by review importance rather than alphabetically. The priority ordering determines both the displayed list order and the CRPG tab order. The ordering uses a tiered heuristic:

1. **Core source code** (application logic, components, business logic) -- most important
2. **Configuration that affects behavior** (build config, CI, command definitions)
3. **Specs and documentation** (markdown specs, design docs)
4. **Supporting files** (indexes, glossaries, changelogs)
5. **Test files** -- least urgent for manual review

Within each tier, files are sorted alphabetically by path (case-insensitive) as a tiebreaker.

The prompt includes guidance and examples so the agent applies the priority sorting correctly. The agent uses its understanding of file paths, extensions, and directory names to classify files into tiers (e.g., files in `src/` are core source, files ending in `.test.ts` or in `tests/` are test files, `.md` files are documentation, etc.).

Given: `src/utils.ts`, `src/app.tsx`, `README.md`, `tests/utils.test.ts`, `vite.config.ts`

Sorted: `src/app.tsx`, `src/utils.ts`, `vite.config.ts`, `README.md`, `tests/utils.test.ts`

---

## Session State

> Implements: `FR-sr-iteration-loop`, `FR-sr-completion-summary`

The agent tracks minimal state during the review session. All state lives in the agent's conversation context (working memory). There is no persistent storage and no iteration index.

| State Variable | Type | Description |
|---|---|---|
| `file_list` | array of `{path, change_type}` | The sorted (priority-ordered), filtered list of files to review |
| `total_changeset` | integer | Total files from git diff (excluding deletes) |
| `excluded_count` | integer | Files removed by filtering |
| `total_reviewable` | integer | Length of `file_list` |
| `prompt_output` | string | The content of `~/.shepherd/prompt-output.md` returned by the CRPG when the user clicks "Done" |

### Session Flow

There is no per-file iteration loop. The flow is:

1. Agent presents the changeset overview with per-file summaries and the prioritized file list.
2. User confirms they want to proceed.
3. Agent invokes `shepherd-launch.sh` with all file paths (as absolute paths).
4. Agent cleans up stale `~/.shepherd/prompt-output.md` (deletes if exists).
5. Agent waits (polls) for `~/.shepherd/prompt-output.md` to appear.
6. When the file appears, agent reads it and stores the content as `prompt_output`.
7. Agent displays the completion summary and feedback handoff.

The user controls the review entirely within the CRPG UI -- navigating tabs freely, adding comments on whichever files they choose, and clicking "Done" once when finished.

### Skip and Quit Behavior

There are no explicit "skip" or "quit" commands during the review. The user simply reviews whichever files they want in the CRPG and clicks "Done" at any point. Files without comments are implicitly skipped. The user can end the session at any time by clicking "Done" -- there is no concept of "remaining" files.

> Implements: `AC-sr-skip-file`, `AC-sr-quit-early`, `AC-sr-batch-open`, `AC-sr-unified-prompt`

---

## Install Script Update

> Implements: `FR-sr-install`, `AC-sr-install-global`

### File: `scripts/install-command.sh`

The existing install script creates a symlink for `shepherd.md`. It needs to be updated to also create a symlink for `shepherd-review.md`.

### Changes

The script currently handles a single source/target pair. The update adds a second source/target pair using the same logic (verify source exists, check for existing file, create symlink). The structure changes from handling one command to looping over a list of commands.

**Before** (handles one file):

```
SOURCE="$REPO_ROOT/.claude/commands/shepherd.md"
TARGET="$TARGET_DIR/shepherd.md"
# ... check and symlink ...
```

**After** (handles multiple files):

```
COMMANDS=("shepherd.md" "shepherd-review.md")
for CMD in "${COMMANDS[@]}"; do
  SOURCE="$REPO_ROOT/.claude/commands/$CMD"
  TARGET="$TARGET_DIR/$CMD"
  # ... same check-and-symlink logic per file ...
done
```

The help text and success message are updated to mention both commands:

```
Installed: ~/.claude/commands/shepherd.md -> <repo>/.claude/commands/shepherd.md
Installed: ~/.claude/commands/shepherd-review.md -> <repo>/.claude/commands/shepherd-review.md

The /shepherd and /shepherd-review commands are now available globally in Claude Code.
Updates will propagate automatically when you git pull this repo.
```

The `--force` flag applies to all commands (if set, it overwrites all existing files/symlinks). The "Already installed" check is per-file -- if one is already installed and the other is not, only the new one is symlinked.

---

## Error Handling

> Implements: `FR-sr-git-required`, `AC-sr-not-git-repo`, `AC-sr-no-changes`, `AC-sr-all-filtered`

### Error Cases and Agent Behavior

| Condition | Detection | Agent Output | Stops? |
|---|---|---|---|
| Not a git repository | `git rev-parse --is-inside-work-tree` returns non-zero | `Not a git repository. /shepherd-review must be run from within a git repo.` | Yes |
| No merge base found | `git merge-base HEAD main` returns non-zero | `No changes found relative to main.` | Yes |
| Empty diff (no changes) | `git diff --name-status` produces no output | `No changes found relative to main.` | Yes |
| All files filtered | Filter step produces zero reviewable files | `No reviewable files found. All <N> changed files were filtered out (lockfiles, generated, binary).` | Yes |
| User cancels before starting | User says "quit"/"cancel" at the pre-launch prompt | `Review cancelled.` | Yes |
| Launch script fails | `shepherd-launch.sh` exits with non-zero status | Agent displays the error output from the launch script and stops. | Yes |
| Unrecognized argument | `$ARGUMENTS` is not empty and does not match `--staged` or `--unstaged` | Agent displays a usage message: `Usage: /shepherd-review [--staged | --unstaged]` | Yes |
| Unrecognized user input (pre-launch) | User input does not match "go" or "quit" synonyms | `I did not understand that. Say "go" to begin the review, or "quit" to cancel.` | No -- re-prompt |

### Git Command Failures

If any git command fails unexpectedly (e.g., git is not installed, or the repository is corrupted), the agent should report the error output from the git command and stop. The prompt instructs the agent to check the exit code of each git command and surface errors.

---

## Multi-File Launch

> Implements: `FR-sr-multi-file-launch`, `AC-sr-invokes-shepherd`, `AC-sr-batch-open`

Instead of invoking `/shepherd` per file, the command opens all reviewable files in a single CRPG session by calling `shepherd-launch.sh` with multiple file path arguments.

### Invocation Pattern

The agent invokes `shepherd-launch.sh` via the `Bash` tool:

```bash
<repo-root>/scripts/shepherd-launch.sh <abs-path-1> <abs-path-2> ... <abs-path-N>
```

Where each `<abs-path>` is constructed as `<repo-root>/<relative-path>` using the repository root obtained from `git rev-parse --show-toplevel`. The paths are passed in priority order (matching `FR-sr-priority-ordering`), which determines the CRPG tab order.

### Changes to `shepherd-launch.sh`

The launch script currently accepts a single file path. It needs to be updated to accept multiple file path arguments:

1. **Argument parsing**: Accept one or more positional arguments after the `--fresh` flag. Validate each file (existence, readability, non-binary) the same way the current single-file path is validated. If any file fails validation, report the error for that file and skip it (do not abort the entire launch).
2. **URL construction**: Construct a URL with multiple `file` query parameters, one per file. Each path is URL-encoded independently. Example: `http://localhost:5173?file=%2Fpath%2Fto%2Ffile1.ts&file=%2Fpath%2Fto%2Ffile2.ts&file=%2Fpath%2Fto%2Ffile3.ts`
3. **Server management**: Unchanged -- check/start the dev server the same way as today.
4. **Browser open**: Unchanged -- open the constructed URL in the default browser.
5. **Summary output**: Updated to report the number of files opened (e.g., `Opened CRPG at http://localhost:5173 — loaded 5 files (reusing server)`).

### Changes to `useFileFromUrl.ts`

The web app's `useFileFromUrl` hook currently reads a single `?file=<path>` query parameter. It needs to be updated to read multiple `file` parameters:

1. **Read all `file` params**: Use `params.getAll('file')` instead of `params.get('file')` to retrieve all file paths from the URL.
2. **Load first file**: Call `loadFile(content, fileName, language)` for the first file (this clears any existing session and sets up the initial file).
3. **Add remaining files**: Call `addFile(content, fileName, language)` for each subsequent file (this adds them as additional tabs without clearing the session).
4. **Tab order**: Files are loaded in URL parameter order, which matches the priority ordering from `FR-sr-priority-ordering`. The first `file` param becomes the active tab.
5. **URL cleanup**: After all files are loaded, clean all `file` params from the URL (same `replaceState` pattern as today).
6. **Error handling**: If any individual file fails to load (e.g., file not found), log the error and continue loading the remaining files. The CRPG should open with whatever files loaded successfully.

### Prompt Output Mechanism

After opening the browser, the agent:

1. **Cleans up stale output**: Deletes `~/.shepherd/prompt-output.md` if it exists from a previous session.
2. **Waits for output**: Polls for `~/.shepherd/prompt-output.md` to appear. This is the same file-watcher pattern used by the `/shepherd` command. The CRPG writes this file when the user clicks "Done" -- it already handles multi-file prompts.
3. **Reads the output**: When the file appears, the agent reads its content. This is the unified multi-file prompt covering all files that received comments.

The prompt-output mechanism is unchanged from `/shepherd` -- the CRPG already generates multi-file prompts and writes them to `~/.shepherd/prompt-output.md`.

> Implements: `FR-sr-feedback-collection`, `AC-sr-unified-prompt`

---

## Command File Content Outline

The actual `.claude/commands/shepherd-review.md` file will contain the following content structure. This is not the literal file (that is produced during implementation), but the architectural outline:

```
Orchestrate a multi-file code review using the CRPG.

Allowed tools: Bash, Read

## Instructions

You are orchestrating a multi-file code review. Follow these steps exactly.

### Step 1: Verify git repository
[Run git rev-parse --is-inside-work-tree, handle failure]

### Step 2: Get repository root
[Run git rev-parse --show-toplevel]

### Step 3: Parse scope argument and detect changeset
[Parse $ARGUMENTS for --staged/--unstaged, run git merge-base, run
 appropriate git diff --name-status, parse output, merge untracked files]

### Step 4: Filter files
[Complete exclusion pattern list, filtering instructions]

### Step 5: Read diffs for context
[Read diffs for all reviewable files to generate per-file summaries]

### Step 6: Changeset overview and file list
[Present changeset overview paragraph, per-file context summaries,
 prioritized file list, exclusion count, wait for go/quit]

### Step 7: Batch-open all files
[Invoke shepherd-launch.sh with all absolute file paths,
 delete stale ~/.shepherd/prompt-output.md,
 poll for ~/.shepherd/prompt-output.md to appear,
 read the prompt output]

### Step 8: Completion summary and feedback handoff
[Display summary: total opened, filtered, files with comments.
 If prompt has feedback, present action options: apply, discuss, save, nothing.
 If no feedback, note and end session.]

### Error messages
[Exact wording for each error case]
```

The prompt must be self-contained -- the agent should not need to read any other files to execute the command. All rules, patterns, and formats are embedded in the command file.

---

## Performance Considerations

> Implements: `NFR-sr-startup-speed`

| Phase | Expected Time | Notes |
|---|---|---|
| Git repository check | ~5ms | `git rev-parse` is near-instant |
| Merge base computation | ~10ms | `git merge-base` reads the commit graph |
| Changeset detection | ~50ms | `git diff --name-status` for up to 1,000 files |
| Agent filtering + sorting | ~0ms (agent reasoning) | No shell commands; the agent applies rules in its reasoning |
| **Total to file list display** | **< 1 second** | Well within the 3-second budget |

The batch-open speed depends on the launch script's server startup and browser opening, which are outside this command's control. Once the CRPG is open, the review pace is entirely user-driven.

---

## Project Structure

New and modified files:

```
shepherd/                                    (project root)
  .claude/
    commands/
      shepherd.md                            EXISTING -- no changes
      shepherd-review.md                     NEW -- the review orchestration command

  scripts/
    shepherd-launch.sh                       MODIFIED -- accept multiple file paths, construct multi-file URL
    install-command.sh                       MODIFIED -- add shepherd-review.md symlink

  engineering/
    apps/web/src/hooks/
      useFileFromUrl.ts                      MODIFIED -- read multiple ?file= params, load via loadFile + addFile
    shepherd-review.md                       NEW -- this spec
```

The changes touch the launch script, the web app's URL-loading hook, the command file, and the install script. No new npm packages or binaries.

---

## Implementation Plan

### Step 1: Update `shepherd-launch.sh` to accept multiple file paths

Modify `scripts/shepherd-launch.sh` to accept multiple positional arguments (file paths). Each path is validated independently. The URL is constructed with multiple `file` query parameters. The summary message reports the total file count.

**Slug coverage**: `FR-sr-multi-file-launch`

### Step 2: Update `useFileFromUrl.ts` to load multiple `?file=` params

Modify `engineering/apps/web/src/hooks/useFileFromUrl.ts` to read all `file` parameters from the URL using `getAll('file')`. Load the first file via `loadFile()` (clears session) and subsequent files via `addFile()` (adds tabs). Handle per-file errors gracefully.

**Slug coverage**: `FR-sr-multi-file-launch`, `AC-sr-batch-open`

### Step 3: Create the command file (primary artifact)

Create `.claude/commands/shepherd-review.md` with the complete prompt instructions. This is the core implementation. The file must:

- Declare `Allowed tools: Bash, Read` at the top.
- Contain all git commands to run, with exact command strings.
- Handle `$ARGUMENTS` for `--staged` / `--unstaged` scope (`FR-sr-scope-argument`).
- Contain the complete exclusion pattern list from `FR-sr-file-filtering`.
- Specify the priority sorting heuristic from `FR-sr-priority-ordering`.
- Instruct the agent to read diffs and generate per-file context summaries (`FR-sr-per-file-context`).
- Present the changeset overview with per-file summaries and file list (`FR-sr-changeset-overview`, `FR-sr-file-list-display`).
- Invoke `shepherd-launch.sh` with all file paths (`FR-sr-multi-file-launch`).
- Clean up stale prompt output, wait for `~/.shepherd/prompt-output.md`, read it.
- Display the completion summary and feedback handoff (`FR-sr-completion-summary`).
- Handle all error cases (not a git repo, no changes, all filtered, user cancel, launch failure, unrecognized argument).

**Slug coverage**: `FR-sr-command-file`, `FR-sr-changeset-detection`, `FR-sr-file-filtering`, `FR-sr-file-list-display`, `FR-sr-iteration-loop`, `FR-sr-completion-summary`, `FR-sr-scope-argument`, `FR-sr-git-required`, `FR-sr-changeset-overview`, `FR-sr-per-file-context`, `FR-sr-priority-ordering`, `FR-sr-feedback-collection`, `NFR-sr-agent-native`, `NFR-sr-no-dependencies`, `NFR-sr-cross-platform`, `NFR-sr-startup-speed`, `AC-sr-happy-path`, `AC-sr-filters-lockfiles`, `AC-sr-filters-generated`, `AC-sr-filters-binary`, `AC-sr-includes-config`, `AC-sr-excludes-deleted`, `AC-sr-skip-file`, `AC-sr-quit-early`, `AC-sr-no-changes`, `AC-sr-all-filtered`, `AC-sr-not-git-repo`, `AC-sr-invokes-shepherd`, `AC-sr-list-command`, `AC-sr-completion-summary`, `AC-sr-sorted-file-list`, `AC-sr-batch-open`, `AC-sr-unified-prompt`

### Step 4: Update the install script

Modify `scripts/install-command.sh` to loop over both `shepherd.md` and `shepherd-review.md`. Use the same check-and-symlink logic for each file. Update help text and success messages.

**Slug coverage**: `FR-sr-install`, `AC-sr-install-global`

### Step 5: Manual testing

Test the command by running `/shepherd-review` in a Claude Code session on a branch with changes. Verify:

1. Git repository detection works (run from a git repo and from a non-git directory).
2. Changeset detection finds the correct files (compare against manual `git diff --name-only`).
3. Filtering excludes lockfiles, generated files, and binaries.
4. File list displays in the correct priority-sorted order.
5. `--staged` and `--unstaged` scope arguments work correctly.
6. All files open in a single CRPG session with one tab per file in priority order.
7. The prompt output is returned via `~/.shepherd/prompt-output.md`.
8. Completion summary shows correct counts and feedback handoff works.
9. Edge cases: no changes, all files filtered, user cancel before start, launch script failure.

### Step 6: Iterate on prompt wording

After initial testing, refine the prompt instructions in the command file based on observed agent behavior. Prompt engineering is iterative -- the first version may need adjustments to produce the exact output formats or handle edge cases reliably.

---

## Requirement Traceability

### Functional Requirements

| Slug | Engineering Coverage |
|---|---|
| `FR-sr-changeset-detection` | Git Commands section (merge-base + diff --name-status); Command file Step 3 |
| `FR-sr-file-filtering` | Filtering Logic section (complete exclusion/inclusion pattern lists); Command file Step 4 |
| `FR-sr-priority-ordering` | Sorting section (tiered priority heuristic); determines file list order and CRPG tab order |
| `FR-sr-changeset-overview` | Command file Step 5-6; agent reads diffs and generates changeset overview paragraph |
| `FR-sr-file-list-display` | Sorting section; Command file Step 6; output format from design spec embedded in prompt |
| `FR-sr-per-file-context` | Command file Step 5-6; per-file summaries presented in changeset overview |
| `FR-sr-iteration-loop` | Session State section; Command file Step 7; batch-open via `shepherd-launch.sh` |
| `FR-sr-feedback-collection` | Multi-File Launch section (prompt output mechanism); Command file Step 7-8 |
| `FR-sr-completion-summary` | Session State section; Command file Step 8; summary + feedback handoff |
| `FR-sr-command-file` | Command File Design section; `.claude/commands/shepherd-review.md` |
| `FR-sr-multi-file-launch` | Multi-File Launch section; changes to `shepherd-launch.sh` and `useFileFromUrl.ts` |
| `FR-sr-install` | Install Script Update section; `scripts/install-command.sh` modification |
| `FR-sr-scope-argument` | Scope Argument section; `$ARGUMENTS` parsing for `--staged`/`--unstaged` |
| `FR-sr-git-required` | Git Commands section (Command 1: verify git repo); Error Handling table |

### Non-Functional Requirements

| Slug | Engineering Coverage |
|---|---|
| `NFR-sr-startup-speed` | Performance Considerations section; all git commands are sub-second |
| `NFR-sr-no-dependencies` | Technical Approach section; no new npm packages, no binaries, only git |
| `NFR-sr-agent-native` | Technical Approach section; runs entirely in agent conversation using Bash tool |
| `NFR-sr-cross-platform` | Git Commands section; standard git operations, no platform-specific shell features |

### Acceptance Criteria

| Slug | Engineering Coverage |
|---|---|
| `AC-sr-happy-path` | Full flow: Git Commands -> Filtering -> Sorting -> Changeset Overview -> Batch Open -> Wait -> Summary |
| `AC-sr-filters-lockfiles` | Filtering Logic -- Lockfiles exclusion list |
| `AC-sr-filters-generated` | Filtering Logic -- Generated files exclusion list |
| `AC-sr-filters-binary` | Filtering Logic -- Binary files exclusion list |
| `AC-sr-includes-config` | Filtering Logic -- Inclusion Rules override list |
| `AC-sr-excludes-deleted` | Git Commands -- status code `D` excluded from file list |
| `AC-sr-skip-file` | Session State -- implicit skip (files without comments in CRPG) |
| `AC-sr-quit-early` | Session State -- user clicks "Done" at any point; no concept of "remaining" |
| `AC-sr-no-changes` | Git Commands -- empty diff detection; Error Handling |
| `AC-sr-all-filtered` | Filtering Logic -- zero-files-remaining case; Error Handling |
| `AC-sr-not-git-repo` | Git Commands -- Command 1 failure; Error Handling |
| `AC-sr-invokes-shepherd` | Multi-File Launch section; `shepherd-launch.sh` invocation with all file paths |
| `AC-sr-list-command` | Changeset overview with per-file summaries visible in conversation history |
| `AC-sr-completion-summary` | Session State -- summary with total opened, filtered, files with comments |
| `AC-sr-sorted-file-list` | Sorting section -- priority-based sort; tab order matches displayed list |
| `AC-sr-batch-open` | Multi-File Launch section -- all files open as tabs in a single CRPG session |
| `AC-sr-unified-prompt` | Multi-File Launch section -- CRPG generates one multi-file prompt via prompt-output.md |
| `AC-sr-install-global` | Install Script Update section -- symlink for `shepherd-review.md` |
