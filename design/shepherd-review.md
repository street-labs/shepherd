# Shepherd Review -- Design Spec

> Based on requirements in `../product/shepherd-review.md`

## Overview

This spec defines the conversational user experience for the `/shepherd-review` slash command. Unlike other design specs in this project that describe web UI screens and components, this spec describes a text-based interaction that takes place entirely within an AI coding agent conversation (Claude Code). The agent outputs formatted plain text, prompts the user for input at defined points, and invokes `shepherd-launch.sh` with all reviewable file paths to open a single CRPG browser session with every file loaded as a tab.

There is no new web UI. The "interface" is the sequence of text messages exchanged between the agent and the user in the agent conversation, plus the existing CRPG browser experience (now batch-opened with all reviewable files as tabs). The user controls the review entirely within the CRPG -- navigating tabs freely, adding comments on whichever files they choose, and clicking "Done" once to produce a unified multi-file prompt.

---

## Interface Inventory

| Surface | Role |
|---|---|
| **Agent conversation (Claude Code)** | Primary surface. All file discovery, filtering, changeset overview, list display, launch confirmation, and summary messages appear here as plain text. |
| **CRPG web app (browser)** | Secondary surface. Invoked once for all reviewable files -- each file appears as a tab. The user navigates tabs freely, adds comments, and clicks "Done" to generate a unified multi-file prompt. The CRPG's existing multi-file support is unchanged; this spec does not modify it. |

The agent conversation is the orchestration layer. The CRPG is the review tool for all files in a single session. This spec covers only the orchestration layer.

---

## Command Syntax (`FR-sr-scope-argument`, `FR-sr-command-file`)

```
/shepherd-review [--staged | --unstaged]
```

The command accepts an optional scope argument:

- **No argument (default)**: Review all changes in the working tree relative to main. This includes committed branch changes, staged changes, unstaged changes, and untracked new files -- the broadest view.
- **`--staged`**: Review only staged changes (files in the git index). Useful after `git add` when the user wants to review exactly what will be committed.
- **`--unstaged`**: Review only unstaged changes and untracked files. Useful after staging some files to review what remains.

If an unrecognized argument is provided, the agent displays:

```
Unknown argument: <arg>

Usage: /shepherd-review [--staged | --unstaged]
```

The command auto-detects the current branch and compares against `main` (`FR-sr-changeset-detection`).

The command is implemented as a Claude Code custom command file at `.claude/commands/shepherd-review.md`. It is installed globally via `scripts/install-command.sh` (`FR-sr-install`).

---

## Output Format

All output is plain text rendered in the agent conversation. No emoji, no ANSI escape codes, no color codes, no rich formatting beyond what the agent conversation natively supports (plain text, code blocks). Every message the agent produces is specified below with exact wording.

### File List Display (`FR-sr-file-list-display`, `FR-sr-changeset-overview`, `FR-sr-per-file-context`, `FR-sr-priority-ordering`, `AC-sr-sorted-file-list`)

After changeset detection, filtering, and priority sorting, the agent displays the file list in this exact format:

```
Reviewing: <scope-label>

<changeset-overview-paragraph>

Found <N> files to review.

  1. <relative-path>  [<change-type>]
     <per-file-context-summary>
  2. <relative-path>  [<change-type>]
     <per-file-context-summary>
  3. <relative-path>  [<change-type>]
     <per-file-context-summary>
  ...

<M> files excluded (lockfiles, generated, binary).

Ready to start? Say "go" to begin, or "quit" to cancel.
```

Field definitions:

- `<scope-label>` -- one of: `all changes vs main` (default, no argument), `staged changes only` (`--staged`), or `unstaged changes only` (`--unstaged`).
- `<changeset-overview-paragraph>` -- a brief (2-4 sentence) summary of the overall changeset derived from reading the diffs (`FR-sr-changeset-overview`). Describes the theme or purpose of the changes to orient the reviewer before they dive in.
- `<N>` -- the count of files that passed filtering. Always a positive integer in this format (the zero case is handled separately).
- `<relative-path>` -- the file path relative to the repository root. Uses forward slashes on all platforms. Sorted by review priority (`FR-sr-priority-ordering`, `AC-sr-sorted-file-list`).
- `<per-file-context-summary>` -- a brief (1-2 sentence) summary for each file describing what changed (`FR-sr-per-file-context`). Indented under the file path. Mentions specific function names, sections, or structural changes derived from the diff. This context is presented upfront because all files open simultaneously -- there is no per-file announcement moment.
- `<change-type>` -- one of `modified`, `added`, or `renamed`. Displayed in square brackets after two spaces. For renamed files, the format is `renamed from <old-path>` (addressing Open Question 7 from the product spec).
- Position numbers are right-aligned to the width of the largest number. For 1-9 files, no padding is needed. For 10-99 files, single-digit numbers are padded with a leading space. For example, with 12 files: ` 1.` through `12.`.
- The exclusion line appears only if `<M>` is greater than zero. If no files were excluded, this line is omitted.
- A blank line separates each major section: scope label, overview paragraph, count line, numbered list, exclusion line, and prompt.

**Sorting rules -- Priority Ordering** (`FR-sr-priority-ordering`):

Files are sorted by review importance, not alphabetically. The ordering uses a tier-based heuristic:

1. **Tier 1 -- Core source code**: Application logic, components, business logic files. These are the most important for manual review.
2. **Tier 2 -- Configuration**: Build config, CI config, command definitions, project config files that affect behavior.
3. **Tier 3 -- Specs and documentation**: Markdown specs, design docs, READMEs.
4. **Tier 4 -- Supporting files**: Indexes, glossaries, changelogs.
5. **Tier 5 -- Test files**: Test files are least urgent for manual review since they can be verified by running them.

Within each tier, files with larger or more significant changes rank higher. The goal is that the reviewer sees the most impactful files first and can focus attention where it matters most. The CRPG tab order matches this priority order.

Example: given `src/utils.ts` (modified, 45 lines changed), `src/app.tsx` (modified, 120 lines changed), `vitest.config.ts` (modified, 5 lines changed), `README.md` (modified, 10 lines changed), `tests/utils.test.ts` (added, 80 lines changed), the sorted order is:

```
Reviewing: all changes vs main

This changeset adds utility functions and updates the main app component
to use them. Configuration and documentation are updated to match.

Found 5 files to review.

  1. src/app.tsx                        [modified]
     Refactored the main component to use the new utility helpers.
  2. src/utils.ts                       [modified]
     Added formatDate and parseQuery helper functions.
  3. vitest.config.ts                   [modified]
     Added path alias for the new utils module.
  4. README.md                          [modified]
     Updated usage section to document the new utility functions.
  5. tests/utils.test.ts                [added]
     New test suite covering formatDate and parseQuery.

Ready to start? Say "go" to begin, or "quit" to cancel.
```

### Completion Summary Format (`FR-sr-completion-summary`, `FR-sr-feedback-collection`, `AC-sr-completion-summary`)

When the agent receives the CRPG-generated prompt (either pasted by the user or returned via `~/.shepherd/prompt-output.md`), it displays a summary:

```
Review complete.
  <T> files in changeset
  <E> filtered out (lockfiles, generated, binary)
  <N> files opened
  <C> files with comments
```

- `<T>` -- total files detected in the changeset (before filtering, excluding deleted files).
- `<E>` -- files excluded by filtering. This line is omitted if `<E>` is zero.
- `<N>` -- files opened in the CRPG session. Equals the count from the file list display.
- `<C>` -- files that received at least one comment in the CRPG. Derived from parsing the returned prompt.
- Numbers are right-aligned to the width of the largest number in the summary for readability.

There are no `reviewed`/`skipped`/`remaining` fields. In the batch-open model the user controls which files they engage with entirely within the CRPG; the agent only knows which files received comments.

**Feedback handoff** (`FR-sr-feedback-collection`):

If the returned prompt contains feedback (at least one file with comments), the agent displays the full prompt content followed by the action menu:

```
What would you like to do with this feedback?

  apply     Implement the changes described above
  discuss   Talk through the feedback before acting
  save      Write the feedback to a file for later
  nothing   End the session

>
```

If the returned prompt contains no comments (or the user indicates no feedback was collected), the agent displays:

```
No feedback was collected. Session complete.
```

The session ends with no further interaction.

Full example for a review with feedback:

```
Review complete.
  12 files in changeset
   5 filtered out (lockfiles, generated, binary)
   7 files opened
   4 files with comments

What would you like to do with this feedback?

  apply     Implement the changes described above
  discuss   Talk through the feedback before acting
  save      Write the feedback to a file for later
  nothing   End the session

>
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

### Flow 1: Happy Path -- Batch Open Review (`AC-sr-happy-path`, `AC-sr-batch-open`)

This flow covers a complete review session from command invocation through feedback handoff.

1. User types `/shepherd-review` in their Claude Code session (optionally with `--staged` or `--unstaged`).
2. Agent reads the custom command file and begins execution.
3. Agent checks that the current working directory is inside a git repository by running `git rev-parse --is-inside-work-tree`. If this fails, agent outputs the "Not a git repository" error and stops (`FR-sr-git-required`).
4. Agent determines the merge base between HEAD and `main` using `git merge-base HEAD main` (`FR-sr-changeset-detection`). If this fails (e.g., `main` does not exist or HEAD is `main` with no divergence), agent outputs "No changes found relative to main." and stops.
5. Agent runs `git diff --name-status <merge-base>...HEAD` (or the appropriate variant for `--staged`/`--unstaged` per `FR-sr-scope-argument`) to get the list of changed files with their change types (M=modified, A=added, R=renamed, D=deleted).
6. Agent removes deleted files from the list (`AC-sr-excludes-deleted`).
7. Agent applies the filtering rules from `FR-sr-file-filtering` to exclude lockfiles, generated files, binary files, IDE files, and snapshot files (`AC-sr-filters-lockfiles`, `AC-sr-filters-generated`, `AC-sr-filters-binary`). Config files listed in the inclusion rules are kept (`AC-sr-includes-config`).
8. Agent sorts the remaining files by review priority (`FR-sr-priority-ordering`, `AC-sr-sorted-file-list`).
9. Agent reads diffs for all reviewable files and generates the changeset overview with per-file context summaries (`FR-sr-changeset-overview`, `FR-sr-per-file-context`).
10. Agent displays the scope label, changeset overview, file list with per-file summaries, exclusion count, and the "Ready to start?" prompt (see "File List Display" format above).
11. Agent waits for the user to respond.
12. User says "go" (or equivalent affirmative: "yes", "start", "y", "ok", "begin").
13. Agent invokes `shepherd-launch.sh` with all reviewable file paths as arguments (`FR-sr-multi-file-launch`, `AC-sr-invokes-shepherd`). All files open in a single CRPG session as tabs in priority order (`AC-sr-batch-open`).
14. Agent cleans up any stale `~/.shepherd/prompt-output.md` from a previous session, then waits for the user to complete their review in the CRPG.
15. User reviews files freely in the CRPG -- navigating tabs in any order, adding comments on whichever files they choose.
16. User clicks "Done" in the CRPG. The CRPG writes a unified multi-file prompt to `~/.shepherd/prompt-output.md` (`AC-sr-unified-prompt`).
17. Agent reads the prompt from `~/.shepherd/prompt-output.md` (`FR-sr-feedback-collection`).
18. Agent displays the completion summary (see "Completion Summary Format").
19. If the prompt contains feedback: agent displays the full prompt content and the feedback action menu (apply, discuss, save, nothing). User selects an action and the agent proceeds accordingly.
20. If the prompt contains no feedback: agent displays "No feedback was collected. Session complete." and the session ends.

### Flow 2: No Changes Found (`AC-sr-no-changes`)

1. User types `/shepherd-review`.
2. Agent verifies git repository (passes).
3. Agent determines the merge base. Either HEAD is `main` itself, or there is no divergence.
4. Agent outputs:
   ```
   No changes found relative to main.
   ```
5. Command ends. No file list, no CRPG session.

### Flow 3: All Files Filtered (`AC-sr-all-filtered`)

1. User types `/shepherd-review`.
2. Agent verifies git repository (passes).
3. Agent detects the changeset: 4 files (e.g., `package-lock.json`, `yarn.lock`, `dist/bundle.js`, `logo.png`).
4. All 4 files match exclusion rules. Zero files remain after filtering.
5. Agent outputs:
   ```
   No reviewable files found. All 4 changed files were filtered out (lockfiles, generated, binary).
   ```
6. Command ends. No file list, no CRPG session.

### Flow 4: Not a Git Repository (`AC-sr-not-git-repo`)

1. User types `/shepherd-review`.
2. Agent runs `git rev-parse --is-inside-work-tree`. The command fails.
3. Agent outputs:
   ```
   Not a git repository. /shepherd-review must be run from within a git repo.
   ```
4. Command ends.

### Flow 5: User Reviews a Subset of Files (`AC-sr-skip-file`)

1. The CRPG opens with 5 tabs (one per reviewable file).
2. User navigates to 3 of the 5 files and adds comments on those 3.
3. User clicks "Done" in the CRPG.
4. The CRPG generates a unified prompt that includes only the 3 files with comments. The 2 files without comments are effectively skipped -- no explicit action is required.
5. Agent reads the prompt, displays the completion summary showing "3 files with comments", and presents the feedback action menu.

Design note: In the batch-open model, skipping is implicit. The user simply does not comment on files they choose to skip. There is no "skip" command and no bookkeeping distinction between "reviewed without comments" and "not reviewed" -- the agent only knows which files received comments.

### Flow 6: User Ends Session at Any Point (`AC-sr-quit-early`)

1. The CRPG opens with 5 tabs.
2. User reviews 2 files, adds comments, and clicks "Done" before visiting the other 3 tabs.
3. The CRPG generates a prompt covering whatever comments exist at that point.
4. Agent reads the prompt, displays the completion summary, and presents the feedback action menu (or "no feedback" message if no comments were added).

There is no concept of "remaining" files or "quit early" in the batch-open model. The user simply finishes whenever they are ready by clicking "Done."

### Flow 7: User Cancels Before Starting

1. Agent displays the file list and the "Ready to start?" prompt.
2. User says "quit" (or "no", "cancel", "stop", "exit", "q").
3. Agent outputs:
   ```
   Review cancelled.
   ```
4. Command ends. No CRPG session is opened and no summary is displayed.

---

## User Input Recognition

The agent must recognize variations of user commands. The following table defines the canonical command and its accepted synonyms. Matching is case-insensitive.

| Canonical | Synonyms | Context |
|---|---|---|
| `go` | "yes", "start", "y", "ok", "begin", "ready" | Pre-launch prompt only |
| `quit` | "stop", "exit", "q", "quit review", "cancel", "no" | Pre-launch prompt only |
| `apply` | "implement", "do it" | Post-prompt feedback menu only |
| `discuss` | "talk", "let's discuss" | Post-prompt feedback menu only |
| `save` | "write", "save to file" | Post-prompt feedback menu only |
| `nothing` | "done", "end", "no thanks", "skip" | Post-prompt feedback menu only |

There are only two interaction contexts where the agent waits for user input:

1. **Pre-launch prompt**: After displaying the file list and "Ready to start?" The user says `go` to proceed or `quit` to cancel.
2. **Post-prompt feedback menu**: After the CRPG prompt is returned and the summary is displayed. The user says `apply`, `discuss`, `save`, or `nothing`.

The `next`, `skip`, and `list` commands from the old sequential model are removed. The user controls all file navigation within the CRPG UI.

If the user's input does not match any recognized command at the pre-launch prompt, the agent responds:

```
I did not understand that. Say "go" to begin the review, or "quit" to cancel.

>
```

If the user's input does not match any recognized command at the post-prompt feedback menu, the agent responds:

```
I did not understand that. Your options are:

  apply     Implement the changes described above
  discuss   Talk through the feedback before acting
  save      Write the feedback to a file for later
  nothing   End the session

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

The launch script is invoked with the new path (which exists on disk).

---

## Filtering Implementation Notes (`FR-sr-file-filtering`)

The filtering is performed by the agent using path-pattern matching only. No file contents are read during filtering (`FR-sr-file-filtering` specifies heuristic path-based filtering). The agent applies the exclusion rules in the order defined in the product spec.

The filtering logic is embedded in the command file's prompt instructions. The agent evaluates each file path against the exclusion patterns and removes matches. Files that do not match any exclusion pattern are included.

The exclusion count displayed in the file list is the total count of files removed by filtering (including deleted files, which are conceptually "filtered" even though they are removed for a different reason). This ensures `<T> = <E> + <N>` in the summary.

Design decision: Deleted files are counted in `<T>` (total files in changeset) and in `<E>` (filtered out), not shown as a separate category. This keeps the summary simple. The user does not need to know the breakdown of why files were filtered -- they just need to know how many were excluded and that the remaining files are the ones worth reviewing.

---

## Pacing and Flow Considerations

The interaction is designed to avoid overwhelming the user and to keep them oriented at all times:

1. **Before launch**: The changeset overview orients the user on the purpose and scope of the changes. The per-file context summaries give a preview of what each file contains. The explicit "go" confirmation prevents the CRPG from opening unexpectedly.

2. **During review**: The user controls pacing entirely within the CRPG. They navigate tabs freely, review files in any order, and spend as much or as little time as they want on each file. The agent conversation is idle during this phase -- the CRPG is the active surface. The changeset overview and per-file summaries remain visible in the conversation history above for reference.

3. **After review**: The completion summary provides closure -- the user knows how many files were opened and how many received comments. The feedback action menu gives them clear next steps.

4. **Error cases**: All errors are concise single-line (or near-single-line) messages. No interactive recovery is attempted. The user can simply re-invoke the command after addressing the issue.

---

## Multi-File Launch (`FR-sr-multi-file-launch`, `AC-sr-invokes-shepherd`, `AC-sr-batch-open`)

When the user confirms they want to proceed, the agent opens all reviewable files in a single CRPG session by calling `shepherd-launch.sh` with all absolute file paths as arguments:

```
shepherd-launch.sh <abs-path-1> <abs-path-2> <abs-path-3> ...
```

The agent constructs each absolute path by combining the repository root (from `git rev-parse --show-toplevel`) with the relative file path from the changeset. The paths are passed in priority order (`FR-sr-priority-ordering`), which determines the tab order in the CRPG.

The launch script constructs a URL that tells the CRPG web app to load all specified files, each appearing as a tab. The browser opens a single CRPG session -- there are no per-file `/shepherd` invocations. The CRPG's existing multi-file support handles tab navigation, per-file comments, and unified prompt generation.

After launching, the agent cleans up any stale `~/.shepherd/prompt-output.md` from a previous session, then waits for the new file to appear. When the user clicks "Done" in the CRPG, the CRPG writes the unified multi-file prompt to `~/.shepherd/prompt-output.md`. The agent reads this file to obtain the feedback.

If the launch script reports an error (e.g., the script is not found or the browser fails to open), the agent displays the error as-is and the session ends. The user can resolve the issue and re-run `/shepherd-review`.

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
| `FR-sr-file-list-display` | Output Format -- File List Display; scope label, changeset overview, per-file summaries, and example |
| `FR-sr-priority-ordering` | Output Format -- File List Display sorting rules (tier-based priority ordering); Flow 1 step 8 |
| `FR-sr-changeset-overview` | Output Format -- File List Display (changeset overview paragraph); Flow 1 step 9 |
| `FR-sr-per-file-context` | Output Format -- File List Display (per-file context summaries under each file); Flow 1 step 9 |
| `FR-sr-iteration-loop` | Flow 1 step 13 (batch-open via shepherd-launch.sh); Multi-File Launch section |
| `FR-sr-multi-file-launch` | Multi-File Launch section; Flow 1 step 13 |
| `FR-sr-feedback-collection` | Completion Summary Format (feedback handoff); Flow 1 steps 17-20 |
| `FR-sr-completion-summary` | Output Format -- Completion Summary Format; Flow 1 step 18 |
| `FR-sr-command-file` | Command Syntax section |
| `FR-sr-install` | Installation section |
| `FR-sr-scope-argument` | Command Syntax section (--staged/--unstaged arguments); Flow 1 step 5 |
| `FR-sr-git-required` | Flow 4 (not a git repo); Error Message Formats |

### Non-Functional Requirements

| Slug | Design Coverage |
|---|---|
| `NFR-sr-startup-speed` | Implicit -- the command uses only fast git operations (Flow 1 steps 3-5); no file content reading during filtering (Filtering Implementation Notes). Changeset overview generation (step 9) reads diffs but does not block on external tools. |
| `NFR-sr-no-dependencies` | Implicit -- the command file uses only git and the existing `shepherd-launch.sh` script; no new tools introduced |
| `NFR-sr-agent-native` | Entire spec -- all orchestration happens in the agent conversation; Output Format section specifies plain text only; CRPG handles in-browser review |
| `NFR-sr-cross-platform` | Implicit -- git commands used (diff, merge-base, rev-parse) are cross-platform; forward-slash paths in display |

### Acceptance Criteria

| Slug | Design Coverage |
|---|---|
| `AC-sr-happy-path` | Flow 1 (complete happy path walkthrough including batch-open and feedback handoff) |
| `AC-sr-batch-open` | Flow 1 step 13 (all files open as tabs in a single CRPG session); Multi-File Launch section |
| `AC-sr-unified-prompt` | Flow 1 step 16 (CRPG writes unified multi-file prompt); Completion Summary Format (feedback handoff) |
| `AC-sr-filters-lockfiles` | Flow 1 step 7; Filtering Implementation Notes |
| `AC-sr-filters-generated` | Flow 1 step 7; Filtering Implementation Notes |
| `AC-sr-filters-binary` | Flow 1 step 7; Filtering Implementation Notes |
| `AC-sr-includes-config` | Flow 1 step 7; Filtering Implementation Notes |
| `AC-sr-excludes-deleted` | Flow 1 step 6; Change Type Detection table (D excluded) |
| `AC-sr-skip-file` | Flow 5 (user reviews subset of files; files without comments are implicitly skipped) |
| `AC-sr-quit-early` | Flow 6 (user clicks Done at any point; no concept of "remaining") |
| `AC-sr-no-changes` | Flow 2; Error Message Formats |
| `AC-sr-all-filtered` | Flow 3; Error Message Formats |
| `AC-sr-not-git-repo` | Flow 4; Error Message Formats |
| `AC-sr-invokes-shepherd` | Flow 1 step 13; Multi-File Launch section (single launch script invocation with all paths) |
| `AC-sr-list-command` | File List Display (changeset overview with per-file summaries visible in conversation history); CRPG tab bar shows all file names |
| `AC-sr-completion-summary` | Output Format -- Completion Summary Format; Flow 1 step 18 |
| `AC-sr-sorted-file-list` | Output Format -- File List Display priority ordering rules and example; CRPG tab order matches |
| `AC-sr-install-global` | Installation section |
