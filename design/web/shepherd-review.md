# Shepherd Review -- Design Spec

> Based on requirements in `../../product/shepherd-review.md`

## Overview

This spec defines the conversational user experience for the `/shepherd-review` slash command. Unlike other design specs in this project that describe web UI screens and components, this spec describes a text-based interaction that takes place within an AI coding agent conversation (Claude Code) plus a data handoff to the CRPG browser experience. The agent discovers the changeset, generates structured review context (neutral + review feedback, at both overall and per-file levels), displays a brief summary in the conversation, and immediately auto-opens `shepherd-launch.sh` with all reviewable file paths and the structured context data to open a single CRPG browser session with every file loaded as a tab.

The agent conversation is minimal -- it shows a brief summary (scope, file count, exclusion count) and handles the post-review feedback handoff. The detailed context and review feedback are displayed in the CRPG alongside the diffs, not in the conversation. The user controls the review entirely within the CRPG -- navigating tabs freely, reading context and feedback alongside each diff, adding comments on whichever files they choose, and clicking "Done" once to produce a unified multi-file prompt.

---

## Interface Inventory

| Surface | Role |
|---|---|
| **Agent conversation (Claude Code)** | Orchestration surface. Displays a brief summary (scope, file count, exclusion count) and auto-opens the CRPG. Also handles the post-review feedback handoff (completion summary and action menu). The detailed changeset overview, per-file context, and review feedback are NOT displayed here. |
| **CRPG web app (browser)** | Primary review surface. Invoked once for all reviewable files -- each file appears as a tab. Displays structured context data: overall neutral context and review feedback at the session level, plus per-file neutral context and review feedback alongside each diff. The user navigates tabs freely, adds comments, and clicks "Done" to generate a unified multi-file prompt. |

The agent conversation is the orchestration layer -- it discovers the changeset, generates context, and handles feedback. The CRPG is the review tool where context, code, and feedback converge. This spec covers the orchestration layer and the data handoff to the CRPG (`FR-sr-context-handoff`).

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

### Conversation Summary Display (`FR-sr-file-list-display`, `AC-sr-auto-open`)

After changeset detection, filtering, priority sorting, and context generation, the agent displays a brief summary in the conversation and immediately auto-opens the CRPG. The conversation summary uses this exact format:

```
Reviewing: <scope-label>

Opening <N> files for review.
<M> files excluded (lockfiles, generated, binary).
```

Field definitions:

- `<scope-label>` -- one of: `all changes vs main` (default, no argument), `staged changes only` (`--staged`), or `unstaged changes only` (`--unstaged`).
- `<N>` -- the count of files that passed filtering. Always a positive integer in this format (the zero case is handled separately).
- The exclusion line appears only if `<M>` is greater than zero. If no files were excluded, this line is omitted.
- A blank line separates the scope label from the file count line.

The detailed changeset overview, numbered file list, per-file context summaries, and review feedback are NOT displayed in the conversation. That information is passed as structured data to the CRPG (`FR-sr-context-handoff`, `FR-sr-changeset-overview`, `FR-sr-per-file-context`) where it appears alongside the diffs in the tool UI (see "Context Handoff to CRPG" section below). There is no "Ready to start?" prompt -- the CRPG opens automatically after this summary (`AC-sr-auto-open`).

Example: given `src/utils.ts` (modified), `src/app.tsx` (modified), `vitest.config.ts` (modified), `README.md` (modified), `tests/utils.test.ts` (added), with 2 binary files filtered out:

```
Reviewing: all changes vs main

Opening 5 files for review.
2 files excluded (lockfiles, generated, binary).
```

**Sorting rules -- Priority Ordering** (`FR-sr-priority-ordering`, `AC-sr-sorted-file-list`):

Files are sorted by review importance, not alphabetically. The ordering uses a tier-based heuristic:

1. **Tier 1 -- Core source code**: Application logic, components, business logic files. These are the most important for manual review.
2. **Tier 2 -- Configuration**: Build config, CI config, command definitions, project config files that affect behavior.
3. **Tier 3 -- Specs and documentation**: Markdown specs, design docs, READMEs.
4. **Tier 4 -- Supporting files**: Indexes, glossaries, changelogs.
5. **Tier 5 -- Test files**: Test files are least urgent for manual review since they can be verified by running them.

Within each tier, files with larger or more significant changes rank higher. The goal is that the reviewer sees the most impactful files first and can focus attention where it matters most. The CRPG tab order matches this priority order. Although the priority ordering is not visible in the brief conversation summary, it determines the tab order in the CRPG.

### Completion Summary Format (`FR-sr-completion-summary`, `FR-sr-feedback-collection`, `AC-sr-completion-summary`)

When the user selects "Added comments" from the interactive prompt and the agent reads `~/.shepherd/sessions/<session-id>/prompt-output.md`, it displays a summary:

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

### Flow 1: Happy Path -- Batch Open Review (`AC-sr-happy-path`, `AC-sr-batch-open`, `AC-sr-auto-open`)

This flow covers a complete review session from command invocation through feedback handoff.

1. User types `/shepherd-review` in their Claude Code session (optionally with `--staged` or `--unstaged`).
2. Agent reads the custom command file and begins execution.
3. Agent checks that the current working directory is inside a git repository by running `git rev-parse --is-inside-work-tree`. If this fails, agent outputs the "Not a git repository" error and stops (`FR-sr-git-required`).
4. Agent determines the merge base between HEAD and `main` using `git merge-base HEAD main` (`FR-sr-changeset-detection`). If this fails (e.g., `main` does not exist or HEAD is `main` with no divergence), agent outputs "No changes found relative to main." and stops.
5. Agent runs `git diff --name-status <merge-base>...HEAD` (or the appropriate variant for `--staged`/`--unstaged` per `FR-sr-scope-argument`) to get the list of changed files with their change types (M=modified, A=added, R=renamed, D=deleted).
6. Agent removes deleted files from the list (`AC-sr-excludes-deleted`).
7. Agent applies the filtering rules from `FR-sr-file-filtering` to exclude lockfiles, generated files, binary files, IDE files, and snapshot files (`AC-sr-filters-lockfiles`, `AC-sr-filters-generated`, `AC-sr-filters-binary`). Config files listed in the inclusion rules are kept (`AC-sr-includes-config`).
8. Agent sorts the remaining files by review priority (`FR-sr-priority-ordering`, `AC-sr-sorted-file-list`).
9. Agent reads diffs for all reviewable files and generates structured context: overall neutral context and review feedback, plus per-file neutral context and review feedback (`FR-sr-changeset-overview`, `FR-sr-per-file-context`).
10. Agent displays the brief conversation summary -- scope label, file count, and exclusion count (see "Conversation Summary Display" format above).
11. Agent immediately invokes `shepherd-launch.sh` with all reviewable file paths and the structured context data (`FR-sr-multi-file-launch`, `FR-sr-context-handoff`, `AC-sr-invokes-shepherd`, `AC-sr-auto-open`). All files open in a single CRPG session as tabs in priority order (`AC-sr-batch-open`). The CRPG displays the overall and per-file context with neutral/review separation (`AC-sr-context-in-crpg`).
12. Agent cleans up any stale `~/.shepherd/sessions/<session-id>/prompt-output.md` from the current session directory.
13. Agent presents an interactive prompt (`AskUserQuestion`) with three options: "Added comments", "Reviewed, no comments", "Cancel" (`AC-sr-interactive-prompt`).
14. User reviews files freely in the CRPG -- navigating tabs in any order, reading context and review feedback alongside diffs, and adding comments on whichever files they choose. When done, the user clicks "Done" in the CRPG, which writes the unified multi-file prompt to `~/.shepherd/sessions/<session-id>/prompt-output.md` (`AC-sr-unified-prompt`).
15. User returns to the agent conversation and selects one of the three options from the interactive prompt.
16. If "Added comments": Agent reads `~/.shepherd/sessions/<session-id>/prompt-output.md` (`FR-sr-feedback-collection`), displays the completion summary (see "Completion Summary Format"), displays the full prompt content, and presents the feedback action menu (apply, discuss, save, nothing). User selects an action and the agent proceeds accordingly.
17. If "Reviewed, no comments": Agent displays a brief completion summary noting zero comments and ends the session. No feedback action menu is shown.
18. If "Cancel": Session ends immediately with no summary.

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
5. User selects "Added comments" from the interactive prompt. Agent reads `~/.shepherd/sessions/<session-id>/prompt-output.md`, displays the completion summary showing "3 files with comments", and presents the feedback action menu.

Design note: In the batch-open model, skipping is implicit. The user simply does not comment on files they choose to skip. There is no "skip" command and no bookkeeping distinction between "reviewed without comments" and "not reviewed" -- the agent only knows which files received comments.

### Flow 6: User Ends Session at Any Point (`AC-sr-quit-early`)

1. The CRPG opens with 5 tabs.
2. User reviews 2 files, adds comments, and clicks "Done" before visiting the other 3 tabs.
3. The CRPG generates a prompt covering whatever comments exist at that point.
4. User returns to the agent conversation and selects "Added comments" from the interactive prompt. Agent reads `~/.shepherd/sessions/<session-id>/prompt-output.md`, displays the completion summary, and presents the feedback action menu.

Alternatively, the user can select "Cancel" from the interactive prompt in the agent conversation at any time -- even without clicking "Done" in the CRPG. This ends the session immediately with no summary and no feedback handoff.

There is no concept of "remaining" files or "quit early" in the batch-open model. The user simply finishes whenever they are ready by clicking "Done" in the CRPG and selecting an option from the interactive prompt.

---

## User Input Recognition

The agent must recognize variations of user commands. The following table defines the canonical command and its accepted synonyms. Matching is case-insensitive.

| Canonical | Synonyms | Context |
|---|---|---|
| `apply` | "implement", "do it" | Post-prompt feedback menu only |
| `discuss` | "talk", "let's discuss" | Post-prompt feedback menu only |
| `save` | "write", "save to file" | Post-prompt feedback menu only |
| `nothing` | "done", "end", "no thanks", "skip" | Post-prompt feedback menu only |

There are two interaction contexts where the agent waits for user input:

1. **Post-launch review prompt** (`AC-sr-interactive-prompt`): After the CRPG opens, the agent presents an `AskUserQuestion` with three options. This prompt remains visible in the conversation while the user reviews in the CRPG. The user selects one option when they are ready.
   - **"Added comments"** -- User reviewed and clicked Done in CRPG. Agent reads `~/.shepherd/sessions/<session-id>/prompt-output.md` and proceeds to the completion summary and feedback menu.
   - **"Reviewed, no comments"** -- User looked but did not add comments. Agent displays a brief summary noting zero comments and ends the session.
   - **"Cancel"** -- Abandon the review session. Session ends immediately with no summary.
2. **Post-prompt feedback menu**: After the agent reads the CRPG prompt (triggered by the user selecting "Added comments") and the summary is displayed. The user says `apply`, `discuss`, `save`, or `nothing`.

There is no pre-launch prompt. The CRPG opens automatically after changeset detection and context generation (`AC-sr-auto-open`). The `go`, `quit`, `next`, `skip`, and `list` commands from earlier designs are all removed. The user controls all file navigation within the CRPG UI.

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

For renamed files, the per-file context data passed to the CRPG includes the change type `renamed from <old-path>`, which the CRPG displays alongside the file's diff tab. For example, a file renamed from `src/helpers.ts` to `src/utils/helpers.ts` would have the change type `renamed from src/helpers.ts`.

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

1. **Before launch**: The agent displays a brief summary (scope, file count, exclusion count) so the user knows what is about to happen. There is no confirmation prompt -- the user invoked `/shepherd-review`, so the intent to review is already established. The CRPG opens immediately. The changeset overview, per-file context, and review feedback are generated during this phase but are NOT displayed in the conversation; they are passed to the CRPG where they will be co-located with the code being reviewed (`FR-sr-context-handoff`).

2. **During review**: The user controls pacing entirely within the CRPG. They navigate tabs freely, review files in any order, and spend as much or as little time as they want on each file. The agent conversation displays the interactive prompt (`AskUserQuestion`) with the three options ("Added comments", "Reviewed, no comments", "Cancel") during this phase -- the prompt is visible but non-blocking while the CRPG is the active surface. Context and review feedback are visible directly in the CRPG alongside the diffs, so the user does not need to scroll back through the agent conversation to find orientation information.

3. **After review**: The completion summary provides closure -- the user knows how many files were opened and how many received comments. The feedback action menu gives them clear next steps.

4. **Error cases**: All errors are concise single-line (or near-single-line) messages. No interactive recovery is attempted. The user can simply re-invoke the command after addressing the issue.

---

## Multi-File Launch (`FR-sr-multi-file-launch`, `AC-sr-invokes-shepherd`, `AC-sr-batch-open`, `AC-sr-auto-open`)

Immediately after displaying the brief conversation summary, the agent opens all reviewable files in a single CRPG session by calling `shepherd-launch.sh` with all absolute file paths as arguments:

```
shepherd-launch.sh <abs-path-1> <abs-path-2> <abs-path-3> ...
```

The agent constructs each absolute path by combining the repository root (from `git rev-parse --show-toplevel`) with the relative file path from the changeset. The paths are passed in priority order (`FR-sr-priority-ordering`), which determines the tab order in the CRPG.

The launch script constructs a URL that tells the CRPG web app to load all specified files, each appearing as a tab. The browser opens a single CRPG session -- there are no per-file `/shepherd` invocations. The CRPG's existing multi-file support handles tab navigation, per-file comments, and unified prompt generation.

After launching, the agent cleans up any stale `~/.shepherd/sessions/<session-id>/prompt-output.md` from the current session directory, then presents an interactive prompt (`AskUserQuestion`) with three options: "Added comments", "Reviewed, no comments", "Cancel" (`AC-sr-interactive-prompt`). When the user clicks "Done" in the CRPG, the CRPG writes the unified multi-file prompt to `~/.shepherd/sessions/<session-id>/prompt-output.md`. The user then returns to the agent conversation and selects an option. The agent reads `~/.shepherd/sessions/<session-id>/prompt-output.md` only when the user selects "Added comments".

If the launch script reports an error (e.g., the script is not found or the browser fails to open), the agent displays the error as-is and the session ends. The user can resolve the issue and re-run `/shepherd-review`.

---

## Context Handoff to CRPG (`FR-sr-context-handoff`, `AC-sr-context-in-crpg`)

The command generates structured context data and passes it to the CRPG alongside the file paths. This context is what the CRPG displays in its UI -- it is NOT shown in the agent conversation. The data has a two-level structure, each level split into neutral and review parts:

**Overall context** (applies to the entire changeset):
- **Neutral context**: A factual summary of the changeset -- what features or areas are touched, what files changed, the structural nature of the changes (new feature, refactor, bug fix, etc.). Objective description only.
- **Review feedback**: The agent's assessment of the changes -- quality observations, potential concerns, patterns worth noting, suggestions for improvement.

**Per-file context** (one entry per reviewable file, in priority order):
- **File path**: Relative to the repository root.
- **Change type**: `modified`, `added`, or `renamed from <old-path>`.
- **Neutral context**: A factual description of what changed in this file -- functions added or modified, lines changed, structural changes. Derived from the diff. No opinions.
- **Review feedback**: The agent's observations about this file -- code quality notes, potential issues, suggestions. Explicitly the agent's opinion.

The CRPG must present neutral context and review feedback as visually distinct sections so the reviewer can tell at a glance which text is factual description and which is the agent's opinion (`AC-sr-context-in-crpg`). The overall context appears at the session level (e.g., a summary panel or header). Each file's context appears alongside its diff in the corresponding tab.

The specific mechanism for passing this data (file on disk, URL parameters, or other approach) is an engineering decision. The design requirement is that the data arrives at the CRPG intact, with the neutral/review distinction preserved, and is displayed alongside the code being reviewed.

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
| `FR-sr-file-list-display` | Output Format -- Conversation Summary Display (brief summary with scope, file count, exclusion count) |
| `FR-sr-priority-ordering` | Conversation Summary Display sorting rules (tier-based priority ordering); Flow 1 step 8; CRPG tab order |
| `FR-sr-changeset-overview` | Context Handoff to CRPG section (overall neutral context); Flow 1 step 9 |
| `FR-sr-per-file-context` | Context Handoff to CRPG section (per-file neutral context and review feedback); Flow 1 step 9 |
| `FR-sr-context-handoff` | Context Handoff to CRPG section; Flow 1 step 11 (structured context data passed to CRPG alongside file paths) |
| `FR-sr-iteration-loop` | Flow 1 step 11 (auto-open via shepherd-launch.sh); Multi-File Launch section |
| `FR-sr-multi-file-launch` | Multi-File Launch section; Flow 1 step 11 |
| `FR-sr-feedback-collection` | Completion Summary Format (feedback handoff); Flow 1 steps 15-18 |
| `FR-sr-completion-summary` | Output Format -- Completion Summary Format; Flow 1 step 16 |
| `FR-sr-command-file` | Command Syntax section |
| `FR-sr-install` | Installation section |
| `FR-sr-scope-argument` | Command Syntax section (--staged/--unstaged arguments); Flow 1 step 5 |
| `FR-sr-git-required` | Flow 4 (not a git repo); Error Message Formats |

### Non-Functional Requirements

| Slug | Design Coverage |
|---|---|
| `NFR-sr-startup-speed` | Implicit -- the command uses only fast git operations (Flow 1 steps 3-5); no file content reading during filtering (Filtering Implementation Notes). Context generation (step 9) reads diffs but does not block on external tools. The CRPG auto-opens immediately after context generation. |
| `NFR-sr-no-dependencies` | Implicit -- the command file uses only git and the existing `shepherd-launch.sh` script; no new tools introduced |
| `NFR-sr-agent-native` | Entire spec -- all orchestration happens in the agent conversation; Output Format section specifies plain text only; CRPG handles in-browser review |
| `NFR-sr-cross-platform` | Implicit -- git commands used (diff, merge-base, rev-parse) are cross-platform; forward-slash paths in display |

### Acceptance Criteria

| Slug | Design Coverage |
|---|---|
| `AC-sr-happy-path` | Flow 1 (complete happy path walkthrough including auto-open, context handoff, batch-open, and feedback handoff) |
| `AC-sr-batch-open` | Flow 1 step 11 (all files auto-open as tabs in a single CRPG session); Multi-File Launch section |
| `AC-sr-auto-open` | Flow 1 steps 10-11 (CRPG opens automatically after brief summary, no confirmation prompt); Conversation Summary Display; Multi-File Launch section |
| `AC-sr-unified-prompt` | Flow 1 step 14 (CRPG writes unified multi-file prompt); Completion Summary Format (feedback handoff) |
| `AC-sr-context-in-crpg` | Context Handoff to CRPG section (overall and per-file context displayed in CRPG with neutral/review separation); Flow 1 step 11 |
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
| `AC-sr-invokes-shepherd` | Flow 1 step 11; Multi-File Launch section (single launch script invocation with all paths and context data) |
| `AC-sr-list-command` | Context Handoff to CRPG section (overall and per-file context visible in CRPG UI); CRPG tab bar shows all file names |
| `AC-sr-completion-summary` | Output Format -- Completion Summary Format; Flow 1 step 16 |
| `AC-sr-sorted-file-list` | Conversation Summary Display priority ordering rules; CRPG tab order matches |
| `AC-sr-interactive-prompt` | Flow 1 step 13 (AskUserQuestion with three options); User Input Recognition -- Post-launch review prompt; Multi-File Launch section; Pacing and Flow Considerations step 2 |
| `AC-sr-install-global` | Installation section |
