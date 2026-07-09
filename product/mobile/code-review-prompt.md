# Code Review Prompt Generator — Mobile Platform

> Mobile-specific requirements for the Code Review Prompt Generator. See ../code-review-prompt.md for shared requirements.

## Overview

The mobile platform brings the CRPG to iOS and Android devices. Since mobile apps cannot access the file system directly or run local servers, files and context must be passed via deep links from Buzz Mobile. The UI is optimized for touch input and smaller screens, with collapsible panels and gesture-based navigation.

## Relationship to Shared Spec

The shared product spec (`../code-review-prompt.md`) defines the core CRPG functionality: loading files, adding inline comments, generating structured prompts, and multi-file review. **All of those requirements apply to mobile unchanged.**

This supplement adds **only** the mobile-specific requirements that don't exist on other platforms:

- **Launch mechanism**: Deep link protocol instead of local server
- **Input method**: Touch gestures instead of mouse/keyboard
- **Screen constraints**: Smaller screens require collapsible UI
- **Offline support**: Session persistence for network interruptions
- **Platform integration**: Integration with Buzz Mobile for agent handoff

## User Stories

### US-CRPM-1: Launch CRPG from Buzz Mobile via deep link
**As a** developer using Buzz Mobile, **I want to** tap a "Review" button in the Buzz agent conversation that opens Shepherd with all the files and context already loaded, **so that** I can review code on my phone or tablet without manual file selection.

### US-CRPM-2: Navigate between files with touch gestures
**As a** mobile user, **I want to** swipe left/right to navigate between file tabs, **so that** I can quickly move through files without tapping small UI controls.

###US-CRPM-3: Add comments with minimal keyboard use
**As a** mobile user, **I want** the option to use voice input for comments, **so that** I can review code even when typing on a small keyboard is inconvenient.

### US-CRPM-4: Continue reviewing when network drops
**As a** mobile user, **I want** my review session to persist locally even if my network connection drops, **so that** I don't lose my comments when connectivity is unreliable.

### US-CRPM-5: Read code on a small screen
**As a** mobile user, **I want** collapsible context panels and fullscreen code view, **so that** I can see the code clearly even on a phone screen.

### US-CRPM-6: Zoom code for readability
**As a** mobile user, **I want to** pinch-to-zoom on code content, **so that** I can adjust text size for my device and lighting conditions.

## Requirements

### Launch and Handoff

The mobile platform has no file system access and no local server. All data comes via deep links.

- **Deep link launch** `FR-crpm-deeplink-launch`: The application accepts a deep link from Buzz Mobile containing: session ID, base64-encoded file content for each file, optional diff data per file, optional changeset context (neutral + review feedback), and optional per-file context (neutral + review feedback). The deep link format is defined by engineering. When launched via deep link, all files are loaded immediately and the session ID is associated with the session for handoff back to Buzz.

- **Deep link handoff** `FR-crpm-deeplink-handoff`: When the user taps "Done", the application generates the structured prompt and sends it back to Buzz Mobile via a deep link callback. The callback includes the session ID and the full prompt text. If the deep link callback fails (Buzz Mobile not installed or not responding), the prompt is copied to the system clipboard and the user is shown a message to paste it manually.

- **Offline session persistence** `FR-crpm-offline-persist`: The session state (all loaded files, all comments, preamble, scroll positions, active file) is persisted to local storage every time the user adds, edits, or deletes a comment, or changes the preamble. If the app is backgrounded or closed, the session can be restored from local storage when the app returns to the foreground. This ensures comments are not lost if the app is killed by the OS or network connectivity is interrupted.

- **Offline sync queue** `FR-crpm-offline-sync`: If the deep link handoff fails because of network unavailability, the generated prompt is queued locally. The next time the app launches or network connectivity is restored, the app attempts to send any queued prompts via deep link callback. The user can see queued prompts in a "Pending" list and retry sending them manually.

### Touch Interaction

Mobile devices have no mouse hover, no right-click, and require larger tap targets.

- **Touch line select** `FR-crpm-touch-select`: Tapping a line number opens the comment input box for that line, anchored directly below the line. There is no hover preview (mobile has no hover state). The tap target for line numbers is at least 44pt (iOS) / 48dp (Android) in height to meet accessibility guidelines.

- **Gesture navigation** `FR-crpm-gesture-nav`: Swiping left navigates to the next file in the file list. Swiping right navigates to the previous file. Swipe gestures are recognized on the code content area, not on UI chrome. The file navigator shows a visual indicator of the current file position in the list.

- **Pinch zoom** `FR-crpm-pinch-zoom`: The user can pinch-to-zoom on the code content area to increase or decrease text size for readability. Zoom level persists per-file within the session (switching files and switching back preserves zoom). Zoom does not affect line number alignment or comment positioning. Minimum zoom is 50% of default size, maximum is 200%.

- **Comment voice input** `FR-crpm-voice-input`: When the comment input box is open, the user can tap a microphone icon to dictate the comment text using the platform's native speech-to-text. This is optional — keyboard input remains the default. Speech recognition uses the device's language setting. If speech recognition is unavailable (no microphone permission or unsupported device), the microphone button is hidden.

### Screen Adaptation

Mobile screens are smaller, especially on phones. UI must adapt without hiding critical functionality.

- **Collapsible context panel** `FR-crpm-mobile-context`: When review context data is present (from `/shepherd-review`), it is displayed in a collapsible panel that can be swiped up from the bottom (drawer pattern) or collapsed to show only a header. When collapsed, only the first line of the neutral context is visible. When expanded, both neutral context and review feedback are shown in full. The panel does not obscure the code content when collapsed. The collapse state persists within the session.

- **Fullscreen code toggle** `FR-crpm-fullscreen`: The user can toggle fullscreen code view, which hides all UI chrome except the code content and line numbers. In fullscreen mode, tapping the top of the screen reveals a minimal toolbar with "Exit Fullscreen" and "Done" buttons. This maximizes screen space for reading code on small devices.

- **Mobile file tabs** `FR-crpm-mobile-tabs`: The file navigator is displayed as a horizontal scrollable strip of tabs at the top of the screen (consistent with mobile browser tabs). Each tab shows the file name (truncated if too long) and the number of comments on that file. The active tab is visually highlighted. Tapping a tab switches to that file. The tab strip scrolls horizontally if there are more files than fit on screen.

### Performance

Mobile devices have less memory and slower processors than desktops.

- **Lazy file loading** `NFR-crpm-mobile-lazy`: When a session is launched via deep link with many files (10+), only the first file's content is decoded and rendered immediately. Other files are decoded and rendered on-demand when the user navigates to them. This prevents long initial load times and excessive memory use on resource-constrained devices.

- **Comment input responsiveness** `NFR-crpm-mobile-input-lag`: Opening the comment input box (tapping a line number) must complete within 200ms, even on older devices. The keyboard appears immediately; any heavy processing (like re-rendering the comment count indicator) is deferred until after the keyboard is shown.

## Acceptance Criteria

These are mobile-specific acceptance criteria. See `../code-review-prompt.md` for shared acceptance criteria that also apply to mobile.

- [ ] **Deep link launch loads files** `AC-crpm-deeplink-load`: When the app is launched via a deep link containing encoded file data, all files are loaded into the session and visible in the file tabs without any manual file selection.

- [ ] **Deep link handoff sends prompt** `AC-crpm-deeplink-send`: When the user taps "Done", the generated prompt is sent back to Buzz Mobile via deep link callback, and Buzz Mobile receives the prompt and session ID correctly.

- [ ] **Offline clipboard fallback** `AC-crpm-offline-clipboard`: When deep link handoff fails (Buzz not responding), the prompt is copied to the clipboard and a message is shown instructing the user to paste it manually into Buzz.

- [ ] **Session survives app kill** `AC-crpm-session-persist`: When the user adds comments, backgrounds the app, and the OS kills it, relaunching the app restores the session with all comments intact.

- [ ] **Swipe navigates files** `AC-crpm-swipe-nav`: Swiping left on the code content area navigates to the next file; swiping right navigates to the previous file. Swipes are smooth and responsive.

- [ ] **Pinch zoom works** `AC-crpm-pinch-zoom`: Pinching on the code content area zooms the text in/out. Zoom persists when switching files and returning.

- [ ] **Voice input captures text** `AC-crpm-voice-capture`: When the user taps the microphone button and speaks, the transcribed text appears in the comment input box.

- [ ] **Context panel collapses** `AC-crpm-context-collapse`: When review context is present, swiping down on the context panel collapses it to show only the header. Swiping up expands it to full height. The code content is always visible when the panel is collapsed.

- [ ] **Fullscreen hides chrome** `AC-crpm-fullscreen-chrome`: When fullscreen mode is activated, all UI except code and line numbers is hidden. Tapping the top of the screen reveals a minimal toolbar.

- [ ] **First file loads fast** `AC-crpm-first-file-speed`: When launched with 20 files, the first file is visible and interactive within 2 seconds. Navigating to the 10th file does not cause a noticeable delay (< 500ms).

## Open Questions

None at this time.

## Dependencies

- Deep link protocol must be agreed upon between Buzz Mobile and Shepherd Mobile engineering teams
- Buzz Mobile must support sending the deep link and receiving the callback
- Native platform APIs for speech-to-text (iOS Speech framework, Android SpeechRecognizer)
- Local storage mechanism for offline persistence (iOS UserDefaults/file storage, Android SharedPreferences/file storage)
