# Shepherd Review

## Overview

A slash command (`/shepherd-review`) that orchestrates a multi-file code review workflow within an AI coding agent conversation. Instead of manually identifying which files changed, finding the interesting ones, and invoking `/shepherd` on each one individually, the developer types `/shepherd-review` and the command automatically discovers the changeset of the current branch versus main, filters out uninteresting files (lockfiles, generated code, binaries), presents a prioritized list of files to review, and then opens all reviewable files at once in a single CRPG session — each file appearing as a tab that the user can navigate freely.

This addresses the workflow gap between "I have a branch with changes" and "I want to review my changed files in the CRPG." Today, the developer must manually run `git diff --name-only`, mentally filter out noise files, and invoke `/shepherd` repeatedly. `/shepherd-review` collapses that entire workflow into a single command that batch-opens every reviewable file in one CRPG session.

The CRPG already supports multi-file tabs, per-file comments, and multi-file prompt generation. `/shepherd-review` leverages this by passing all files to a single launch, letting the user review files in any order, add comments on whichever files they choose, and click "Done" once to produce a unified multi-file prompt covering all reviewed files.

## User Stories

### US-SR-1: Review all interesting changed files in my branch
**As a** developer who has been working with an AI coding agent on a feature branch, **I want to** invoke a single command that opens all meaningfully changed files at once in the CRPG, **so that** I can review every change in a single session without manually tracking which files I have and haven't reviewed.

### US-SR-2: Skip uninteresting files automatically
**As a** developer, **I want** the review command to automatically exclude lockfiles, generated files, and binary files from the review list, **so that** I only spend time reviewing files that contain meaningful, human-authored changes.

### US-SR-3: See the full list before starting
**As a** developer, **I want to** see the complete list of files that will be reviewed before the iteration begins, **so that** I can understand the scope of the review and mentally prepare for what is ahead.

### US-SR-4: Control the pace of review
**As a** developer, **I want to** navigate between file tabs freely in the CRPG, reviewing files in whatever order and at whatever pace I choose, **so that** I am never forced into a fixed sequence and can spend as much time as I need on each file.

### US-SR-5: Review only the files I care about
**As a** developer, **I want to** leave comments only on the files I care about and click "Done" at any point to end the session, **so that** I am not forced to visit every file and can focus my attention where it matters most.

### US-SR-6: Use the command from any branch
**As a** developer, **I want** the command to work on whatever branch I am currently on and compare against main (or the appropriate base branch), **so that** I do not need to specify branches manually.

### US-SR-7: Review all files in a single CRPG session
**As a** developer, **I want** all reviewable files to open together in one CRPG session with a tab per file, **so that** I can see the full scope of changes, navigate between related files, and produce a single unified review prompt covering all my comments.

## Requirements

### Functional Requirements

#### `FR-sr-changeset-detection` -- Detect the changeset of the current branch
The command determines which files have been modified, added, or deleted by comparing the **working tree** (not just committed changes) to the base branch. The base branch defaults to `main`. The comparison uses the merge base of the current branch and the base branch as the reference point, and compares the working tree against it. This captures all changes: committed changes on the branch, staged but uncommitted changes, and unstaged modifications. Additionally, untracked new files (not yet `git add`ed) are included as `added` files. This means the review covers the full set of changes a developer would see before committing — which is the primary use case for local code review. If no changes are found (the working tree matches the merge base), the command reports "No changes found relative to main" and stops. Deleted files are counted in the total changeset but excluded from the review list and counted as filtered (there is nothing to open in the CRPG for a deleted file). Renamed files are included using their new path.

#### `FR-sr-file-filtering` -- Filter out uninteresting files
The command filters the changeset to exclude files that are not worth reviewing. The filtering rules are:

**Excluded by default** (these file patterns are skipped):
- Lockfiles: `package-lock.json`, `yarn.lock`, `pnpm-lock.yaml`, `Gemfile.lock`, `Cargo.lock`, `poetry.lock`, `composer.lock`, `go.sum`, `flake.lock`, `Pipfile.lock`
- Generated files: files in directories named `dist/`, `build/`, `out/`, `.next/`, `coverage/`, `__generated__/`, `node_modules/`; files with extensions `.min.js`, `.min.css`, `.map`, `.d.ts`; files named `*.generated.*` or `*.auto.*`
- Binary files: common binary extensions including `.png`, `.jpg`, `.jpeg`, `.gif`, `.ico`, `.svg`, `.woff`, `.woff2`, `.ttf`, `.eot`, `.mp3`, `.mp4`, `.zip`, `.tar`, `.gz`, `.pdf`, `.exe`, `.dll`, `.so`, `.dylib`
- IDE/editor files: `.idea/` (entire directory), `.vscode/` (entire directory), `.DS_Store`
- Snapshot files: `*.snap`, `*.snapshot`

**Included** (these are meaningful to review even though they are "config"):
- Build configuration: `vite.config.*`, `webpack.config.*`, `tsconfig.json`, `tsconfig.*.json`, `jest.config.*`, `vitest.config.*`, `eslint.config.*`, `.eslintrc.*`, `babel.config.*`, `rollup.config.*`, `esbuild.config.*`
- Project configuration: `package.json`, `Cargo.toml`, `go.mod`, `pyproject.toml`, `Makefile`, `Dockerfile`, `docker-compose.*`, `.env.example`
- CI configuration: files in `.github/workflows/`, `.gitlab-ci.yml`, `Jenkinsfile`
- Command files: `.claude/commands/*.md`

The filtering is heuristic-based and applied by file path and extension. The command does not read file contents to determine whether a file is interesting; it uses path patterns only. **Exclusion rules take precedence over inclusion rules.** If a file matches an exclusion rule (e.g., it is inside `dist/`), it is excluded even if it also matches an inclusion pattern (e.g., `vite.config.ts`). The inclusion list only prevents exclusion of files that are *not* in an excluded directory. If a file does not match any exclusion rule, it is included.

#### `FR-sr-priority-ordering` -- Sort files by review importance
After filtering, the command sorts files by review importance rather than alphabetically. The ordering uses a general-purpose heuristic:
1. Core source code (application logic, components, business logic) — most important
2. Configuration that affects behavior (build config, CI, command definitions)
3. Specs and documentation (markdown specs, design docs)
4. Supporting files (indexes, glossaries, changelogs)
5. Test files — least urgent for manual review

Within each tier, larger/more significant changes rank higher. The goal is that the reviewer sees the most impactful files first, so they can focus attention where it matters most.

#### `FR-sr-changeset-overview` -- Provide a changeset overview before starting
Before presenting the file list, the command reads the diffs for all reviewable files and provides a brief (2-4 sentence) summary of the overall changeset: what is being changed, what the theme or purpose is. This orients the reviewer before they dive into individual files.

#### `FR-sr-file-list-display` -- Present the prioritized file list to the user
After ordering and generating the overview, the command presents the list of files to review in a numbered format. The display includes:
1. The scope label (all changes vs main, staged only, or unstaged only)
2. The changeset overview paragraph
3. The total count of files to review (e.g., "Found 7 files to review")
4. A numbered list showing each file's relative path in priority order
5. If any files were filtered out, a note indicating how many were excluded

After presenting the list, the command asks the user if they want to proceed.

#### `FR-sr-per-file-context` -- Provide per-file context in the changeset overview
Since all files open simultaneously in a single CRPG session, per-file context is presented upfront as part of the changeset overview (see `FR-sr-changeset-overview`) rather than announced before each file. The changeset overview includes a brief (1-2 sentence) summary for each file describing what changed: what was added, modified, or removed, and why it matters. This is derived from the diff and should mention specific function names, sections, or structural changes. The reviewer can consult this overview while navigating tabs in the CRPG.

#### `FR-sr-iteration-loop` -- Batch-open all files in a single CRPG session
When the user confirms they want to proceed, the command opens all reviewable files at once in a single CRPG session. The files appear as tabs in the CRPG, ordered by review priority (see `FR-sr-priority-ordering`). The user navigates between tabs freely, reviewing files in whatever order they choose and adding comments on whichever files they want.

The command invokes the launch script (see `FR-sr-multi-file-launch`) with all file paths, which opens the CRPG with one tab per file. The command then waits for the user to complete their review. The user clicks "Done" once in the CRPG when finished, which generates a single multi-file prompt covering all files that received comments. The user pastes this prompt back into the conversation (or it is returned automatically, depending on CRPG integration).

There is no sequential iteration, no "next" or "skip" commands, and no per-file prompting. The user controls their review entirely within the CRPG UI.

#### `FR-sr-feedback-collection` -- Receive unified multi-file feedback from CRPG
Feedback is collected as a single multi-file prompt generated by the CRPG when the user clicks "Done." This prompt contains all comments across all files, organized by file. The user pastes this prompt back into the conversation (or it is returned automatically). The command does NOT need to collect feedback file-by-file or prompt the user to paste after each file — the CRPG handles aggregation internally and produces one unified output.

#### `FR-sr-completion-summary` -- Display a review summary and feedback handoff
When the user pastes the CRPG-generated prompt back into the conversation (or it is returned automatically), the command displays a summary including: total files opened, filtered count, and files that received comments.

If the prompt contains feedback, the command presents the full prompt content and asks the user what to do:
- **apply** — implement the changes described in the feedback
- **discuss** — talk through the feedback before acting
- **save** — write feedback to a file for later
- **nothing** — end the session

If the user returns from the CRPG with no comments (empty prompt or indicates no feedback), the summary notes this and the session ends.

#### `FR-sr-command-file` -- Implemented as a Claude Code command file
The command is implemented as a Claude Code custom command file at `.claude/commands/shepherd-review.md`, following the same pattern as the existing `/shepherd` command at `.claude/commands/shepherd.md`. The command file contains the prompt instructions that the AI coding agent executes. No compiled code or external binary is required — the command is pure prompt engineering executed by the agent. The command invokes the launch script with multiple file paths to open all reviewable files in a single CRPG session (see `FR-sr-multi-file-launch`).

#### `FR-sr-multi-file-launch` -- Open multiple files in a single CRPG session
The command opens all reviewable files in a single CRPG session by passing multiple file paths to the launch script (`shepherd-launch.sh`). The launch script constructs a URL that tells the CRPG web app to load all specified files, each appearing as a tab. The tab order matches the priority ordering from `FR-sr-priority-ordering`. The CRPG's existing multi-file support handles tab navigation, per-file comments, and unified prompt generation. The launch script must accept multiple file path arguments (updating its current single-file interface). The web app must support receiving multiple files via URL parameters (new engineering work).

#### `FR-sr-install` -- Installable via the existing symlink mechanism
The command can be made globally available using the same `scripts/install-command.sh` script that installs the `/shepherd` command. The install script is updated to also create a symlink for `shepherd-review.md` at `~/.claude/commands/shepherd-review.md`. Since the global command is a symlink, `git pull` in the repo automatically updates it.

#### `FR-sr-scope-argument` -- Optional scope argument
The command accepts an optional argument to control which changes are reviewed:

- **No argument (default)**: Review all changes in the working tree relative to main. This includes committed branch changes, staged changes, unstaged changes, and untracked new files. This is the broadest view — "everything that differs from main."
- **`--staged`**: Review only staged changes (files in the git index). This is useful after `git add` when the user wants to review exactly what will be committed. Uses `git diff --name-status --cached` against the merge base.
- **`--unstaged`**: Review only unstaged changes and untracked files. This is useful after staging some files to review what's left. Uses `git diff --name-status` (working tree vs HEAD) plus untracked files.

If an unrecognized argument is provided, the command displays a usage message and stops.

#### `FR-sr-git-required` -- Requires a git repository
The command must be invoked from within a git repository. If the current working directory is not inside a git repository, the command reports an error: "Not a git repository. /shepherd-review must be run from within a git repo." and stops.

### Non-Functional Requirements

#### `NFR-sr-startup-speed` -- Fast changeset detection
The time from invoking `/shepherd-review` to displaying the file list must be under 3 seconds for repositories with up to 1,000 changed files. The changeset detection relies on git commands that are inherently fast.

#### `NFR-sr-no-dependencies` -- No additional dependencies
The command requires only git (available on the PATH) and the existing `/shepherd` command infrastructure. It does not introduce any new runtime dependencies, npm packages, or compiled binaries.

#### `NFR-sr-agent-native` -- Runs entirely within the agent conversation
The command runs entirely within the AI coding agent's conversation context. It uses only bash commands (git, standard shell utilities) and the existing `/shepherd` command. There is no separate process, daemon, or server beyond what `/shepherd` already manages.

#### `NFR-sr-cross-platform` -- Cross-platform git compatibility
The git commands used by the command must work on macOS, Linux, and Windows (Git Bash or WSL). The command does not rely on platform-specific shell features beyond what is available in bash.

## Acceptance Criteria

#### `AC-sr-happy-path` -- Full review session completes successfully
**Given** the user is on a feature branch with 5 modified source files and 3 lockfiles/generated files relative to main, **when** the user types `/shepherd-review`, **then** the command displays "Found 5 files to review (3 excluded)" with a prioritized list and changeset overview, and after the user confirms, opens all 5 files at once in a single CRPG session with one tab per file. The user reviews files freely, clicks "Done" in the CRPG, pastes the generated prompt, and the command displays a summary with feedback action options.

#### `AC-sr-filters-lockfiles` -- Lockfiles are excluded
**Given** the changeset includes `package-lock.json` and `pnpm-lock.yaml`, **when** the file list is displayed, **then** neither lockfile appears in the review list and the exclusion count reflects them.

#### `AC-sr-filters-generated` -- Generated/build output files are excluded
**Given** the changeset includes files in `dist/` and a file named `schema.generated.ts`, **when** the file list is displayed, **then** those files are excluded from the review list.

#### `AC-sr-filters-binary` -- Binary files are excluded
**Given** the changeset includes `logo.png` and `font.woff2`, **when** the file list is displayed, **then** those files are excluded from the review list.

#### `AC-sr-includes-config` -- Meaningful config files are included
**Given** the changeset includes `vite.config.ts`, `tsconfig.json`, and `package.json`, **when** the file list is displayed, **then** all three appear in the review list.

#### `AC-sr-excludes-deleted` -- Deleted files are excluded
**Given** the changeset includes a file that was deleted (exists on main but not on the current branch), **when** the file list is displayed, **then** the deleted file does not appear in the review list.

#### `AC-sr-skip-file` -- User can skip files implicitly
**Given** 5 files are open as tabs in the CRPG, **when** the user reviews only 3 files and adds comments to those 3, then clicks "Done", **then** the generated prompt includes only the 3 files with comments. The 2 files without comments are effectively skipped without any explicit action required.

#### `AC-sr-quit-early` -- User can end the session at any point
**Given** 5 files are open as tabs in the CRPG, **when** the user clicks "Done" after reviewing only 2 files, **then** the session ends and the generated prompt covers whatever comments exist at that point. There is no concept of "remaining" files — the user simply finishes whenever they are ready.

#### `AC-sr-no-changes` -- No changes produces a clear message
**Given** the user is on a branch with no changes relative to main (or is on main itself), **when** the user types `/shepherd-review`, **then** the command outputs "No changes found relative to main." and stops without presenting a file list.

#### `AC-sr-all-filtered` -- All files filtered produces a clear message
**Given** the changeset contains only lockfiles and binary files (every file is excluded by filtering), **when** the file list is computed, **then** the command outputs "No reviewable files found. All 4 changed files were filtered out (lockfiles, generated, binary)." and stops.

#### `AC-sr-not-git-repo` -- Error outside a git repository
**Given** the current working directory is not inside a git repository, **when** the user types `/shepherd-review`, **then** the command outputs "Not a git repository. /shepherd-review must be run from within a git repo." and stops.

#### `AC-sr-invokes-shepherd` -- All files open in a single CRPG session
**Given** the reviewable files are `src/utils.ts`, `src/app.tsx`, and `lib/helpers.ts`, **when** the command launches the review, **then** it invokes the launch script with all three file paths, opening a single CRPG session in the browser with three tabs (one per file) in priority order.

#### `AC-sr-list-command` -- File list is available in the changeset overview
**Given** the command has displayed the changeset overview with per-file context summaries, **when** the user wants to reference the file list while reviewing in the CRPG, **then** the file list and summaries are visible in the conversation history above. The CRPG tab bar also shows all file names for navigation.

#### `AC-sr-completion-summary` -- Summary displays after CRPG prompt is returned
**Given** the user completes a review of 5 files and pastes the CRPG-generated prompt, **when** the command receives the prompt, **then** the command displays a summary showing the total files opened, the number of files that received comments, and presents the action options (apply, discuss, save, nothing).

#### `AC-sr-sorted-file-list` -- Files are sorted by review priority and tab order matches
**Given** the changeset includes `src/utils.ts`, `src/app.tsx`, `lib/helpers.ts`, `tests/utils.test.ts`, and `README.md`, **when** the file list is displayed and the CRPG opens, **then** the files appear in priority order (core source first, then config, then docs, then tests) both in the displayed list and in the CRPG tab order.

#### `AC-sr-batch-open` -- All files open as tabs in a single CRPG session
**Given** there are 5 reviewable files, **when** the user confirms they want to proceed, **then** a single CRPG session opens in the browser with 5 tabs (one per file). The user does not need to wait for sequential prompts or invoke any per-file commands.

#### `AC-sr-unified-prompt` -- CRPG generates a single multi-file prompt
**Given** the user has added comments on 3 of 5 open files in the CRPG, **when** the user clicks "Done", **then** the CRPG generates a single prompt that includes all comments organized by file. This prompt is what gets pasted back into the conversation.

#### `AC-sr-install-global` -- Command is available globally via symlink
**Given** the user runs `./scripts/install-command.sh`, **when** the script completes, **then** a symlink exists at `~/.claude/commands/shepherd-review.md` pointing to the repo's `.claude/commands/shepherd-review.md`, and `/shepherd-review` is available as a global command in Claude Code.

## Open Questions

1. **Base branch detection**: The spec defaults to `main` as the base branch. Some repositories use `master`, `develop`, or other branch names. Should the command attempt to auto-detect the default branch (e.g., by reading `git symbolic-ref refs/remotes/origin/HEAD`), or should it accept an optional argument to override the base branch? V1 assumes `main`; auto-detection or an override argument is a natural v2 enhancement.

2. ~~**File ordering strategy**: Resolved — files are sorted by review priority (see `FR-sr-priority-ordering`). Priority ordering determines both the displayed list order and the CRPG tab order. Core source files appear first, tests last.~~

3. **Resumable sessions**: If the user quits early and later runs `/shepherd-review` again, should it offer to resume where they left off? This would require some form of state persistence (e.g., a dotfile in the repo). Deferred; each invocation starts fresh in v1.

4. ~~**Per-file context/summary**: Resolved — per-file context summaries are now included in the changeset overview (see `FR-sr-per-file-context`). Since all files open at once, there is no per-file announcement moment; instead, summaries are presented upfront before the CRPG opens.~~

5. **Custom exclusion patterns**: Should the user be able to customize which files are filtered out (e.g., via a `.shepherd-review.yml` config file)? Deferred. The built-in heuristics should cover the vast majority of cases for v1.

6. **Diff view vs. file view**: When `/shepherd` opens a file in the CRPG, the user can choose file view or diff view. Should `/shepherd-review` default to diff view (since the whole point is reviewing changes)? This is a UX question best resolved in the design phase. The product spec does not mandate a default view mode; that is left to the existing CRPG and `/shepherd` behavior.

7. **Renamed file handling**: Git reports renames as a pair (old path, new path). The command should use the new path (which exists on disk). Should it also mention the old path in the file list annotation? Deferred to design.

8. **Maximum batch size**: Is there a practical upper limit on how many files can be batch-opened as tabs in a single CRPG session? For very large changesets (e.g., 50+ files), the tab bar may become unwieldy and the URL may exceed browser limits. Should the command warn or paginate above a threshold? Deferred to design/engineering to determine practical limits.

9. **URL parameter format for multiple files**: The CRPG currently supports `?file=<path>` for a single file. The multi-file URL format (e.g., repeated `file` params, comma-separated, or a different mechanism) needs to be defined in engineering. This is a technical design decision, not a product decision.

10. ~~**Prompt return mechanism**: Resolved — the CRPG writes the unified multi-file prompt to `~/.shepherd/prompt-output.md` when the user clicks "Done." The agent's file-watcher mechanism detects this file and reads the prompt automatically. This leverages the existing prompt handoff infrastructure from the `/shepherd` command. No manual paste is needed.~~

## Dependencies

- **`shepherd-launch.sh` script**: The launch script must be updated to accept multiple file path arguments and construct a URL that loads all files as tabs in a single CRPG session. Currently supports a single `?file=<path>` parameter.
- **CRPG multi-file URL support**: The CRPG web app must support loading multiple files from URL parameters (new engineering work). The in-app multi-file tab support already exists; this dependency is specifically about initializing a multi-file session from a URL.
- **CRPG multi-file prompt generation**: The CRPG already supports generating a unified multi-file prompt from comments across tabs. No new work needed here.
- **Git**: The command requires git to be installed and the working directory to be inside a git repository. Git is used for changeset detection (`git diff`, `git merge-base`).
- **Claude Code custom commands**: The command is implemented as a `.claude/commands/` markdown file and relies on Claude Code's custom command execution model.
- **`scripts/install-command.sh`**: The existing install script must be updated to also symlink the new command file for global availability.
