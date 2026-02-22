# Shepherd Review

## Overview

A slash command (`/shepherd-review`) that orchestrates a multi-file code review workflow within an AI coding agent conversation. Instead of manually identifying which files changed, finding the interesting ones, and invoking `/shepherd` on each one individually, the developer types `/shepherd-review` and the command automatically discovers the changeset of the current branch versus main, filters out uninteresting files (lockfiles, generated code, binaries), presents a numbered list of files to review, and then walks through them one by one — invoking the existing `/shepherd` command for each file and waiting for the user to finish before moving to the next.

This addresses the workflow gap between "I have a branch with changes" and "I want to review each changed file in the CRPG." Today, the developer must manually run `git diff --name-only`, mentally filter out noise files, and invoke `/shepherd` repeatedly. `/shepherd-review` collapses that entire workflow into a single command with an interactive iteration loop.

V1 is intentionally simple: discover files, filter, present, iterate. No per-file context summaries, no AI-generated descriptions of changes, no batch operations. Just the loop.

## User Stories

### US-SR-1: Review all interesting changed files in my branch
**As a** developer who has been working with an AI coding agent on a feature branch, **I want to** invoke a single command that walks me through each meaningfully changed file one at a time in the CRPG, **so that** I can systematically review every change without manually tracking which files I have and haven't reviewed.

### US-SR-2: Skip uninteresting files automatically
**As a** developer, **I want** the review command to automatically exclude lockfiles, generated files, and binary files from the review list, **so that** I only spend time reviewing files that contain meaningful, human-authored changes.

### US-SR-3: See the full list before starting
**As a** developer, **I want to** see the complete list of files that will be reviewed before the iteration begins, **so that** I can understand the scope of the review and mentally prepare for what is ahead.

### US-SR-4: Control the pace of iteration
**As a** developer, **I want to** tell the agent when I am done with a file and ready for the next one, **so that** I am never rushed and can spend as much time as I need on each file.

### US-SR-5: Skip a file or stop early
**As a** developer, **I want to** skip a file I do not want to review or stop the review entirely before reaching the end, **so that** I am not locked into reviewing every single file if I change my mind.

### US-SR-6: Use the command from any branch
**As a** developer, **I want** the command to work on whatever branch I am currently on and compare against main (or the appropriate base branch), **so that** I do not need to specify branches manually.

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

#### `FR-sr-per-file-context` -- Provide per-file context before opening each file
Before opening each file in the CRPG, the command provides a 2-4 sentence summary of what changed in that specific file: what was added, modified, or removed, and why it matters. This is derived from the diff and should mention specific function names, sections, or structural changes. The reviewer should understand what to look for before the file opens.

#### `FR-sr-iteration-loop` -- Iterate through files one by one
When the user confirms they want to proceed, the command begins iterating through the file list in priority order. For each file:
1. The command announces the current file with its position, path, change type, and a context summary of what changed.
2. The command invokes the existing `/shepherd` command with the file path, which opens the file in the CRPG.
3. The command then waits for the user to indicate they are done reviewing the file.

The user can respond with:
- **"next"** (or "done", "continue", "n", "looks good", "lgtm") — file looks good, move on
- **"feedback"** (or "comments", "paste", "f") — the user has comments to share; they will paste CRPG output
- **"skip"** — skip the current file without reviewing it
- **"quit"** (or "stop", "exit", "q") — end the review session immediately
- **"list"** — re-display the full file list with the current position highlighted

#### `FR-sr-feedback-collection` -- Collect and accumulate review feedback
When the user chooses "feedback" during the iteration, the command prompts them to paste their comments (typically the generated prompt output from the CRPG). The pasted content is stored in memory, tagged with the file path it pertains to. The command does NOT act on the feedback immediately — it simply acknowledges receipt and lets the user continue reviewing.

Feedback accumulates across all files during the review session. After the review is complete, all collected feedback is presented together for the user to decide what to do with it.

#### `FR-sr-completion-summary` -- Display a review summary and feedback handoff
When the review loop ends (either all files reviewed or the user quit early), the command displays a summary including: total files, filtered count, reviewed count, skipped count, files with feedback, and remaining count (if quit early).

If feedback was collected, it is displayed in full, grouped by file, followed by a prompt asking the user what to do:
- **apply** — implement the changes described in the feedback
- **discuss** — talk through the feedback before acting
- **save** — write feedback to a file for later
- **nothing** — end the session

If no feedback was collected, the summary notes this and the session ends.

#### `FR-sr-command-file` -- Implemented as a Claude Code command file
The command is implemented as a Claude Code custom command file at `.claude/commands/shepherd-review.md`, following the same pattern as the existing `/shepherd` command at `.claude/commands/shepherd.md`. The command file contains the prompt instructions that the AI coding agent executes. No compiled code or external binary is required — the command is pure prompt engineering executed by the agent.

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

#### `AC-sr-happy-path` -- Full review loop completes successfully
**Given** the user is on a feature branch with 5 modified source files and 3 lockfiles/generated files relative to main, **when** the user types `/shepherd-review`, **then** the command displays "Found 5 files to review (3 excluded)" with a numbered list, and after the user confirms, iterates through all 5 files by invoking `/shepherd` for each, waiting for the user to say "next" between each file, and displays a completion summary at the end.

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

#### `AC-sr-skip-file` -- User can skip a file
**Given** the review iteration is on file 2 of 5, **when** the user says "skip", **then** the command moves to file 3 without invoking `/shepherd` for file 2, and the final summary counts file 2 as skipped.

#### `AC-sr-quit-early` -- User can quit the review early
**Given** the review iteration is on file 3 of 5, **when** the user says "quit", **then** the review ends immediately and the summary shows 2 files reviewed (or reviewed + skipped), 2 remaining, and that the user quit early.

#### `AC-sr-no-changes` -- No changes produces a clear message
**Given** the user is on a branch with no changes relative to main (or is on main itself), **when** the user types `/shepherd-review`, **then** the command outputs "No changes found relative to main." and stops without presenting a file list.

#### `AC-sr-all-filtered` -- All files filtered produces a clear message
**Given** the changeset contains only lockfiles and binary files (every file is excluded by filtering), **when** the file list is computed, **then** the command outputs "No reviewable files found. All 4 changed files were filtered out (lockfiles, generated, binary)." and stops.

#### `AC-sr-not-git-repo` -- Error outside a git repository
**Given** the current working directory is not inside a git repository, **when** the user types `/shepherd-review`, **then** the command outputs "Not a git repository. /shepherd-review must be run from within a git repo." and stops.

#### `AC-sr-invokes-shepherd` -- Each file opens via /shepherd
**Given** the iteration is on file `src/utils.ts`, **when** the command processes that file, **then** it invokes the existing `/shepherd` slash command with the full path to `src/utils.ts`, which opens the file in the CRPG in the browser.

#### `AC-sr-list-command` -- User can re-display the file list
**Given** the review iteration is on file 3 of 7, **when** the user says "list", **then** the command re-displays the numbered file list with file 3 highlighted or indicated as the current file, and then continues waiting for the user's next instruction on file 3.

#### `AC-sr-completion-summary` -- Summary displays at the end
**Given** the user completes a review of 5 files (reviewing 4, skipping 1), **when** the last file is processed, **then** the command displays a summary showing 5 files to review, 4 reviewed, 1 skipped, 0 remaining.

#### `AC-sr-sorted-file-list` -- Files are sorted by directory then name
**Given** the changeset includes `src/utils.ts`, `src/app.tsx`, `lib/helpers.ts`, and `README.md`, **when** the file list is displayed, **then** the files are grouped by directory and sorted alphabetically: `lib/helpers.ts`, `README.md`, `src/app.tsx`, `src/utils.ts`.

#### `AC-sr-install-global` -- Command is available globally via symlink
**Given** the user runs `./scripts/install-command.sh`, **when** the script completes, **then** a symlink exists at `~/.claude/commands/shepherd-review.md` pointing to the repo's `.claude/commands/shepherd-review.md`, and `/shepherd-review` is available as a global command in Claude Code.

## Open Questions

1. **Base branch detection**: The spec defaults to `main` as the base branch. Some repositories use `master`, `develop`, or other branch names. Should the command attempt to auto-detect the default branch (e.g., by reading `git symbolic-ref refs/remotes/origin/HEAD`), or should it accept an optional argument to override the base branch? V1 assumes `main`; auto-detection or an override argument is a natural v2 enhancement.

2. **File ordering strategy**: The spec sorts files alphabetically by directory and name. An alternative would be to sort by "most interesting" (e.g., source files before tests, larger diffs before smaller ones) or by dependency order. For v1, alphabetical sorting is simple and predictable. More sophisticated ordering is deferred.

3. **Resumable sessions**: If the user quits early and later runs `/shepherd-review` again, should it offer to resume where they left off? This would require some form of state persistence (e.g., a dotfile in the repo). Deferred; each invocation starts fresh in v1.

4. **Per-file context/summary**: The user explicitly deferred this. A future enhancement could show a brief summary of what changed in each file (lines added/removed, a one-sentence AI description) before opening it. Not in v1.

5. **Custom exclusion patterns**: Should the user be able to customize which files are filtered out (e.g., via a `.shepherd-review.yml` config file)? Deferred. The built-in heuristics should cover the vast majority of cases for v1.

6. **Diff view vs. file view**: When `/shepherd` opens a file in the CRPG, the user can choose file view or diff view. Should `/shepherd-review` default to diff view (since the whole point is reviewing changes)? This is a UX question best resolved in the design phase. The product spec does not mandate a default view mode; that is left to the existing CRPG and `/shepherd` behavior.

7. **Renamed file handling**: Git reports renames as a pair (old path, new path). The command should use the new path (which exists on disk). Should it also mention the old path in the file list annotation? Deferred to design.

## Dependencies

- **`/shepherd` slash command** (`FR-sc-invoke-command`): The iteration loop invokes `/shepherd <filepath>` for each file. The entire per-file review experience is delegated to the existing command.
- **Git**: The command requires git to be installed and the working directory to be inside a git repository. Git is used for changeset detection (`git diff`, `git merge-base`).
- **Claude Code custom commands**: The command is implemented as a `.claude/commands/` markdown file and relies on Claude Code's custom command execution model.
- **`scripts/install-command.sh`**: The existing install script must be updated to also symlink the new command file for global availability.
