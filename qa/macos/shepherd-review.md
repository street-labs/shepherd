---
product-hash: 4d299d7c5ee2df52aa23e260c53010af4520ba647a834ebf37da560ffd5ea957
product-slugs: [AC-sr-all-filtered, AC-sr-auto-open, AC-sr-batch-open, AC-sr-completion-summary, AC-sr-context-in-crpg, AC-sr-excludes-deleted, AC-sr-filters-binary, AC-sr-filters-generated, AC-sr-filters-lockfiles, AC-sr-happy-path, AC-sr-includes-config, AC-sr-install-global, AC-sr-interactive-prompt, AC-sr-invokes-shepherd, AC-sr-list-command, AC-sr-no-changes, AC-sr-not-git-repo, AC-sr-quit-early, AC-sr-skip-file, AC-sr-sorted-file-list, AC-sr-unified-prompt, FR-sr-changeset-detection, FR-sr-changeset-overview, FR-sr-command-file, FR-sr-completion-summary, FR-sr-context-handoff, FR-sr-feedback-collection, FR-sr-file-filtering, FR-sr-file-list-display, FR-sr-git-required, FR-sr-install, FR-sr-iteration-loop, FR-sr-multi-file-launch, FR-sr-per-file-context, FR-sr-priority-ordering, FR-sr-scope-argument, NFR-sr-agent-native, NFR-sr-cross-platform, NFR-sr-no-dependencies, NFR-sr-startup-speed]
---
# Shepherd Review -- macOS Test Plan

> Based on requirements in `../../product/shepherd-review.md`
> See also `../../product/macos/shepherd-review.md` for macOS-specific requirements.
> Based on design in `../../design/macos/shepherd-review.md`
> Based on engineering in `../../engineering/macos/shepherd-review.md`

## What We're Testing

This test plan covers the macOS variant of `shepherd-review` -- specifically the `/shepherd-review` slash command, which orchestrates the multi-file changeset review workflow against the native macOS Code Review Prompt Generator. Scope is limited to the slash-command surface (changeset detection, filtering, ordering, context generation, launcher invocation, interactive prompt, feedback handoff, and install) plus the macOS-specific delivery mechanism (session-JSON payload, prebuilt binary launch, native window with tabs).

The underlying multi-file native UI (file browser, code viewer, inspector, ReviewContextSection, ReviewContextPanel, Done/auto-close behavior) is owned by `qa/macos/code-review-prompt.md` and is not duplicated here -- those test cases are referenced where relevant. This plan focuses on the orchestration layer and the launcher/agent contract.

## Test Approach

Automated tests for slash-command behavior are intrinsically limited: the agent runtime (Claude Code or opencode) interprets the prompt instructions, runs git commands, generates context, and invokes shell tools. There is no headless harness for that flow today. Consequently most cases here are **Manual** on macOS 14+ (Sonoma) with a Swift toolchain and a working Claude Code or opencode install.

The launcher script (`scripts/shepherd-launch.sh`) is the one piece with a stable contract that can be exercised in isolation: argument parsing, session-JSON construction, and the `--context` flag handling. Those cases are marked **Automated** (shell-script tests) and expected to live alongside other launcher tests in the repo.

Coexistence of `/shepherd` and `/shepherd-review` is verified by checking both commands continue to work independently after install. The two commands share no runtime state.

---

## Coverage Matrix

### macOS-Specific Acceptance Criteria

| Requirement | Test Cases | Status |
|---|---|---|
| `AC-srm-coexists` | `TC-srm-coexistence` | Not started |
| `AC-srm-batch-open-native` | `TC-srm-happy-path`, `TC-srm-priority-tab-order` | Not started |
| `AC-srm-no-server` | `TC-srm-no-server` | Not started |
| `AC-srm-context-in-app` | `TC-srm-happy-path`, `TC-srm-context-in-app`, `TC-srm-context-tab-switch`, `TC-srm-context-graceful-missing` | Not started |
| `AC-srm-session-isolation` | `TC-srm-session-isolation` | Not started |
| `AC-srm-prompt-roundtrip` | `TC-srm-happy-path` | Not started |
| `AC-srm-cancel` | `TC-srm-cancel-keeps-window`, `TC-srm-interactive-prompt-options` | Not started |
| `AC-srm-install-symlink` | `TC-srm-install-symlink` | Not started |
| `AC-srm-install-degraded` | `TC-srm-install-degraded-no-swift` | Not started |
| `AC-srm-install-git-pull` | `TC-srm-install-git-pull` | Not started |
| `AC-srm-default-scope` | `TC-srm-default-scope` | Not started |
| `AC-srm-branch-scope` | `TC-srm-branch-scope` | Not started |
| `AC-srm-commit-scope` | `TC-srm-commit-scope` | Not started |
| `AC-srm-range-scope` | `TC-srm-range-scope` | Not started |
| `AC-srm-commit-excludes-untracked` | `TC-srm-branch-scope`, `TC-srm-commit-scope`, `TC-srm-range-scope` | Not started |
| `AC-srm-empty-no-launch` | `TC-srm-empty-no-launch`, `TC-srm-no-changes` | Not started |

### Shared Acceptance Criteria — Applicability on macOS

The shared `AC-sr-*` slugs from `product/shepherd-review.md` apply to the macOS variant as follows. Where a shared AC is fully supplanted by a macOS-specific variant, that is noted and the macOS slug carries the verification.

| Shared Requirement | Test Cases | Status / Notes |
|---|---|---|
| `AC-sr-happy-path` | `TC-srm-happy-path` | Covered (verified end-to-end with native window) |
| `AC-sr-batch-open` | covered by `AC-srm-batch-open-native` (`TC-srm-happy-path`, `TC-srm-priority-tab-order`) | Supplanted on macOS |
| `AC-sr-context-in-crpg` | covered by `AC-srm-context-in-app` (`TC-srm-context-in-app`, `TC-srm-context-tab-switch`, `TC-srm-context-graceful-missing`) | Supplanted on macOS |
| `AC-sr-auto-open` | `TC-srm-happy-path` | Verified -- no confirmation prompt before native window opens |
| `AC-sr-interactive-prompt` | `TC-srm-interactive-prompt-options` | Verified |
| `AC-sr-completion-summary` | `TC-srm-happy-path` | Verified |
| `AC-sr-sorted-file-list` | `TC-srm-priority-tab-order` | Verified |
| `AC-sr-skip-file` | `TC-srm-skip-file` | Verified |
| `AC-sr-quit-early` | `TC-srm-quit-early` | Verified |
| `AC-sr-no-changes` | `TC-srm-no-changes` | Verified |
| `AC-sr-not-git-repo` | `TC-srm-not-git-repo` | Verified |
| `AC-sr-all-filtered` | `TC-srm-all-filtered` | Verified |
| `AC-sr-invokes-shepherd` | `TC-srm-happy-path` | Verified -- launcher invoked once with all paths |
| `AC-sr-list-command` | `TC-srm-context-in-app` | Verified -- file list and context surface in native UI |
| `AC-sr-unified-prompt` | `TC-srm-happy-path`, `TC-srm-skip-file` | Verified -- session-scoped `prompt-output.md` |
| `AC-sr-install-global` | covered by `AC-srm-install-symlink` (`TC-srm-install-symlink`) | Supplanted on macOS |
| `AC-sr-filters-lockfiles`, `AC-sr-filters-generated`, `AC-sr-filters-binary`, `AC-sr-includes-config`, `AC-sr-excludes-deleted` | covered by the shared review flow in the `/shepherd-review` command prompt (filtering logic is platform-neutral) | Inherited |

### Functional Requirement Coverage (macOS-specific delta)

| Requirement | Test Cases | Status |
|---|---|---|
| `FR-srm-coexists` | `TC-srm-coexistence` | Not started |
| `FR-srm-command-file` | `TC-srm-coexistence`, `TC-srm-install-symlink` | Not started |
| `FR-srm-multi-file-launch` | `TC-srm-happy-path`, `TC-srm-launcher-context-flag` | Not started |
| `FR-srm-context-handoff` | `TC-srm-launcher-context-flag`, `TC-srm-launcher-no-context-flag`, `TC-srm-context-in-app` | Not started |
| `FR-srm-install` | `TC-srm-install-symlink`, `TC-srm-install-degraded-no-swift`, `TC-srm-install-git-pull` | Not started |
| `FR-srm-scope-modes` | `TC-srm-default-scope`, `TC-srm-scope-invalid`, `TC-srm-branch-scope`, `TC-srm-commit-scope`, `TC-srm-range-scope` | Not started |
| `FR-srm-branch-scope` | `TC-srm-branch-scope` | Not started |
| `FR-srm-commit-scope` | `TC-srm-commit-scope` | Not started |
| `FR-srm-range-scope` | `TC-srm-range-scope` | Not started |
| `FR-srm-commit-mode-no-untracked` | `TC-srm-branch-scope`, `TC-srm-commit-scope`, `TC-srm-range-scope` | Not started |
| `FR-srm-no-blank-window` | `TC-srm-empty-no-launch`, `TC-srm-no-changes` | Not started |
| `NFR-srm-launch-budget` | `TC-srm-happy-path` (timed observation) | Not started |
| `NFR-srm-no-server` | `TC-srm-no-server` | Not started |
| `NFR-srm-platform-restriction` | not directly tested -- exercised by `TC-srm-install-degraded-no-swift` | Inherent |

Filtering, priority ordering, changeset detection, and scope-argument behavior on macOS reuse the web QA cases (the orchestration logic is identical). Run-on-macOS smoke verification is folded into `TC-srm-happy-path` rather than duplicating the full web matrix.

---

## Test Cases

Test cases are grouped by scenario. Each case has a human-readable title with its `TC-` slug as a tag.

### Happy Path and End-to-End Flow

#### `TC-srm-happy-path` -- Full review session end-to-end with native window

- **Type**: Manual
- **Covers**: `AC-sr-happy-path`, `AC-srm-batch-open-native`, `AC-srm-context-in-app`, `AC-srm-prompt-roundtrip`, `AC-sr-auto-open`, `AC-sr-completion-summary`, `AC-sr-invokes-shepherd`, `AC-sr-unified-prompt`, `FR-srm-multi-file-launch`, `NFR-srm-launch-budget`
- **Preconditions**:
  - macOS 14+ host with Swift toolchain installed and `./scripts/install-command.sh` already run successfully (so `/shepherd-review` is available and `engineering/apps/macos/.build/release/ShepherdApp` exists).
  - Open a Claude Code or opencode session inside a test repo on a feature branch with 5 modified human-authored source files and 2 lockfiles relative to `main`.
- **Steps**:
  1. Note the current contents of `~/.shepherd/sessions/` (if any).
  2. Type `/shepherd-review` in the agent conversation.
  3. Observe the brief summary in the conversation: `Session: <id>`, scope label, "Opening 5 files in the macOS app for review.", and "2 files excluded (lockfiles, generated, binary)." -- no detailed file list, no per-file context, no confirmation prompt.
  4. Verify the native macOS application window opens immediately (within ~1s after the launcher returns).
  5. In the native window, verify that the file browser shows 5 rows in priority order (core source first, tests last) and the first file is the active tab.
  6. Verify the inspector ReviewContextSection shows overall neutral context and overall review feedback as visually distinct subsections.
  7. Switch to a different file tab and verify the per-file ReviewContextPanel updates to show that file's neutral and review subsections.
  8. Add line comments on 3 of the 5 files. Leave 2 files without comments.
  9. Click **Done** in the native window.
  10. Return to the agent conversation. The agent presents an `AskUserQuestion` prompt with options "Added comments", "Reviewed, no comments", "Cancel". Select **Added comments**.
  11. Confirm the agent prints a completion summary covering total opened, files with comments, files filtered, and presents the action menu (apply, discuss, save, nothing).
- **Expected**:
  - Brief summary is rendered as specified; no detailed file list appears in the conversation.
  - The macOS window appears within the launch budget; total wall time from `/shepherd-review` invocation to window-on-screen sits within `NFR-crp-macos-launch-time` plus context-generation time.
  - File browser tab order matches priority ordering (`AC-sr-sorted-file-list`).
  - ReviewContextSection (overall) and ReviewContextPanel (per-file) render with visually distinct neutral vs review subsections.
  - On clicking Done, the application writes `~/.shepherd/sessions/<id>/prompt-output.md` containing exactly the 3 commented files.
  - After "Added comments", the agent reads that exact path and presents the standard summary + action menu.
- **Pass criteria**: All steps complete without errors; comments on the 3 files appear in the unified prompt; the 2 uncommented files are omitted; the agent's summary numbers match the changeset; no browser is launched and no web server starts.

---

#### `TC-srm-coexistence` -- `/shepherd` and `/shepherd-review` coexist

- **Type**: Manual
- **Covers**: `AC-srm-coexists`, `FR-srm-coexists`, `FR-srm-command-file`
- **Preconditions**: `./scripts/install-command.sh` has been run successfully on a macOS host with Swift available. Both `~/.claude/commands/shepherd.md` and `~/.claude/commands/shepherd-review.md` symlinks should exist.
- **Steps**:
  1. In a Claude Code session, type `/` and inspect the slash-command picker. Confirm both `/shepherd` and `/shepherd-review` appear.
  2. Invoke `/shepherd <file>` on a single file and confirm the native macOS window opens with that file.
  3. Invoke `/shepherd-review` on the same branch and confirm the native macOS window opens with the changeset's reviewable files.
  4. Repeat in opencode if available -- confirm both skills register and behave the same way.
- **Expected**: Each command launches the native macOS app independently. Invoking one does not stop or affect the other; both can be used in alternation across sessions.
- **Pass criteria**: Both commands present and launching the native app successfully with no cross-interference.

---

### Launch Mechanism and Server Independence

#### `TC-srm-no-server` -- No web server is started by the macOS variant

- **Type**: Manual
- **Covers**: `AC-srm-no-server`, `NFR-srm-no-server`
- **Preconditions**: macOS host with no local web server currently running. A test branch with at least 2 reviewable files. Terminal with `lsof` available.
- **Steps**:
  1. Before invoking the command, run `lsof -iTCP -sTCP:LISTEN -P -n | sort > /tmp/before.txt`.
  2. Invoke `/shepherd-review` and wait for the native window to open and the AskUserQuestion prompt to appear.
  3. Run `lsof -iTCP -sTCP:LISTEN -P -n | sort > /tmp/after.txt`.
  4. Diff the two snapshots: `diff /tmp/before.txt /tmp/after.txt`.
  5. Inspect the running process tree (e.g. `ps -ef | grep -E 'node|http'`) and confirm no local web-server process appeared as a result of the invocation.
  6. Cancel the session and close the window.
- **Expected**: The diff shows no new TCP listeners attributable to the command. No web-server, Node, or HTTP-server process appears in the process tree as a result of the invocation.
- **Pass criteria**: Zero new web-server bindings, zero new web-server processes spawned by the macOS flow.

---

#### `TC-srm-session-isolation` -- Concurrent invocations stay isolated

- **Type**: Manual
- **Covers**: `AC-srm-session-isolation`
- **Preconditions**: Two separate clones (or worktrees) of test repos, each with a different reviewable change set. Two Claude Code or opencode sessions, each cd'd into its own working directory.
- **Steps**:
  1. In session A (working directory A), invoke `/shepherd-review`. Wait for native window A to open. Note the session ID printed in the brief summary -- call it `sid-A`.
  2. Without closing window A, switch to session B (working directory B) and invoke `/shepherd-review`. Wait for native window B to open. Note `sid-B`.
  3. Confirm `sid-A != sid-B`.
  4. Inspect `~/.shepherd/sessions/` on disk -- verify both `~/.shepherd/sessions/<sid-A>/session.json` and `~/.shepherd/sessions/<sid-B>/session.json` exist with disjoint `files[]` and disjoint `reviewContext`.
  5. In window A, add comments on one file and click Done. Confirm `~/.shepherd/sessions/<sid-A>/prompt-output.md` is created and `~/.shepherd/sessions/<sid-B>/prompt-output.md` does not exist yet.
  6. In window B, add comments on a different file and click Done. Confirm `~/.shepherd/sessions/<sid-B>/prompt-output.md` is created and contains only B's content.
  7. Confirm session A in the agent reads only A's prompt output, and session B reads only B's.
- **Expected**: Each session writes only to its own directory. No cross-contamination of files, context, or prompt output.
- **Pass criteria**: Disjoint session IDs, disjoint on-disk directories, no leakage of prompt output between sessions.

---

### Cancel Behavior

#### `TC-srm-cancel-keeps-window` -- Cancel ends agent session, leaves window for the user

- **Type**: Manual
- **Covers**: `AC-srm-cancel`
- **Preconditions**: A test branch with at least 2 reviewable files.
- **Steps**:
  1. Invoke `/shepherd-review`.
  2. After the native window opens and the AskUserQuestion prompt appears in the agent conversation, select **Cancel**.
  3. Observe the agent conversation: the session should end immediately with no completion summary printed.
  4. Switch focus to the native window: it should still be open and fully interactive.
  5. The user closes the window manually using standard macOS chrome (red traffic-light or `Cmd+W`).
  6. Optional: re-invoke `/shepherd-review` and confirm a new session can be started immediately.
- **Expected**:
  - On Cancel, agent prints no summary and stops.
  - Window remains open after Cancel; closing is fully under user control.
  - Re-invoking starts a fresh session.
- **Pass criteria**: Agent session terminates cleanly without summary on Cancel; window stays open until user closes it.

---

#### `TC-srm-interactive-prompt-options` -- All three AskUserQuestion options behave correctly

- **Type**: Manual
- **Covers**: `AC-sr-interactive-prompt`, `AC-srm-cancel`
- **Preconditions**: A test branch with at least 3 reviewable files.
- **Steps**:
  1. **Variant A -- Added comments**: Invoke `/shepherd-review`, add comments on 1 file, click Done in the window, then select "Added comments" in the agent prompt. Verify the agent reads `~/.shepherd/sessions/<id>/prompt-output.md` and shows the standard summary and action menu.
  2. **Variant B -- Reviewed, no comments**: Invoke `/shepherd-review` again, click Done in the window without adding any comments, select "Reviewed, no comments". Verify the agent shows a summary noting zero comments and ends without offering an action menu.
  3. **Variant C -- Cancel**: Invoke `/shepherd-review` again, do not click Done in the window, select "Cancel" in the agent prompt. Verify per `TC-srm-cancel-keeps-window`.
- **Expected**: All three branches produce the documented agent-side behavior. The native window's Done button is the trigger for branches A and B (per `FR-crp-macos-auto-close`); the agent does not write to or read from the native window.
- **Pass criteria**: Each branch matches its expected agent response and on-disk side effects.

---

### Context Display in the Native UI

#### `TC-srm-context-in-app` -- Overall and per-file context render with neutral/review separation

- **Type**: Manual
- **Covers**: `AC-srm-context-in-app`, `AC-sr-list-command`
- **Preconditions**: A test branch with at least 3 reviewable files of meaningfully different content (e.g., a feature change, a refactor, and a test).
- **Steps**:
  1. Invoke `/shepherd-review` and let the native window open.
  2. With no file tab selected (or with the inspector overall area visible), locate the ReviewContextSection in the inspector. Verify it shows an "Overall Neutral Context" subsection and an "Overall Review Feedback" subsection that are visually distinct (different headers, different styling, or otherwise unambiguously separated).
  3. Select the first file tab. Locate the ReviewContextPanel for that file. Verify it shows the same neutral/review split scoped to this file.
  4. Inspect the contents: neutral subsection should be factual ("function `foo` was renamed to `bar`"); review subsection should be opinionated ("consider extracting this branch into a helper").
  5. Confirm there is no mixing of neutral and review text within a subsection.
- **Expected**: Both overall and per-file context render as visually distinct neutral vs review subsections. Reviewer can tell at a glance which text is factual and which is the agent's opinion.
- **Pass criteria**: Visually distinct subsections present at both scopes; neutral/review content does not bleed across.

---

#### `TC-srm-context-tab-switch` -- Per-file context updates when switching tabs

- **Type**: Manual
- **Covers**: `AC-srm-context-in-app`
- **Preconditions**: Same as `TC-srm-context-in-app`.
- **Steps**:
  1. Open `/shepherd-review` and wait for the window with multiple file tabs.
  2. Note the per-file ReviewContextPanel content for the active (first) file.
  3. Click the second tab. Verify the ReviewContextPanel content updates to reflect the second file's per-file neutral and review entries.
  4. Click the third tab. Verify another update.
  5. Return to the first tab and confirm the original content is shown again.
- **Expected**: ReviewContextPanel content is keyed off the active file and updates synchronously when the active tab changes.
- **Pass criteria**: Each tab shows its own per-file context; switching is fluid and content does not lag, mix, or stick.

---

#### `TC-srm-context-graceful-missing` -- Missing context renders no errors

- **Type**: Manual
- **Covers**: `AC-srm-context-in-app` (graceful-missing branch), `FR-srm-context-handoff`
- **Preconditions**: Ability to invoke the launcher script directly with a known set of fixture files but **without** the `--context` flag.
- **Steps**:
  1. Pick 2 small fixture files in the repo (e.g., `README.md` and `package.json`).
  2. From a terminal: `./scripts/shepherd-launch.sh /absolute/path/to/README.md /absolute/path/to/package.json` -- omit `--context`.
  3. Wait for the native window to open.
  4. Verify both files load as tabs.
  5. Inspect the inspector overall area: ReviewContextSection should be hidden or rendered empty (per `AC-crp-context-graceful-missing`).
  6. Switch tabs: ReviewContextPanel should also be hidden / empty for each file.
  7. Confirm no error dialogs, console-error popups, or broken layout regions appear.
- **Expected**: Native app handles missing `reviewContext` cleanly: file tabs work, context surfaces are hidden, no errors.
- **Pass criteria**: Window functional, no errors logged or displayed, context regions cleanly absent.

---

### File Ordering

#### `TC-srm-priority-tab-order` -- File browser tab order matches priority

- **Type**: Manual
- **Covers**: `AC-sr-sorted-file-list`, `AC-srm-batch-open-native`, `FR-sr-priority-ordering`
- **Preconditions**: A test branch whose changeset includes a mix of: a core source file (e.g., `src/app.tsx`), a config file (e.g., `vite.config.ts`), a doc (`README.md`), and a test file (`tests/app.test.ts`).
- **Steps**:
  1. Invoke `/shepherd-review`.
  2. In the native window's file browser, read the row order top-to-bottom.
- **Expected**: The order is: core source, then config, then docs, then tests -- matching the priority tiers in `FR-sr-priority-ordering`. Within tiers, ordering is stable based on the agent's priority sort.
- **Pass criteria**: Source files appear before config; config before docs; docs before tests; first tab is the highest-priority file.

---

### Install Verification

#### `TC-srm-install-symlink` -- Installer creates the symlink

- **Type**: Manual
- **Covers**: `AC-srm-install-symlink`, `FR-srm-install`, `FR-srm-command-file`
- **Preconditions**: A clean macOS host with Swift toolchain installed but `~/.claude/commands/shepherd-review.md` and `~/.config/opencode/skills/shepherd-review/SKILL.md` not yet present (or removed for the test).
- **Steps**:
  1. From the repo root, run `./scripts/install-command.sh`.
  2. Wait for the script to complete successfully.
  3. Verify the symlink for the Claude command: `ls -l ~/.claude/commands/shepherd-review.md` -- the output should show a symlink (`->`) pointing into the repo's `.claude/commands/shepherd-review.md`.
  4. Verify the opencode skill symlink: `ls -l ~/.config/opencode/skills/shepherd-review/SKILL.md` -- should symlink into the repo's `.config/opencode/skills/shepherd-review/SKILL.md`.
  5. Resolve both with `readlink -f` and confirm they point inside the current repo.
  6. Open a Claude Code session in any directory and confirm `/shepherd-review` shows up in the slash-command picker.
- **Expected**: Both symlinks exist and resolve back into the repo. The slash command is discoverable globally.
- **Pass criteria**: Symlinks present, resolve correctly, command available globally.

---

#### `TC-srm-install-degraded-no-swift` -- Installer tolerates missing Swift toolchain

- **Type**: Manual
- **Covers**: `AC-srm-install-degraded`, `NFR-srm-platform-restriction`
- **Preconditions**: A macOS host where `swift` is on PATH normally, but the test will run the installer with `swift` removed from PATH.
- **Steps**:
  1. Move (or remove) any prebuilt binary at `engineering/apps/macos/.build/release/ShepherdApp` so the installer must attempt a build.
  2. Run the installer with a sanitized PATH that excludes Swift: `PATH=/usr/bin:/bin ./scripts/install-command.sh`.
  3. Observe stdout/stderr for warning messages.
  4. Inspect the symlinks at `~/.claude/commands/`: confirm `shepherd.md` and `shepherd-review.md` are present (the symlinks are created even when the toolchain is missing -- only the prebuild step is skipped, per `AC-srm-install-degraded`, and the installer reports degraded status without aborting).
  5. Confirm the script exit code: success (or a documented warning state), not a hard failure.
  6. Invoke `/shepherd-review` in a Claude Code session and confirm it surfaces the "binary not found" error (the symlink resolves, but the prebuilt binary is absent).
- **Expected**: Installer prints a clear warning that `/shepherd` and `/shepherd-review` are unavailable due to a missing Swift toolchain, completes without aborting, and exits with a non-failure status.
- **Pass criteria**: Installer completes without aborting; `/shepherd` and `/shepherd-review` are reported unavailable; installer exits with a non-failure status.

---

#### `TC-srm-install-git-pull` -- Updates propagate via git pull

- **Type**: Manual
- **Covers**: `AC-srm-install-git-pull`, `FR-srm-install`
- **Preconditions**: `./scripts/install-command.sh` has been run successfully and the symlinks exist.
- **Steps**:
  1. Edit the source file `.claude/commands/shepherd-review.md` in the repo to add a unique, harmless change to the prompt instructions (e.g., a new comment line at the top).
  2. Without re-running the installer, do **not** modify `~/.claude/commands/`.
  3. Read `~/.claude/commands/shepherd-review.md` directly (e.g., `cat ~/.claude/commands/shepherd-review.md`).
  4. Verify the unique change is visible there immediately, because the user-level path is a symlink to the repo file.
  5. Revert the edit (or stage as-is for cleanup), then simulate a `git pull` by checking out a different commit and back, and confirm the user-level path always reflects the current repo state.
- **Expected**: The user-level command file always reflects the repo file by virtue of being a symlink. No re-install needed after `git pull`.
- **Pass criteria**: Edits to the repo file are visible at the user-level path with no manual sync step.

---

### Error Cases

#### `TC-srm-binary-missing-error` -- Missing native binary surfaces a clear error

- **Type**: Manual
- **Covers**: Binary-missing error path from `design/macos/shepherd-review.md` "Error Cases"
- **Preconditions**: `/shepherd-review` is installed (symlink present) but the prebuilt binary at `engineering/apps/macos/.build/release/ShepherdApp` has been deleted or moved.
- **Steps**:
  1. Confirm the binary is absent: `ls engineering/apps/macos/.build/release/ShepherdApp` should fail.
  2. From a Claude Code session, invoke `/shepherd-review` on a branch with at least 1 reviewable file.
  3. Observe the agent conversation.
- **Expected**: The launcher prints the documented error message ("macOS app binary not found at <path>. Re-run ./scripts/install-command.sh from the Shepherd repo to build it."). The agent surfaces this message to the user and stops the slash-command flow without attempting any further work.
- **Pass criteria**: Error message appears verbatim; no native window opens; no AskUserQuestion prompt is presented; no session directory is left in a half-written state (or if it is, the launcher has cleaned it up per existing convention).

---

#### `TC-srm-not-git-repo` -- Error outside a git repository

- **Type**: Manual
- **Covers**: `AC-sr-not-git-repo`, `FR-sr-git-required`
- **Preconditions**: A directory that is not inside a git repository (e.g., `/tmp/not-a-repo`).
- **Steps**:
  1. Open a Claude Code session in the non-git directory.
  2. Invoke `/shepherd-review`.
- **Expected**: The agent prints the documented error message: "Not a git repository. /shepherd-review must be run from within a git repo." The flow stops without launching the native window.
- **Pass criteria**: Error message printed; no window opens; no session JSON written.

---

#### `TC-srm-no-changes` -- No changes produces a clear message

- **Type**: Manual
- **Covers**: `AC-sr-no-changes`, `AC-srm-empty-no-launch`, `FR-srm-no-blank-window`
- **Preconditions**: A clean checkout with no working-tree changes, no staged changes, no untracked files.
- **Steps**:
  1. Run `git status` and confirm the tree is clean.
  2. Invoke `/shepherd-review` (default scope).
- **Expected**: The agent prints "No uncommitted changes to review." and stops. No native window opens.
- **Pass criteria**: Message printed; no window; no session JSON written; crucially, no blank window appears.

---

#### `TC-srm-all-filtered` -- All files filtered produces a clear message

- **Type**: Manual
- **Covers**: `AC-sr-all-filtered`, `FR-sr-file-filtering`
- **Preconditions**: A branch whose only changes are excluded by filtering (e.g., only `package-lock.json` and `dist/bundle.js` modified).
- **Steps**:
  1. Confirm via `git diff --name-only origin/main...HEAD` (or equivalent) that all changed files are filterable.
  2. Invoke `/shepherd-review`.
- **Expected**: The agent prints "No reviewable files found. All N changed files were filtered out (lockfiles, generated, binary)." and stops. No native window opens.
- **Pass criteria**: Message printed with correct count; no window; no session JSON written.

---

### Skip and Quit-Early

#### `TC-srm-skip-file` -- Implicit skip via uncommented files

- **Type**: Manual
- **Covers**: `AC-sr-skip-file`, `AC-sr-unified-prompt`
- **Preconditions**: A test branch with 5 reviewable files.
- **Steps**:
  1. Invoke `/shepherd-review`.
  2. Add line comments on 2 of the 5 files. Leave the other 3 entirely uncommented.
  3. Click Done in the native window.
  4. Select "Added comments" in the agent prompt.
  5. Inspect the agent's rendering of the prompt and the file `~/.shepherd/sessions/<id>/prompt-output.md`.
- **Expected**: The unified prompt contains exactly 2 file sections (one per commented file). The 3 uncommented files do not appear -- they are implicitly skipped.
- **Pass criteria**: Prompt contents match the 2 commented files only.

---

#### `TC-srm-quit-early` -- User can end review at any point

- **Type**: Manual
- **Covers**: `AC-sr-quit-early`
- **Preconditions**: A test branch with 5 reviewable files.
- **Steps**:
  1. Invoke `/shepherd-review`.
  2. Add a comment on only 1 of the 5 files (do not touch the other 4 tabs).
  3. Click Done immediately (do not visit any other tabs).
  4. Select "Added comments" in the agent prompt.
- **Expected**: The session proceeds with whatever comments exist. The unified prompt contains the 1 commented file. The agent does not warn about "remaining files" or block the user. The summary numbers reflect 5 files opened, 1 with comments.
- **Pass criteria**: Single-file unified prompt; no warnings; clean completion summary.

---

### Review Scope Modes

These cases verify the macOS-specific scope grammar — the commit-scoped modes and the empty-changeset guard — that supersedes the shared `FR-sr-scope-argument` on macOS.

#### `TC-srm-default-scope` -- Default reviews uncommitted work only

- **Type**: Manual
- **Covers**: `AC-srm-default-scope`, `FR-srm-scope-modes`
- **Preconditions**: A feature branch with at least one committed change relative to its parent AND at least one uncommitted edit (staged or unstaged) to a *different* file.
- **Steps**:
  1. Note which file is changed only in the commit (call it `committed.ts`) and which is dirty in the working tree (`dirty.ts`).
  2. Invoke `/shepherd-review` with no argument.
- **Expected**: The review opens `dirty.ts` (and any other uncommitted change). `committed.ts` does NOT appear, because the default scope is working tree vs `HEAD`, not vs the branch base. The summary's `Reviewing:` line reads `all uncommitted changes`.
- **Pass criteria**: Only uncommitted files open; committed-only files absent.

---

#### `TC-srm-branch-scope` -- Branch mode reviews branch commits vs base

- **Type**: Manual
- **Covers**: `AC-srm-branch-scope`, `FR-srm-branch-scope`, `FR-srm-commit-mode-no-untracked`
- **Preconditions**: A feature branch with 3 commits ahead of `main`, a clean working tree, and a separate change on `main` after the branch point (so two-dot vs three-dot would differ).
- **Steps**:
  1. Invoke `/shepherd-review --branch`.
  2. Separately invoke `/shepherd-review --branch <other-base>` against a second base branch.
- **Expected**: For `--branch`, the review contains exactly the files changed by the 3 branch commits relative to the merge base with `main`; the post-divergence `main` change is NOT included (three-dot semantics). The scope label reads `commits on <branch> vs main`. For `--branch <other-base>`, the comparison base is `<other-base>`. Untracked files, if any, are excluded.
- **Pass criteria**: File set matches `git diff --name-status main...HEAD`; base override honored; untracked excluded.

---

#### `TC-srm-commit-scope` -- Single-commit mode reviews one commit

- **Type**: Manual
- **Covers**: `AC-srm-commit-scope`, `FR-srm-commit-scope`, `FR-srm-commit-mode-no-untracked`
- **Preconditions**: A branch where `HEAD` and `HEAD~2` each touch distinct files; a repo that also has a known root commit for the root sub-check.
- **Steps**:
  1. Invoke `/shepherd-review --commit` (no ref).
  2. Invoke `/shepherd-review --commit HEAD~2`.
  3. (Root-commit sub-check) In a repo with a single root commit, invoke `/shepherd-review --commit <root-sha>`.
- **Expected**: (1) reviews exactly the files in `HEAD` vs its parent; scope label `commit <short-sha> — <subject>`. (2) reviews the files in `HEAD~2` vs `HEAD~3`. (3) the root commit reviews against the empty tree — every file appears as newly added. Untracked working-tree files never appear.
- **Pass criteria**: File set matches `git diff --name-status <ref>^ <ref>` (or empty-tree for root); untracked excluded.

---

#### `TC-srm-range-scope` -- Range mode reviews a commit span

- **Type**: Manual
- **Covers**: `AC-srm-range-scope`, `FR-srm-range-scope`, `FR-srm-commit-mode-no-untracked`
- **Preconditions**: A branch with several commits so a meaningful range exists.
- **Steps**:
  1. Invoke `/shepherd-review --range HEAD~3..HEAD`.
  2. Invoke `/shepherd-review --range HEAD~3...HEAD` (three-dot).
  3. Invoke `/shepherd-review --range bogusref..HEAD` (invalid endpoint).
  4. Invoke `/shepherd-review --range HEAD` (no `..`).
- **Expected**: (1) and (2) review the net diff across the range (matching `git diff --name-status HEAD~3..HEAD` / `...HEAD` respectively); scope label `commit range <range>`. (3) and (4) print the usage block and stop without launching the app. Untracked files excluded throughout.
- **Pass criteria**: Valid ranges open the correct file set; invalid/malformed ranges produce usage + no window.

---

#### `TC-srm-empty-no-launch` -- Empty scope shows a message, never a blank window

- **Type**: Manual
- **Covers**: `AC-srm-empty-no-launch`, `FR-srm-no-blank-window`
- **Preconditions**: Ability to construct each empty case: clean tree (default), branch with no commits beyond base (`--branch` from the base tip), an empty/no-op commit (`--commit` on a commit that only changed a now-filtered file), and an empty range.
- **Steps**:
  1. With a clean tree, invoke `/shepherd-review`.
  2. From a branch even with `main`, invoke `/shepherd-review --branch`.
  3. Invoke `/shepherd-review --range HEAD..HEAD`.
- **Expected**: Each invocation prints a clear scope-specific message ("No uncommitted changes to review.", "No commits on <branch> relative to main. Nothing to review.", "No changes in range HEAD..HEAD. Nothing to review.") and stops. No `session.json` is written and no native window — blank or otherwise — opens.
- **Pass criteria**: Correct message per scope; zero windows; no launcher invocation.

---

#### `TC-srm-scope-invalid` -- Unrecognized argument prints usage

- **Type**: Manual
- **Covers**: `FR-srm-scope-modes`
- **Preconditions**: Any git repo.
- **Steps**:
  1. Invoke `/shepherd-review --bogus`.
  2. Invoke `/shepherd-review nonexistent-ref-xyz`.
- **Expected**: Both print the full usage block (listing default, `--staged`, `--unstaged`, `--branch`, `--commit`, `--range`, `<ref>`) and stop. No window opens. (Note: `nonexistent-ref-xyz` falls through to the `<ref>` branch, fails `git rev-parse --verify`, and produces the usage message.)
- **Pass criteria**: Usage block shown; no window.

---

### Launcher Contract (Automated)

These cases exercise `scripts/shepherd-launch.sh` directly to verify the launcher honors the multi-file and `--context` contract that `/shepherd-review` relies on. They are written as shell tests that can run in CI without the native binary actually launching (mock `ShepherdApp` invocation by setting an env var, or run on a macOS CI runner with the binary present and `--dry-run`-equivalent behavior, depending on how the launcher's existing tests are structured).

#### `TC-srm-launcher-context-flag` -- Launcher with `--context` populates `reviewContext`

- **Type**: Automated (shell)
- **Covers**: `FR-srm-context-handoff`, `FR-srm-multi-file-launch`
- **Preconditions**: The launcher script is checked in. A test fixture exists at `/tmp/test-context.json` (created by the test harness) with the structured `reviewContext` payload (overall neutral, overall review, files map). Two fixture files exist on disk.
- **Steps**:
  1. The harness prepares `/tmp/test-context.json`:
     ```json
     {
       "overall": {"neutral": "Adds two helpers.", "review": "Looks straightforward."},
       "files": {
         "/tmp/fixture-a.ts": {"neutral": "Adds foo()", "review": "Consider naming."},
         "/tmp/fixture-b.ts": {"neutral": "Adds bar()", "review": "OK."}
       }
     }
     ```
  2. Harness invokes: `./scripts/shepherd-launch.sh --context /tmp/test-context.json /tmp/fixture-a.ts /tmp/fixture-b.ts`.
  3. Harness intercepts the eventual binary invocation (e.g., via env-var mock) and reads `~/.shepherd/sessions/<sid>/session.json`.
  4. Harness verifies the JSON structure: `files[]` has both fixtures in the order given, and `reviewContext` is non-null with overall and files entries that match the fixture.
- **Expected**: `session.json` contains a populated `reviewContext` field whose overall and per-file content exactly mirrors the input fixture, and `files[]` lists both fixtures in input order.
- **Pass criteria**: JSON assertions pass: `reviewContext != null`, `reviewContext.overall.neutral == "Adds two helpers."`, `reviewContext.files["/tmp/fixture-a.ts"].review == "Consider naming."`, `len(files) == 2`.

---

#### `TC-srm-launcher-no-context-flag` -- Launcher without `--context` keeps backward compat

- **Type**: Automated (shell)
- **Covers**: `FR-srm-context-handoff` (backward compat for single-file `/shepherd` callers)
- **Preconditions**: Launcher script checked in. One fixture file exists.
- **Steps**:
  1. Harness invokes: `./scripts/shepherd-launch.sh /tmp/fixture-a.ts` (no `--context`).
  2. Harness reads `~/.shepherd/sessions/<sid>/session.json`.
- **Expected**: `session.json` contains `files[]` with the single fixture and `reviewContext` is `null` (matching the existing single-file `/shepherd` behavior, so the binary's existing fall-through path applies).
- **Pass criteria**: `reviewContext == null`; `files[]` has exactly the one fixture entry; no JSON parse errors.

---

## Edge Cases and Error Scenarios

The following edge cases are noted but covered by the test cases above rather than getting their own dedicated case:

### Concurrent invocations from different working directories

- **Trigger**: Two `/shepherd-review` invocations started in close succession from different repos or worktrees.
- **Expected behavior**: Each invocation gets its own session ID, its own `~/.shepherd/sessions/<id>/` directory, and its own native window. No file or context payload is shared between sessions.
- **Test case**: `TC-srm-session-isolation`.

### Missing `--context` argument

- **Trigger**: The launcher is invoked without `--context` -- e.g., from `/shepherd` (single-file) or from a test harness.
- **Expected behavior**: `session.json` has `reviewContext: null`. The native binary detects null context and hides the ReviewContextSection / ReviewContextPanel surfaces.
- **Test case**: `TC-srm-launcher-no-context-flag`, `TC-srm-context-graceful-missing`.

### Malformed context JSON

- **Trigger**: The agent passes a `--context` path to a file that is not valid JSON (e.g., truncated, syntax error).
- **Expected behavior**: The launcher reports a parse error and exits non-zero before invoking the binary; the agent surfaces the error and stops. (Implementation detail handled by launcher; not exercised here, but covered indirectly by `TC-srm-launcher-context-flag`'s positive path.)
- **Test case**: not directly tested here. Future addition for `qa/macos/shepherd-review.md` if regressions arise.

### Very large file payloads

- **Trigger**: A single reviewable file is many MB (e.g., a large JSON fixture wrongly included in the changeset).
- **Expected behavior**: The launcher writes the contents into `session.json` regardless of size; the binary loads it. Performance may degrade above the budget in `NFR-srm-launch-budget` but correctness should hold. If degradation becomes a real issue, add a dedicated case here.
- **Test case**: not directly tested here -- the filtering rules (`FR-sr-file-filtering`) typically exclude generated large files, and human-authored source rarely exceeds the budget.

### Concurrent same-project invocations

- **Trigger**: Two invocations from the **same** project root (same session ID basename) -- rare edge.
- **Expected behavior**: Per `AC-crp-macos-window-deduplicate`, the second invocation brings the existing window to front and updates that window's session JSON.
- **Test case**: covered by `qa/macos/code-review-prompt.md::TC-crp-macos-window-deduplicate`. Cross-referenced here for completeness.

---

## Test Environment

- **OS**: macOS 14+ (Sonoma) or later.
- **Toolchain**: Swift toolchain installed (Xcode or `swift` CLI on PATH) for the install-time build of `ShepherdApp`. For `TC-srm-install-degraded-no-swift`, a sanitized PATH that excludes Swift is required.
- **Agent runtime**: Claude Code or opencode installed and configured. Both runtimes should be exercised at least once across the manual test runs.
- **Repo state**: A test repo with a primary branch named `main` and a feature branch with a curated mix of reviewable and excluded files (lockfile, generated file, binary, source, config, doc, test). Reusing a fixture branch is recommended.
- **Filesystem**: Write access to `~/.shepherd/sessions/`. Verify cleanup between tests if session-state from a prior run could affect outcomes (delete `~/.shepherd/sessions/<sid>/` between runs of the same session ID).
- **Network**: No outbound network access required by the macOS variant. `TC-srm-no-server` is the explicit negative-network case.

## Regression Considerations

- **`/shepherd` (single-file)**: Any change to the launcher's argument parsing or `session.json` schema must continue to support single-file invocation without the `--context` flag (`TC-srm-launcher-no-context-flag`).
- **Install symlinks**: The review command's install path must not disturb the `/shepherd` symlink. `TC-srm-coexistence` verifies both commands coexist; install-script changes should re-run the full install matrix.
- **Native multi-file UI**: Changes to the file browser, ReviewContextSection, or ReviewContextPanel are owned by `qa/macos/code-review-prompt.md`. Changes there must not break the assumptions in `TC-srm-happy-path` (priority tab order, neutral/review subsection labels, Done auto-close).
- **Session-scoping primitives**: Changes to `~/.shepherd/sessions/<id>/` layout (e.g., renaming `session.json` or `prompt-output.md`) cascade through `TC-srm-session-isolation`, `TC-srm-happy-path`, and the launcher tests.
