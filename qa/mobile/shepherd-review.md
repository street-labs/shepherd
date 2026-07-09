---
product-hash: 092d40e94addeca0baa25855d2e4519347c147d7de862d7947168eb1c6a09fcd
product-slugs: [AC-sr-all-filtered, AC-sr-auto-open, AC-sr-batch-open, AC-sr-completion-summary, AC-sr-context-in-crpg, AC-sr-excludes-deleted, AC-sr-filters-binary, AC-sr-filters-generated, AC-sr-filters-lockfiles, AC-sr-happy-path, AC-sr-includes-config, AC-sr-install-global, AC-sr-interactive-prompt, AC-sr-invokes-shepherd, AC-sr-list-command, AC-sr-no-changes, AC-sr-not-git-repo, AC-sr-quit-early, AC-sr-skip-file, AC-sr-sorted-file-list, AC-sr-unified-prompt, FR-sc-session-id, FR-sc-session-scoped-output, FR-sr-changeset-detection, FR-sr-changeset-overview, FR-sr-command-file, FR-sr-completion-summary, FR-sr-context-handoff, FR-sr-feedback-collection, FR-sr-file-filtering, FR-sr-file-list-display, FR-sr-git-required, FR-sr-install, FR-sr-iteration-loop, FR-sr-multi-file-launch, FR-sr-per-file-context, FR-sr-priority-ordering, FR-sr-scope-argument, NFR-sr-agent-native, NFR-sr-cross-platform, NFR-sr-no-dependencies, NFR-sr-startup-speed]
---

# Shepherd Review — Mobile Test Plan

> Based on requirements in `../../product/shepherd-review.md`
> See also `../../product/mobile/shepherd-review.md` for mobile-specific requirements.
> See also `../../design/mobile/shepherd-review.md` for mobile design spec.

## What We're Testing

The mobile launch and handoff flow for multi-file code review. Testing focuses on deep link payload construction and delivery from Buzz Mobile to Shepherd Mobile, error handling for large changesets, loading states, and the completion callback flow. The core CRPG review experience is tested separately in `code-review-prompt.md` — this test plan covers only the mobile-specific entry and exit points for `/shepherd-review`.

### Test Scope

- **In scope**: Deep link launch from Buzz Mobile, payload encoding/decoding, large payload handling, loading states, context visibility in mobile UI, completion callback to Buzz
- **Out of scope**: Core CRPG UI (file navigation, commenting, prompt generation) — covered in `code-review-prompt.md`

### Test Environment

- **Platform**: iOS 17+ and Android 13+
- **Devices**: Physical device testing preferred (deep links behave differently on simulators/emulators)
- **Tools**: Manual testing with Buzz Mobile and Shepherd Mobile installed
- **Fixtures**: Sample changesets ranging from 1 file to 50+ files, with varying diff sizes

---

## Coverage Matrix

### Mobile-Specific Acceptance Criteria

| Requirement | Test Cases | Status |
|---|---|---|
| `AC-srm-deeplink-files` | `TC-srm-deeplink-launch-happy`, `TC-srm-deeplink-file-order` | Not started |
| `AC-srm-context-display` | `TC-srm-context-overall-visible`, `TC-srm-context-per-file-visible` | Not started |
| `AC-srm-chunking` | `TC-srm-large-payload-chunking` | Not started |
| `AC-srm-large-blocked` | `TC-srm-very-large-blocked` | Not started |

### Shared Acceptance Criteria (Mobile Integration Points Only)

Testing shared requirements only where they intersect with mobile-specific launch/handoff. Full testing of shared CRPG behavior is in `code-review-prompt.md`.

| Requirement | Test Cases | Status |
|---|---|---|
| `AC-sr-happy-path` | `TC-srm-happy-path-end-to-end` | Not started |
| `AC-sr-no-changes` | `TC-srm-no-changes-in-buzz` | Not started |
| `AC-sr-all-filtered` | `TC-srm-all-filtered-in-buzz` | Not started |

---

## Test Cases

### Happy Path

#### Multi-file launch from Buzz Mobile `TC-srm-deeplink-launch-happy`
- **Type**: Manual / E2E
- **Covers**: `AC-srm-deeplink-files`, `AC-sr-happy-path`, `FR-srm-deeplink-launch`
- **Preconditions**: Buzz Mobile and Shepherd Mobile installed on device. User on a feature branch with 7 reviewable files and 3 filtered files (lockfiles, binary).
- **Steps**:
  1. Open Buzz Mobile agent conversation
  2. Type `/shepherd-review` and send
  3. Observe brief summary in Buzz conversation: "Opening 7 files for review (3 excluded)"
  4. Observe transition to Shepherd Mobile
  5. Observe loading state briefly ("Loading 7 files...")
  6. First file appears and is interactive within 3 seconds
  7. Verify all 7 files loaded as tabs
  8. Verify file tabs are visible and tappable
  9. Tap each tab to confirm file content is visible
- **Expected Result**: Shepherd Mobile opens with 7 tabs in priority order (core source first, tests last). First file is visible and interactive within 3 seconds. All files load successfully. Overall context is visible in collapsed drawer at bottom. No errors.

#### File priority order preserved `TC-srm-deeplink-file-order`
- **Type**: Manual
- **Covers**: `AC-srm-deeplink-files`, `FR-sr-priority-ordering`
- **Preconditions**: Changeset includes source files (`src/app.ts`, `src/utils.ts`), config (`vite.config.ts`), docs (`README.md`), and tests (`tests/app.test.ts`).
- **Steps**:
  1. Run `/shepherd-review` in Buzz Mobile
  2. When Shepherd Mobile opens, observe tab order from left to right
- **Expected Result**: Tabs appear in priority order: source files first (app.ts, utils.ts), then config (vite.config.ts), then docs (README.md), then tests (app.test.ts) last.

#### Full review workflow from Buzz to Shepherd and back `TC-srm-happy-path-end-to-end`
- **Type**: Manual / E2E
- **Covers**: `AC-sr-happy-path`, `AC-srm-deeplink-files`, `FR-srm-deeplink-launch`, `FR-crpm-deeplink-handoff`
- **Preconditions**: Buzz Mobile and Shepherd Mobile installed. User on a feature branch with reviewable files.
- **Steps**:
  1. Open Buzz Mobile, type `/shepherd-review`, send
  2. Observe Shepherd Mobile opens with all files loaded
  3. Tap line numbers to add comments on 3 files
  4. Tap "Done" button
  5. Observe "Sent to Buzz" success toast
  6. Switch back to Buzz Mobile
  7. Verify unified prompt appears in Buzz conversation with all 3 files' comments
- **Expected Result**: Prompt is successfully delivered to Buzz via deep link callback. All comments are included in the prompt organized by file. No errors.

### Context Display

#### Overall context visible in drawer `TC-srm-context-overall-visible`
- **Type**: Manual
- **Covers**: `AC-srm-context-display`, `FR-sr-changeset-overview`, `FR-sr-context-handoff`
- **Preconditions**: `/shepherd-review` launched from Buzz with context data in deep link payload.
- **Steps**:
  1. When Shepherd Mobile opens, tap "Context" button at bottom (or swipe up from bottom)
  2. Observe Review Context Drawer expands
  3. Locate "Overall Context" section
  4. Tap to expand accordion
  5. Verify neutral context is visible (factual description of what changed)
  6. Verify review feedback is visible (agent's opinions and suggestions)
  7. Verify visual distinction between neutral and review sections (different icons/backgrounds)
- **Expected Result**: Overall neutral context and overall review feedback are both visible in the drawer, clearly separated with distinct visual styling. User can tell at a glance which is factual and which is the agent's opinion.

#### Per-file context visible and switches with file navigation `TC-srm-context-per-file-visible`
- **Type**: Manual
- **Covers**: `AC-srm-context-display`, `FR-sr-per-file-context`, `FR-sr-context-handoff`
- **Preconditions**: `/shepherd-review` launched with multiple files, each having per-file context.
- **Steps**:
  1. Open Review Context Drawer
  2. Observe "File Context" section header shows current file name
  3. Expand "File Context" accordion
  4. Verify per-file neutral context is visible for current file
  5. Verify per-file review feedback is visible for current file
  6. Switch to a different file tab
  7. Observe "File Context" section header updates to new file name
  8. Verify per-file content updates to match new file
- **Expected Result**: Per-file context updates automatically when switching files. Each file's context is distinct and correctly associated. Neutral and review sections are visually separated.

### Large Payload Handling

#### Large payload chunking or fallback `TC-srm-large-payload-chunking`
- **Type**: Manual / Integration
- **Covers**: `AC-srm-chunking`, `FR-srm-deeplink-chunking`
- **Preconditions**: Changeset with 15 files and large diffs that exceed iOS deep link size limit (~100KB).
- **Steps**:
  1. Run `/shepherd-review` in Buzz Mobile
  2. Observe Buzz agent detects payload size exceeds limit
  3. Observe fallback mechanism activates (chunking or file-based temporary storage)
  4. Observe Shepherd Mobile opens
  5. Verify all 15 files load correctly
  6. Tap through each file to confirm content is complete
  7. Verify all context data is present (overall and per-file)
- **Expected Result**: Fallback mechanism works transparently. All files and context data arrive in Shepherd Mobile intact. No data truncation or silent failures.

#### Very large changeset blocked with message `TC-srm-very-large-blocked`
- **Type**: Manual
- **Covers**: `AC-srm-large-blocked`, `FR-srm-large-fallback`
- **Preconditions**: Changeset with 50+ files (or changesets totaling >500KB even with chunking).
- **Steps**:
  1. Run `/shepherd-review` in Buzz Mobile
  2. Observe Buzz agent detects changeset is too large for mobile
  3. Observe error message in Buzz conversation: "This changeset is too large for mobile review (payload exceeds XKB). Try one of these options: - Review on desktop instead - Filter the changeset: /shepherd-review --staged - Review files individually: /shepherd <file>"
  4. Verify Shepherd Mobile does NOT launch
- **Expected Result**: Clear, actionable error message displayed in Buzz. Shepherd Mobile is not launched with incomplete data. User remains in Buzz and can choose alternative approach.

### Error States

#### No changes detected `TC-srm-no-changes-in-buzz`
- **Type**: Manual
- **Covers**: `AC-sr-no-changes`
- **Preconditions**: User on a branch with no changes relative to main.
- **Steps**:
  1. Run `/shepherd-review` in Buzz Mobile
  2. Observe message in Buzz conversation: "No changes found relative to main."
- **Expected Result**: Clear message displayed in Buzz. Shepherd Mobile does NOT launch. No errors.

#### All files filtered `TC-srm-all-filtered-in-buzz`
- **Type**: Manual
- **Covers**: `AC-sr-all-filtered`
- **Preconditions**: Changeset contains only lockfiles and binary files (all filtered by `FR-sr-file-filtering`).
- **Steps**:
  1. Run `/shepherd-review` in Buzz Mobile
  2. Observe message in Buzz conversation: "No reviewable files found. All 4 changed files were filtered out (lockfiles, generated, binary)."
- **Expected Result**: Clear message displayed in Buzz. Shepherd Mobile does NOT launch. No errors.

### Loading Performance

#### Launch time meets performance threshold `TC-srm-launch-time-10-files`
- **Type**: Manual / Performance
- **Covers**: `NFR-srm-launch-time`
- **Preconditions**: Changeset with 10 files. Physical device (not simulator).
- **Steps**:
  1. Run `/shepherd-review` in Buzz Mobile
  2. Start timer when Shepherd Mobile app icon appears
  3. Stop timer when first file is visible and code is tappable (interactive)
  4. Record time
- **Expected Result**: First file is visible and interactive within 3 seconds. Time from app launch to first interactive state is ≤3s.

### Completion Callback

#### Done sends prompt back to Buzz `TC-srm-done-callback-success`
- **Type**: Manual
- **Covers**: `AC-sr-completion-summary`, `FR-crpm-deeplink-handoff`
- **Preconditions**: Review session open in Shepherd Mobile with at least one comment.
- **Steps**:
  1. Tap "Done" button in Shepherd Mobile
  2. Observe "Done" button shows loading spinner
  3. Observe "Sent to Buzz" success toast appears
  4. Wait 1 second
  5. Observe Shepherd Mobile closes or shows "Done! Switch back to Buzz."
  6. Switch to Buzz Mobile
  7. Verify unified prompt appears in conversation
- **Expected Result**: Deep link callback succeeds. Success toast appears. Prompt is delivered to Buzz. Shepherd Mobile auto-closes (if platform allows) or shows completion message.

#### Done callback fails with clipboard fallback `TC-srm-done-callback-fail`
- **Type**: Manual
- **Covers**: `AC-crp-done-fallback-clipboard`, `FR-crpm-deeplink-handoff`
- **Preconditions**: Review session open in Shepherd Mobile with at least one comment. Buzz Mobile force-closed (to simulate callback failure).
- **Steps**:
  1. Force-close Buzz Mobile app
  2. Return to Shepherd Mobile
  3. Tap "Done" button
  4. Observe "Done" button shows loading spinner for 3 seconds
  5. Observe error banner appears: "Could not send to Buzz. Prompt copied to clipboard. [Retry]"
  6. Open any text field (e.g., Notes app) and paste
  7. Verify prompt content is in clipboard
- **Expected Result**: Callback fails after 3-second timeout. Error banner appears with clear message. Prompt is copied to clipboard as fallback. Retry button is present.

---

## Edge Cases & Error Scenarios

### Shepherd Mobile Not Installed
- **Trigger**: User runs `/shepherd-review` in Buzz Mobile, but Shepherd Mobile is not installed on device.
- **Expected behavior**: Buzz Mobile displays message: "Shepherd Mobile is not installed. Install it to review code on mobile." with link to App Store / Play Store.
- **Test case**: `TC-srm-shepherd-not-installed` (manual)

### Deep Link Malformed Payload
- **Trigger**: Deep link payload is corrupted or malformed (simulated by manual URL construction).
- **Expected behavior**: Shepherd Mobile shows error state: "Could not load files. Try again or review on desktop." User can tap "Close" to exit.
- **Test case**: `TC-srm-malformed-payload` (manual, requires dev tools to construct malformed deep link)

### Offline at Launch
- **Trigger**: User runs `/shepherd-review` while device is offline.
- **Expected behavior**: Deep link construction and launch still work (all data is in the payload). Shepherd Mobile opens normally. Only the completion callback (Done -> Buzz) will fail, handled by existing fallback.
- **Test case**: `TC-srm-offline-launch` (manual)

### Rapid File Switching During Load
- **Trigger**: User taps multiple file tabs rapidly while files are still loading.
- **Expected behavior**: File switches are smooth. Only the final settled file loads fully. No crashes. Loading state persists for files not yet loaded.
- **Test case**: `TC-srm-rapid-tab-switch-loading` (manual)

---

## Test Execution Notes

- **Deep link testing**: Must be performed on physical devices. Simulators/emulators often have unreliable deep link behavior.
- **Payload size limits**: iOS deep link limit is ~100KB. Test with realistic changesets that approach and exceed this limit.
- **Platform differences**: Test chunking/fallback mechanism on both iOS and Android, as URL size limits differ.
- **Callback reliability**: Test callback under various conditions (app backgrounded, app force-closed, network offline) to ensure fallback works consistently.

---

## Regression Considerations

- Changes to deep link URL scheme or parameter encoding could break handoff between Buzz and Shepherd. Always test full launch -> review -> callback flow after changes.
- Changes to context data structure in `/shepherd-review` command must be reflected in Shepherd Mobile's parsing logic. Test context visibility after any schema changes.
- Performance regressions in file decoding or context parsing will be most visible on older devices. Test on devices 2-3 years old, not just latest models.
