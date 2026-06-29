---
product-hash: 4d299d7c5ee2df52aa23e260c53010af4520ba647a834ebf37da560ffd5ea957
product-slugs: [AC-sr-all-filtered, AC-sr-auto-open, AC-sr-batch-open, AC-sr-completion-summary, AC-sr-context-in-crpg, AC-sr-excludes-deleted, AC-sr-filters-binary, AC-sr-filters-generated, AC-sr-filters-lockfiles, AC-sr-happy-path, AC-sr-includes-config, AC-sr-install-global, AC-sr-interactive-prompt, AC-sr-invokes-shepherd, AC-sr-list-command, AC-sr-no-changes, AC-sr-not-git-repo, AC-sr-quit-early, AC-sr-skip-file, AC-sr-sorted-file-list, AC-sr-unified-prompt, FR-sr-changeset-detection, FR-sr-changeset-overview, FR-sr-command-file, FR-sr-completion-summary, FR-sr-context-handoff, FR-sr-feedback-collection, FR-sr-file-filtering, FR-sr-file-list-display, FR-sr-git-required, FR-sr-install, FR-sr-iteration-loop, FR-sr-multi-file-launch, FR-sr-per-file-context, FR-sr-priority-ordering, FR-sr-scope-argument, NFR-sr-agent-native, NFR-sr-cross-platform, NFR-sr-no-dependencies, NFR-sr-startup-speed]
---

# Shepherd Review — macOS Design Spec

> Based on requirements in `../../product/shepherd-review.md`
> See also `../../product/macos/shepherd-review.md` for macOS-specific requirements.
> Reuses the native multi-file UI defined in `./code-review-prompt.md`.

## What We're Designing

The conversational and native-app interaction for `/shepherd-mac-review`. The orchestration layer (agent conversation) is the same as the web variant of `shepherd-review` — the design here documents only the platform-specific differences: command syntax, launch surface, and how structured context is presented inside the native macOS window. The native window itself follows the multi-file layout already specified in `./code-review-prompt.md`; this spec does not redefine that UI, it only describes how `shepherd-review` populates and uses it.

## Surface Inventory

| Surface | Role |
|---|---|
| **Agent conversation (Claude Code or opencode)** | Orchestration. Same as the web variant: changeset detection, filtering, priority ordering, context generation, brief summary, auto-launch, `AskUserQuestion` interactive prompt, completion summary, feedback action menu. |
| **Native macOS application window** | Review surface. Multi-file three-column layout (file browser left, code viewer center, inspector right) per `./code-review-prompt.md`. Each reviewable file appears as a row in the file browser; the priority-ordered first file is the initial active tab. Overall and per-file review context render in the inspector and code viewer per `FR-crp-review-context-display`. |

The agent conversation is identical to `../web/shepherd-review.md`. Refer there for the conversation transcript, the brief-summary format, the interactive prompt, the completion summary, and the feedback action menu. The only surface difference is the launch step: instead of opening a browser via URL parameters, the macOS variant invokes a launcher script that writes a session payload and runs the prebuilt native binary.

## Command Syntax

```
/shepherd-mac-review [--staged | --unstaged | --branch [base] | --commit [ref] | --range <range> | <ref>]
```

The macOS variant adds three commit-scoped modes on top of the web variant's working-tree scopes (`FR-srm-scope-modes`, `FR-srm-branch-scope`, `FR-srm-commit-scope`, `FR-srm-range-scope`):

| Argument | Scope label (shown in summary) | What it reviews |
|---|---|---|
| _no argument_ | `all uncommitted changes` | Working tree vs `HEAD` — staged + unstaged + untracked |
| `--staged` | `staged changes only` | The git index |
| `--unstaged` | `unstaged changes only` | Unstaged modifications + untracked |
| `--branch [base]` | `commits on <branch> vs <base>` | The branch's own commits vs the merge base with `base` (default `main`) |
| `--commit [ref]` | `commit <short-sha> — <subject>` | A single commit vs its parent (`ref` default `HEAD`) |
| `--range <range>` | `commit range <range>` | The net diff across a git range (`A..B` or `A...B`) |
| `<ref>` | `changes vs <ref>` | Working tree vs an arbitrary commit/branch/tag |

The working-tree scopes (no-argument, `--staged`, `--unstaged`, `<ref>`) include untracked files; the commit scopes (`--branch`, `--commit`, `--range`) do not (`FR-srm-commit-mode-no-untracked`). The scope label appears in the brief summary's `Reviewing:` line (see Conversation Surface).

An unrecognized argument, a malformed `--range`, or a ref/base that does not resolve prints a usage block listing every scope and stops:

```
Usage: /shepherd-mac-review [--staged | --unstaged | --branch [base] | --commit [ref] | --range <range> | <ref>]

Review changes in the macOS CRPG.

Scopes:
  (default)        All uncommitted changes (staged + unstaged + untracked) vs HEAD
  --staged         Only staged changes
  --unstaged       Only unstaged changes and untracked files
  --branch [base]  Commits on the current branch vs <base> (default: main)
  --commit [ref]   A single commit vs its parent (default: HEAD — your last commit)
  --range <range>  A commit range, e.g. main..HEAD or v1.0..v1.1
  <ref>            Working tree vs a commit, branch, or tag
```

The command is implemented as `.claude/commands/shepherd-mac-review.md` plus an opencode skill at `.config/opencode/skills/shepherd-mac-review/SKILL.md`. Installed globally via `scripts/install-command.sh` (`AC-srm-install-symlink`).

## Conversation Surface

The agent conversation flow is byte-identical to `../web/shepherd-review.md`'s flow with three substitutions:

1. The brief summary mentions the native app:
   ```
   Session: <session-id>
   Reviewing: <scope-label>

   Opening <N> files in the macOS app for review.
   <M> files excluded (lockfiles, generated, binary).
   ```
   The "in the macOS app" phrase replaces the implicit "in the CRPG" of the web flow. The remaining lines (counts, exclusion suffix, blank-line separators) match the web spec verbatim.

2. The launch step invokes the macOS launcher script (see "Launch and Handoff" below), not `shepherd-launch.sh`.

3. The "Cancel" branch of the interactive prompt does **not** close the native window. The user keeps full control over the window via standard macOS chrome (`AC-crp-macos-close-last-window`); cancelling only ends the agent's part of the session. This matches `AC-srm-cancel`.

All other surface details — error messages, `AskUserQuestion` options ("Added comments", "Reviewed, no comments", "Cancel"), completion summary numbers, feedback action menu (apply, discuss, save, nothing), input-recognition synonyms — are inherited unchanged from `../web/shepherd-review.md`.

## Launch and Handoff

After context generation, the agent invokes:

```
<repo-root>/scripts/shepherd-launch-macos.sh [--context <context-json-path>] <abs-path-1> <abs-path-2> ... <abs-path-N>
```

The launcher (existing) writes `~/.shepherd/sessions/<session-id>/session.json` with:

- `sessionID`, `workingDirectory`, `projectName` — derived as today
- `files[]` — one entry per validated file, in priority order from `FR-sr-priority-ordering`
- `reviewContext` — the structured context object (overall + files), populated from the agent-supplied context JSON when `--context` is provided; `null` when invoked single-file from `/shepherd-mac` (existing behavior). The `<context-json-path>` is an agent-owned temp file (e.g. produced via `mktemp`) — not a session-scoped file — so the agent does not need to know the session ID before invoking the launcher. The launcher inlines the JSON into `session.json.reviewContext` at launch time; the temp file is no longer needed afterward and the agent deletes it.

The launcher then runs the prebuilt `ShepherdApp` binary detached with `--session <id>` and prints `Session: <id>` plus a "loaded N files" summary on stdout — matching the existing contract so the agent's stdout-parsing logic is identical to `/shepherd-mac`.

The native window opens, reads the session JSON via `SessionClient.loadSession`, and presents:

- **Multi-file three-column layout** when `files.count >= 2` (per `./code-review-prompt.md` Multi-File State).
- **Single-file two-column layout** when only one file is reviewable.
- **Inspector ReviewContextSection** populated with `reviewContext.overall.neutral` and `reviewContext.overall.review` as visually distinct sections (`AC-srm-context-in-app`, inheriting `FR-crp-review-context-overall`).
- **Per-file ReviewContextPanel** populated with `reviewContext.files[<active-path>]` for the currently active tab; updates when the user switches files (`FR-crp-review-context-per-file`). When a file's per-file context is missing, the panel hides for that tab (graceful-missing per `AC-crp-context-graceful-missing`).

After launch the agent presents the same `AskUserQuestion` as the web flow. When the user clicks **Done** in the native window, the application writes `~/.shepherd/sessions/<session-id>/prompt-output.md` and closes the window per `FR-crp-macos-auto-close`. The agent reads that file when the user selects "Added comments" and proceeds with the standard completion summary.

## Tab Order and File Browser

The file browser sidebar lists the `files[]` entries in the order they appear in the session payload, which is the priority order defined by `FR-sr-priority-ordering`. The first file is the active tab on launch (`AC-sr-sorted-file-list`). Per-file comment counts and review-status indicators are owned by `./code-review-prompt.md` and apply unchanged.

When the user adds comments and clicks Done, the prompt aggregator (`PromptBuilder` in `SharedModels`) emits one section per file in priority order, identical to the web variant's `FR-crp-multi-file-prompt-format`. Files without comments are omitted from the prompt.

## Nothing to Review (Empty Changeset)

Per `FR-srm-no-blank-window`, the agent never launches the native app when the selected scope resolves to zero reviewable files — this is the design fix for the "blank window" symptom. Before invoking the launcher, the agent checks the changed-file count (after filtering). If it is zero, it prints a scope-specific message and stops. No `session.json` is written, the launcher is not called, and no window appears. Messages by scope:

| Scope | Message |
|---|---|
| default | `No uncommitted changes to review.` |
| `--staged` | `No staged changes to review.` |
| `--unstaged` | `No unstaged changes to review.` |
| `--branch [base]` | `No commits on <branch> relative to <base>. Nothing to review.` |
| `--commit [ref]` | `Commit <ref> has no changes to review.` |
| `--range <range>` | `No changes in range <range>. Nothing to review.` |
| any scope, all filtered | `No reviewable files found. All <N> changed files were filtered out (lockfiles, generated, binary).` |

When the agent *does* launch, it first clears any stale `prompt-output.md` and overwrites `session.json` for the session ID, so a reused window (same project root) reflects the current invocation rather than leftover tabs from a prior review (`FR-srm-no-blank-window` clause 2; consistent with `AC-crp-macos-window-deduplicate`).

## Error Cases

All error messages match the web variant verbatim, with two macOS-only additions:

- **Binary missing** — when the launcher cannot find `.build/release/ShepherdApp`:
  ```
  macOS app binary not found at <path>.
  Re-run ./scripts/install-command.sh from the Shepherd repo to build it.
  ```
  This is the existing message emitted by `shepherd-launch-macos.sh`. The agent surfaces it as-is and stops.

- **Toolchain missing at install time** — handled by the install script per `AC-srm-install-degraded`. The slash command itself never sees this branch; if the binary is missing at invocation time, the previous case applies.

## Concurrency

Two `/shepherd-mac-review` invocations from different working directories produce different session IDs (basename of project root), open independent windows (`FR-crp-macos-window-management`), and read/write disjoint session directories (`AC-srm-session-isolation`). A second invocation from the same project root with the same session ID brings the existing window to front and updates that window's session JSON before reload — same behavior as `/shepherd-mac` (`AC-crp-macos-window-deduplicate`).

## Accessibility

Inherited from `./code-review-prompt.md`:
- `NFR-crp-accessibility-keyboard` — full keyboard navigation across the file browser, code viewer, and inspector
- VoiceOver labels for ReviewContextSection ("Overall changeset context") and ReviewContextPanel ("Review context for `<filename>`") so screen-reader users can distinguish neutral context from review feedback by their respective subsection labels

The orchestration surface (agent conversation) inherits accessibility from the host agent.

## Requirement Traceability

| Slug | Design coverage |
|---|---|
| `FR-sr-changeset-detection` | Conversation Surface (inherited from `../web/shepherd-review.md`) |
| `FR-sr-file-filtering` | Conversation Surface (inherited) |
| `FR-sr-priority-ordering` | Tab Order and File Browser |
| `FR-sr-changeset-overview` | Launch and Handoff (`reviewContext.overall`) |
| `FR-sr-per-file-context` | Launch and Handoff (`reviewContext.files`); Tab Order |
| `FR-sr-context-handoff` | Launch and Handoff (session-JSON-embedded `reviewContext`) — supplanted by `FR-srm-context-handoff` per `../../product/macos/shepherd-review.md` |
| `FR-sr-file-list-display` | Conversation Surface (brief summary format) |
| `FR-sr-iteration-loop` | Conversation Surface (auto-open, AskUserQuestion); Launch and Handoff |
| `FR-sr-multi-file-launch` | Launch and Handoff — supplanted by `FR-srm-multi-file-launch` |
| `FR-sr-feedback-collection` | Conversation Surface (Done → prompt-output.md → "Added comments") |
| `FR-sr-completion-summary` | Conversation Surface (inherited summary + feedback menu) |
| `FR-sr-command-file` | Command Syntax — supplanted by `FR-srm-command-file` |
| `FR-sr-install` | Command Syntax (install reference) — supplanted by `FR-srm-install` |
| `FR-sr-scope-argument` | Command Syntax — superseded on macOS by `FR-srm-scope-modes` |
| `FR-srm-scope-modes` | Command Syntax (scope table, usage block) |
| `FR-srm-branch-scope` | Command Syntax (`--branch` row) |
| `FR-srm-commit-scope` | Command Syntax (`--commit` row) |
| `FR-srm-range-scope` | Command Syntax (`--range` row) |
| `FR-srm-commit-mode-no-untracked` | Command Syntax (untracked-files note) |
| `FR-srm-no-blank-window` | Nothing to Review (Empty Changeset) |
| `AC-srm-default-scope`, `AC-srm-branch-scope`, `AC-srm-commit-scope`, `AC-srm-range-scope`, `AC-srm-commit-excludes-untracked` | Command Syntax (scope table) |
| `AC-srm-empty-no-launch` | Nothing to Review (Empty Changeset) |
| `FR-sr-git-required` | Conversation Surface (inherited error message) |
| `AC-sr-happy-path` | Conversation Surface + Launch and Handoff (full flow) |
| `AC-sr-auto-open` | Conversation Surface (no confirmation prompt) |
| `AC-sr-batch-open` | Launch and Handoff; Tab Order — supplanted by `AC-srm-batch-open-native` |
| `AC-sr-context-in-crpg` | Launch and Handoff — supplanted by `AC-srm-context-in-app` |
| `AC-sr-interactive-prompt` | Conversation Surface |
| `AC-sr-completion-summary` | Conversation Surface |
| `AC-sr-sorted-file-list` | Tab Order and File Browser |
| `AC-sr-unified-prompt` | Launch and Handoff (Done → prompt-output.md) |
| `AC-sr-skip-file`, `AC-sr-quit-early` | Conversation Surface (inherited) |
| `AC-sr-no-changes`, `AC-sr-not-git-repo`, `AC-sr-all-filtered` | Conversation Surface (inherited error messages) |
| `AC-sr-invokes-shepherd` | Launch and Handoff (single launcher invocation with all paths + context) |
| `AC-sr-list-command` | Launch and Handoff (file browser shows all files; ReviewContext sections show overall + per-file) |
| `AC-sr-install-global` | Command Syntax (install reference) — supplanted by `AC-srm-install-symlink` |
| `AC-sr-filters-*`, `AC-sr-includes-config`, `AC-sr-excludes-deleted` | Conversation Surface (inherited filtering) |
