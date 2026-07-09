---
product-hash: ff5cf4ef4c29c0a83a9af96e2b6cfb6cc96bb2690ed05b2ed160c4e4bdc51360
product-slugs: [AC-sc-absolute-path, AC-sc-binary-file-rejected, AC-sc-cold-launch-8s, AC-sc-concurrent-sessions, AC-sc-cross-platform-open, AC-sc-directory-rejected, AC-sc-file-not-found, AC-sc-install-global, AC-sc-install-symlink, AC-sc-large-file-warning, AC-sc-launch-happy-path, AC-sc-no-args-usage, AC-sc-permission-denied, AC-sc-prompt-cleanup-stale, AC-sc-prompt-output-api-localhost-only, AC-sc-prompt-output-api-success, AC-sc-prompt-received, AC-sc-prompt-watcher-timeout, AC-sc-server-manual-stop, AC-sc-server-reuse, AC-sc-session-clear-on-new-file, AC-sc-session-output-isolation, AC-sc-single-tool-call, AC-sc-standalone-window, AC-sc-warm-launch-2s, FR-crp-done-action, FR-crp-file-load, FR-crp-syntax-highlight, FR-sc-app-serve, FR-sc-auto-load-file, FR-sc-browser-open, FR-sc-concurrent-windows, FR-sc-dynamic-port, FR-sc-file-api, FR-sc-file-resolution, FR-sc-file-validation, FR-sc-install, FR-sc-invoke-command, FR-sc-launcher-script, FR-sc-output-feedback, FR-sc-prompt-cleanup, FR-sc-prompt-output-api, FR-sc-prompt-receive, FR-sc-server-shutdown, FR-sc-session-cleanup, FR-sc-session-id, FR-sc-session-scoped-output, NFR-crp-client-only, NFR-crp-large-file-perf, NFR-sc-cross-platform, NFR-sc-launch-speed, NFR-sc-localhost-only, NFR-sc-minimal-footprint, NFR-sc-no-global-deps, NFR-sc-no-telemetry, NFR-sc-watcher-low-overhead]
---
# Slash Command Protocol — Mobile Design Spec

> Based on requirements in `../../product/slash-command.md` and `../../product/mobile/slash-command.md`

## What We're Designing

This design spec covers the **mobile-specific protocol and error handling UX** for the slash command system. When a user invokes `/shepherd` or `/shepherd-review` in Buzz Mobile, the command launches Shepherd Mobile via deep link, the user annotates code in Shepherd, and the generated prompt returns to Buzz via callback deep link. This spec defines the transitions, feedback states, and error recovery flows for that roundtrip. It does NOT cover the CRPG visual UI (that's in the CRPG and shepherd-review specs).

## Interaction Flows

These flows define the mobile-specific protocol behavior, error states, and user feedback patterns.

### Flow 1: Successful Roundtrip (Happy Path)

User invokes `/shepherd file.swift` in Buzz Mobile, annotates in Shepherd Mobile, and the prompt returns successfully.

**Requirements satisfied**: `FR-scm-deeplink-protocol`, `FR-scm-mobile-callback`, `FR-sc-session-id`, `AC-scm-deeplink-open`, `AC-scm-callback-deliver`

1. **User invokes command** — User types `/shepherd file.swift` in Buzz Mobile conversation
2. **Buzz agent constructs deep link** — Server-side agent builds `shepherd://review?session=<session-id>&files=<base64>&context=<base64>`
3. **Deep link launches Shepherd** — Buzz Mobile opens the deep link, iOS/Android transition animation shows Buzz fading/sliding out, Shepherd Mobile app opens
4. **Shepherd shows loading state** — Brief spinner while parsing payload (target: under 500ms)
5. **Shepherd loads file** — Code viewer displays with syntax highlighting, session ID visible in header/title area (e.g., "Review Session: project-name")
6. **User annotates and taps Done** — User adds comments/preamble, taps Done button
7. **Shepherd shows "Sending to Buzz..."** — Brief confirmation message with loading indicator
8. **Callback deep link sent** — Shepherd constructs `buzz://shepherd-result?session=<session-id>&prompt=<base64>` and opens it
9. **OS transitions back to Buzz** — Native app-switch animation (Shepherd fades/slides away, Buzz returns)
10. **Buzz receives prompt** — Buzz Mobile decodes prompt, agent conversation resumes with prompt as input

**Transition style**: Use native OS app-switch animation (iOS inter-app transition, Android activity transition). No custom animations needed — leverage platform defaults for familiar feel.

### Flow 2: Callback Failure with Clipboard Fallback

Callback deep link fails (Buzz not responding, network down), Shepherd falls back to clipboard.

**Requirements satisfied**: `FR-scm-mobile-callback`, `FR-scm-callback-timeout`, `AC-scm-timeout-fallback`

1. **Steps 1-6 from Flow 1** (same up to Done tap)
2. **Shepherd attempts callback** — Sends `buzz://shepherd-result?...` deep link
3. **Timeout after 5 seconds** — Buzz Mobile doesn't acknowledge receipt (app not running, crashed, or network issue)
4. **Shepherd shows fallback dialog**:
   - **Title**: "Prompt Copied to Clipboard"
   - **Body**: "Buzz didn't respond. The prompt has been copied to your clipboard. Switch to Buzz and paste it manually."
   - **Primary button**: "Open Buzz" (attempts to open Buzz via base deep link `buzz://`)
   - **Secondary button**: "Dismiss"
5. **Prompt copied to clipboard** — Full markdown prompt text available for manual paste

**Visual feedback**: Use standard iOS/Android alert dialog style. No custom modal needed. The "Open Buzz" button is a fallback to help user navigate back, but doesn't guarantee Buzz is ready to receive.

### Flow 3: Offline Queue and Retry

Network unavailable when callback is attempted, prompt queued locally for later delivery.

**Requirements satisfied**: `FR-scm-offline-queue`, `AC-scm-offline-queue`

1. **Steps 1-6 from Flow 1** (same up to Done tap)
2. **Shepherd detects offline** — Network reachability check fails before attempting callback
3. **Prompt queued locally** — Saved to device storage with session ID, timestamp
4. **Shepherd shows queue confirmation**:
   - **Toast/banner**: "Offline — Prompt queued for delivery"
   - **Duration**: 3 seconds, auto-dismiss
   - **Action button**: "View Queue" (navigates to Pending Prompts screen if user taps)
5. **User can view queue** — Accessible via settings/menu, shows list of pending prompts with:
   - Session ID (e.g., "project-name")
   - Timestamp (e.g., "2 minutes ago")
   - Retry button per item
6. **Automatic retry on reconnect** — When network becomes available, Shepherd attempts to send all queued prompts in background
7. **Success notification** — "Prompt delivered to Buzz" toast when send succeeds
8. **Persistent failure** — After 3 automatic retry attempts, item stays in queue for manual retry

**Pending Prompts screen** (minimal):
- **Title**: "Pending Prompts"
- **Empty state**: "No pending prompts"
- **Populated state**: List of queued prompts, newest first
- **Per-item actions**: "Retry" button, "Copy to Clipboard" button, "Delete" button
- **Bulk action**: "Clear All" (with confirmation)

### Flow 4: Multi-Session Handling

User has multiple Buzz conversations active (different branches), each launches Shepherd with different session IDs.

**Requirements satisfied**: `FR-sc-session-id`, `FR-scm-session-consistency`, `AC-scm-session-match`, `AC-sc-concurrent-sessions`

1. **Session A launched** — User in Buzz conversation A invokes `/shepherd file1.swift`, Shepherd opens with session ID "project-main"
2. **User switches to Buzz conversation B** — Without closing Shepherd, user returns to Buzz, navigates to different conversation
3. **Session B launched** — User invokes `/shepherd file2.swift` in conversation B, Shepherd receives new deep link with session ID "project-feature-branch"
4. **Shepherd replaces session** — Clears previous session (project-main) and loads new session (project-feature-branch) without confirmation
   - **Brief transition**: "Loading project-feature-branch..." overlay (under 300ms)
   - **Session indicator updated**: Header/title shows new session ID
5. **User completes session B** — Annotates, taps Done, callback goes to Buzz conversation B (session ID matches)
6. **Session A lost** — Previous session (project-main) is not preserved. Launching a new session always replaces the current one.

**Design decision**: **No multi-session UI complexity** — Shepherd Mobile maintains one active session at a time. If a user needs to preserve work from session A before starting session B, they must tap Done to send it back to Buzz first. Attempting to support multiple concurrent sessions in-app adds significant UI complexity (tab switching, session list, accidental cross-session edits) for minimal benefit. The deep link protocol is stateless — each launch is a fresh start.

**Session identity visible**: Header or navigation bar shows session ID (derived from worktree name per `FR-sc-session-id`). This helps user confirm which Buzz conversation the prompt will return to.

### Flow 5: Large Payload Handling (Future)

If deep link payload exceeds iOS/Android URL length limits (typically 2-4 KB), chunking or alternative transport needed.

**Requirements satisfied**: `FR-srm-deeplink-chunking` (referenced in mobile supplement but not yet defined — this is forward-looking)

**Current behavior**: For V1, if payload is too large, Buzz Mobile shows error: "File too large for deep link. Please use a smaller file or contact support." This is a known limitation — no chunking implemented yet.

**Future design** (when implemented):
1. Buzz Mobile detects large payload (> 2 KB)
2. Stores payload in shared container (iOS App Groups or Android Shared Storage)
3. Deep link includes only session ID and storage key: `shepherd://review?session=<id>&key=<storage-key>`
4. Shepherd Mobile reads from shared storage using key
5. Callback works the same (prompt returned via deep link or stored if too large)

This is **not implemented in V1** — flagged for later iteration.

## States and Feedback

### Session Identity Indicator

**Location**: Navigation bar or header area of Shepherd Mobile when CRPG is active

**Content**: Session ID text (e.g., "project-main", "my-feature-branch")

**Purpose**: User can confirm which Buzz conversation this session corresponds to. Important when user has multiple Buzz conversations active.

**States**:
- **Active session**: Session ID displayed in header (e.g., "Session: project-main")
- **No session**: Header shows app name only ("Shepherd")

### Callback Confirmation States

**After user taps Done in CRPG:**

1. **Sending** (0-5 seconds):
   - Loading indicator (spinner or progress bar)
   - Text: "Sending to Buzz..."
   - Not dismissible — user must wait

2. **Success** (auto-dismiss after 1 second):
   - Checkmark icon
   - Text: "Sent to Buzz"
   - Then automatically returns to Buzz via OS app-switch

3. **Failure - Timeout** (persistent until dismissed):
   - Alert dialog (per Flow 2)
   - User must acknowledge and choose action

4. **Failure - Offline** (auto-dismiss after 3 seconds):
   - Toast/banner (per Flow 3)
   - Prompt queued for later

### Error Messages

All error messages follow platform conventions (iOS alerts, Android Material dialogs).

| Error Condition | Title | Body | Actions |
|---|---|---|---|
| Callback timeout (5s) | "Prompt Copied to Clipboard" | "Buzz didn't respond. The prompt has been copied to your clipboard. Switch to Buzz and paste it manually." | "Open Buzz" (primary), "Dismiss" (secondary) |
| Network unavailable | (Toast/banner only) | "Offline — Prompt queued for delivery" | "View Queue" (tap action, optional) |
| Malformed deep link | "Invalid Link" | "The link format is invalid. Please try again from Buzz." | "OK" |
| Missing session ID | "Session Missing" | "This link is missing required session information. Please invoke the command from Buzz again." | "OK" |
| Deep link payload too large (V1) | "File Too Large" | "The file size exceeds the deep link limit. Please use a smaller file." | "OK" |

## Accessibility

- **Session ID in header** must be readable by VoiceOver/TalkBack (labeled as "Review session: [session-id]")
- **Loading states** must announce to screen reader ("Sending to Buzz")
- **Error dialogs** must be keyboard navigable (tab between buttons, Enter to confirm)
- **Pending Prompts screen** must support VoiceOver list navigation with item actions announced

## Responsive Behavior

Mobile-only design — no tablet-specific variants needed for protocol flows. Session ID header scales with system font size (iOS Dynamic Type, Android system font scaling).

## Open Questions

None at this time. Chunking/large payload handling is explicitly deferred to future iteration.

## Requirements Coverage

This spec addresses the mobile-specific requirements in `product/mobile/slash-command.md`:

- **Launch mechanism**: `FR-scm-deeplink-protocol`, `FR-scm-session-consistency`
- **Callback and handoff**: `FR-scm-mobile-callback`
- **Error handling**: `FR-scm-offline-queue`, `FR-scm-callback-timeout`
- **Multi-session**: `FR-sc-session-id`, `FR-sc-concurrent-windows` (adapted for mobile single-session model)

All acceptance criteria from the mobile supplement are covered by the flows above.
