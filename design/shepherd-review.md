# Shepherd Review -- Design Spec

> Based on requirements in `../product/shepherd-review.md`

## Overview

This spec defines the conversational user experience for the `/shepherd-review` slash command. Unlike other design specs in this project that describe web UI screens and components, this spec describes a text-based interaction that takes place entirely within an AI coding agent conversation (Claude Code). The agent outputs formatted plain text, prompts the user for input at defined points, and invokes the existing `/shepherd` command to open individual files in the CRPG browser app.

There is no new web UI. The "interface" is the sequence of text messages exchanged between the agent and the user in the agent conversation, plus the existing CRPG browser experience invoked via `/shepherd`.

---

## Interface Inventory

| Surface | Role |
|---|---|
| **Agent conversation (Claude Code)** | Primary surface. All file discovery, filtering, list display, iteration prompts, and summary messages appear here as plain text. |
| **CRPG web app (browser)** | Secondary surface. Invoked via the existing `/shepherd` command for each file the user chooses to review. The CRPG experience is unchanged; this spec does not modify it. |

The agent conversation is the orchestration layer. The CRPG is the per-file review tool. This spec covers only the orchestration layer.

---

## Command Syntax (`FR-sr-no-args`, `FR-sr-command-file`)

```
/shepherd-review
```

No arguments. No flags. No options. The command auto-detects the current branch and compares against `main` (`FR-sr-changeset-detection`).

The command is implemented as a Claude Code custom command file at `.claude/commands/shepherd-review.md`. It is installed globally via `scripts/install-command.sh` (`FR-sr-install`).

---

## Output Format

All output is plain text rendered in the agent conversation. No emoji, no ANSI escape codes, no color codes, no rich formatting beyond what the agent conversation natively supports (plain text, code blocks). Every message the agent produces is specified below with exact wording.

### File List Display (`FR-sr-file-list-display`, `AC-sr-sorted-file-list`)

After changeset detection and filtering, the agent displays the file list in this exact format:

```
Found <N> files to review.

  1. <relative-path>  [<change-type>]
  2. <relative-path>  [<change-type>]
  3. <relative-path>  [<change-type>]
  ...

<M> files excluded (lockfiles, generated, binary).

Ready to start? Say "go" to begin, or "quit" to cancel.
```

Field definitions:

- `<N>` -- the count of files that passed filtering. Always a positive integer in this format (the zero case is handled separately).
- `<relative-path>` -- the file path relative to the repository root. Uses forward slashes on all platforms. Sorted by directory then by filename alphabetically (`AC-sr-sorted-file-list`). Root-level files (no directory) sort before any directory. Within the same directory level, directories are interleaved alphabetically with files.
- `<change-type>` -- one of `modified`, `added`, or `renamed`. Displayed in square brackets after two spaces. For renamed files, the format is `renamed from <old-path>` (addressing Open Question 7 from the product spec).
- Position numbers are right-aligned to the width of the largest number. For 1-9 files, no padding is needed. For 10-99 files, single-digit numbers are padded with a leading space. For example, with 12 files: ` 1.` through `12.`.
- The exclusion line appears only if `<M>` is greater than zero. If no files were excluded, this line is omitted.
- A blank line separates the count line from the numbered list, the numbered list from the exclusion line, and the exclusion line from the prompt.

**Sorting rules** (detailed):

Files are sorted by their full relative path using a directory-first alphabetical sort. Concretely:
1. Split each path into its directory components and filename.
2. Root-level files (no directory prefix) sort before any files inside directories.
3. Within the same directory, files sort alphabetically by filename (case-insensitive).
4. Directories sort alphabetically relative to each other (case-insensitive).
5. Files in a parent directory sort before files in its subdirectories.

Example: given `src/utils.ts`, `src/app.tsx`, `lib/helpers.ts`, `README.md`, `src/components/Button.tsx`, the sorted order is:

```
  1. README.md                          [modified]
  2. lib/helpers.ts                     [added]
  3. src/app.tsx                        [modified]
  4. src/components/Button.tsx           [added]
  5. src/utils.ts                       [modified]
```

### File Announcement Format (`FR-sr-iteration-loop`)

When the iteration moves to a new file, the agent announces it:

```
[<position>/<total>] <relative-path>  [<change-type>]

Opening in the Code Review Prompt Generator...
```

- `<position>` -- the 1-based index of the current file.
- `<total>` -- the total number of files to review.
- The announcement is followed by a blank line, then the "Opening..." line.
- After the "Opening..." line, the agent invokes `/shepherd <absolute-path>` (`AC-sr-invokes-shepherd`). The `/shepherd` command output appears naturally in the conversation.

### User Prompt Format (Waiting for Input)

After `/shepherd` finishes loading the file, the agent displays:

```
Review this file in the browser, then tell me when you are ready.

  next     Move to the next file
  skip     Skip this file
  list     Show the file list
  quit     End the review

>
```

The `>` character on its own line indicates the agent is waiting for user input. The menu is always shown in full each time (not abbreviated after the first file) so the user does not need to memorize commands.

### Re-displayed File List (In-Progress) (`AC-sr-list-command`)

When the user says "list" during the iteration, the file list is re-displayed with the current file indicated:

```
  1. README.md                          [modified]
  2. lib/helpers.ts                     [added]
> 3. src/app.tsx                        [modified]
  4. src/components/Button.tsx           [added]
  5. src/utils.ts                       [modified]

Currently reviewing file 3 of 5.
```

- The current file is indicated by a `>` character replacing the leading space before the position number.
- Already-reviewed files are not visually distinguished from upcoming files. The current-position indicator is sufficient to communicate progress.
- Below the list, a summary line states the current position.
- After displaying the list, the agent returns to the user prompt format (the menu with `next`, `skip`, `list`, `quit` options) for the current file. It does not re-invoke `/shepherd`.

### Completion Summary Format (`FR-sr-completion-summary`, `AC-sr-completion-summary`)

When the review ends (all files processed or user quit), the agent displays:

```
Review complete.
  <T> files in changeset
  <E> filtered out (lockfiles, generated, binary)
  <R> files to review
  <V> reviewed
  <S> skipped
```

- `<T>` -- total files detected in the changeset (before filtering, excluding deleted files).
- `<E>` -- files excluded by filtering. This line is omitted if `<E>` is zero.
- `<R>` -- files presented for review (T minus E). Equals `<N>` from the file list display.
- `<V>` -- files that the user advanced past with "next" or "done" (files where `/shepherd` was invoked).
- `<S>` -- files the user explicitly skipped.
- Numbers are right-aligned to the width of the largest number in the summary for readability.

If the user quit early (`AC-sr-quit-early`), two additional lines appear:

```
  <Q> remaining (quit early)
```

- `<Q>` -- files that were not reached (not reviewed and not skipped) because the user quit.

Full example for a quit-early scenario:

```
Review complete.
  12 files in changeset
   5 filtered out (lockfiles, generated, binary)
   7 files to review
   4 reviewed
   1 skipped
   2 remaining (quit early)
```

### Error Message Formats

All error messages are a single output from the agent. No further interaction follows an error -- the command stops.

**Not a git repository** (`FR-sr-git-required`, `AC-sr-not-git-repo`):

```
Not a git repository. /shepherd-review must be run from within a git repo.
```

**No changes found** (`AC-sr-no-changes`):

```
No changes found relative to main.
```

This covers both the case where the user is on `main` itself and the case where the branch has no divergence from `main`.

**All files filtered** (`AC-sr-all-filtered`):

```
No reviewable files found. All <N> changed files were filtered out (lockfiles, generated, binary).
```

- `<N>` is the total number of files in the changeset before filtering.

---

## Interaction Flows

### Flow 1: Happy Path -- Full Review Loop (`AC-sr-happy-path`)

This flow covers a complete review of all files from start to finish.

1. User types `/shepherd-review` in their Claude Code session.
2. Agent reads the custom command file and begins execution.
3. Agent checks that the current working directory is inside a git repository by running `git rev-parse --is-inside-work-tree`. If this fails, agent outputs the "Not a git repository" error and stops (`FR-sr-git-required`).
4. Agent determines the merge base between HEAD and `main` using `git merge-base HEAD main` (`FR-sr-changeset-detection`). If this fails (e.g., `main` does not exist or HEAD is `main` with no divergence), agent outputs "No changes found relative to main." and stops.
5. Agent runs `git diff --name-status <merge-base>...HEAD` to get the list of changed files with their change types (M=modified, A=added, R=renamed, D=deleted).
6. Agent removes deleted files from the list (`AC-sr-excludes-deleted`).
7. Agent applies the filtering rules from `FR-sr-file-filtering` to exclude lockfiles, generated files, binary files, IDE files, and snapshot files (`AC-sr-filters-lockfiles`, `AC-sr-filters-generated`, `AC-sr-filters-binary`). Config files listed in the inclusion rules are kept (`AC-sr-includes-config`).
8. Agent sorts the remaining files by directory and then by filename alphabetically (`AC-sr-sorted-file-list`).
9. Agent displays the file list (see "File List Display" format above).
10. Agent waits for the user to respond.
11. User says "go" (or equivalent affirmative: "yes", "start", "y", "ok", "begin").
12. Agent enters the iteration loop. For each file:
    a. Agent displays the file announcement (see "File Announcement Format").
    b. Agent invokes `/shepherd <absolute-path>` to open the file in the CRPG (`AC-sr-invokes-shepherd`).
    c. Agent displays the user prompt (see "User Prompt Format").
    d. User says "next" (or "done", "continue", "n").
    e. Agent records the file as "reviewed" and moves to the next file.
13. After the last file is processed, agent displays the completion summary (see "Completion Summary Format").

### Flow 2: No Changes Found (`AC-sr-no-changes`)

1. User types `/shepherd-review`.
2. Agent verifies git repository (passes).
3. Agent determines the merge base. Either HEAD is `main` itself, or there is no divergence.
4. Agent outputs:
   ```
   No changes found relative to main.
   ```
5. Command ends. No file list, no iteration.

### Flow 3: All Files Filtered (`AC-sr-all-filtered`)

1. User types `/shepherd-review`.
2. Agent verifies git repository (passes).
3. Agent detects the changeset: 4 files (e.g., `package-lock.json`, `yarn.lock`, `dist/bundle.js`, `logo.png`).
4. All 4 files match exclusion rules. Zero files remain after filtering.
5. Agent outputs:
   ```
   No reviewable files found. All 4 changed files were filtered out (lockfiles, generated, binary).
   ```
6. Command ends. No file list, no iteration.

### Flow 4: Not a Git Repository (`AC-sr-not-git-repo`)

1. User types `/shepherd-review`.
2. Agent runs `git rev-parse --is-inside-work-tree`. The command fails.
3. Agent outputs:
   ```
   Not a git repository. /shepherd-review must be run from within a git repo.
   ```
4. Command ends.

### Flow 5: User Skips a File (`AC-sr-skip-file`)

1. Review iteration is on file 2 of 5. The agent has displayed the file announcement and user prompt.
2. User says "skip".
3. Agent does NOT invoke `/shepherd` for this file (if it had not already been invoked). Note: per the iteration loop design, `/shepherd` is invoked before the prompt, so the file will already have been opened. The "skip" response means the user is choosing not to spend time reviewing it. The agent records the file as "skipped" (not "reviewed") for the summary.
4. Agent moves to file 3 and displays its announcement and prompt.
5. At completion, the summary counts file 2 as "skipped".

Design note on skip behavior: Because `/shepherd` is invoked as part of the file announcement (before the prompt), the browser will have already opened the file when the user says "skip." The skip action is a bookkeeping distinction -- it signals intent ("I chose not to review this") rather than preventing the file from being opened. The alternative design (prompting before opening) was rejected because it would add an extra interaction step for every file in the common case where the user does review the file.

### Flow 6: User Quits Early (`AC-sr-quit-early`)

1. Review iteration is on file 3 of 5. The agent has displayed the file announcement and user prompt.
2. User says "quit" (or "stop", "exit", "q").
3. Agent immediately ends the iteration loop.
4. Agent displays the completion summary. The summary shows files 1-2 as reviewed (or reviewed/skipped as appropriate), file 3 as the file where the user quit (counted based on whether `/shepherd` was invoked -- since it was, file 3 counts as reviewed), and files 4-5 as remaining.

Example summary for this scenario (assuming files 1 and 2 were reviewed normally):

```
Review complete.
  8 files in changeset
  3 filtered out (lockfiles, generated, binary)
  5 files to review
  3 reviewed
  0 skipped
  2 remaining (quit early)
```

### Flow 7: User Says "list" to Re-display Files (`AC-sr-list-command`)

1. Review iteration is on file 3 of 7. The agent has displayed the file announcement and user prompt.
2. User says "list".
3. Agent re-displays the full file list with the current position indicated (see "Re-displayed File List" format).
4. Agent re-displays the user prompt for file 3.
5. The user's next response applies to file 3 (the list command does not change the current position).

### Flow 8: User Cancels Before Starting

1. Agent displays the file list and the "Ready to start?" prompt.
2. User says "quit" (or "no", "cancel", "stop", "exit", "q").
3. Agent outputs:
   ```
   Review cancelled.
   ```
4. Command ends. No summary is displayed because no files were iterated.

---

## User Input Recognition

The agent must recognize variations of user commands. The following table defines the canonical command and its accepted synonyms. Matching is case-insensitive.

| Canonical | Synonyms | Context |
|---|---|---|
| `go` | "yes", "start", "y", "ok", "begin", "ready" | Pre-iteration prompt only |
| `next` | "done", "continue", "n", "next file" | During iteration only |
| `skip` | "skip this", "pass" | During iteration only |
| `quit` | "stop", "exit", "q", "quit review", "cancel", "no" | Both pre-iteration and during iteration |
| `list` | "show files", "show list", "files" | During iteration only |

If the user's input does not match any recognized command, the agent responds:

```
I did not understand that. Your options are:

  next     Move to the next file
  skip     Skip this file
  list     Show the file list
  quit     End the review

>
```

At the pre-iteration prompt, the unrecognized input message is:

```
I did not understand that. Say "go" to begin the review, or "quit" to cancel.

>
```

---

## Change Type Detection and Display

The `git diff --name-status` output provides change type codes. These are mapped to display labels as follows:

| Git Code | Display Label | Notes |
|---|---|---|
| `M` | `modified` | File existed on base branch and has been changed |
| `A` | `added` | File is new on this branch |
| `R` (with old/new paths) | `renamed from <old-path>` | File was renamed; show old path for context |
| `C` | `added` | Copied file; treat as added for review purposes |
| `T` | `modified` | Type change (e.g., file to symlink); rare, treat as modified |

Deleted files (`D`) are excluded from the list entirely (`AC-sr-excludes-deleted`).

For renamed files, the list display shows the new path as the file path and `renamed from <old-path>` as the change type:

```
  3. src/utils/helpers.ts               [renamed from src/helpers.ts]
```

The `/shepherd` command is invoked with the new path (which exists on disk).

---

## Filtering Implementation Notes (`FR-sr-file-filtering`)

The filtering is performed by the agent using path-pattern matching only. No file contents are read during filtering (`FR-sr-file-filtering` specifies heuristic path-based filtering). The agent applies the exclusion rules in the order defined in the product spec.

The filtering logic is embedded in the command file's prompt instructions. The agent evaluates each file path against the exclusion patterns and removes matches. Files that do not match any exclusion pattern are included.

The exclusion count displayed in the file list is the total count of files removed by filtering (including deleted files, which are conceptually "filtered" even though they are removed for a different reason). This ensures `<T> = <E> + <R>` in the summary.

Design decision: Deleted files are counted in `<T>` (total files in changeset) and in `<E>` (filtered out), not shown as a separate category. This keeps the summary simple. The user does not need to know the breakdown of why files were filtered -- they just need to know how many were excluded and that the remaining files are the ones worth reviewing.

---

## Pacing and Flow Considerations

The interaction is designed to avoid overwhelming the user and to keep them oriented at all times:

1. **Before iteration**: The full file list gives the user an overview. They can mentally prepare for what they will review. The explicit "go" confirmation prevents the iteration from starting unexpectedly.

2. **During iteration**: Each file announcement clearly states position and total (`[3/7]`), so the user always knows where they are in the review. The full command menu is repeated at every prompt so the user never has to remember available commands.

3. **List command**: Available at any point during iteration for re-orientation. Does not interrupt the current file or change position.

4. **After iteration**: The summary provides closure -- the user knows exactly what happened during the review session.

5. **Error cases**: All errors are concise single-line (or near-single-line) messages. No interactive recovery is attempted. The user can simply re-invoke the command after addressing the issue.

---

## Interaction with the `/shepherd` Command (`AC-sr-invokes-shepherd`)

When the iteration loop processes a file, the agent invokes the existing `/shepherd` slash command. This is a direct invocation -- the agent calls `/shepherd <absolute-path-to-file>` as if the user had typed it. The `/shepherd` command handles all file validation, server management, and browser opening as defined in `design/slash-command.md`.

The agent constructs the absolute path by combining the repository root (from `git rev-parse --show-toplevel`) with the relative file path from the changeset.

If `/shepherd` reports an error for a particular file (e.g., the file was deleted between changeset detection and iteration, or a permission error), the agent displays the error as-is (it comes from `/shepherd`'s own error formatting) and then moves to the user prompt. The user can then say "next" to move on or "quit" to end the review. The file is counted as "reviewed" in the summary (the attempt was made).

---

## Installation (`FR-sr-install`, `AC-sr-install-global`)

The `scripts/install-command.sh` script is updated to also create a symlink for the review command:

```
~/.claude/commands/shepherd-review.md -> <repo>/.claude/commands/shepherd-review.md
```

This follows the same pattern as the existing `/shepherd` symlink. Both symlinks are created by the same install script. Updates propagate via `git pull` as with the existing command.

---

## Requirement Traceability

### Functional Requirements

| Slug | Design Coverage |
|---|---|
| `FR-sr-changeset-detection` | Flow 1 steps 4-5; Change Type Detection table; Flow 2 (no changes case) |
| `FR-sr-file-filtering` | Flow 1 step 7; Filtering Implementation Notes section; Flow 3 (all filtered case) |
| `FR-sr-file-list-display` | Output Format -- File List Display; sorting rules and example |
| `FR-sr-iteration-loop` | Output Format -- File Announcement and User Prompt; Flow 1 step 12; User Input Recognition table |
| `FR-sr-completion-summary` | Output Format -- Completion Summary Format; Flow 1 step 13; Flow 6 (quit early summary) |
| `FR-sr-command-file` | Command Syntax section |
| `FR-sr-install` | Installation section |
| `FR-sr-no-args` | Command Syntax section |
| `FR-sr-git-required` | Flow 4 (not a git repo); Error Message Formats |

### Non-Functional Requirements

| Slug | Design Coverage |
|---|---|
| `NFR-sr-startup-speed` | Implicit -- the command uses only fast git operations (Flow 1 steps 3-5); no file content reading during filtering (Filtering Implementation Notes) |
| `NFR-sr-no-dependencies` | Implicit -- the command file uses only git and the existing `/shepherd` command; no new tools introduced |
| `NFR-sr-agent-native` | Entire spec -- all interaction happens in the agent conversation; Output Format section specifies plain text only |
| `NFR-sr-cross-platform` | Implicit -- git commands used (diff, merge-base, rev-parse) are cross-platform; forward-slash paths in display |

### Acceptance Criteria

| Slug | Design Coverage |
|---|---|
| `AC-sr-happy-path` | Flow 1 (complete happy path walkthrough) |
| `AC-sr-filters-lockfiles` | Flow 1 step 7; Filtering Implementation Notes |
| `AC-sr-filters-generated` | Flow 1 step 7; Filtering Implementation Notes |
| `AC-sr-filters-binary` | Flow 1 step 7; Filtering Implementation Notes |
| `AC-sr-includes-config` | Flow 1 step 7; Filtering Implementation Notes |
| `AC-sr-excludes-deleted` | Flow 1 step 6; Change Type Detection table (D excluded) |
| `AC-sr-skip-file` | Flow 5 (skip scenario); User Input Recognition table |
| `AC-sr-quit-early` | Flow 6 (quit early scenario); Completion Summary Format (remaining line) |
| `AC-sr-no-changes` | Flow 2; Error Message Formats |
| `AC-sr-all-filtered` | Flow 3; Error Message Formats |
| `AC-sr-not-git-repo` | Flow 4; Error Message Formats |
| `AC-sr-invokes-shepherd` | Flow 1 step 12b; Interaction with /shepherd section |
| `AC-sr-list-command` | Flow 7; Output Format -- Re-displayed File List |
| `AC-sr-completion-summary` | Output Format -- Completion Summary Format; Flow 1 step 13 |
| `AC-sr-sorted-file-list` | Output Format -- File List Display sorting rules and example |
| `AC-sr-install-global` | Installation section |
