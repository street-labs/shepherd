---
product-hash: 323b3b866d3f9c84f30fca9b3c045f8e898d2504e3bc4a91e659530e8f11be78
product-slugs: [AC-crp-active-file-path-single-file, AC-crp-active-file-path-switches, AC-crp-active-file-path-visible, AC-crp-add-comment-line-range, AC-crp-add-comment-single-line, AC-crp-binary-file-rejected, AC-crp-clear-confirmation, AC-crp-clear-no-confirm-empty, AC-crp-comment-navigation-next, AC-crp-comment-summary-empty, AC-crp-comment-summary-realtime, AC-crp-comment-summary-shows-all, AC-crp-context-graceful-missing, AC-crp-context-neutral-vs-review, AC-crp-context-overall-visible, AC-crp-context-per-file-switches, AC-crp-context-per-file-visible, AC-crp-context-readonly, AC-crp-context-sidebar-collapse, AC-crp-copy-clipboard, AC-crp-delete-comment, AC-crp-done-auto-close, AC-crp-done-confirmation, AC-crp-done-disabled-no-comments, AC-crp-done-fallback-clipboard, AC-crp-done-sends-prompt, AC-crp-done-standalone-hidden, AC-crp-edit-comment, AC-crp-empty-state, AC-crp-file-mark-reviewed, AC-crp-file-path-display, AC-crp-file-path-single-dir, AC-crp-file-reviewed-clear-session, AC-crp-file-reviewed-grouping, AC-crp-file-reviewed-progress-count, AC-crp-file-reviewed-survives-tab-switch, AC-crp-file-reviewed-with-comments, AC-crp-file-tooltip-full-path, AC-crp-file-tooltip-reviewed, AC-crp-file-unmark-reviewed, AC-crp-generate-prompt-no-comments, AC-crp-generate-prompt-structure, AC-crp-keyboard-add-comment, AC-crp-large-file-scroll, AC-crp-line-wrap-comment-target, AC-crp-line-wrap-default-on, AC-crp-line-wrap-persists-session, AC-crp-line-wrap-preserves-line-numbers, AC-crp-line-wrap-toggle, AC-crp-load-drag-drop, AC-crp-load-paste, AC-crp-load-upload, AC-crp-multi-file-clear-all, AC-crp-multi-file-comment-count, AC-crp-multi-file-drop-multiple, AC-crp-multi-file-empty-after-remove-last, AC-crp-multi-file-load-adds, AC-crp-multi-file-nav-preserves-state, AC-crp-multi-file-prompt-omits-uncommented, AC-crp-multi-file-prompt-structure, AC-crp-multi-file-remove-no-comments, AC-crp-multi-file-remove-with-comments, AC-crp-overall-comment-in-prompt, AC-crp-overall-comment-label, AC-crp-panel-resize-bounds, AC-crp-panel-resize-double-click, AC-crp-panel-resize-drag, AC-crp-panel-resize-keyboard, AC-crp-panel-resize-persists, AC-crp-preview-matches-copy, AC-crp-syntax-highlight-detected, AC-crpm-context-collapse, AC-crpm-deeplink-load, AC-crpm-deeplink-send, AC-crpm-first-file-speed, AC-crpm-fullscreen-chrome, AC-crpm-offline-clipboard, AC-crpm-pinch-zoom, AC-crpm-session-persist, AC-crpm-swipe-nav, AC-crpm-voice-capture, FR-crp-active-file-path, FR-crp-clear-session, FR-crp-comment-count, FR-crp-comment-indicator, FR-crp-comment-navigation, FR-crp-comment-summary, FR-crp-done-action, FR-crp-file-display, FR-crp-file-load, FR-crp-file-reviewed-grouping, FR-crp-file-reviewed-persistence, FR-crp-file-reviewed-progress, FR-crp-file-reviewed-toggle, FR-crp-file-reviewed-visual, FR-crp-file-tooltip, FR-crp-filename-display, FR-crp-line-comment-create, FR-crp-line-comment-delete, FR-crp-line-comment-edit, FR-crp-line-range-comment, FR-crp-line-wrap, FR-crp-multi-file-load, FR-crp-multi-file-nav, FR-crp-multi-file-prompt, FR-crp-multi-file-prompt-format, FR-crp-multi-file-remove, FR-crp-panel-resize, FR-crp-prompt-copy, FR-crp-prompt-format, FR-crp-prompt-generate, FR-crp-prompt-handoff, FR-crp-prompt-preamble, FR-crp-prompt-preview, FR-crp-review-context-collapsible, FR-crp-review-context-display, FR-crp-review-context-overall, FR-crp-review-context-per-file, FR-crp-review-context-receive, FR-crp-session-identity, FR-crp-syntax-highlight, FR-crpm-deeplink-handoff, FR-crpm-deeplink-launch, FR-crpm-fullscreen, FR-crpm-gesture-nav, FR-crpm-mobile-context, FR-crpm-mobile-tabs, FR-crpm-offline-persist, FR-crpm-offline-sync, FR-crpm-pinch-zoom, FR-crpm-touch-select, FR-crpm-voice-input, FR-sc-file-api, FR-sc-session-id, NFR-crp-accessibility-keyboard, NFR-crp-browser-support, NFR-crp-client-only, NFR-crp-large-file-perf, NFR-crp-no-data-persistence, NFR-crp-prompt-gen-time, NFR-crp-render-time, NFR-crp-responsive-layout, NFR-crpm-mobile-input-lag, NFR-crpm-mobile-lazy]
---

# Code Review Prompt Generator — Mobile QA Test Plan

> Based on requirements in `../../product/code-review-prompt.md`  
> See also `../../product/mobile/code-review-prompt.md` for mobile-specific requirements  
> Based on design in `../../design/mobile/code-review-prompt.md`

## What We're Testing

This test plan covers the mobile (iOS and Android) implementation of the Code Review Prompt Generator. The CRPG is a touch-first application launched via deep links from Buzz Mobile, allowing developers to review code files, add inline comments using touch gestures and voice input, and send structured prompts back to the AI agent. Key risk areas include deep link handling with large payloads, offline persistence across app kills, touch interaction accuracy on small screens, and gesture conflicts between navigation and scrolling.

## Test Infrastructure

### Platforms

- **iOS**: iOS 15+ on iPhone (8/SE, 12 Pro, 14 Pro Max) and iPad (9th gen, Pro 11")
- **Android**: Android 8.0+ on phones (Pixel 4a, Samsung S21, S23 Ultra) and tablets (Samsung Tab S7)

### Test Types

- **Unit tests**: SwiftUI/TCA state logic (iOS), Jetpack Compose ViewModels (Android)
- **UI tests**: XCUITest (iOS), Espresso (Android) for touch gestures, navigation, accessibility
- **Integration tests**: Deep link handling, Buzz Mobile callback, local storage persistence
- **Manual tests**: Device-specific testing, voice input accuracy, accessibility with VoiceOver/TalkBack

### Test Data

- Small file: 50 lines TypeScript
- Medium file: 500 lines JavaScript with long lines (150+ chars)
- Large file: 5,000 lines Python
- Multi-file session: 7 files across 3 directories, 20+ comments total
- Deep link payload: Base64-encoded 10-file session (~200KB)

---

## Coverage Matrix

| Requirement | Test Cases | Status |
|---|---|---|
| `FR-crpm-deeplink-launch` | `TC-crpm-deeplink-launch-single`, `TC-crpm-deeplink-launch-multi`, `TC-crpm-deeplink-malformed`, `TC-crpm-deeplink-large-payload` | Not started |
| `FR-crpm-deeplink-handoff` | `TC-crpm-deeplink-send-success`, `TC-crpm-deeplink-send-fail`, `TC-crpm-deeplink-send-offline` | Not started |
| `FR-crpm-offline-persist` | `TC-crpm-offline-persist-comment`, `TC-crpm-offline-persist-appkill`, `TC-crpm-offline-restore` | Not started |
| `FR-crpm-offline-sync` | `TC-crpm-offline-queue`, `TC-crpm-offline-retry-auto`, `TC-crpm-offline-retry-manual` | Not started |
| `FR-crpm-touch-select` | `TC-crpm-touch-line-single`, `TC-crpm-touch-line-wrapped`, `TC-crpm-touch-target-size` | Not started |
| `FR-crpm-gesture-nav` | `TC-crpm-swipe-next`, `TC-crpm-swipe-prev`, `TC-crpm-swipe-wrap`, `TC-crpm-swipe-conflict` | Not started |
| `FR-crpm-pinch-zoom` | `TC-crpm-zoom-in`, `TC-crpm-zoom-out`, `TC-crpm-zoom-persist`, `TC-crpm-zoom-bounds` | Not started |
| `FR-crpm-voice-input` | `TC-crpm-voice-dictate`, `TC-crpm-voice-permission`, `TC-crpm-voice-unsupported` | Not started |
| `FR-crpm-mobile-context` | `TC-crpm-context-expand`, `TC-crpm-context-collapse`, `TC-crpm-context-scroll` | Not started |
| `FR-crpm-fullscreen` | `TC-crpm-fullscreen-enter`, `TC-crpm-fullscreen-exit` | Not started |
| `FR-crpm-mobile-tabs` | `TC-crpm-tabs-switch`, `TC-crpm-tabs-scroll`, `TC-crpm-tabs-truncate` | Not started |
| `NFR-crpm-mobile-lazy` | `TC-crpm-lazy-load-first`, `TC-crpm-lazy-load-deferred` | Not started |
| `NFR-crpm-mobile-input-lag` | `TC-crpm-input-responsiveness` | Not started |
| `AC-crpm-deeplink-load` | `TC-crpm-deeplink-launch-single`, `TC-crpm-deeplink-launch-multi` | Not started |
| `AC-crpm-deeplink-send` | `TC-crpm-deeplink-send-success` | Not started |
| `AC-crpm-offline-clipboard` | `TC-crpm-deeplink-send-fail` | Not started |
| `AC-crpm-session-persist` | `TC-crpm-offline-persist-appkill` | Not started |
| `AC-crpm-swipe-nav` | `TC-crpm-swipe-next`, `TC-crpm-swipe-prev` | Not started |
| `AC-crpm-pinch-zoom` | `TC-crpm-zoom-in`, `TC-crpm-zoom-persist` | Not started |
| `AC-crpm-voice-capture` | `TC-crpm-voice-dictate` | Not started |
| `AC-crpm-context-collapse` | `TC-crpm-context-expand`, `TC-crpm-context-collapse` | Not started |
| `AC-crpm-fullscreen-chrome` | `TC-crpm-fullscreen-enter`, `TC-crpm-fullscreen-exit` | Not started |
| `AC-crpm-first-file-speed` | `TC-crpm-lazy-load-first` | Not started |

---

## Test Cases

### Deep Link Launch and Handoff

Mobile apps are launched via deep links from Buzz Mobile, which encode files and context data.

#### Deep link launches single file `TC-crpm-deeplink-launch-single`
- **Type**: Integration
- **Covers**: `FR-crpm-deeplink-launch`, `AC-crpm-deeplink-load`
- **Preconditions**: Buzz Mobile installed, CRPG app installed but not running
- **Steps**:
  1. From Buzz Mobile conversation, tap "Review" button for single file
  2. Buzz Mobile generates deep link with session ID and base64-encoded file content
  3. OS launches CRPG app via deep link
  4. Observe CRPG UI after launch
- **Expected Result**: CRPG opens with single file loaded in code viewer, file name visible in tab, syntax highlighting applied, no comments yet, session ID associated with session

#### Deep link launches multi-file session `TC-crpm-deeplink-launch-multi`
- **Type**: Integration
- **Covers**: `FR-crpm-deeplink-launch`, `AC-crpm-deeplink-load`
- **Preconditions**: Buzz Mobile running with multi-file review ready
- **Steps**:
  1. Buzz Mobile encodes 7 files with context data in deep link
  2. Tap "Review" button
  3. OS launches CRPG
  4. Wait for first file to render
  5. Check file tab strip for all 7 files
  6. Swipe through files to verify all loaded
- **Expected Result**: First file renders within 2 seconds, all 7 files appear in tab strip, context drawer shows overall context, swiping between files works smoothly

#### Deep link with malformed payload `TC-crpm-deeplink-malformed`
- **Type**: Integration
- **Covers**: `FR-crpm-deeplink-launch`
- **Preconditions**: Test deep link with invalid base64 or missing session ID
- **Steps**:
  1. Construct deep link with corrupted file data
  2. Launch CRPG via test deep link
  3. Observe error handling
- **Expected Result**: CRPG shows error message "Could not load files from Buzz. Invalid data received." App does not crash. User can dismiss error and return to empty state or close app.

#### Deep link with large payload `TC-crpm-deeplink-large-payload`
- **Type**: Performance / Integration
- **Covers**: `FR-crpm-deeplink-launch`, `NFR-crpm-mobile-lazy`
- **Preconditions**: Deep link encoding 20 files totaling ~500KB
- **Steps**:
  1. Launch CRPG with large payload deep link
  2. Measure time until first file visible
  3. Check memory usage on device
  4. Navigate to 10th file
  5. Measure delay
- **Expected Result**: First file visible within 2 seconds, memory usage under 150MB, navigating to 10th file takes under 500ms (lazy loading defers decode until needed)

#### Deep link handoff success `TC-crpm-deeplink-send-success`
- **Type**: Integration
- **Covers**: `FR-crpm-deeplink-handoff`, `AC-crpm-deeplink-send`
- **Preconditions**: CRPG launched from Buzz Mobile, at least one comment added
- **Steps**:
  1. Add comment on line 5 of active file
  2. Tap Done button in bottom toolbar
  3. Observe CRPG behavior
  4. Check Buzz Mobile conversation
- **Expected Result**: CRPG sends deep link callback with session ID and prompt text, Buzz Mobile receives prompt and displays it in conversation, CRPG shows confirmation "Sent to Buzz!" and attempts to close app or shows "Done! Switch back to Buzz." message

#### Deep link handoff fails network unavailable `TC-crpm-deeplink-send-fail`
- **Type**: Integration
- **Covers**: `FR-crpm-deeplink-handoff`, `AC-crpm-offline-clipboard`
- **Preconditions**: CRPG running with comments, device in airplane mode
- **Steps**:
  1. Enable airplane mode
  2. Add comment
  3. Tap Done button
  4. Observe error handling
  5. Check system clipboard
- **Expected Result**: Deep link callback fails, error banner appears "Could not send to Buzz. Prompt copied to clipboard.", prompt text is on clipboard, prompt queued locally for retry (see offline sync tests)

#### Deep link handoff offline queue `TC-crpm-deeplink-send-offline`
- **Type**: Integration
- **Covers**: `FR-crpm-offline-sync`
- **Preconditions**: CRPG with offline queued prompt (from previous test)
- **Steps**:
  1. Re-enable network connectivity
  2. Launch CRPG (if closed) or wait for auto-retry
  3. Observe prompt queue behavior
- **Expected Result**: App attempts to send queued prompt automatically when network restored, on success removes from queue and shows toast "Queued prompt sent to Buzz"

---

### Offline Persistence

Session state must survive app backgrounding and OS kills.

#### Comment persists after app background `TC-crpm-offline-persist-comment`
- **Type**: Integration
- **Covers**: `FR-crpm-offline-persist`
- **Preconditions**: CRPG running with 2 files loaded
- **Steps**:
  1. Add comment on line 10 of file A: "Refactor this function"
  2. Switch to file B
  3. Add comment on line 5 of file B: "Add error handling"
  4. Background app (home button or swipe up)
  5. Wait 5 seconds
  6. Reopen CRPG
- **Expected Result**: Session restores immediately, both files still loaded, both comments present, file B active (was active when backgrounded), scroll position preserved

#### Session survives app kill by OS `TC-crpm-offline-persist-appkill`
- **Type**: Integration
- **Covers**: `FR-crpm-offline-persist`, `AC-crpm-session-persist`
- **Preconditions**: CRPG running with multi-file session and comments
- **Steps**:
  1. Add 5 comments across 3 files
  2. Background app
  3. Force-quit app via OS task manager or memory pressure
  4. Relaunch CRPG from home screen (not via deep link)
- **Expected Result**: App restores last session from local storage, all 3 files loaded, all 5 comments intact, active file restored, preamble text (if any) restored

#### Session restore from local storage `TC-crpm-offline-restore`
- **Type**: Unit / Integration
- **Covers**: `FR-crpm-offline-persist`
- **Preconditions**: CRPG closed, local storage contains persisted session
- **Steps**:
  1. Launch app from home screen (not deep link)
  2. Observe session restoration
- **Expected Result**: Previous session loads automatically, all files and comments restored, if no persisted session exists, app shows empty state "Open from Buzz Mobile to start reviewing code"

---

### Offline Sync Queue

When handoff fails, prompts are queued and retried when network returns.

#### Prompt queues locally when offline `TC-crpm-offline-queue`
- **Type**: Integration
- **Covers**: `FR-crpm-offline-sync`
- **Preconditions**: Device offline, CRPG running with comments
- **Steps**:
  1. Tap Done
  2. Observe error and queue behavior
  3. Check in-app "Pending" list (if accessible via menu)
- **Expected Result**: Error banner shows, prompt added to local queue, queue persists in local storage, user sees pending prompt in list with timestamp

#### Offline queue auto-retries on network restore `TC-crpm-offline-retry-auto`
- **Type**: Integration
- **Covers**: `FR-crpm-offline-sync`
- **Preconditions**: One queued prompt
- **Steps**:
  1. Restore network connectivity
  2. Observe app behavior (no user action)
- **Expected Result**: App detects network, attempts to send queued prompt automatically, on success shows toast "Queued prompt sent", removes from queue

#### Manual retry of queued prompt `TC-crpm-offline-retry-manual`
- **Type**: Manual
- **Covers**: `FR-crpm-offline-sync`
- **Preconditions**: One queued prompt, network available
- **Steps**:
  1. Open "Pending" list from menu
  2. Tap "Retry" button on queued prompt
  3. Observe result
- **Expected Result**: Prompt sends successfully, removed from queue, Buzz Mobile receives prompt

---

### Touch Interaction

Mobile devices require larger tap targets and no hover states.

#### Tap line number opens comment input `TC-crpm-touch-line-single`
- **Type**: UI
- **Covers**: `FR-crpm-touch-select`, `FR-crp-line-comment-create`
- **Preconditions**: File loaded in code viewer
- **Steps**:
  1. Tap line number 12 in gutter
  2. Observe UI response
- **Expected Result**: Line 12 highlights, comment input box appears anchored below line 12, keyboard slides up from bottom, focus in input field, microphone button visible if voice input available

#### Tap wrapped line targets correct logical line `TC-crpm-touch-line-wrapped`
- **Type**: UI
- **Covers**: `FR-crpm-touch-select`, `AC-crp-line-wrap-comment-target`
- **Preconditions**: File with long line that wraps to 3 visual rows, line wrap ON
- **Steps**:
  1. Tap on second visual row of wrapped line 20
  2. Observe which line number is targeted
- **Expected Result**: Comment input opens for line 20 (logical line), not a different line, line number indicator shows line 20

#### Tap target size meets guidelines `TC-crpm-touch-target-size`
- **Type**: Manual / UI
- **Covers**: `FR-crpm-touch-select`, accessibility guidelines
- **Preconditions**: File loaded on phone screen
- **Steps**:
  1. Measure line number gutter tap target height
  2. Attempt to tap line numbers on edges of screen (top, bottom)
  3. Attempt to tap with large finger or stylus
- **Expected Result**: Gutter tap target height is at least 44pt (iOS) / 48dp (Android), tapping any line number successfully opens comment input without mis-taps

---

### Gesture Navigation

Swipe gestures navigate between files without tapping small tab controls.

#### Swipe left navigates to next file `TC-crpm-swipe-next`
- **Type**: UI
- **Covers**: `FR-crpm-gesture-nav`, `AC-crpm-swipe-nav`
- **Preconditions**: 3 files loaded (A, B, C), file A active
- **Steps**:
  1. Swipe left on code content area
  2. Observe transition
- **Expected Result**: Screen slides left with animation, file B slides in from right, file B becomes active, tab strip updates to show file B highlighted, per-file context updates

#### Swipe right navigates to previous file `TC-crpm-swipe-prev`
- **Type**: UI
- **Covers**: `FR-crpm-gesture-nav`, `AC-crpm-swipe-nav`
- **Preconditions**: File B active
- **Steps**:
  1. Swipe right on code content area
  2. Observe transition
- **Expected Result**: Screen slides right, file A returns, file A becomes active

#### Swipe navigation wraps around `TC-crpm-swipe-wrap`
- **Type**: UI
- **Covers**: `FR-crpm-gesture-nav`
- **Preconditions**: File C (last file) active
- **Steps**:
  1. Swipe left
  2. Observe behavior
- **Expected Result**: Wraps to file A (first file), smooth transition

#### Swipe does not conflict with horizontal scroll `TC-crpm-swipe-conflict`
- **Type**: UI
- **Covers**: `FR-crpm-gesture-nav`
- **Preconditions**: File with long lines, line wrap OFF, horizontal scrolling enabled
- **Steps**:
  1. Attempt to scroll horizontally within code content
  2. Attempt to swipe left to navigate to next file
- **Expected Result**: Horizontal scroll within code works (two-finger swipe or scroll indicator drag), single-finger swipe left/right still navigates files, gestures distinguishable and do not interfere

---

### Pinch Zoom

Adjust code text size for readability on small screens.

#### Pinch out zooms in code text `TC-crpm-zoom-in`
- **Type**: UI
- **Covers**: `FR-crpm-pinch-zoom`, `AC-crpm-pinch-zoom`
- **Preconditions**: File loaded, zoom at default (100%)
- **Steps**:
  1. Perform pinch-out gesture on code content
  2. Observe text size increase
- **Expected Result**: Text size increases smoothly following gesture, line numbers scale proportionally, comment boxes remain aligned to lines, zoom stops at 200% maximum

#### Pinch in zooms out code text `TC-crpm-zoom-out`
- **Type**: UI
- **Covers**: `FR-crpm-pinch-zoom`
- **Preconditions**: Zoom at 150%
- **Steps**:
  1. Perform pinch-in gesture
  2. Observe text size decrease
- **Expected Result**: Text size decreases smoothly, zoom stops at 50% minimum

#### Zoom level persists per-file `TC-crpm-zoom-persist`
- **Type**: UI
- **Covers**: `FR-crpm-pinch-zoom`, `AC-crpm-pinch-zoom`
- **Preconditions**: File A zoomed to 150%, file B at default zoom
- **Steps**:
  1. Switch from file A to file B
  2. Observe zoom level
  3. Switch back to file A
  4. Observe zoom level
- **Expected Result**: File B displays at 100% (default), switching back to file A restores 150% zoom

#### Zoom respects bounds `TC-crpm-zoom-bounds`
- **Type**: UI
- **Covers**: `FR-crpm-pinch-zoom`
- **Preconditions**: File loaded
- **Steps**:
  1. Pinch out beyond 200%
  2. Attempt to zoom further
  3. Pinch in to 50%
  4. Attempt to zoom further
- **Expected Result**: Zoom stops at 200%, further pinch-out has no effect, zoom stops at 50%, further pinch-in has no effect

---

### Voice Input

Use device speech-to-text for comment input without typing.

#### Voice input dictates comment text `TC-crpm-voice-dictate`
- **Type**: UI / Manual
- **Covers**: `FR-crpm-voice-input`, `AC-crpm-voice-capture`
- **Preconditions**: Microphone permission granted, file loaded
- **Steps**:
  1. Tap line number to open comment input
  2. Tap microphone button in input box
  3. Speak clearly: "Rename this variable to userProfile"
  4. Wait for transcription
  5. Tap Done
- **Expected Result**: Microphone button highlights, platform speech recognition starts (recording indicator visible), transcribed text "Rename this variable to userProfile" appears in input field, tapping Done saves comment with transcribed text

#### Voice input requires microphone permission `TC-crpm-voice-permission`
- **Type**: UI / Manual
- **Covers**: `FR-crpm-voice-input`
- **Preconditions**: Microphone permission denied
- **Steps**:
  1. Open comment input
  2. Check for microphone button
- **Expected Result**: Microphone button not visible (hidden because permission denied), keyboard input still works

#### Voice input unavailable on unsupported device `TC-crpm-voice-unsupported`
- **Type**: UI / Manual
- **Covers**: `FR-crpm-voice-input`
- **Preconditions**: Device without microphone or speech API (rare, e.g., emulator without mic)
- **Steps**:
  1. Open comment input
  2. Check for microphone button
- **Expected Result**: Microphone button hidden, keyboard input works normally

---

### Review Context Drawer

Collapsible bottom drawer showing changeset context and review feedback.

#### Context drawer expands on swipe up `TC-crpm-context-expand`
- **Type**: UI
- **Covers**: `FR-crpm-mobile-context`, `AC-crpm-context-collapse`
- **Preconditions**: CRPG launched from shepherd-review with context data, drawer collapsed
- **Steps**:
  1. Swipe up on drawer handle at bottom of screen
  2. Observe drawer behavior
- **Expected Result**: Drawer slides up smoothly, expands to ~50% screen height, code content pushed up but partially visible, drawer shows overall context section and per-file context section

#### Context drawer collapses on swipe down `TC-crpm-context-collapse`
- **Type**: UI
- **Covers**: `FR-crpm-mobile-context`, `AC-crpm-context-collapse`
- **Preconditions**: Drawer expanded
- **Steps**:
  1. Swipe down on drawer handle
  2. Observe drawer behavior
- **Expected Result**: Drawer slides down, collapses to header-only state showing "Context: Overall + [filename]", code content slides down to fill screen

#### Context drawer content scrolls `TC-crpm-context-scroll`
- **Type**: UI
- **Covers**: `FR-crpm-mobile-context`
- **Preconditions**: Drawer expanded, context content longer than drawer height
- **Steps**:
  1. Scroll within drawer content area
  2. Observe scrolling
- **Expected Result**: Context content scrolls vertically within drawer, code content above drawer does not scroll

---

### Fullscreen Mode

Hide UI chrome to maximize code readability on small screens.

#### Fullscreen mode hides chrome `TC-crpm-fullscreen-enter`
- **Type**: UI
- **Covers**: `FR-crpm-fullscreen`, `AC-crpm-fullscreen-chrome`
- **Preconditions**: File loaded in normal mode
- **Steps**:
  1. Trigger fullscreen mode (long-press code area, or button in menu)
  2. Observe UI
- **Expected Result**: File tabs hidden, bottom toolbar hidden, context drawer hidden, only code content and line numbers visible, screen maximized for reading

#### Fullscreen mode exits on tap `TC-crpm-fullscreen-exit`
- **Type**: UI
- **Covers**: `FR-crpm-fullscreen`, `AC-crpm-fullscreen-chrome`
- **Preconditions**: Fullscreen mode active
- **Steps**:
  1. Tap top of screen
  2. Observe minimal toolbar appearance
  3. Tap "Exit Fullscreen" button
- **Expected Result**: Tapping top reveals minimal toolbar with "Exit Fullscreen" and "Done" buttons, tapping "Exit Fullscreen" restores normal UI (tabs, toolbar, context drawer if was open)

---

### Mobile File Tabs

Horizontal scrollable tab strip at top of screen.

#### Tap tab switches file `TC-crpm-tabs-switch`
- **Type**: UI
- **Covers**: `FR-crpm-mobile-tabs`, `FR-crp-multi-file-nav`
- **Preconditions**: 5 files loaded, file A active
- **Steps**:
  1. Tap tab for file C
  2. Observe file switch
- **Expected Result**: File C loads in code viewer, tab C highlighted, code content and per-file context update, comments for file C visible

#### Tab strip scrolls horizontally `TC-crpm-tabs-scroll`
- **Type**: UI
- **Covers**: `FR-crpm-mobile-tabs`
- **Preconditions**: 10 files loaded (more than fit on screen)
- **Steps**:
  1. Swipe left on tab strip
  2. Observe scrolling
- **Expected Result**: Tab strip scrolls horizontally, additional tabs visible, active tab remains highlighted

#### Long file name truncates `TC-crpm-tabs-truncate`
- **Type**: UI
- **Covers**: `FR-crpm-mobile-tabs`
- **Preconditions**: File with very long name loaded (e.g., VeryLongComponentNameWithManyWords.tsx)
- **Steps**:
  1. Observe file tab
  2. Long-press tab
- **Expected Result**: File name truncates with ellipsis in tab (e.g., "VeryLongComp..."), comment count badge visible, long-press shows full name in tooltip or detail overlay

---

### Performance - Lazy Loading

Defer decoding and rendering files until needed.

#### First file loads fast in multi-file session `TC-crpm-lazy-load-first`
- **Type**: Performance
- **Covers**: `NFR-crpm-mobile-lazy`, `AC-crpm-first-file-speed`
- **Preconditions**: Deep link with 20 files
- **Steps**:
  1. Launch CRPG via deep link
  2. Measure time until first file visible and interactive
- **Expected Result**: First file visible within 2 seconds, syntax highlighting applied, user can tap line number to add comment, other 19 files appear in tab strip but not yet decoded

#### Deferred files load on navigation `TC-crpm-lazy-load-deferred`
- **Type**: Performance
- **Covers**: `NFR-crpm-mobile-lazy`
- **Preconditions**: 20-file session, first file loaded
- **Steps**:
  1. Swipe to 10th file
  2. Measure delay
  3. Observe memory usage
- **Expected Result**: 10th file decodes and renders within 500ms, no visible loading spinner or jank, memory usage increases gradually as files decoded (not all at once)

---

### Performance - Input Responsiveness

Comment input must open instantly.

#### Comment input opens within 200ms `TC-crpm-input-responsiveness`
- **Type**: Performance
- **Covers**: `NFR-crpm-mobile-input-lag`
- **Preconditions**: File loaded on older device (e.g., iPhone 8, Pixel 4a)
- **Steps**:
  1. Tap line number
  2. Measure time until keyboard visible
- **Expected Result**: Comment input box appears within 200ms, keyboard slides up immediately, no visible lag or freeze, comment count update deferred until after keyboard shown

---

### Screen Size and Orientation

Adaptive layout for phones vs tablets, portrait vs landscape.

#### Portrait phone layout `TC-crpm-portrait-phone`
- **Type**: UI / Manual
- **Covers**: Design responsive behavior
- **Preconditions**: iPhone SE or similar small phone, portrait orientation
- **Steps**:
  1. Load multi-file session
  2. Observe layout
  3. Open context drawer
  4. Add comment
- **Expected Result**: Tab strip shows ~2-3 tabs at a time, code content uses full width minus small margins, context drawer covers ~50% of screen when expanded, all interactive elements reachable and tappable

#### Landscape phone layout `TC-crpm-landscape-phone`
- **Type**: UI / Manual
- **Covers**: Design responsive behavior
- **Preconditions**: Phone in landscape
- **Steps**:
  1. Rotate device to landscape
  2. Observe layout adaptation
- **Expected Result**: More tabs visible (~4-5), code content has more horizontal space, context drawer shorter vertically, toolbar buttons compact layout, all features still accessible

#### Tablet layout `TC-crpm-tablet`
- **Type**: UI / Manual
- **Covers**: Design responsive behavior
- **Preconditions**: iPad or Android tablet
- **Steps**:
  1. Load multi-file session on tablet
  2. Observe layout
- **Expected Result**: Tab strip shows many tabs (~6-8 or more), code content has generous margins, context drawer can be larger (60% height) or side-by-side layout, easier to read without zoom

---

### Accessibility

VoiceOver/TalkBack, Dynamic Type, high contrast, reduced motion.

#### VoiceOver announces line numbers `TC-crpm-voiceover-lines`
- **Type**: Accessibility / Manual
- **Covers**: `NFR-crp-accessibility-keyboard`, VoiceOver support
- **Preconditions**: iOS device, VoiceOver enabled
- **Steps**:
  1. Open file with comments on lines 5 and 10
  2. Swipe through code viewer with VoiceOver
  3. Listen to announcements
- **Expected Result**: Line numbers announced as "Line 5, tap to add comment" or "Line 10, 1 comment, tap to view", comment text read aloud when focused

#### TalkBack navigation `TC-crpm-talkback-nav`
- **Type**: Accessibility / Manual
- **Covers**: `NFR-crp-accessibility-keyboard`, TalkBack support
- **Preconditions**: Android device, TalkBack enabled
- **Steps**:
  1. Navigate through file tabs with swipe gestures
  2. Navigate to line numbers and comments
- **Expected Result**: All interactive elements have clear labels, tab announces "utils.ts tab, 3 comments", comment boxes announce comment text, Done button announces "Done button, sends prompt to Buzz"

#### Dynamic Type scales text `TC-crpm-dynamic-type`
- **Type**: Accessibility / Manual
- **Covers**: Design accessibility
- **Preconditions**: iOS with Large or Extra Large text size setting
- **Steps**:
  1. Enable Large text size in iOS settings
  2. Open CRPG
  3. Observe text scaling
- **Expected Result**: Code text scales with system font size (in addition to pinch zoom), UI labels scale, tap target sizes maintained, layout reflows gracefully

#### High contrast mode `TC-crpm-high-contrast`
- **Type**: Accessibility / Manual
- **Covers**: Design accessibility
- **Preconditions**: iOS with Increase Contrast enabled, or Android high contrast theme
- **Steps**:
  1. Enable high contrast mode
  2. Open CRPG
  3. Observe color contrast
- **Expected Result**: Syntax highlighting uses high contrast colors (4.5:1 minimum), comment indicators distinguishable, active tab vs inactive tab clearly distinct

#### Reduced motion respected `TC-crpm-reduced-motion`
- **Type**: Accessibility / Manual
- **Covers**: Design accessibility
- **Preconditions**: iOS with Reduce Motion enabled
- **Steps**:
  1. Enable Reduce Motion in iOS settings
  2. Swipe between files
  3. Expand/collapse context drawer
- **Expected Result**: File transitions instant (no slide animation), drawer expand/collapse instant, focus changes immediate, all functionality still works

---

### Edge Cases and Error Scenarios

Things that can go wrong on mobile.

#### App backgrounded during comment input `TC-crpm-background-input`
- **Type**: Integration
- **Covers**: `FR-crpm-offline-persist`
- **Preconditions**: Comment input open with partial text typed
- **Steps**:
  1. Tap line number, type "Refactor this fun..."
  2. Background app without submitting comment
  3. Wait 10 seconds
  4. Reopen app
- **Expected Result**: Session restores, comment input still open with partial text "Refactor this fun..." preserved, user can continue typing or cancel

#### Low memory warning during session `TC-crpm-low-memory`
- **Type**: Integration / Manual
- **Covers**: `NFR-crpm-mobile-lazy`, error handling
- **Preconditions**: Device with low available memory, 20-file session
- **Steps**:
  1. Trigger low memory condition (run memory-intensive app in background)
  2. Navigate through CRPG files
  3. Observe app behavior
- **Expected Result**: App unloads non-active file content to free memory, active file remains loaded and interactive, switching to previously loaded file re-decodes it (small delay acceptable), app does not crash

#### Network drops mid-handoff `TC-crpm-network-drop`
- **Type**: Integration
- **Covers**: `FR-crpm-offline-sync`
- **Preconditions**: Comments ready, network initially available
- **Steps**:
  1. Tap Done button
  2. Disable network during handoff (turn off WiFi/cellular)
  3. Observe error handling
- **Expected Result**: Handoff fails mid-request, error banner appears, prompt copied to clipboard, prompt queued for retry

#### Deep link encoding limit `TC-crpm-deeplink-size-limit`
- **Type**: Integration / Manual
- **Covers**: `FR-crpm-deeplink-launch`, error handling
- **Preconditions**: Extremely large file set (50+ files or very large files)
- **Steps**:
  1. Attempt to launch CRPG with oversized deep link payload
  2. Observe error handling
- **Expected Result**: If payload exceeds platform URL length limit (~2MB on iOS, varies on Android), Buzz Mobile shows error "Changeset too large for mobile review. Review on desktop instead." or falls back to file-based handoff if available

#### Rapid swipe gestures `TC-crpm-rapid-swipe`
- **Type**: UI
- **Covers**: `FR-crpm-gesture-nav`, edge case
- **Preconditions**: 5 files loaded
- **Steps**:
  1. Swipe left rapidly 3 times in quick succession
  2. Observe file transitions
- **Expected Result**: Each swipe navigates to next file without skipping, transitions queue smoothly, no UI jank or crash, ends at 4th file (A->B->C->D)

#### Comment on last line of file `TC-crpm-comment-last-line`
- **Type**: UI
- **Covers**: `FR-crp-line-comment-create`, edge case
- **Preconditions**: File with 100 lines
- **Steps**:
  1. Scroll to line 100 (last line)
  2. Tap line number
  3. Observe comment input positioning
- **Expected Result**: Comment input appears anchored below line 100, input not cut off by screen bottom, keyboard does not obscure input field, scrolling adjusts if needed

#### Very long comment text `TC-crpm-long-comment`
- **Type**: UI
- **Covers**: `FR-crp-line-comment-create`, edge case
- **Preconditions**: Comment input open
- **Steps**:
  1. Type very long comment (500+ characters)
  2. Observe input behavior
- **Expected Result**: Input field expands vertically up to 5 lines, then scrolls internally, keyboard remains visible, comment saves successfully when Done tapped, long comment displays in comment box with scroll or wrapping

---

## Regression Considerations

### What Existing Functionality Could Break

- **Deep link handling**: Changes to deep link format could break launches from Buzz Mobile. Requires coordination between teams.
- **Local storage schema**: Changes to persistence format could corrupt existing sessions on upgrade.
- **Gesture recognizers**: Adding new gestures could conflict with existing swipe/pinch/tap handlers.
- **Tab strip layout**: Changes to tab rendering could break with many files or long names.
- **Context drawer**: Changes to drawer mechanics could break collapsing/expanding or scrolling.

### Platform-Specific Risks

#### iOS

- **iOS version compatibility**: Test on iOS 15, 16, 17, 18 to ensure no SwiftUI layout regressions
- **Keyboard handling**: iOS keyboard behavior varies by device and iOS version
- **VoiceOver changes**: iOS updates often change VoiceOver behavior

#### Android

- **Device fragmentation**: Test on Samsung, Pixel, OnePlus devices (different Android skins)
- **Keyboard variations**: Gboard, Samsung Keyboard, SwiftKey have different behaviors
- **TalkBack compatibility**: Varies by Android version and device

---

## Manual Test Checklist

For each release candidate, execute these manual tests across devices:

### Core Flows (30 min)

- [ ] Launch from Buzz Mobile with single file
- [ ] Launch from Buzz Mobile with multi-file session
- [ ] Add comment using tap + keyboard
- [ ] Add comment using voice input
- [ ] Edit existing comment
- [ ] Delete comment
- [ ] Navigate between files using swipe gestures
- [ ] Navigate between files using tab strip
- [ ] Zoom in/out using pinch gesture
- [ ] Expand/collapse context drawer
- [ ] View All Comments summary
- [ ] Send prompt back to Buzz Mobile via Done button

### Device Matrix (1 hour per device type)

Test on:
- [ ] Small phone (iPhone SE / small Android)
- [ ] Large phone (iPhone Pro Max / Android flagship)
- [ ] Tablet (iPad / Android tablet)
- [ ] Portrait orientation
- [ ] Landscape orientation

### Accessibility (30 min)

- [ ] VoiceOver navigation (iOS)
- [ ] TalkBack navigation (Android)
- [ ] Dynamic Type / Large Text
- [ ] High Contrast mode
- [ ] Reduced Motion

### Edge Cases (20 min)

- [ ] Background app during comment input
- [ ] Force-quit and relaunch
- [ ] Airplane mode during Done action
- [ ] Very long file names
- [ ] 20+ file session

---

## Automation Priorities

High-value tests to automate first:

1. **Deep link launch and parsing** — integration tests, fast feedback on handoff protocol
2. **Touch gesture recognition** — UI tests for swipe/pinch/tap, catch regressions early
3. **Offline persistence** — integration tests, verify state survives app kills
4. **Comment CRUD operations** — UI tests, core functionality
5. **File navigation** — UI tests for tabs and swipe gestures

Lower priority for automation (manual testing acceptable):
- Voice input (requires audio input simulation, flaky)
- Accessibility (VoiceOver/TalkBack automation complex and brittle)
- Device-specific layout (screenshot tests better handled manually)
- Network edge cases (timing-sensitive, hard to simulate reliably)

---

## Test Execution Log

Results will be recorded here after test execution.

**Status legend**: Not started | Pass | Fail

_No results yet. Execute tests and update this section with findings._
