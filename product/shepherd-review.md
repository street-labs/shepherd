# Shepherd Review

## Overview

A slash command (`/shepherd-review`) that orchestrates a multi-file code review workflow within an AI coding agent conversation. Instead of manually identifying which files changed, finding the interesting ones, and invoking `/shepherd` on each one individually, the developer types `/shepherd-review` and the command automatically discovers the changeset of the current branch versus main, filters out uninteresting files (lockfiles, generated code, binaries), generates structured review context (both neutral descriptions and the agent's review feedback), and immediately auto-opens all reviewable files in a single CRPG session — each file appearing as a tab that the user can navigate freely, with context and feedback visible in the tool UI.

This addresses the workflow gap between "I have a branch with changes" and "I want to review my changed files in the CRPG." Today, the developer must manually run `git diff --name-only`, mentally filter out noise files, and invoke `/shepherd` repeatedly. `/shepherd-review` collapses that entire workflow into a single command that batch-opens every reviewable file in one CRPG session with full review context.

The CRPG already supports multi-file tabs, per-file comments, and multi-file prompt generation. `/shepherd-review` leverages this by passing all files and structured context data to a single launch, letting the user review files in any order with the agent's context and feedback visible alongside each diff. The user adds comments on whichever files they choose and clicks "Done" once to produce a unified multi-file prompt covering all reviewed files. The context is split into neutral (factual descriptions of what changed) and review feedback (the agent's opinions and suggestions), displayed as visually distinct sections so the reviewer always knows which is which.

## User Stories

### US-SR-1: Review all interesting changed files in my branch
**As a** developer who has been working with an AI coding agent on a feature branch, **I want to** invoke a single command that opens all meaningfully changed files at once in the CRPG, **so that** I can review every change in a single session without manually tracking which files I have and haven't reviewed.

### US-SR-2: Skip uninteresting files automatically
**As a** developer, **I want** the review command to automatically exclude lockfiles, generated files, and binary files from the review list, **so that** I only spend time reviewing files that contain meaningful, human-authored changes.

### US-SR-3: Get straight into the review without unnecessary prompts
**As a** developer, **I want** the CRPG to open immediately after I invoke `/shepherd-review` without asking me to confirm, **so that** I can start reviewing right away instead of typing "go" in a confirmation step that adds no value.

### US-SR-4: Control the pace of review
**As a** developer, **I want to** navigate between file tabs freely in the CRPG, reviewing files in whatever order and at whatever pace I choose, **so that** I am never forced into a fixed sequence and can spend as much time as I need on each file.

### US-SR-5: Review only the files I care about
**As a** developer, **I want to** leave comments only on the files I care about and click "Done" at any point to end the session, **so that** I am not forced to visit every file and can focus my attention where it matters most.

### US-SR-6: Use the command from any branch
**As a** developer, **I want** the command to work on whatever branch I am currently on and compare against main (or the appropriate base branch), **so that** I do not need to specify branches manually.

### US-SR-7: Review all files in a single CRPG session
**As a** developer, **I want** all reviewable files to open together in one CRPG session with a tab per file, **so that** I can see the full scope of changes, navigate between related files, and produce a single unified review prompt covering all my comments.

### US-SR-8: See context and review feedback in the tool, not the terminal
**As a** developer, **I want** the changeset context and the agent's review feedback to appear in the CRPG UI alongside the diffs I am reviewing, **so that** I do not have to scroll back through the agent conversation in a separate terminal window to find the context about what changed and what the agent thinks. The review context should be where I am doing the review.

### US-SR-9: Distinguish factual context from the agent's opinions
**As a** developer, **I want** the CRPG to clearly separate neutral descriptions of what changed from the agent's review opinions, **so that** I can quickly get oriented on the facts and then decide how much weight to give the agent's suggestions. I do not want the two mixed together as if they are the same kind of information.

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

#### `FR-sr-changeset-overview` -- Generate a structured changeset overview for the CRPG
After detecting and filtering the changeset, the command reads the diffs for all reviewable files and generates a structured overview with two distinct parts:

- **Neutral context** (overall): A factual summary of what the changeset contains — what features or areas are touched, what files changed, the structural nature of the changes (new feature, refactor, bug fix, etc.). This is objective description only; no opinions, quality judgments, or suggestions.
- **Review feedback** (overall): The agent's assessment of the changes — quality observations, potential concerns, patterns worth noting, suggestions for improvement, and things that look good. This is explicitly the agent's take on the changeset.

This overview is not displayed in the agent conversation. Instead, it is passed as structured data to the CRPG (see `FR-sr-context-handoff`) where it is displayed in the tool UI. The separation between neutral context and review feedback must be preserved so the CRPG can present them distinctly, making it clear to the reviewer what is factual description versus the agent's opinion.

#### `FR-sr-file-list-display` -- Show a brief summary in the conversation before auto-opening
After ordering and generating context, the command displays a brief summary in the agent conversation before auto-opening the CRPG. The summary includes:
1. The scope label (all changes vs main, staged only, or unstaged only)
2. The total count of files to review (e.g., "Opening 7 files for review")
3. If any files were filtered out, a note indicating how many were excluded

The detailed file list with per-file context and review feedback is not displayed in the conversation. That information is passed to the CRPG (see `FR-sr-context-handoff`) where it is displayed in the tool UI alongside the actual diffs. The conversation summary is intentionally minimal — just enough to confirm what is happening before the CRPG opens.

#### `FR-sr-per-file-context` -- Generate per-file context with neutral and review separation
For each reviewable file, the command generates context with two distinct parts:

- **Neutral context** (per-file): A factual description of what changed in this file — functions added, modified, or removed; lines changed; structural changes (new exports, renamed parameters, moved logic). This is derived from the diff and should mention specific names and locations. No opinions or quality judgments.
- **Review feedback** (per-file): The agent's observations about this specific file — code quality notes, potential issues, suggestions for improvement, things done well, patterns that look unusual. This is explicitly the agent's opinion.

Per-file context is not displayed in the agent conversation. It is passed as structured data to the CRPG (see `FR-sr-context-handoff`) where each file's context appears alongside its diff in the tool UI. This keeps the review context co-located with the code being reviewed, rather than in a separate conversation window the developer must scroll back to.

#### `FR-sr-context-handoff` -- Pass structured context data to the CRPG
The command passes all generated context to the CRPG as structured data so the tool can display it in its UI. The context data is scoped to the session (tied to the session ID from `FR-sc-session-id`), so concurrent reviews from different worktrees do not clobber each other's context. The data includes:

1. **Overall neutral context**: The factual changeset summary (from `FR-sr-changeset-overview`)
2. **Overall review feedback**: The agent's assessment of the changeset (from `FR-sr-changeset-overview`)
3. **Per-file entries**, each containing:
   - File path (relative to repo root)
   - Change type (added, modified, renamed)
   - Neutral context for this file (from `FR-sr-per-file-context`)
   - Review feedback for this file (from `FR-sr-per-file-context`)
4. **File ordering**: The priority order from `FR-sr-priority-ordering`

The specific mechanism for passing this data (file on disk, URL parameters, or other approach) is an engineering decision. The product requirement is that the CRPG receives all of the above as structured data with the neutral/review distinction preserved, scoped to the session so that concurrent reviews are isolated, and displays both parts in its UI with clear visual separation so the reviewer can distinguish factual context from the agent's opinions.

#### `FR-sr-iteration-loop` -- Auto-open all files in a single CRPG session
Immediately after changeset detection, context generation, and the brief conversation summary (see `FR-sr-file-list-display`), the command auto-opens all reviewable files in a single CRPG session. There is no confirmation prompt — the user invoked `/shepherd-review`, so the intent to review is already established. The CRPG opens automatically.

The files appear as tabs in the CRPG, ordered by review priority (see `FR-sr-priority-ordering`). The structured context data (overall and per-file, neutral and review) is passed to the CRPG alongside the file list (see `FR-sr-context-handoff`). The user navigates between tabs freely, reviewing files in whatever order they choose and adding comments on whichever files they want.

The command invokes the launch script (see `FR-sr-multi-file-launch`) with all file paths and context data, which opens the CRPG with one tab per file. After launching the CRPG, the command presents an interactive prompt (via `AskUserQuestion`) asking the user about their review outcome. The prompt offers three choices:

- **"Added comments"** — The user reviewed files in the CRPG and clicked "Done" (which writes the unified multi-file prompt to `~/.shepherd/sessions/<session-id>/prompt-output.md`). The agent reads the session-scoped prompt output file to collect feedback.
- **"Reviewed, no comments"** — The user looked at the files but did not add any comments. The session proceeds to the completion summary with zero comments.
- **"Cancel"** — The user abandons the review session entirely. The session ends immediately with no summary.

There is no sequential iteration, no "next" or "skip" commands, no per-file prompting, no pre-launch confirmation prompt, and no file-watcher or polling loop. The user controls their review entirely within the CRPG UI and signals completion through the interactive prompt.

#### `FR-sr-feedback-collection` -- Receive unified multi-file feedback from CRPG
After the user selects "Added comments" from the interactive prompt, the agent reads the session-scoped prompt output file (`~/.shepherd/sessions/<session-id>/prompt-output.md`, written by the CRPG's "Done" action). This file contains a single multi-file prompt with all comments across all files, organized by file. The CRPG handles aggregation internally and produces one unified output. If the user selects "Reviewed, no comments", the session proceeds to the completion summary with zero comments. If the user selects "Cancel", the session ends immediately with no summary. The command does NOT need to collect feedback file-by-file — the CRPG aggregates all per-file comments into one prompt output file.

#### `FR-sr-completion-summary` -- Display a review summary and feedback handoff
When the user selects "Added comments" from the interactive prompt and the agent successfully reads the session-scoped prompt output file (`~/.shepherd/sessions/<session-id>/prompt-output.md`), the command displays a summary including: total files opened, filtered count, and files that received comments.

If the prompt output file contains feedback, the command presents the full prompt content and asks the user what to do:
- **apply** — implement the changes described in the feedback
- **discuss** — talk through the feedback before acting
- **save** — write feedback to a file for later
- **nothing** — end the session

When the user selects "Reviewed, no comments" from the interactive prompt, the summary notes that the review was completed with no comments and the session ends cleanly.

When the user selects "Cancel" from the interactive prompt, the session ends immediately with no summary.

#### `FR-sr-command-file` -- Implemented as a Claude Code command file
The command is implemented as a Claude Code custom command file at `.claude/commands/shepherd-review.md`, following the same pattern as the existing `/shepherd` command at `.claude/commands/shepherd.md`. The command file contains the prompt instructions that the AI coding agent executes. No compiled code or external binary is required — the command is pure prompt engineering executed by the agent. The command invokes the launch script with multiple file paths to open all reviewable files in a single CRPG session (see `FR-sr-multi-file-launch`).

#### `FR-sr-multi-file-launch` -- Open multiple files in a single CRPG session
The command opens all reviewable files in a single CRPG session by passing multiple file paths to the launch script (`shepherd-launch.sh`). The launch script constructs a launch URL that tells the CRPG to load all specified files, each appearing as a tab. The tab order matches the priority ordering from `FR-sr-priority-ordering`. The CRPG's existing multi-file support handles tab navigation, per-file comments, and unified prompt generation. The launch script must accept multiple file path arguments (updating its current single-file interface). The application must support receiving multiple files via launch parameters (new engineering work).

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

#### `NFR-sr-startup-speed` -- Fast changeset detection and context generation
The time from invoking `/shepherd-review` to auto-opening the CRPG must be under 5 seconds for repositories with up to 1,000 changed files. The changeset detection relies on git commands that are inherently fast. Context generation (neutral and review, overall and per-file) adds agent processing time but should not introduce significant delay.

#### `NFR-sr-no-dependencies` -- No additional dependencies
The command requires only git (available on the PATH) and the existing `/shepherd` command infrastructure. It does not introduce any new runtime dependencies, npm packages, or compiled binaries.

#### `NFR-sr-agent-native` -- Runs entirely within the agent conversation
The command runs entirely within the AI coding agent's conversation context. It uses only bash commands (git, standard shell utilities) and the existing `/shepherd` command. There is no separate process, daemon, or server beyond what `/shepherd` already manages.

#### `NFR-sr-cross-platform` -- Cross-platform git compatibility
The git commands used by the command must work on macOS, Linux, and Windows (Git Bash or WSL). The command does not rely on platform-specific shell features beyond what is available in bash.

## Acceptance Criteria

#### `AC-sr-happy-path` -- Full review session completes successfully
**Given** the user is on a feature branch with 5 modified source files and 3 lockfiles/generated files relative to main, **when** the user types `/shepherd-review`, **then** the command displays a brief summary ("Opening 5 files for review (3 excluded)") in the conversation and immediately auto-opens all 5 files in a single CRPG session with one tab per file, using a unique session ID. The CRPG displays the overall neutral context and review feedback, and each file tab shows its per-file neutral context and review feedback alongside the diff. There is no confirmation prompt before opening the CRPG. The agent then presents an interactive prompt with three options. The user reviews files freely, clicks "Done" in the CRPG, selects "Added comments" from the interactive prompt, the agent reads the session-scoped prompt output file (`~/.shepherd/sessions/<session-id>/prompt-output.md`), and the command displays a summary with feedback action options.

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
**Given** 5 files are open as tabs in the CRPG, **when** the user clicks "Done" after reviewing only 2 files and selects "Added comments" from the interactive prompt, **then** the agent reads the prompt output and the session proceeds with whatever comments exist at that point. Alternatively, the user can select "Cancel" from the interactive prompt to abandon the session entirely without completing the CRPG review — the session ends immediately with no summary. There is no concept of "remaining" files — the user simply finishes whenever they are ready.

#### `AC-sr-no-changes` -- No changes produces a clear message
**Given** the user is on a branch with no changes relative to main (or is on main itself), **when** the user types `/shepherd-review`, **then** the command outputs "No changes found relative to main." and stops without presenting a file list.

#### `AC-sr-all-filtered` -- All files filtered produces a clear message
**Given** the changeset contains only lockfiles and binary files (every file is excluded by filtering), **when** the file list is computed, **then** the command outputs "No reviewable files found. All 4 changed files were filtered out (lockfiles, generated, binary)." and stops.

#### `AC-sr-not-git-repo` -- Error outside a git repository
**Given** the current working directory is not inside a git repository, **when** the user types `/shepherd-review`, **then** the command outputs "Not a git repository. /shepherd-review must be run from within a git repo." and stops.

#### `AC-sr-invokes-shepherd` -- All files open in a single CRPG session
**Given** the reviewable files are `src/utils.ts`, `src/app.tsx`, and `lib/helpers.ts`, **when** the command launches the review, **then** it invokes the launch script with all three file paths, opening a single CRPG session with three tabs (one per file) in priority order.

#### `AC-sr-list-command` -- File list and context are available in the CRPG
**Given** the command has opened the CRPG with 5 files, **when** the user wants to reference the file list and context while reviewing, **then** the overall neutral context and review feedback are visible in the CRPG UI (not in the agent conversation). Each file tab shows its per-file neutral context and review feedback alongside the diff. The CRPG tab bar shows all file names for navigation.

#### `AC-sr-completion-summary` -- Summary displays after CRPG prompt is returned
**Given** the user completes a review of 5 files and selects "Added comments" from the interactive prompt, **when** the agent reads the session-scoped prompt output file (`~/.shepherd/sessions/<session-id>/prompt-output.md`), **then** the command displays a summary showing the total files opened, the number of files that received comments, and presents the action options (apply, discuss, save, nothing).

#### `AC-sr-sorted-file-list` -- Files are sorted by review priority and tab order matches
**Given** the changeset includes `src/utils.ts`, `src/app.tsx`, `lib/helpers.ts`, `tests/utils.test.ts`, and `README.md`, **when** the file list is displayed and the CRPG opens, **then** the files appear in priority order (core source first, then config, then docs, then tests) both in the displayed list and in the CRPG tab order.

#### `AC-sr-batch-open` -- All files open as tabs in a single CRPG session
**Given** there are 5 reviewable files, **when** the command finishes changeset detection and context generation, **then** a single CRPG session auto-opens with 5 tabs (one per file), without any confirmation prompt. The user does not need to wait for sequential prompts or invoke any per-file commands.

#### `AC-sr-unified-prompt` -- CRPG generates a single multi-file prompt
**Given** the user has added comments on 3 of 5 open files in the CRPG, **when** the user clicks "Done", **then** the CRPG generates a single prompt that includes all comments organized by file and writes it to the session-scoped path (`~/.shepherd/sessions/<session-id>/prompt-output.md`). The agent reads this file after the user selects "Added comments" from the interactive prompt.

#### `AC-sr-install-global` -- Command is available globally via symlink
**Given** the user runs `./scripts/install-command.sh`, **when** the script completes, **then** a symlink exists at `~/.claude/commands/shepherd-review.md` pointing to the repo's `.claude/commands/shepherd-review.md`, and `/shepherd-review` is available as a global command in Claude Code.

#### `AC-sr-context-in-crpg` -- Context is displayed in the CRPG with clear neutral/review separation
**Given** the command has generated overall and per-file context (both neutral and review), **when** the CRPG opens, **then** the overall neutral context and overall review feedback are displayed in the CRPG UI as visually distinct sections. For each file tab, the per-file neutral context and per-file review feedback are displayed alongside the diff, also as visually distinct sections. The reviewer can tell at a glance which text is factual description and which is the agent's opinion.

#### `AC-sr-auto-open` -- CRPG opens without confirmation prompt
**Given** the user types `/shepherd-review` and there are reviewable files, **when** changeset detection and context generation complete, **then** the CRPG opens automatically. The user is not asked "Ready to start?" or any similar confirmation question. The brief summary appears in the conversation and the CRPG opens immediately.

#### `AC-sr-interactive-prompt` -- Interactive prompt presented after CRPG launch
**Given** the CRPG has been opened with N files, **when** the agent finishes launching the CRPG, **then** it presents an interactive prompt (`AskUserQuestion`) with three options: "Added comments", "Reviewed, no comments", and "Cancel". There is no file-watcher polling loop. The agent waits for the user's selection before proceeding.

## Open Questions

1. **Base branch detection**: The spec defaults to `main` as the base branch. Some repositories use `master`, `develop`, or other branch names. Should the command attempt to auto-detect the default branch (e.g., by reading `git symbolic-ref refs/remotes/origin/HEAD`), or should it accept an optional argument to override the base branch? V1 assumes `main`; auto-detection or an override argument is a natural v2 enhancement.

2. ~~**File ordering strategy**: Resolved — files are sorted by review priority (see `FR-sr-priority-ordering`). Priority ordering determines both the displayed list order and the CRPG tab order. Core source files appear first, tests last.~~

3. **Resumable sessions**: If the user quits early and later runs `/shepherd-review` again, should it offer to resume where they left off? This would require some form of state persistence (e.g., a dotfile in the repo). Deferred; each invocation starts fresh in v1.

4. ~~**Per-file context/summary**: Resolved — per-file context is generated by the agent and passed to the CRPG as structured data (see `FR-sr-per-file-context`, `FR-sr-context-handoff`). Each file's context appears in the CRPG UI alongside its diff, split into neutral context (factual) and review feedback (agent's opinion). Context is displayed in the tool where the review happens, not in the agent conversation.~~

5. **Custom exclusion patterns**: Should the user be able to customize which files are filtered out (e.g., via a `.shepherd-review.yml` config file)? Deferred. The built-in heuristics should cover the vast majority of cases for v1.

6. **Diff view vs. file view**: When `/shepherd` opens a file in the CRPG, the user can choose file view or diff view. Should `/shepherd-review` default to diff view (since the whole point is reviewing changes)? This is a UX question best resolved in the design phase. The product spec does not mandate a default view mode; that is left to the existing CRPG and `/shepherd` behavior.

7. **Renamed file handling**: Git reports renames as a pair (old path, new path). The command should use the new path (which exists on disk). Should it also mention the old path in the file list annotation? Deferred to design.

8. **Maximum batch size**: Is there a practical upper limit on how many files can be batch-opened as tabs in a single CRPG session? For very large changesets (e.g., 50+ files), the file list may become unwieldy and the launch mechanism may hit platform limits. Should the command warn or paginate above a threshold? Deferred to design/engineering to determine practical limits.

9. **URL parameter format for multiple files**: The CRPG currently supports `?file=<path>` for a single file. The multi-file URL format (e.g., repeated `file` params, comma-separated, or a different mechanism) needs to be defined in engineering. This is a technical design decision, not a product decision.

10. ~~**Prompt return mechanism**: Resolved — the CRPG writes the unified multi-file prompt to `~/.shepherd/prompt-output.md` when the user clicks "Done." After opening the CRPG, the agent presents an interactive prompt (`AskUserQuestion`) with three options: "Added comments" (reads the prompt output file), "Reviewed, no comments" (proceeds with no-feedback summary), or "Cancel" (ends session). No file-watcher or polling is needed.~~

## Dependencies

- **`shepherd-launch.sh` script**: The launch script must be updated to accept multiple file path arguments, context data, and construct a URL that loads all files as tabs in a single CRPG session. Currently supports a single `?file=<path>` parameter. Must also support passing structured context data (overall and per-file, neutral and review) to the CRPG.
- **CRPG multi-file URL support**: The CRPG must support loading multiple files from launch parameters (new engineering work). The in-app multi-file support already exists; this dependency is specifically about initializing a multi-file session from the launch mechanism.
- **CRPG context display**: The CRPG must support receiving and displaying structured context data (see `FR-sr-context-handoff`). This includes overall neutral context and review feedback displayed in the UI, plus per-file neutral context and review feedback displayed alongside each file's diff. The neutral and review sections must be visually distinct. This is new engineering work.
- **CRPG multi-file prompt generation**: The CRPG already supports generating a unified multi-file prompt from comments across tabs and writing it to the session-scoped path (`~/.shepherd/sessions/<session-id>/prompt-output.md`). No new work needed here beyond session-scoping (see `FR-sc-session-scoped-output`). The agent uses an interactive prompt (`AskUserQuestion`) rather than a file-watcher or polling mechanism to determine when the user is done and which outcome to process. The prompt output file is still written by the CRPG; only the path is now session-scoped.
- **Git**: The command requires git to be installed and the working directory to be inside a git repository. Git is used for changeset detection (`git diff`, `git merge-base`).
- **Claude Code custom commands**: The command is implemented as a `.claude/commands/` markdown file and relies on Claude Code's custom command execution model. The command uses `AskUserQuestion` (a standard agent capability) to present the interactive prompt after launching the CRPG.
- **`scripts/install-command.sh`**: The existing install script must be updated to also symlink the new command file for global availability.
