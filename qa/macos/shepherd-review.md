---
product-hash: 3be8b01ef980231ee907e94c5591e47414c5e047c1e0495541e48426acbca4ae
product-slugs: [AC-sr-all-filtered, AC-sr-auto-open, AC-sr-batch-open, AC-sr-bunker-signing, AC-sr-completion-summary, AC-sr-context-in-crpg, AC-sr-excludes-deleted, AC-sr-filters-binary, AC-sr-filters-generated, AC-sr-filters-lockfiles, AC-sr-happy-path, AC-sr-includes-config, AC-sr-install-global, AC-sr-interactive-prompt, AC-sr-invokes-shepherd, AC-sr-list-command, AC-sr-no-changes, AC-sr-not-git-repo, AC-sr-patch-application-conflicts, AC-sr-patch-conflicting-args, AC-sr-patch-event-not-found, AC-sr-patch-happy-path, AC-sr-patch-invalid-diff, AC-sr-patch-invalid-event-id, AC-sr-patch-metadata-displayed, AC-sr-patch-reply-publish, AC-sr-patch-reply-respond, AC-sr-quit-early, AC-sr-reviewer-identity, AC-sr-skip-file, AC-sr-sorted-file-list, AC-sr-unified-prompt, FR-sc-session-id, FR-sc-session-scoped-output, FR-sr-bunker-signing, FR-sr-changeset-detection, FR-sr-changeset-overview, FR-sr-command-file, FR-sr-completion-summary, FR-sr-context-handoff, FR-sr-feedback-collection, FR-sr-file-filtering, FR-sr-file-list-display, FR-sr-git-required, FR-sr-install, FR-sr-iteration-loop, FR-sr-multi-file-launch, FR-sr-patch-application, FR-sr-patch-fetch, FR-sr-patch-metadata-display, FR-sr-patch-replies-display, FR-sr-patch-replies-live, FR-sr-patch-reply-publish, FR-sr-patch-reply-respond, FR-sr-patch-source, FR-sr-patch-validation, FR-sr-per-file-context, FR-sr-priority-ordering, FR-sr-relay-client, FR-sr-reviewer-identity, FR-sr-scope-argument, NFR-sr-agent-native, NFR-sr-cross-platform, NFR-sr-no-dependencies, NFR-sr-startup-speed]
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
| `AC-srm-patch-open-happy` | `TC-srm-patch-open-happy`, `TC-srm-patch-open-splitter-unit` | Not started |
| `AC-srm-patch-open-nevent` | `TC-srm-patch-open-nevent` | Not started |
| `AC-srm-patch-open-invalid-id` | `TC-srm-patch-open-invalid-id` | Not started |
| `AC-srm-patch-open-not-found` | `TC-srm-patch-open-not-found` | Not started |
| `AC-srm-patch-open-wrong-kind` | `TC-srm-patch-open-wrong-kind` | Not started |
| `AC-srm-patch-open-bad-diff` | `TC-srm-patch-open-bad-diff` | Not started |
| `AC-srm-patch-open-no-relays` | `TC-srm-patch-open-no-relays` | Not started |
| `AC-srm-patch-open-activates-thread` | `TC-srm-patch-open-activates-thread` | Not started |
| `AC-sr-patch-happy-path` | `TC-sr-patch-happy-path` | Not started |
| `AC-sr-patch-event-not-found` | `TC-sr-patch-event-not-found` | Not started |
| `AC-sr-patch-invalid-diff` | `TC-sr-patch-invalid-diff` | Not started |
| `AC-sr-patch-application-conflicts` | `TC-sr-patch-application-conflicts` | Not started |
| `AC-sr-patch-metadata-displayed` | `TC-sr-patch-metadata-displayed` | Not started |
| `AC-sr-patch-invalid-event-id` | `TC-sr-patch-invalid-event-id` | Not started |
| `AC-sr-patch-conflicting-args` | `TC-sr-patch-conflicting-args` | Not started |
| `AC-sr-patch-reply-publish` | `TC-sr-patch-reply-publish`, `TC-srm-comment-publish` | Not started |
| `AC-sr-patch-reply-respond` | `TC-sr-patch-reply-respond`, `TC-srm-reply-to-reply` | Not started |
| `AC-sr-reviewer-identity` | `TC-srm-identity-load`, `TC-srm-identity-indicator` | Not started |
| `AC-srm-identity-load` | `TC-srm-identity-load`, `TC-srm-identity-no-key` | Not started |
| `AC-srm-comment-publish` | `TC-srm-comment-publish`, `TC-srm-comment-publish-no-identity` | Not started |
| `AC-srm-reply-to-reply` | `TC-srm-reply-to-reply` | Not started |
| `AC-srm-publish-no-dup` | `TC-srm-publish-no-dup` | Not started |
| `AC-srm-publish-relay-failure` | `TC-srm-publish-relay-failure` | Not started |
| `AC-sr-bunker-signing` | `TC-srm-bunker-sign`, `TC-srm-bunker-sign-failure` | Not started |
| `AC-srm-bunker-connect` | `TC-srm-bunker-connect`, `TC-srm-bunker-uri-malformed` | Not started |
| `AC-srm-bunker-sign` | `TC-srm-bunker-sign` | Not started |
| `AC-srm-bunker-sign-failure` | `TC-srm-bunker-sign-failure` | Not started |

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
| `FR-sr-patch-source` | `TC-sr-patch-happy-path`, `TC-sr-patch-event-not-found` | Not started |
| `FR-sr-patch-fetch` | `TC-sr-patch-happy-path`, `TC-sr-patch-event-not-found` | Not started |
| `FR-sr-patch-validation` | `TC-sr-patch-invalid-diff`, `TC-sr-patch-invalid-event-id` | Not started |
| `FR-sr-patch-application` | `TC-sr-patch-application-conflicts` | Not started |
| `FR-sr-patch-metadata-display` | `TC-sr-patch-metadata-displayed` | Not started |
| `FR-sr-patch-replies-display` | `TC-sr-patch-replies-displayed`, `TC-sr-patch-replies-empty` | Not started |
| `FR-sr-patch-replies-live` | `TC-sr-patch-replies-live`, `TC-sr-patch-replies-live-no-relays` | Not started |
| `FR-sr-relay-client` | `TC-sr-patch-replies-live`, `TC-sr-patch-replies-live-no-relays` | Not started |
| `FR-sr-patch-reply-publish` | `TC-sr-patch-reply-publish`, `TC-srm-comment-publish` | Not started |
| `FR-sr-reviewer-identity` | `TC-srm-identity-load`, `TC-srm-identity-indicator`, `TC-srm-bunker-connect` | Not started |
| `FR-sr-patch-reply-respond` | `TC-sr-patch-reply-respond`, `TC-srm-reply-to-reply` | Not started |
| `FR-sr-bunker-signing` | `TC-srm-bunker-sign`, `TC-srm-bunker-sign-failure` | Not started |
| `FR-srm-identity-load` | `TC-srm-identity-load`, `TC-srm-identity-no-key`, `TC-srm-bunker-uri-malformed` | Not started |
| `FR-srm-bunker-connect` | `TC-srm-bunker-connect`, `TC-srm-bunker-uri-malformed`, `TC-srm-nip44-unit` | Not started |
| `FR-srm-event-sign` | `TC-srm-comment-publish` (signed event verified), `TC-srm-signer-unit`, `TC-srm-bunker-sign` | Not started |
| `FR-srm-bunker-sign-failure` | `TC-srm-bunker-sign-failure` | Not started |
| `FR-srm-event-publish` | `TC-srm-comment-publish`, `TC-srm-publish-relay-failure` | Not started |
| `FR-srm-comment-publish-on-submit` | `TC-srm-comment-publish`, `TC-srm-comment-publish-no-identity` | Not started |
| `FR-srm-reply-to-reply` | `TC-srm-reply-to-reply` | Not started |
| `FR-srm-identity-indicator` | `TC-srm-identity-indicator`, `TC-srm-identity-no-key`, `TC-srm-bunker-identity-indicator` | Not started |

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
- **Preconditions**: A clean macOS host with Swift toolchain installed but `~/.claude/commands/shepherd-review.md` and `~/.config/opencode/skills/shepherd-review/SKILL.md` not present (or removed for the test).
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

### NIP-34 Patch Review

Testing patch review via `--patch <event-id>` mode.

#### NIP-34 patch happy path `TC-sr-patch-happy-path`
- **Type**: Manual
- **Covers**: `AC-sr-patch-happy-path`, `FR-sr-patch-source`, `FR-sr-patch-fetch`, `FR-sr-patch-validation`, `FR-sr-patch-application`, `FR-sr-patch-metadata-display`, `AC-sr-patch-metadata-displayed`
- **Preconditions**: 
  - Valid NIP-34 patch event exists on a configured Nostr relay (create test event or use a known good one)
  - Event ID is known (64-char hex)
  - Relay URLs configured (via `NOSTR_RELAYS` env var or default relays)
  - Current repo has the parent commit of the patch
- **Steps**:
  1. From Claude Code/opencode: `/shepherd-review --patch <event-id>`
  2. Observe agent conversation output (fetching event, validating, applying patch)
  3. Verify agent reports "Opening N files in the macOS app for review" with scope label "NIP-34 patch <short-id>"
  4. Native macOS window opens with reviewable files as tabs
  5. Inspector shows patch metadata section above overall review context:
     - Patch ID (short + copy button)
     - Author (resolved name or short pubkey)
     - Commit message (first line)
     - Parent commit (short hash)
     - Status badge (color-coded: open=blue, merged=green, closed=red, draft=gray)
  6. Click Done in native window, select "Added comments" in interactive prompt
  7. Verify agent reads prompt output and displays completion summary
  8. Check original branch is restored and stash is popped (if one was created)
  9. Verify `review/patch-<short-id>` branch exists
- **Expected**: Full patch review workflow completes successfully, patch metadata is displayed correctly in native UI, review branch created, original state restored.

#### Patch event not found `TC-sr-patch-event-not-found`
- **Type**: Manual
- **Covers**: `AC-sr-patch-event-not-found`, `FR-sr-patch-fetch`
- **Preconditions**: Relay URLs configured
- **Steps**:
  1. From agent: `/shepherd-review --patch 0000000000000000000000000000000000000000000000000000000000000000` (non-existent ID)
  2. Observe agent output
- **Expected**: Command reports "Patch event 0000... not found on relays: [relay URLs]" and stops. No review branch created, no window opens.

#### Invalid patch diff format `TC-sr-patch-invalid-diff`
- **Type**: Manual
- **Covers**: `AC-sr-patch-invalid-diff`, `FR-sr-patch-validation`
- **Preconditions**: NIP-34 event exists with malformed diff content (missing `diff --git` headers or mangled hunks)
- **Steps**:
  1. From agent: `/shepherd-review --patch <malformed-event-id>`
  2. Observe agent output
- **Expected**: Command reports "Invalid patch diff format in event <id>" and stops. No patch is applied, no window opens.

#### Patch application conflicts `TC-sr-patch-application-conflicts`
- **Type**: Manual
- **Covers**: `AC-sr-patch-application-conflicts`, `FR-sr-patch-application`
- **Preconditions**: NIP-34 patch event with diff that conflicts with current repo state (e.g., file doesn't exist, hunks don't apply)
- **Steps**:
  1. From agent: `/shepherd-review --patch <conflicting-event-id>`
  2. Observe agent output when `git apply` fails
- **Expected**: Command reports git error (e.g., "error: patch failed: src/utils.ts:42") and stops. Review branch is created but patch is not applied. Original branch/stash unchanged.

#### Patch metadata displayed correctly `TC-sr-patch-metadata-displayed`
- **Type**: Manual
- **Covers**: `AC-sr-patch-metadata-displayed`, `FR-sr-patch-metadata-display`
- **Preconditions**: Valid patch event with known author pubkey, commit message, parent commit, and status
- **Steps**:
  1. Review a patch via `/shepherd-review --patch <event-id>`
  2. Inspect patch metadata section in native macOS window inspector
  3. Verify all five fields are present and correctly formatted:
     - Patch ID shows short form with Copy button
     - Author shows resolved display name (if available) or truncated npub
     - Commit message shows first line, truncated to 60 chars if longer
     - Parent commit shows 8-char short hash
     - Status badge shows correct color coding
- **Expected**: All metadata fields render correctly with proper formatting and color coding.

#### Patch thread replies displayed `TC-sr-patch-replies-displayed`
- **Type**: Manual
- **Covers**: `FR-sr-patch-replies-display`
- **Preconditions**: Valid patch event with at least two kind:1 reply notes tagged `["e", "<patch-event-id>", "", "root"]` on a configured relay -- one from a known bot/agent pubkey, one from a human. At least one reply carries a line-range anchor pointing at a file in the applied patch. A NIP-34 status-transition event (kind 1630-1633) for the same patch also exists on the relay.
- **Steps**:
  1. From agent: `/shepherd-review --patch <event-id>`
  2. Native window opens; inspect the inspector below the patch metadata section
  3. Verify a "Patch Thread (<n>)" section lists both replies
  4. Verify the bot reply shows a `BOT` badge + purple tint + cpu glyph; the human reply shows orange tint + person glyph and no badge
  5. Verify the status-transition event is NOT listed as a reply
  6. Switch to the file tab the anchored reply points at; verify the anchored reply also renders inline at its line span, read-only (no edit/delete chrome), visually distinct from the reviewer's own Comment bubbles
  7. Switch to a different file tab; verify the anchored reply does NOT render inline there (only on its anchored file)
- **Expected**: Both replies appear in the inspector section with correct bot/human markers; the status-transition event is excluded; the anchored reply renders inline only on its anchored file; all reply surfaces are read-only.

#### Patch with no thread replies renders no section `TC-sr-patch-replies-empty`
- **Type**: Manual
- **Covers**: `FR-sr-patch-replies-display`
- **Preconditions**: Valid patch event with zero kind:1 root replies on configured relays.
- **Steps**:
  1. From agent: `/shepherd-review --patch <event-id>`
  2. Native window opens; inspect the inspector
- **Expected**: No "Patch Thread" section appears (gated on non-empty replies). The patch metadata section still renders. The review completes normally.

#### Patch thread replies refresh live `TC-sr-patch-replies-live`
- **Type**: Manual
- **Covers**: `FR-sr-patch-replies-live`, `FR-sr-relay-client`
- **Preconditions**: Valid patch event reviewed via `/shepherd-review --patch <event-id>`; the macOS window is open; the app can reach at least one configured Nostr relay over WebSocket. A new kind:1 root reply is published to a configured relay while the window is open.
- **Steps**:
  1. Open the patch review; confirm the initial reply snapshot (from `session.json`) renders in the inspector
  2. From another client, publish a new kind:1 note tagged `["e", "<patch-event-id>", "", "root"]` to a configured relay
  3. Wait for the relay to deliver the event (sub-second to a few seconds)
  4. Verify the new reply appears in the inspector "Patch Thread" section without relaunching
  5. If the new reply carries a `["range", file, start, end]` tag whose `file` matches an open tab's absolute path, verify it also renders inline on that tab
  6. Click Done; verify the window closes and the relay subscription is cancelled (no lingering connection)
- **Expected**: New replies appear live with no relaunch; the subscription is torn down when the window closes.

#### Patch reply live subscription degrades when relays are unreachable `TC-sr-patch-replies-live-no-relays`
- **Type**: Manual
- **Covers**: `FR-sr-patch-replies-live`, `FR-sr-relay-client`
- **Preconditions**: A patch review is opened with all configured relays unreachable (e.g. `NOSTR_RELAYS=wss://invalid.invalid`); the initial snapshot was baked into `session.json`.
- **Steps**:
  1. Open `/shepherd-review --patch <event-id>` with relays unreachable
  2. Confirm the window opens and renders the initial snapshot (or "no replies")
  3. Wait; confirm no crash, no errors surfaced, the window remains usable
- **Expected**: The app renders the initial snapshot only and is otherwise unaffected. Best-effort degradation; no external `nak` process is required.

#### Invalid event ID format `TC-sr-patch-invalid-event-id`
- **Type**: Manual
- **Covers**: `AC-sr-patch-invalid-event-id`, `FR-sr-patch-validation`
- **Preconditions**: None
- **Steps**:
  1. From agent: `/shepherd-review --patch not-a-valid-hex-string`
  2. Observe agent output
- **Expected**: Command reports "Invalid event ID format. Expected 64-character hex string." and stops immediately. No relay queries attempted.

#### Conflicting patch arguments `TC-sr-patch-conflicting-args`
- **Type**: Manual
- **Covers**: `AC-sr-patch-conflicting-args`
- **Preconditions**: None
- **Steps**:
  1. From agent: `/shepherd-review --patch abc123... --staged`
  2. Observe agent output
- **Expected**: Command reports "Cannot combine --patch with --staged or --unstaged" and displays usage message. No work is performed.

### Patch-Thread Reply Publishing (Bidirectional)

These cases verify the reviewer can publish replies to the patch thread from the native app under their own Nostr identity, respond to existing replies, and that publish state and failure are handled. They require a configured reviewer identity (`SHEPHERD_NSEC` or `~/.config/nostr/identity`) and a test patch event on a reachable relay.

#### Reviewer publishes a reply from the native app `TC-sr-patch-reply-publish`
- **Type**: Manual
- **Covers**: `AC-sr-patch-reply-publish`, `FR-sr-patch-reply-publish`, `FR-srm-comment-publish-on-submit`
- **Preconditions**: A test patch event reviewed via `/shepherd-review --patch <event-id>`; the reviewer identity configured (`SHEPHERD_NSEC` set to a test nsec); at least one configured relay reachable.
- **Steps**:
  1. Open the patch review; confirm the identity indicator shows the reviewer's display name / npub.
  2. Click a line range on the diff to open the inline comment editor; type a comment; click **Publish**.
  3. Observe the editor close and the reply render immediately (inline at its anchor and in the inspector Patch Thread section) with the `YOU` badge -- before any relay round-trip.
  4. From a separate client, run `nak req -k 1 -e <patch-event-id>` and confirm a kind:1 note exists whose `pubkey` is the reviewer's, tagged `["e", "<patch-id>", "", "root"]`, the repo `a` tag, and a `range` anchor matching the commented file + lines.
- **Expected**: A signed kind:1 reply is published under the reviewer's identity, carries the root `e`, `a`, and `range` tags, and renders immediately in the reviewer's own window with the self marker.

#### Reviewer responds to an existing reply `TC-sr-patch-reply-respond`
- **Type**: Manual
- **Covers**: `AC-sr-patch-reply-respond`, `FR-sr-patch-reply-respond`, `FR-srm-reply-to-reply`
- **Preconditions**: A patch review open with at least one existing patch-thread reply from another participant; reviewer identity configured.
- **Steps**:
  1. Click **Reply** on an existing reply's inspector row (or inline bubble).
  2. Confirm the inline comment editor opens pre-targeted at that reply.
  3. Type a response and click **Publish**.
  4. Confirm the response renders alongside the replied-to reply with the `YOU` badge.
  5. From a separate client, fetch the published event and confirm it carries a root `e` tag on the patch event, a reply `e` tag `["e", "<replied-to-id>", "", "reply"]`, and a `p` tag naming the replied-to reply's author.
- **Expected**: The published response is threaded correctly (root + reply `e` + `p` tags) and renders alongside the replied-to reply.

#### Identity loaded from config `TC-srm-identity-load`
- **Type**: Manual
- **Covers**: `AC-srm-identity-load`, `FR-srm-identity-load`
- **Preconditions**: `SHEPHERD_NSEC` set to a known test nsec (or `~/.config/nostr/identity` populated).
- **Steps**:
  1. Open a patch review.
  2. Inspect the identity indicator: confirm it shows the display name (or truncated npub) matching the configured nsec's public key.
  3. Confirm the editor submit button reads **Publish** (publish is offered).
- **Expected**: The app loads the configured identity, surfaces it, and offers publish.

#### No identity configured -- publish unavailable, local still works `TC-srm-identity-no-key`
- **Type**: Manual
- **Covers**: `AC-srm-identity-load`, `AC-sr-reviewer-identity`, `FR-srm-identity-indicator`
- **Preconditions**: `SHEPHERD_NSEC` unset and `~/.config/nostr/identity` absent.
- **Steps**:
  1. Open a patch review.
  2. Confirm the identity indicator shows the no-identity warning (`No identity -- replies won't publish`) and the config hint.
  3. Add an inline comment and confirm the submit button reads **Save locally** (not **Publish**).
  4. Submit the comment; confirm it is recorded locally and renders, but no kind:1 event is published (verify via `nak req -k 1 -e <patch-id>` that no new reply with the reviewer's absence appears).
- **Expected**: Read-only review and local commenting work; no publish is offered or attempted; the indicator makes the no-identity state clear.

#### Identity indicator states `TC-srm-identity-indicator`
- **Type**: Manual
- **Covers**: `FR-srm-identity-indicator`, `AC-sr-reviewer-identity`
- **Preconditions**: Ability to toggle `SHEPHERD_NSEC` between set and unset across two launches.
- **Steps**:
  1. With `SHEPHERD_NSEC` set, open a patch review; confirm the indicator shows the key glyph + display name with the full npub in the tooltip/accessibility label.
  2. Unset `SHEPHERD_NSEC`, relaunch; confirm the indicator shows the warning glyph + no-identity text + config hint.
  3. Open a non-patch review (default scope) with `SHEPHERD_NSEC` set; confirm the identity indicator is absent (present only for patch reviews).
- **Expected**: Indicator reflects loaded vs no-identity state for patch reviews and is absent for non-patch reviews.

#### Comment publishes on submit (happy path) `TC-srm-comment-publish`
- **Type**: Manual
- **Covers**: `AC-srm-comment-publish`, `FR-srm-comment-publish-on-submit`, `FR-srm-event-sign`, `FR-srm-event-publish`
- **Preconditions**: Patch review open; reviewer identity configured; relay reachable.
- **Steps**:
  1. Submit an inline comment anchored to a line range.
  2. Confirm the submit button shows `Publishing...` then the editor closes and a `Reply published to patch thread` confirmation appears.
  3. Confirm the reply renders immediately with the `YOU` badge at both surfaces.
  4. Confirm the published event's `id`/`pubkey`/`sig` form a valid NIP-01 event (verify signature with `nak verify` or equivalent).
- **Expected**: Submit signs and publishes a valid NIP-01 event; the reply renders immediately; publish confirmation shows.

#### Comment submit with no identity stays local `TC-srm-comment-publish-no-identity`
- **Type**: Manual
- **Covers**: `AC-srm-comment-publish` (no-identity branch), `FR-srm-comment-publish-on-submit`
- **Preconditions**: Patch review open; no identity configured.
- **Steps**:
  1. Add an inline comment; confirm submit reads **Save locally**.
  2. Submit; confirm the comment is recorded locally and renders.
  3. Confirm no publish occurred (no relay EVENT frame sent -- inspect with a relay monitor or confirm no new event via `nak req`).
- **Expected**: Local-only comment; no publish attempted.

#### Respond to a reply from inline `TC-srm-reply-to-reply`
- **Type**: Manual
- **Covers**: `AC-srm-reply-to-reply`, `FR-srm-reply-to-reply`
- **Preconditions**: Patch review open with an existing reply; reviewer identity configured.
- **Steps**:
  1. Click **Reply** on an inline anchored reply bubble.
  2. Confirm the editor opens at that bubble's line span, pre-targeted at the reply.
  3. Submit a response; confirm it publishes with the threaded `e`/`p` tags (per `TC-sr-patch-reply-respond` step 5) and renders with the `YOU` badge.
- **Expected**: Reply-to-reply works from the inline surface; published event is threaded correctly.

#### Self-published reply is not duplicated on relay round-trip `TC-srm-publish-no-dup`
- **Type**: Manual
- **Covers**: `AC-srm-publish-no-dup`
- **Preconditions**: Patch review open; reviewer identity configured; relay reachable; live subscription active.
- **Steps**:
  1. Publish a reply from the app (per `TC-srm-comment-publish`).
  2. Wait for the live relay subscription to deliver the same event back (a few seconds).
  3. Confirm the reply still renders exactly once at both surfaces (no duplicate row in the inspector, no duplicate inline bubble).
- **Expected**: The relay-delivered copy of the reviewer's own reply is deduplicated by event id; only one render.

#### Publish tolerates relay failure `TC-srm-publish-relay-failure`
- **Type**: Manual
- **Covers**: `AC-srm-publish-relay-failure`, `FR-srm-event-publish`
- **Preconditions**: Patch review open; reviewer identity configured; `NOSTR_RELAYS` set to only an invalid/unreachable relay (`wss://invalid.invalid`).
- **Steps**:
  1. Submit an inline comment.
  2. Confirm the editor reopens with the inline error `Couldn't publish reply -- no relay accepted it. Your comment is saved locally.`
  3. Confirm the local comment is retained and renders.
  4. Restore `NOSTR_RELAYS` to a reachable relay and retry the publish; confirm it succeeds.
- **Expected**: When no relay accepts the event, the reviewer is informed, the local comment is retained, and retry succeeds once a relay is reachable.

#### Signer unit test -- valid NIP-01 signature `TC-srm-signer-unit`
- **Type**: Automated (Swift unit test)
- **Covers**: `FR-srm-event-sign`
- **Preconditions**: `NostrSigner` and `NostrEvent.sign` implemented.
- **Steps**:
  1. In a Swift test, construct a `NostrEvent` with fixed kind/content/tags/created_at and a fixed test secret key.
  2. Sign it via `NostrEvent.sign(secretKey:)`.
  3. Assert the resulting `id` equals the SHA-256 of the canonical serialized event, `pubkey` equals the derived public key, and `sig` is a valid Schnorr signature that verifies against the pubkey.
- **Expected**: The signer produces a valid NIP-01 event whose signature verifies. Deterministic given the fixed inputs.

### Bunker (NIP-46) Identity

These cases verify the reviewer can publish under a NIP-46 bunker connection instead of a raw `nsec`, so the secret key never lives on the host. They require a reachable test bunker (e.g. `nak bunker` against a test key, or an in-process mock bunker in the automated cases) and a test patch event.

#### Bunker connect handshake `TC-srm-bunker-connect`
- **Type**: Automated (Swift unit test) + manual confirmation
- **Covers**: `AC-srm-bunker-connect`, `FR-srm-bunker-connect`, `FR-sr-reviewer-identity`
- **Preconditions**: `SHEPHERD_BUNKER` set to a `bunker://<pubkey>?relay=<wss-url>[&secret=<token>]` URI pointing at a reachable test bunker; no `SHEPHERD_NSEC`.
- **Steps**:
  1. (Automated) Inject a mock `RelayClient` that echoes NIP-46 kind `24133` responses; drive `BunkerClient.connect()` and assert it sends a NIP-44-encrypted `connect` request whose `params[0]` is the bunker (remote-signer) pubkey (not the session pubkey), with `secret` in position 1, an empty string for perms in position 2, and client metadata in position 3; receives the response; and then `get_public_key` returns the reviewer's (user) pubkey.
  2. (Automated) Assert no reviewer secret key is materialized in the client -- only the ephemeral session keypair and the parsed bunker params.
  3. (Manual) Open a patch review with a real test bunker; confirm the identity indicator shows the shield glyph + `BUNKER` badge + green (connected) status dot and the reviewer's display name.
- **Expected**: The NIP-46 handshake completes, the reviewer's pubkey is obtained from the bunker, the indicator shows connected, and no host-side secret key is used.

#### Bunker unreachable / refused -- publish unavailable `TC-srm-bunker-connect` (failure branch)
- **Type**: Automated (Swift unit test)
- **Covers**: `AC-srm-bunker-connect` (failure branch), `FR-srm-bunker-connect`
- **Preconditions**: `SHEPHERD_BUNKER` set; mock `RelayClient` that does not respond to `connect` (or returns a refusal for a bad `secret`).
- **Steps**:
  1. Drive `BunkerClient.connect()` against the non-responsive/refusing mock.
  2. Assert the connection state flips to `.failed` with a cause, `get_public_key` yields no pubkey, and read-only review + local commenting remain available.
- **Expected**: A failed handshake degrades to unavailable-for-publish without crashing; the failure is observable as `.failed`.

#### Malformed bunker URI `TC-srm-bunker-uri-malformed`
- **Type**: Automated (Swift unit test)
- **Covers**: `AC-srm-identity-load` (malformed-URI branch), `FR-srm-identity-load`
- **Preconditions**: `SHEPHERD_BUNKER` set to a malformed string (missing `relay=`, not `bunker://`, unparseable pubkey).
- **Steps**:
  1. Load identity with each malformed variant.
  2. Assert the identity resolves to the parse-error state (not silently no-identity) and the indicator surfaces the parse error.
- **Expected**: Malformed URIs produce a distinct parse-error identity state; the app does not attempt a connection.

#### Reply signed by the bunker `TC-srm-bunker-sign`
- **Type**: Automated (Swift unit test) + manual confirmation
- **Covers**: `AC-srm-bunker-sign`, `AC-sr-bunker-signing`, `FR-sr-bunker-signing`, `FR-srm-event-sign` (bunker mode)
- **Preconditions**: Patch review open; a connected mock bunker (automated) or real test bunker (manual); no `SHEPHERD_NSEC`.
- **Steps**:
  1. Submit an inline comment anchored to a line range.
  2. (Automated) Assert `NostrSigner.sign(event:)` sends a `sign_event` request to the bunker and returns the bunker's signed event (id/pubkey/sig populated); assert no secret key was used locally.
  3. (Manual) Confirm the reply renders immediately with the `YOU` badge; from a separate client fetch the published event and confirm its `pubkey` is the reviewer's and the signature verifies -- indistinguishable from a locally-signed reply.
- **Expected**: The bunker signs the event; the app publishes it under the reviewer's pubkey; the reviewer's secret key is never present on the host.

#### Bunker sign failure degrades gracefully `TC-srm-bunker-sign-failure`
- **Type**: Automated (Swift unit test) + manual confirmation
- **Covers**: `AC-srm-bunker-sign-failure`, `FR-srm-bunker-sign-failure`
- **Preconditions**: Patch review open with a bunker identity connected; mock bunker that drops the channel / refuses / times out on `sign_event` (automated), or a real bunker taken offline mid-session (manual).
- **Steps**:
  1. Submit an inline comment.
  2. Assert the editor reopens with the bunker-named error (`Couldn't publish reply -- the bunker didn't respond. Your comment is saved locally.`), the indicator flips to red/failed with cause, and the local comment is retained.
  3. Assert no event was published.
  4. Restore the bunker (or reconnect) and retry; assert the reply publishes on retry.
- **Expected**: A bunker sign failure retains the comment locally, surfaces a bunker-named error, does not silently drop the reply, and retry succeeds once the bunker is back.

#### Bunker identity indicator states `TC-srm-bunker-identity-indicator`
- **Type**: Manual
- **Covers**: `FR-srm-identity-indicator`
- **Preconditions**: Ability to set `SHEPHERD_BUNKER` to a reachable and an unreachable bunker across launches.
- **Steps**:
  1. With a reachable bunker, open a patch review; confirm the indicator shows the shield glyph + `BUNKER` badge + green status dot + display name, with the full `bunker://` URI in the accessibility label.
  2. With an unreachable bunker, relaunch; confirm the indicator shows the red status dot + failure subtext while read-only review and local commenting still work.
  3. Open a non-patch review; confirm the identity indicator is absent.
- **Expected**: The indicator renders bunker-specific states (connected / failed) and is absent for non-patch reviews.

#### NIP-44 crypto round-trip `TC-srm-nip44-unit`
- **Type**: Automated (Swift unit test)
- **Covers**: `FR-srm-bunker-connect`
- **Preconditions**: `NIP44Crypto` implemented.
- **Steps**:
  1. Generate two secp256k1 keypairs (sender, bunker); compute the ECDH shared secret on both sides and assert they match.
  2. Encrypt a fixed plaintext with the sender's key to the bunker's pubkey (NIP-44: ChaCha20-Poly1305 + HKDF); decrypt with the bunker's key from the sender's pubkey; assert the output equals the plaintext.
  3. Assert tampering a ciphertext byte fails decryption (Poly1305 auth tag mismatch).
- **Expected**: NIP-44 encrypt/decrypt round-trips and rejects tampered ciphertext. No new package dependency is exercised (uses `P256K` for ECDH + `CryptoKit` `ChaChaPoly`/`HKDF`); no AES-CBC is used.

---

### In-App Patch Open

#### Open Patch from empty state (happy path) `TC-srm-patch-open-happy`
- **Type**: Manual
- **Covers**: `AC-srm-patch-open-happy`, `FR-srm-patch-open-entry`, `FR-srm-patch-open-input`, `FR-srm-patch-open-fetch`, `FR-srm-patch-open-load`
- **Preconditions**: App in standalone empty state; a valid NIP-34 patch event (kind 1617 or 1621) with a unified-diff content exists on the configured relays; reviewer identity configured.
- **Steps**:
  1. Confirm the empty state shows an `Open Patch…` button alongside `Open Files…` and `Paste from Clipboard`.
  2. Click `Open Patch…`; confirm the Open Patch sheet appears with the text field and `Fetch`/`Cancel` buttons.
  3. Paste the patch event's 64-char hex id and click `Fetch`; confirm the sheet shows `Fetching patch from relays…`.
  4. On success confirm the sheet closes and the window enters the multi-file layout with one tab per changed file (tab name = file path from the `diff --git` header).
  5. Confirm the inspector shows the Patch Metadata section (author, message, parent, status) and the reviewer identity indicator.
  6. Add an inline comment on a diff line and submit; confirm it publishes to the patch thread (`TC-srm-comment-publish`).
  7. Confirm no shell process or `/shepherd-review` invocation was used (the review started entirely in-app).
- **Expected**: Patch opens in-app by event id; per-file diff tabs load; patch metadata + live thread + publish all activate with no CLI/shell.

#### nevent/naddr reference opens the patch `TC-srm-patch-open-nevent`
- **Type**: Manual
- **Covers**: `AC-srm-patch-open-nevent`, `FR-srm-patch-open-input`
- **Preconditions**: As above; a `nevent1…` (or `naddr1…`) encoding of the patch event is available.
- **Steps**:
  1. Open the sheet and paste the `nevent1…` reference; submit.
  2. Confirm the fetch is directed at the relays encoded in the reference and the patch loads as in `TC-srm-patch-open-happy`.
- **Expected**: `nevent1`/`naddr1` references decode to the event id + relays and open the patch.

#### Invalid reference rejected inline `TC-srm-patch-open-invalid-id`
- **Type**: Automated (unit) + Manual
- **Covers**: `AC-srm-patch-open-invalid-id`, `FR-srm-patch-open-input`
- **Preconditions**: App in empty state.
- **Steps**:
  1. Open the sheet; type `not-a-valid-ref` and submit.
  2. Confirm an inline error `Enter a 64-character hex event id or a nevent1/naddr1 reference` appears, `Fetch` is disabled, no network call is made, and the sheet stays open.
  3. (Unit) assert `OpenPatchFeature` produces its invalid-input state for non-hex, wrong-length, and non-bech32 inputs.
- **Expected**: Only well-formed references trigger a fetch; everything else is rejected inline.

#### Patch event not found `TC-srm-patch-open-not-found`
- **Type**: Manual (with a relay fixture returning no event)
- **Covers**: `AC-srm-patch-open-not-found`, `FR-srm-patch-open-fetch`
- **Steps**:
  1. Submit a well-formed hex id that no relay has.
  2. Confirm that after the relay wait window the sheet reports `Patch event <short-id> not found on the configured relays.` and stays open; no review is started.
- **Expected**: A valid-but-absent id produces a clear not-found message, not a hang or blank review.

#### Non-patch event rejected `TC-srm-patch-open-wrong-kind`
- **Type**: Automated (unit) + Manual
- **Covers**: `AC-srm-patch-open-wrong-kind`, `FR-srm-patch-open-fetch`
- **Steps**:
  1. Submit an id for a real event of kind 1 (a text note) or kind 0.
  2. Confirm the sheet reports `Event <short-id> is not a NIP-34 patch (kind <k>).` and no review starts.
  3. (Unit) assert `PatchDiffSplitter` rejects kinds other than 1617/1621.
- **Expected**: Only NIP-34 patch kinds load; other events are rejected with the kind named.

#### Malformed diff rejected `TC-srm-patch-open-bad-diff`
- **Type**: Automated (unit)
- **Covers**: `AC-srm-patch-open-bad-diff`, `FR-srm-patch-open-fetch`
- **Steps**:
  1. (Unit) feed `PatchDiffSplitter` a kind-1617 event whose content is plain text (no `diff --git`) and one with a `diff --git` header but no `@@` hunk.
  2. Assert both are rejected with `Patch event <short-id> does not contain a valid unified diff.`
- **Expected**: Events that are not a valid unified diff are rejected before any tabs load.

#### No relays reachable `TC-srm-patch-open-no-relays`
- **Type**: Manual
- **Covers**: `AC-srm-patch-open-no-relays`, `FR-srm-patch-open-fetch`
- **Preconditions**: Relay configuration points only at unreachable hosts (or no relays configured).
- **Steps**:
  1. Submit a valid reference.
  2. Confirm the sheet reports `No Nostr relays reachable — check your relay configuration.` and no fetch is attempted.
- **Expected**: An unreachable-relay state is surfaced distinctly from not-found.

#### In-app opened patch activates the live thread `TC-srm-patch-open-activates-thread`
- **Type**: Manual
- **Covers**: `AC-srm-patch-open-activates-thread`, `FR-sr-patch-replies-live`, `FR-srm-comment-publish-on-submit`
- **Preconditions**: Patch opened in-app per `TC-srm-patch-open-happy`; a second participant posts a reply to the same patch thread after the window is open.
- **Steps**:
  1. Confirm the initial reply snapshot (if any) renders in the inspector Patch Thread section.
  2. Have the second participant publish a new kind:1 root reply to the patch.
  3. Confirm the new reply appears in the inspector and inline at its anchor without relaunching.
  4. Submit a response via the Reply affordance; confirm it publishes with threaded `e`/`p` tags.
- **Expected**: The in-app-opened patch is indistinguishable from a CLI-launched patch review for live replies and publishing.

#### PatchDiffSplitter unit -- per-file split `TC-srm-patch-open-splitter-unit`
- **Type**: Automated (unit)
- **Covers**: `FR-srm-patch-open-load`
- **Steps**:
  1. Feed the splitter a unified diff with 3 `diff --git` blocks (files a, b, c).
  2. Assert it returns 3 `(filePath, diffBlock)` pairs with the correct paths.
  3. Assert the extracted `PatchMetadata` carries the `a` tag repo coordinate, status, parent commit, and author pubkey from the event.
- **Expected**: Diff splitting and metadata extraction are pure and deterministic.

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
