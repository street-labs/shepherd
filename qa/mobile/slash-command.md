---
product-hash: 4797f99ba4dea08e27dc3fe60a3532fb0f6b30aa6e4ebf7809c10ffd0ff290a4
product-slugs: [AC-sc-absolute-path, AC-sc-binary-file-rejected, AC-sc-cold-launch-8s, AC-sc-concurrent-sessions, AC-sc-cross-platform-open, AC-sc-directory-rejected, AC-sc-file-not-found, AC-sc-install-global, AC-sc-install-symlink, AC-sc-large-file-warning, AC-sc-launch-happy-path, AC-sc-no-args-usage, AC-sc-permission-denied, AC-sc-prompt-cleanup-stale, AC-sc-prompt-output-api-localhost-only, AC-sc-prompt-output-api-success, AC-sc-prompt-received, AC-sc-prompt-watcher-timeout, AC-sc-server-manual-stop, AC-sc-server-reuse, AC-sc-session-clear-on-new-file, AC-sc-session-output-isolation, AC-sc-single-tool-call, AC-sc-standalone-window, AC-sc-warm-launch-2s, AC-scm-callback-deliver, AC-scm-deeplink-open, AC-scm-offline-queue, AC-scm-session-match, AC-scm-timeout-fallback, FR-crp-done-action, FR-crp-file-load, FR-crp-syntax-highlight, FR-sc-app-serve, FR-sc-auto-load-file, FR-sc-browser-open, FR-sc-concurrent-windows, FR-sc-dynamic-port, FR-sc-file-api, FR-sc-file-resolution, FR-sc-file-validation, FR-sc-install, FR-sc-invoke-command, FR-sc-launcher-script, FR-sc-output-feedback, FR-sc-prompt-cleanup, FR-sc-prompt-output-api, FR-sc-prompt-receive, FR-sc-server-shutdown, FR-sc-session-cleanup, FR-sc-session-id, FR-sc-session-scoped-output, FR-scm-callback-timeout, FR-scm-deeplink-protocol, FR-scm-mobile-callback, FR-scm-offline-queue, FR-scm-session-consistency, NFR-crp-client-only, NFR-crp-large-file-perf, NFR-sc-cross-platform, NFR-sc-launch-speed, NFR-sc-localhost-only, NFR-sc-minimal-footprint, NFR-sc-no-global-deps, NFR-sc-no-telemetry, NFR-sc-watcher-low-overhead]
---
# Slash Command Protocol — Mobile Test Plan

> Based on requirements in `../../product/slash-command.md`
> See also `../../product/mobile/slash-command.md` for mobile-specific requirements.
> See also `../../design/mobile/slash-command.md` for mobile design spec.

## What We're Testing

This test plan covers the mobile-specific slash command protocol for Shepherd Mobile. It verifies the deep link launch mechanism, callback protocol, offline queue, error handling, and multi-session coordination between Buzz Mobile and Shepherd Mobile. The protocol layer is distinct from the CRPG UI (tested separately).

## Test Strategy Overview

Tests are organized into four layers:

| Layer | Scope |
|---|---|
| **Unit** | URI parsing, session ID extraction, payload encoding/decoding, base64 validation |
| **Integration** | Deep link roundtrip (Buzz -> Shepherd -> Buzz), callback delivery, offline queue persistence |
| **E2E** | Full user flow from Buzz conversation through annotation to prompt return |
| **Manual** | Cross-app transitions, OS-level deep link registration, multi-session handling |

### Test Environment

- **OS**: iOS 17+ / Android 13+
- **Apps**: Buzz Mobile (client), Shepherd Mobile (test build with deep link handlers enabled)
- **Fixtures**: Sample session IDs, base64-encoded file payloads (small/large/edge cases), malformed deep links
- **Network conditions**: WiFi connected, cellular, airplane mode (offline)
- **Background tools**: Network Link Conditioner (iOS), adb shell (Android) for simulating network failures

---

## Coverage Matrix

### Mobile-Specific Acceptance Criteria

| Requirement | Test Cases | Status |
|---|---|---|
| `AC-scm-deeplink-open` | `TC-scm-deeplink-open-happy`, `TC-scm-deeplink-malformed`, `TC-scm-deeplink-missing-session` | Not started |
| `AC-scm-callback-deliver` | `TC-scm-callback-deliver-happy`, `TC-scm-callback-session-matches` | Not started |
| `AC-scm-session-match` | `TC-scm-session-match-multi`, `TC-scm-session-match-concurrent` | Not started |
| `AC-scm-offline-queue` | `TC-scm-offline-queue-persist`, `TC-scm-offline-queue-auto-retry`, `TC-scm-offline-queue-manual-retry` | Not started |
| `AC-scm-timeout-fallback` | `TC-scm-timeout-fallback-clipboard`, `TC-scm-timeout-fallback-open-buzz` | Not started |

### Functional Requirement Coverage (Mobile-Specific)

| Requirement | Test Cases | Status |
|---|---|---|
| `FR-scm-deeplink-protocol` | `TC-scm-deeplink-open-happy`, `TC-scm-deeplink-payload-decode`, `TC-scm-deeplink-context-parse` | Not started |
| `FR-scm-mobile-callback` | `TC-scm-callback-deliver-happy`, `TC-scm-callback-format-valid`, `TC-scm-callback-base64-encode` | Not started |
| `FR-scm-session-consistency` | `TC-scm-session-match-multi`, `TC-scm-session-id-derived-correctly` | Not started |
| `FR-scm-offline-queue` | `TC-scm-offline-queue-persist`, `TC-scm-offline-queue-auto-retry`, `TC-scm-offline-queue-view` | Not started |
| `FR-scm-callback-timeout` | `TC-scm-timeout-fallback-clipboard`, `TC-scm-timeout-5s-threshold` | Not started |

### Session Management

| Requirement | Test Cases | Status |
|---|---|---|
| `FR-sc-session-id` | `TC-scm-session-id-derived-correctly`, `TC-scm-session-id-slugified` | Not started |
| `AC-sc-concurrent-sessions` | `TC-scm-session-match-concurrent`, `TC-scm-session-replace-on-new-launch` | Not started |

---

## Test Cases

### Deep Link Protocol

These tests verify the deep link URI construction, parsing, and payload handling.

#### Launch via deep link `TC-scm-deeplink-open-happy`
- **Type**: Integration
- **Covers**: `AC-scm-deeplink-open`, `FR-scm-deeplink-protocol`
- **Preconditions**: Buzz Mobile installed, Shepherd Mobile installed and registered for `shepherd://review`
- **Steps**:
  1. Invoke `/shepherd file.swift` in Buzz Mobile conversation
  2. Buzz constructs deep link: `shepherd://review?session=<session-id>&files=<base64>&context=<base64>`
  3. Buzz opens the deep link
  4. Observe OS app-switch animation (Buzz -> Shepherd)
  5. Verify Shepherd Mobile opens
  6. Verify file content loads in code viewer
  7. Verify session ID displayed in header
- **Expected Result**: Shepherd opens with correct file and session ID displayed

#### Malformed deep link rejected `TC-scm-deeplink-malformed`
- **Type**: Unit
- **Covers**: `AC-scm-deeplink-open`
- **Preconditions**: Shepherd Mobile installed
- **Steps**:
  1. Manually trigger deep link with malformed URI: `shepherd://review?session=test&files=NOTBASE64!!!`
  2. Observe Shepherd behavior
- **Expected Result**: Shepherd shows error dialog "Invalid Link" with message "The link format is invalid. Please try again from Buzz."

#### Missing session ID rejected `TC-scm-deeplink-missing-session`
- **Type**: Unit
- **Covers**: `AC-scm-deeplink-open`, `FR-scm-session-consistency`
- **Preconditions**: Shepherd Mobile installed
- **Steps**:
  1. Trigger deep link without session ID: `shepherd://review?files=<base64>`
  2. Observe Shepherd behavior
- **Expected Result**: Shepherd shows error dialog "Session Missing" with message "This link is missing required session information. Please invoke the command from Buzz again."

#### Payload decode successful `TC-scm-deeplink-payload-decode`
- **Type**: Unit
- **Covers**: `FR-scm-deeplink-protocol`
- **Preconditions**: None (unit test of decoder)
- **Steps**:
  1. Create base64-encoded file payload: `{"filename": "test.swift", "content": "let x = 42"}`
  2. Pass to URI parser
  3. Verify decoded content matches original
- **Expected Result**: Payload decoded correctly, filename and content extracted

#### Context data parse `TC-scm-deeplink-context-parse`
- **Type**: Unit
- **Covers**: `FR-scm-deeplink-protocol`
- **Preconditions**: None (unit test)
- **Steps**:
  1. Create deep link with context: `shepherd://review?session=test&files=<base64>&context=<base64-context>`
  2. Parse URI
  3. Verify context data extracted (changeset overview + per-file context)
- **Expected Result**: Context data decoded and available to CRPG

### Callback Protocol

These tests verify the prompt return path from Shepherd back to Buzz.

#### Callback delivers prompt successfully `TC-scm-callback-deliver-happy`
- **Type**: Integration
- **Covers**: `AC-scm-callback-deliver`, `FR-scm-mobile-callback`
- **Preconditions**: Shepherd session active from deep link launch, Buzz Mobile running in background
- **Steps**:
  1. User adds comments in Shepherd
  2. User taps "Done" button
  3. Observe "Sending to Buzz..." indicator
  4. Shepherd constructs callback: `buzz://shepherd-result?session=<session-id>&prompt=<base64-prompt>`
  5. Shepherd opens callback deep link
  6. Observe OS app-switch animation (Shepherd -> Buzz)
  7. Verify Buzz receives callback
  8. Verify prompt decoded correctly
  9. Verify Buzz conversation resumes with prompt as input
- **Expected Result**: Prompt delivered to Buzz, conversation resumes, session ID matches

#### Callback session ID matches launch session `TC-scm-callback-session-matches`
- **Type**: Integration
- **Covers**: `AC-scm-callback-deliver`, `FR-scm-session-consistency`
- **Preconditions**: Shepherd launched with session ID "project-main"
- **Steps**:
  1. User completes annotation, taps Done
  2. Capture callback URI
  3. Extract session parameter from callback
  4. Compare to original session ID from launch deep link
- **Expected Result**: Callback session ID matches launch session ID exactly

#### Callback format valid `TC-scm-callback-format-valid`
- **Type**: Unit
- **Covers**: `FR-scm-mobile-callback`
- **Preconditions**: None (unit test of callback URI builder)
- **Steps**:
  1. Generate prompt text with special characters (newlines, quotes, etc.)
  2. Encode as base64
  3. Construct callback URI
  4. Verify URI format: `buzz://shepherd-result?session=<id>&prompt=<base64>`
  5. Verify base64 is URL-safe
- **Expected Result**: Callback URI well-formed, base64 valid

#### Prompt base64 encoded correctly `TC-scm-callback-base64-encode`
- **Type**: Unit
- **Covers**: `FR-scm-mobile-callback`
- **Preconditions**: None (unit test)
- **Steps**:
  1. Create prompt with markdown formatting, code blocks, special chars
  2. Encode as base64
  3. Decode and compare to original
- **Expected Result**: Round-trip encode/decode preserves prompt exactly

### Session Management

These tests verify session ID consistency and multi-session handling.

#### Session ID derived correctly `TC-scm-session-id-derived-correctly`
- **Type**: Unit
- **Covers**: `FR-sc-session-id`, `FR-scm-session-consistency`
- **Preconditions**: None (unit test)
- **Steps**:
  1. Provide working directory path: `/Users/dev/my-project`
  2. Call session ID derivation function
  3. Verify output is `my-project`
  4. Repeat for path with special chars: `/Users/dev/project_2024-Q1`
  5. Verify output is `project-2024-q1` (lowercased, underscores replaced)
- **Expected Result**: Session IDs derived correctly, slugified

#### Session ID slugified `TC-scm-session-id-slugified`
- **Type**: Unit
- **Covers**: `FR-sc-session-id`
- **Preconditions**: None (unit test)
- **Steps**:
  1. Test session ID derivation with various inputs:
     - `My Project` -> `my-project`
     - `project_name` -> `project-name`
     - `Project123` -> `project123`
     - `project!@#$` -> `project----`
  2. Verify slugification rules applied
- **Expected Result**: All non-alphanumeric chars (except hyphens) replaced, lowercased

#### Multi-session callback routing `TC-scm-session-match-multi`
- **Type**: E2E
- **Covers**: `AC-scm-session-match`, `FR-scm-session-consistency`
- **Preconditions**: Two Buzz conversations active (A: `project-main`, B: `project-feature`)
- **Steps**:
  1. Invoke `/shepherd file1.swift` from Buzz conversation A
  2. Shepherd opens with session `project-main`
  3. Switch back to Buzz, navigate to conversation B
  4. Invoke `/shepherd file2.swift` from conversation B
  5. Shepherd replaces session with `project-feature`
  6. User completes annotation for conversation B, taps Done
  7. Verify callback goes to conversation B (session ID `project-feature`)
  8. Verify conversation A does NOT receive the prompt
- **Expected Result**: Prompt delivered to correct Buzz conversation based on session ID

#### Concurrent session handling `TC-scm-session-match-concurrent`
- **Type**: Manual
- **Covers**: `AC-sc-concurrent-sessions`, `FR-sc-concurrent-windows`
- **Preconditions**: Two Buzz conversations on different devices/instances (not realistic on mobile, but test the protocol)
- **Steps**:
  1. From device A: Invoke `/shepherd file1.swift` in conversation A (session `project-main`)
  2. From device B: Invoke `/shepherd file2.swift` in conversation B (session `project-feature`)
  3. Complete annotation on device A, tap Done
  4. Verify callback goes to device A only
  5. Complete annotation on device B, tap Done
  6. Verify callback goes to device B only
- **Expected Result**: Each session's prompt returns to its originating conversation, no cross-contamination

#### Session replaced on new launch `TC-scm-session-replace-on-new-launch`
- **Type**: Integration
- **Covers**: `AC-sc-concurrent-sessions`
- **Preconditions**: Shepherd open with session A active
- **Steps**:
  1. Shepherd showing file from session `project-main`
  2. User switches to Buzz, invokes `/shepherd file2.swift` with session `project-feature`
  3. Observe Shepherd receives new deep link
  4. Verify session indicator updates to `project-feature`
  5. Verify previous file (session A) cleared
  6. Verify new file (session B) loaded
- **Expected Result**: Session replaced, no confirmation prompt, previous session lost

### Offline Queue

These tests verify prompt queueing when network is unavailable.

#### Offline queue persists across app restart `TC-scm-offline-queue-persist`
- **Type**: Integration
- **Covers**: `AC-scm-offline-queue`, `FR-scm-offline-queue`
- **Preconditions**: Shepherd session active, network disconnected (airplane mode)
- **Steps**:
  1. User completes annotation, taps Done
  2. Observe offline detection: toast "Offline — Prompt queued for delivery"
  3. Force quit Shepherd Mobile
  4. Relaunch Shepherd Mobile
  5. Navigate to Pending Prompts screen
  6. Verify queued prompt appears with session ID and timestamp
- **Expected Result**: Prompt persisted to device storage, survives app restart

#### Offline queue auto-retry on connectivity restore `TC-scm-offline-queue-auto-retry`
- **Type**: Integration
- **Covers**: `AC-scm-offline-queue`, `FR-scm-offline-queue`
- **Preconditions**: Prompt queued from previous offline attempt
- **Steps**:
  1. Open Pending Prompts screen, verify prompt queued
  2. Re-enable network (turn off airplane mode)
  3. Wait for automatic retry (should be background process)
  4. Observe success notification: "Prompt delivered to Buzz"
  5. Verify prompt removed from Pending Prompts list
  6. Switch to Buzz, verify prompt received in correct conversation
- **Expected Result**: Queued prompt sent automatically on reconnect, removed from queue

#### Offline queue manual retry `TC-scm-offline-queue-manual-retry`
- **Type**: E2E
- **Covers**: `AC-scm-offline-queue`, `FR-scm-offline-queue`
- **Preconditions**: Prompt queued, network available but auto-retry hasn't triggered yet
- **Steps**:
  1. Open Pending Prompts screen
  2. Tap "Retry" button on queued prompt
  3. Observe loading indicator
  4. Verify success notification
  5. Verify prompt removed from queue
  6. Switch to Buzz, verify prompt received
- **Expected Result**: Manual retry succeeds, prompt delivered

#### Offline queue view `TC-scm-offline-queue-view`
- **Type**: Integration
- **Covers**: `FR-scm-offline-queue`
- **Preconditions**: Multiple prompts queued from different sessions
- **Steps**:
  1. Navigate to Pending Prompts screen (via settings or menu)
  2. Verify list shows all queued prompts
  3. Verify each item shows: session ID, timestamp, retry/copy/delete buttons
  4. Verify newest prompt first (descending timestamp order)
  5. Tap "Clear All", confirm dialog, verify all prompts cleared
- **Expected Result**: Pending Prompts screen shows all queued items with correct metadata and actions

### Error Handling

These tests verify timeout, fallback, and error states.

#### Timeout fallback to clipboard `TC-scm-timeout-fallback-clipboard`
- **Type**: Integration
- **Covers**: `AC-scm-timeout-fallback`, `FR-scm-callback-timeout`
- **Preconditions**: Shepherd session active, Buzz Mobile NOT running (or not responding)
- **Steps**:
  1. User completes annotation, taps Done
  2. Observe "Sending to Buzz..." indicator
  3. Wait 5 seconds (timeout threshold)
  4. Observe timeout fallback dialog appears:
     - Title: "Prompt Copied to Clipboard"
     - Body: "Buzz didn't respond..."
     - Buttons: "Open Buzz" / "Dismiss"
  5. Verify prompt copied to system clipboard
  6. Tap "Dismiss", verify dialog closes
- **Expected Result**: After 5s timeout, fallback dialog shown, prompt on clipboard

#### Timeout fallback open Buzz button `TC-scm-timeout-fallback-open-buzz`
- **Type**: Manual
- **Covers**: `AC-scm-timeout-fallback`
- **Preconditions**: Timeout fallback dialog showing
- **Steps**:
  1. Tap "Open Buzz" button
  2. Observe OS attempts to open Buzz via base deep link `buzz://`
  3. If Buzz installed: verify app opens (may not receive prompt automatically, user must paste)
  4. If Buzz not installed: verify OS shows "Cannot open" error
- **Expected Result**: "Open Buzz" button attempts deep link, best-effort navigation

#### Timeout threshold 5 seconds `TC-scm-timeout-5s-threshold`
- **Type**: Integration
- **Covers**: `FR-scm-callback-timeout`
- **Preconditions**: Buzz Mobile not responding to callback
- **Steps**:
  1. User taps Done
  2. Start timer
  3. Observe callback attempt
  4. Measure time until fallback dialog appears
  5. Verify time is approximately 5 seconds (±500ms tolerance)
- **Expected Result**: Timeout triggers at 5s, not sooner or significantly later

#### Buzz not installed `TC-scm-buzz-not-installed`
- **Type**: Manual
- **Covers**: `FR-scm-mobile-callback`
- **Preconditions**: Buzz Mobile NOT installed on device
- **Steps**:
  1. User completes annotation, taps Done
  2. Observe callback attempt
  3. Observe OS fails to open `buzz://` deep link
  4. Verify fallback dialog appears (timeout or immediate failure detection)
  5. Verify prompt copied to clipboard
- **Expected Result**: Graceful fallback, prompt on clipboard, user instructed to paste manually

### Edge Cases

#### Large payload (approaching URI limit) `TC-scm-deeplink-large-payload`
- **Type**: Integration
- **Covers**: `FR-scm-deeplink-protocol`
- **Preconditions**: Buzz attempts to launch Shepherd with large file (>2 KB base64-encoded)
- **Steps**:
  1. Invoke `/shepherd large-file.swift` (2000 lines, >10 KB unencoded)
  2. Observe Buzz behavior
  3. Expected V1 behavior: Buzz shows error "File too large for deep link"
  4. Shepherd should NOT launch
- **Expected Result**: V1 limitation acknowledged, error shown, no crash

#### Empty file payload `TC-scm-deeplink-empty-file`
- **Type**: Unit
- **Covers**: `FR-scm-deeplink-protocol`
- **Preconditions**: None (unit test)
- **Steps**:
  1. Construct deep link with empty file content: `shepherd://review?session=test&files=<base64-empty>`
  2. Parse and decode
  3. Verify Shepherd handles gracefully (empty state or error)
- **Expected Result**: No crash, either empty state shown or validation error

#### Prompt with special characters `TC-scm-callback-special-chars`
- **Type**: Unit
- **Covers**: `FR-scm-mobile-callback`
- **Preconditions**: None (unit test)
- **Steps**:
  1. Generate prompt with: newlines, quotes, backticks, emojis, unicode
  2. Encode as base64
  3. Construct callback URI
  4. Send to Buzz mock handler
  5. Decode and compare to original
- **Expected Result**: Special characters preserved exactly through round-trip

#### Multiple queued prompts for same session `TC-scm-offline-queue-same-session`
- **Type**: Integration
- **Covers**: `FR-scm-offline-queue`
- **Preconditions**: Offline mode, same session invoked multiple times
- **Steps**:
  1. Complete annotation #1, tap Done (queued)
  2. Launch same session again, complete annotation #2, tap Done (queued)
  3. View Pending Prompts screen
  4. Verify both prompts queued (distinct by timestamp)
  5. Re-enable network
  6. Verify both prompts sent in order (oldest first)
- **Expected Result**: Multiple prompts per session allowed, sent in FIFO order

---

## Regression Considerations

What existing functionality could this feature break?

- **CRPG UI flows**: The deep link launch must not interfere with existing CRPG interactions (comment add/edit/delete, prompt generation).
- **Session state**: Launching a new deep link session must correctly clear previous session state without leaving orphaned data.
- **Clipboard behavior**: Fallback clipboard copy must not interfere with user's existing clipboard content outside of the timeout scenario.
- **Background behavior**: Offline queue retry must not drain battery or cause performance issues with excessive retries.

---

## Manual Test Scenarios

### Multi-Session Workflow (Manual)
1. Start Buzz conversation A, invoke `/shepherd fileA.swift`
2. Annotate partially, do NOT tap Done
3. Switch to Buzz conversation B, invoke `/shepherd fileB.swift`
4. Verify Shepherd replaces session (A lost, B loaded)
5. Complete annotation B, tap Done
6. Verify prompt goes to conversation B
7. Verify conversation A did NOT receive a prompt

### Network Transition (Manual)
1. Start annotation with WiFi connected
2. Midway through, switch to cellular (or airplane mode then back)
3. Complete annotation, tap Done
4. Verify callback succeeds or queues appropriately based on network state at Done-time

### Rapid Launches (Manual)
1. Invoke `/shepherd file1.swift` in Buzz
2. Before annotation completes, invoke `/shepherd file2.swift` from same conversation
3. Verify Shepherd replaces session cleanly
4. Complete annotation for file2, tap Done
5. Verify only file2 prompt returned (file1 discarded)

---

## Test Execution Results

(Results will be added here as tests are executed)
