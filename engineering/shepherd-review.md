# Shepherd Review -- Technical Spec

> Based on requirements in `../product/shepherd-review.md`
> Based on design in `../design/shepherd-review.md`

## Technical Approach

The `/shepherd-review` command is a Claude Code custom command file -- a markdown prompt that instructs the AI agent to orchestrate a multi-file code review workflow. There is no compiled code, no new npm packages, no server-side logic, and no binaries. The entire implementation is a single prompt file at `.claude/commands/shepherd-review.md`, plus a minor update to `scripts/install-command.sh` for global installation.

The agent executes the prompt by running git commands via `Bash` tool calls, applying filtering logic described in the prompt, presenting results as plain text, and invoking the existing `/shepherd` command for each file. All state (file list, current position, review/skip counts) is tracked in the agent's conversation context -- there is no persistent state.

> Implements: `FR-sr-command-file`, `NFR-sr-no-dependencies`, `NFR-sr-agent-native`

### Key Technical Decisions

| Decision | Choice | Rationale |
|---|---|---|
| Implementation mechanism | Claude Code custom command (`.claude/commands/shepherd-review.md`) | Same pattern as the existing `/shepherd` command. Zero code, zero dependencies. The agent interprets the prompt and executes shell commands. |
| State management | Agent conversation context | The iteration loop (current position, counts) lives in the agent's working memory. No files, no dotfiles, no database. Each invocation starts fresh (`FR-sr-no-args`). |
| File filtering | Prompt-embedded pattern lists | The exclusion rules are written directly in the command file as lists of patterns. The agent applies them by evaluating file paths -- no regex engine or external tool needed. |
| Git operations | `git rev-parse`, `git merge-base`, `git diff --name-status` | Standard cross-platform git commands. No git libraries, no wrappers. The agent runs them via `Bash` and parses the output. |
| Per-file review | Invokes existing `/shepherd` command | The agent calls `/shepherd <absolute-path>` for each file, reusing all existing CRPG infrastructure. No duplication of functionality. |

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
3. **Step 2: Parse scope argument** -- Determine which git commands to run.
4. **Step 3: Changeset detection** -- Find the merge base and run the appropriate `git diff`.
5. **Step 4: Filtering** -- The complete exclusion pattern list and instructions to apply them.
6. **Step 5: File list display** -- Exact output format with sorting rules.
7. **Step 6: Pre-iteration prompt** -- Wait for "go" or "quit".
8. **Step 7: Iteration loop** -- Per-file announcement, `/shepherd` invocation, user prompt, input handling.
9. **Step 8: Completion summary** -- Exact output format with counters.
10. **Error messages** -- Exact wording for each error case.
11. **User input recognition** -- Table of canonical commands and synonyms.

### Allowed Tools

The command file declares `Allowed tools: Bash` at the top. The agent needs `Bash` to run git commands. It does not need `Read`, `Write`, `Edit`, or any other tools. The `/shepherd` invocation happens via the agent's ability to invoke other slash commands (which is a built-in capability, not a tool).

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

The agent also needs the repository root to construct absolute paths for `/shepherd` invocations:

```bash
git rev-parse --show-toplevel
```

This returns the absolute path to the repository root (e.g., `/Users/dev/my-project`). The agent stores this and uses it later to construct `<repo-root>/<relative-path>` for each file.

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

> Implements: `AC-sr-sorted-file-list`

After filtering, the agent sorts the file list for display. The sorting order is:

1. Split each file path into directory components and a filename.
2. Root-level files (no directory prefix) sort before any files inside directories.
3. Directories sort alphabetically among themselves (case-insensitive).
4. Files within the same directory sort alphabetically by filename (case-insensitive).
5. Files in a parent directory sort before files in its subdirectories.

The prompt includes an explicit example so the agent applies the sorting correctly:

Given: `src/utils.ts`, `src/app.tsx`, `lib/helpers.ts`, `README.md`, `src/components/Button.tsx`

Sorted: `README.md`, `lib/helpers.ts`, `src/app.tsx`, `src/components/Button.tsx`, `src/utils.ts`

---

## Iteration State

> Implements: `FR-sr-iteration-loop`, `FR-sr-completion-summary`

The agent tracks the following state during the iteration loop. All state lives in the agent's conversation context (working memory). There is no persistent storage.

| State Variable | Type | Description |
|---|---|---|
| `file_list` | array of `{path, change_type}` | The sorted, filtered list of files to review |
| `current_index` | integer | 0-based index of the current file in the iteration |
| `reviewed_count` | integer | Files the user advanced past with "next"/"done" (where `/shepherd` was invoked) |
| `skipped_count` | integer | Files the user explicitly skipped |
| `total_reviewable` | integer | Length of `file_list` |
| `total_changeset` | integer | Total files from git diff (excluding deletes) |
| `excluded_count` | integer | Files removed by filtering |

### State Transitions

At each file in the iteration:

1. Agent announces the file (`[position/total] path [change-type]`).
2. Agent invokes `/shepherd <absolute-path>`.
3. Agent displays the user prompt with options.
4. User responds:
   - **"next"/"done"/"continue"/"n"**: `reviewed_count += 1`, `current_index += 1`
   - **"skip"/"pass"**: `skipped_count += 1`, `current_index += 1`
   - **"list"**: Re-display the file list with current position; do not change any counters or index.
   - **"quit"/"stop"/"exit"/"q"**: Exit the loop. Compute `remaining = total_reviewable - current_index`. The current file counts as reviewed (since `/shepherd` was already invoked), so `reviewed_count += 1`.

When `current_index >= total_reviewable`, the loop ends naturally.

### Skip Behavior

Per the design spec, `/shepherd` is invoked **before** the user prompt. So when the user says "skip," the file has already been opened in the CRPG. The "skip" action is a bookkeeping distinction -- it counts differently in the summary. The prompt must make this clear to the agent.

However, the agent should still advance to the file announcement and invoke `/shepherd` before presenting the prompt. The "skip" response tells the agent to record the file as "skipped" rather than "reviewed" for the summary.

> Implements: `AC-sr-skip-file`, `AC-sr-quit-early`

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
| User cancels before starting | User says "quit"/"cancel" at the pre-iteration prompt | `Review cancelled.` | Yes |
| `/shepherd` fails for a file | `/shepherd` reports an error (e.g., file deleted between detection and iteration) | Agent displays the error from `/shepherd` as-is, then shows the user prompt. File counts as "reviewed" in the summary. | No -- continues |
| Unrecognized user input (during iteration) | User input does not match any recognized command | `I did not understand that. Your options are: next, skip, list, quit` (with full menu) | No -- re-prompt |
| Unrecognized user input (pre-iteration) | User input does not match "go" or "quit" synonyms | `I did not understand that. Say "go" to begin the review, or "quit" to cancel.` | No -- re-prompt |

### Git Command Failures

If any git command fails unexpectedly (e.g., git is not installed, or the repository is corrupted), the agent should report the error output from the git command and stop. The prompt instructs the agent to check the exit code of each git command and surface errors.

---

## Interaction with `/shepherd`

> Implements: `AC-sr-invokes-shepherd`

For each file in the iteration, the agent invokes the existing `/shepherd` slash command. The invocation pattern is:

```
/shepherd <absolute-path>
```

Where `<absolute-path>` is constructed as `<repo-root>/<relative-path>` using the repository root obtained from `git rev-parse --show-toplevel`.

The agent does not use the `Bash` tool to invoke `/shepherd`. Instead, it invokes the slash command directly as part of its conversation -- the same way a user would type `/shepherd path/to/file`. The `/shepherd` command handles server management, browser opening, and error reporting independently.

After `/shepherd` completes (its output appears in the conversation), the agent displays the iteration prompt with `next`, `skip`, `list`, and `quit` options.

---

## Command File Content Outline

The actual `.claude/commands/shepherd-review.md` file will contain the following content structure. This is not the literal file (that is produced during implementation), but the architectural outline:

```
Orchestrate a multi-file code review using the CRPG.

Allowed tools: Bash

## Instructions

You are orchestrating a multi-file code review. Follow these steps exactly.

### Step 1: Verify git repository
[Run git rev-parse, handle failure]

### Step 2: Get repository root
[Run git rev-parse --show-toplevel]

### Step 3: Find merge base and changeset
[Run git merge-base, run git diff --name-status, parse output]

### Step 4: Filter files
[Complete exclusion pattern list, filtering instructions]

### Step 5: Sort and display file list
[Sorting rules, exact output format, wait for go/quit]

### Step 6: Iteration loop
[Per-file: announce, invoke /shepherd, display prompt, handle input]

### Step 7: Completion summary
[Exact output format with counters]

### Error messages
[Exact wording for each error case]

### User input recognition
[Table of commands and synonyms]
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

The per-file iteration speed depends on the `/shepherd` command's own performance (server startup, browser opening), which is outside this command's control.

---

## Project Structure

New and modified files:

```
shepherd-2/                                  (project root)
  .claude/
    commands/
      shepherd.md                            EXISTING -- no changes
      shepherd-review.md                     NEW -- the review orchestration command

  scripts/
    install-command.sh                       MODIFIED -- add shepherd-review.md symlink

  engineering/
    shepherd-review.md                       NEW -- this spec
```

No new source code files. No modifications to the CRPG web app. No new dependencies.

---

## Implementation Plan

### Step 1: Create the command file (primary artifact)

Create `.claude/commands/shepherd-review.md` with the complete prompt instructions. This is the core implementation. The file must:

- Declare `Allowed tools: Bash` at the top.
- Contain all git commands to run, with exact command strings.
- Contain the complete exclusion pattern list from `FR-sr-file-filtering`.
- Specify the exact output formats from the design spec (file list, file announcement, user prompt, completion summary, error messages).
- Specify the user input recognition table (commands and synonyms).
- Handle all error cases (not a git repo, no changes, all filtered, user cancel).
- Instruct the agent to invoke `/shepherd <absolute-path>` for each file.
- Track iteration state (position, reviewed/skipped counts) in the conversation context.

**Slug coverage**: `FR-sr-command-file`, `FR-sr-changeset-detection`, `FR-sr-file-filtering`, `FR-sr-file-list-display`, `FR-sr-iteration-loop`, `FR-sr-completion-summary`, `FR-sr-no-args`, `FR-sr-git-required`, `NFR-sr-agent-native`, `NFR-sr-no-dependencies`, `NFR-sr-cross-platform`, `NFR-sr-startup-speed`, `AC-sr-happy-path`, `AC-sr-filters-lockfiles`, `AC-sr-filters-generated`, `AC-sr-filters-binary`, `AC-sr-includes-config`, `AC-sr-excludes-deleted`, `AC-sr-skip-file`, `AC-sr-quit-early`, `AC-sr-no-changes`, `AC-sr-all-filtered`, `AC-sr-not-git-repo`, `AC-sr-invokes-shepherd`, `AC-sr-list-command`, `AC-sr-completion-summary`, `AC-sr-sorted-file-list`

### Step 2: Update the install script

Modify `scripts/install-command.sh` to loop over both `shepherd.md` and `shepherd-review.md`. Use the same check-and-symlink logic for each file. Update help text and success messages.

**Slug coverage**: `FR-sr-install`, `AC-sr-install-global`

### Step 3: Manual testing

Test the command by running `/shepherd-review` in a Claude Code session on a branch with changes. Verify:

1. Git repository detection works (run from a git repo and from a non-git directory).
2. Changeset detection finds the correct files (compare against manual `git diff --name-only`).
3. Filtering excludes lockfiles, generated files, and binaries.
4. File list displays in the correct sorted order.
5. Iteration loop invokes `/shepherd` for each file and waits for user input.
6. "skip", "quit", "list" commands work correctly.
7. Completion summary shows correct counts.
8. Edge cases: no changes, all files filtered, user cancel before starting.

### Step 4: Iterate on prompt wording

After initial testing, refine the prompt instructions in the command file based on observed agent behavior. Prompt engineering is iterative -- the first version may need adjustments to produce the exact output formats or handle edge cases reliably.

---

## Requirement Traceability

### Functional Requirements

| Slug | Engineering Coverage |
|---|---|
| `FR-sr-changeset-detection` | Git Commands section (merge-base + diff --name-status); Command file Step 3 |
| `FR-sr-file-filtering` | Filtering Logic section (complete exclusion/inclusion pattern lists); Command file Step 4 |
| `FR-sr-file-list-display` | Sorting section; Command file Step 5; output format from design spec embedded in prompt |
| `FR-sr-iteration-loop` | Iteration State section; Command file Step 6; per-file `/shepherd` invocation |
| `FR-sr-completion-summary` | Iteration State section (counters); Command file Step 7 |
| `FR-sr-command-file` | Command File Design section; `.claude/commands/shepherd-review.md` |
| `FR-sr-install` | Install Script Update section; `scripts/install-command.sh` modification |
| `FR-sr-no-args` | Command File Design section (no `$ARGUMENTS`); prompt header |
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
| `AC-sr-happy-path` | Full flow: Git Commands -> Filtering -> Sorting -> Iteration -> Summary |
| `AC-sr-filters-lockfiles` | Filtering Logic -- Lockfiles exclusion list |
| `AC-sr-filters-generated` | Filtering Logic -- Generated files exclusion list |
| `AC-sr-filters-binary` | Filtering Logic -- Binary files exclusion list |
| `AC-sr-includes-config` | Filtering Logic -- Inclusion Rules override list |
| `AC-sr-excludes-deleted` | Git Commands -- status code `D` excluded from file list |
| `AC-sr-skip-file` | Iteration State -- skip behavior and counting |
| `AC-sr-quit-early` | Iteration State -- quit transitions and remaining count |
| `AC-sr-no-changes` | Git Commands -- empty diff detection; Error Handling |
| `AC-sr-all-filtered` | Filtering Logic -- zero-files-remaining case; Error Handling |
| `AC-sr-not-git-repo` | Git Commands -- Command 1 failure; Error Handling |
| `AC-sr-invokes-shepherd` | Interaction with /shepherd section; absolute path construction |
| `AC-sr-list-command` | Iteration State -- "list" re-displays file list without changing position |
| `AC-sr-completion-summary` | Iteration State -- counter definitions; output format from design spec |
| `AC-sr-sorted-file-list` | Sorting section -- directory-first alphabetical sort rules |
| `AC-sr-install-global` | Install Script Update section -- symlink for `shepherd-review.md` |
