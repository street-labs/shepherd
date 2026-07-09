---
product-hash: 5c2dd73f6ced12cae11c0f54aabe78f933635099c20a300fd9d7f2ffb4b60c3e
product-slugs: [AC-sr-all-filtered, AC-sr-auto-open, AC-sr-batch-open, AC-sr-completion-summary, AC-sr-context-in-crpg, AC-sr-excludes-deleted, AC-sr-filters-binary, AC-sr-filters-generated, AC-sr-filters-lockfiles, AC-sr-happy-path, AC-sr-includes-config, AC-sr-install-global, AC-sr-interactive-prompt, AC-sr-invokes-shepherd, AC-sr-list-command, AC-sr-no-changes, AC-sr-not-git-repo, AC-sr-quit-early, AC-sr-skip-file, AC-sr-sorted-file-list, AC-sr-unified-prompt, FR-sc-session-id, FR-sc-session-scoped-output, FR-sr-changeset-detection, FR-sr-changeset-overview, FR-sr-command-file, FR-sr-completion-summary, FR-sr-context-handoff, FR-sr-feedback-collection, FR-sr-file-filtering, FR-sr-file-list-display, FR-sr-git-required, FR-sr-install, FR-sr-iteration-loop, FR-sr-multi-file-launch, FR-sr-per-file-context, FR-sr-priority-ordering, FR-sr-scope-argument, NFR-sr-agent-native, NFR-sr-cross-platform, NFR-sr-no-dependencies, NFR-sr-startup-speed]
---

# Shepherd Review — Mobile Design Spec

> Based on requirements in `../../product/shepherd-review.md`  
> See also `../../product/mobile/shepherd-review.md` for mobile-specific requirements.

## What We're Designing

The launch and handoff flow for multi-file code review on mobile. When a developer types `/shepherd-review` in Buzz Mobile, the agent performs changeset detection and context generation server-side, then launches Shepherd Mobile via deep link with all reviewable files and review context pre-loaded. The UI itself is the existing mobile CRPG (documented in `code-review-prompt.md`) — this spec focuses solely on how the review session is initiated, how data is transferred from Buzz to Shepherd, error states during launch, and the completion flow that sends the prompt back to Buzz.

This is a launch-and-handoff design spec, not a full UI spec. The review experience once inside Shepherd Mobile is already designed.

## Launch Flow

### Entry Point: Buzz Mobile Conversation

User types `/shepherd-review` in Buzz Mobile conversation. The agent performs changeset detection, filtering, priority ordering, and context generation server-side (all requirements from the shared product spec apply unchanged).

### Brief Summary Display

Before launching Shepherd Mobile, the agent displays a brief summary in the Buzz conversation:

```
Opening 7 files for review (3 excluded)
```

The summary includes:
- Total count of reviewable files (`FR-sr-file-list-display`)
- Optional note about filtered files (if any)
- No detailed file list or context — that appears in Shepherd Mobile, not in the Buzz conversation

This summary is intentionally minimal. The user sees what is about to happen, then Shepherd Mobile opens immediately.

### Deep Link Construction

Buzz Mobile agent constructs a deep link with the following data (`FR-srm-deeplink-launch`):

- Session ID (`FR-sc-session-id`)
- Base64-encoded diff content for each reviewable file
- File paths (relative to repo root)
- File ordering (priority order from `FR-sr-priority-ordering`)
- Overall neutral context (`FR-sr-changeset-overview`)
- Overall review feedback (`FR-sr-changeset-overview`)
- Per-file neutral context (`FR-sr-per-file-context`)
- Per-file review feedback (`FR-sr-per-file-context`)

All structured data is encoded as URL-safe base64 within the deep link payload.

### Launch Transition

After displaying the brief summary, the agent triggers the deep link. Buzz Mobile transitions to background. Shepherd Mobile opens with a loading state.

## Loading States

### Initial Load (Brief)

Shepherd Mobile shows a centered loading spinner with text:

```
Loading 7 files...
```

No progress bar. This state is brief (under 1 second for typical changesets) — just long enough to decode the deep link payload and initialize the CRPG UI.

### Large Changeset Load (With Progress)

For changesets with many files (10+), show a progress indicator:

```
Loading files... 5 / 12
```

Files are decoded and loaded incrementally. The first file becomes visible as soon as it is decoded, even if other files are still loading. User can start reviewing immediately without waiting for all files to finish loading.

**Requirements satisfied:** `NFR-srm-launch-time` (first file visible and interactive within 3 seconds)

## Error States

### Deep Link Payload Too Large

Deep links have platform-specific size limits (iOS ~100KB, Android varies). If the total payload exceeds the limit, Buzz Mobile agent must detect this before attempting launch (`FR-srm-deeplink-chunking`).

**Error message in Buzz conversation:**

```
This changeset is too large for mobile review (payload exceeds 100KB). 
Try one of these options:
- Review on desktop instead
- Filter the changeset: /shepherd-review --staged
- Review files individually: /shepherd <file>
```

Shepherd Mobile is NOT launched. User remains in Buzz conversation and can choose an alternative approach.

**Requirements satisfied:** `FR-srm-large-fallback`

### Buzz Mobile Not Installed

If the user's device does not have Buzz Mobile installed (unlikely scenario, since the command was invoked from Buzz), the deep link will fail silently at the OS level. No special handling is needed in Shepherd Mobile.

### Shepherd Mobile Not Installed

If Buzz Mobile attempts the deep link but Shepherd Mobile is not installed, the OS will fail to open the link. Buzz Mobile should handle this by displaying:

```
Shepherd Mobile is not installed. Install it to review code on mobile.
[Link to App Store / Play Store]
```

This is a Buzz Mobile responsibility, not a Shepherd Mobile design concern. Included here for completeness.

## Shepherd Mobile Launch Experience

Once Shepherd Mobile successfully opens from the deep link, the experience matches the existing CRPG design (`code-review-prompt.md`) with the following entry state:

- All reviewable files loaded as tabs, in priority order (`FR-sr-priority-ordering`, `FR-sr-multi-file-launch`)
- First file (highest priority) is displayed and active
- Review Context Drawer is **collapsed by default** at bottom of screen, showing header "Context: Overall + [first-file-name]" (`FR-crpm-mobile-context`)
- Comment count shows "0 comments" initially
- Done button is disabled (no comments yet)

### Context Drawer Default State

The Review Context Drawer starts **collapsed** because:
- Mobile screen space is limited
- User's first action is typically to read the code, not the context
- Drawer is easily accessible (one tap on Context button or swipe up from bottom)

User can expand the drawer at any time to see overall changeset context and per-file context. The context data is fully loaded and ready — the collapsed state is just the default view to maximize code visibility on small screens.

**Requirements satisfied:** `FR-sr-context-handoff`, `AC-sr-context-in-crpg`

### Context Visibility

When user expands the Review Context Drawer, they see:

1. **Overall Context Section** (collapsible accordion header)
   - Neutral context: factual description of what changed
   - Review feedback: agent's opinions and suggestions
   - Clear visual distinction between the two (icons, background colors, labels)

2. **File Context Section** (collapsible accordion header)
   - Header updates automatically to show current file name
   - Neutral context for current file
   - Review feedback for current file
   - If current file has no context data, section is hidden entirely (`AC-crp-context-graceful-missing`)

The neutral/review separation is preserved exactly as designed in `code-review-prompt.md` (informational icon for neutral, warning/info icons for review feedback, distinct background tints).

**Requirements satisfied:** `FR-crp-review-context-overall`, `FR-crp-review-context-per-file`, `AC-crp-context-neutral-vs-review`, `AC-crp-context-per-file-switches`

## Review Workflow

Once files are loaded, the user reviews them using the existing CRPG UI. This is already fully designed in `code-review-prompt.md`. No new UI is needed here.

Key behaviors (all existing):
- Tap line numbers to add comments
- Navigate between files using tabs or swipe gestures
- View/edit/delete comments
- Mark files as reviewed (optional)
- View All Comments screen for summary across files

## Completion Flow

### User Taps Done

When user has added at least one comment and taps Done button in bottom toolbar:

1. **Prompt generation**: CRPG generates unified multi-file prompt (existing functionality, `FR-crp-prompt-generate`)
2. **Fallback copy**: Prompt is copied to system clipboard immediately (happens before deep link attempt)
3. **Deep link callback**: Shepherd Mobile constructs a deep link back to Buzz Mobile with session ID and prompt content (`FR-crpm-deeplink-handoff`)
4. **Loading state**: Done button shows loading spinner, all buttons disabled
5. **Success path**:
   - Deep link succeeds → Buzz Mobile receives the prompt
   - Shepherd Mobile shows brief confirmation toast: "Sent to Buzz"
   - App attempts to auto-close after 1 second delay (if platform allows), OR shows message "Done! Switch back to Buzz." if auto-close is not supported
6. **Failure path**:
   - Deep link fails (Buzz not responding, timeout after 3 seconds)
   - Error banner appears at top of screen: "Could not send to Buzz. Prompt copied to clipboard."
   - Prompt remains in clipboard for manual paste
   - User can tap "Retry" button in error banner, or manually switch back to Buzz and paste

**Visual feedback:**

Success state (1 second duration before auto-close or message):
```
┌────────────────────────────────────┐
│ ✓ Sent to Buzz                     │ ← Green toast banner
└────────────────────────────────────┘
```

Failure state (persistent error banner):
```
┌────────────────────────────────────┐
│ ⚠ Could not send to Buzz           │ ← Yellow error banner
│ Prompt copied to clipboard [Retry] │
└────────────────────────────────────┘
```

**Requirements satisfied:** `FR-crp-done-action`, `FR-crpm-deeplink-handoff`, `AC-crp-done-sends-prompt`, `AC-crp-done-auto-close`, `AC-crp-done-fallback-clipboard`

### User Reviews Without Commenting

If user navigates through files, expands context, reads everything, but never adds a comment, the Done button remains disabled. User simply switches back to Buzz manually when finished.

No special "I'm done but have no comments" flow is needed — the absence of comments is the signal that no prompt is being sent back.

### User Abandons Review

User can exit Shepherd Mobile at any time:
- Swipe up to close app (iOS gesture)
- Tap back button (Android)
- Switch to another app via app switcher

No data is lost. The session is persisted in local storage (`FR-crpm-offline-persist`). If user reopens Shepherd Mobile later, they can continue the review where they left off (existing offline persistence behavior).

No special "cancel review" confirmation is needed. The user is free to leave at any time.

## Offline Behavior

If user is offline when they tap Done, the deep link callback will fail. The fallback error banner appears ("Could not send to Buzz. Prompt copied to clipboard.") and the prompt is queued for retry when network returns (`FR-crpm-offline-sync`).

The user experience is identical to the deep link failure state described above. Offline is treated as one more reason the callback might fail — no special offline UI is needed beyond what already exists for callback failures.

## Platform-Specific Notes

### iOS
- Deep link URL scheme: `buzz-mobile://shepherd-review-done?session=[id]&prompt=[base64]`
- App auto-close uses `UIApplication.shared.perform(#selector(NSXPCConnection.suspend))` if available, or shows message if not
- Loading spinner uses iOS `UIActivityIndicatorView` style
- Toast banners use iOS-style rounded rectangle with shadow
- Success banner: green background (`systemGreen`), white text
- Error banner: yellow background (`systemYellow`), black text, includes Retry button

### Android
- Deep link URL scheme: `buzzmobile://shepherd-review-done?session=[id]&prompt=[base64]`
- App auto-close uses `finishAffinity()` if available, or shows message if not
- Loading spinner uses Material `CircularProgressIndicator`
- Toast banners use Material Snackbar style
- Success banner: green background (Material `green600`), white text
- Error banner: yellow background (Material `yellow700`), black text, includes Retry button

## Edge Cases

### Very Large Payload (Chunking Not Implemented in V1)

If the changeset is so large that even engineering fallback mechanisms cannot pass it via deep link, Buzz Mobile agent shows the "too large for mobile" message (see Error States section above) and does NOT launch Shepherd Mobile.

This prevents a bad experience where Shepherd opens with incomplete data or fails halfway through loading.

**Requirements satisfied:** `FR-srm-large-fallback`, `AC-srm-large-blocked`

### File With No Context

If a file has no per-file context data (neutral or review), the File Context section in the Review Context Drawer is hidden entirely when viewing that file. The Overall Context section remains visible.

This is existing CRPG behavior (`AC-crp-context-graceful-missing`). No new design needed.

### Rapid Switching Between Files

User swipes rapidly between files (5+ swipes in 2 seconds). Each swipe triggers a file switch and a per-file context update in the drawer (if drawer is expanded).

Expected behavior:
- File switch animation is smooth (no lag)
- Per-file context updates only for the final file that settles into view (intermediate swipe events are debounced)
- No performance degradation

This is engineering implementation detail, not a visual design concern, but noted here for completeness.

## Accessibility

All existing CRPG accessibility features apply (documented in `code-review-prompt.md`). No new accessibility considerations for the launch/handoff flow beyond:

- Loading state announces "Loading files" to screen readers
- Success toast announces "Sent to Buzz" to screen readers
- Error banner announces "Could not send to Buzz. Prompt copied to clipboard." to screen readers
- Retry button is labeled "Retry sending prompt to Buzz"

## Open Questions

None at this time. The mobile CRPG UI is already designed, and the launch/handoff flow is straightforward (deep link in, deep link out, with clipboard fallback).
