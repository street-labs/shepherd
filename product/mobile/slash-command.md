# Slash Command Protocol — Mobile Platform

> Mobile-specific requirements for the slash command protocol. See ../slash-command.md for shared requirements.

## Overview

On mobile, slash commands like `/shepherd` and `/shepherd-review` are invoked from within the Buzz Mobile agent conversation. The commands execute server-side (in the Buzz agent runtime), but instead of spawning local processes or opening local windows, they launch Shepherd Mobile via deep links.

## Relationship to Shared Spec

The shared product spec (`../slash-command.md`) defines the slash command protocol: session ID management, command invocation, agent coordination, and result handoff. **All of those requirements apply to mobile unchanged**, except for the launch mechanism.

This supplement adds **only** the mobile-specific requirements:

- **Deep link launch** instead of local process spawn
- **Deep link callback** instead of file-based or server handoff

## Requirements

### Launch Mechanism

The slash command protocol is unchanged, but the transport changes from local server to deep links.

- **Mobile deep link protocol** `FR-scm-deeplink-protocol`: When a slash command (`/shepherd` or `/shepherd-review`) is invoked in Buzz Mobile, the agent constructs a deep link URI with the format: `shepherd://review?session=<session-id>&files=<base64>&context=<base64>`. The payload includes: session ID, base64-encoded file content, optional diff data, and optional context data (changeset overview + per-file context). The deep link opens Shepherd Mobile, passing all data in the URI or via a fallback mechanism if the payload is too large (per `FR-srm-deeplink-chunking`).

- **Mobile handoff callback** `FR-scm-mobile-callback`: When the user taps "Done" in Shepherd Mobile, the generated prompt is sent back to Buzz Mobile via a callback deep link with the format: `buzz://shepherd-result?session=<session-id>&prompt=<base64>`. The prompt text is base64-encoded to avoid URI encoding issues. Buzz Mobile receives the callback, decodes the prompt, and the Buzz agent resumes the conversation with the prompt as input. If the callback fails (Buzz Mobile not installed or not responding), the prompt is copied to the clipboard and the user is instructed to paste it manually.

- **Session ID consistency** `FR-scm-session-consistency`: The session ID passed in the launch deep link must match the session ID returned in the callback deep link. This ensures the prompt is delivered to the correct agent conversation, even if multiple Shepherd Mobile sessions are open simultaneously (e.g., reviewing different branches in different Buzz conversations).

### Offline and Error Handling

Mobile networks are unreliable, and deep links can fail.

- **Offline queue** `FR-scm-offline-queue`: If the callback deep link fails because of network unavailability or because Buzz Mobile is not running, Shepherd Mobile queues the prompt locally (per `FR-crpm-offline-sync`). The next time Shepherd Mobile launches or connectivity is restored, it attempts to send any queued prompts. The user can see pending prompts and retry sending them manually.

- **Callback timeout** `FR-scm-callback-timeout`: If Shepherd Mobile attempts to send a callback deep link and Buzz Mobile does not acknowledge receipt within 5 seconds, Shepherd Mobile assumes the callback failed and falls back to clipboard copy + user notification. This prevents the user from being stuck waiting if Buzz Mobile crashes or fails to handle the callback.

## Acceptance Criteria

These are mobile-specific acceptance criteria. See `../slash-command.md` for shared acceptance criteria that also apply to mobile.

- [ ] **Deep link opens Shepherd** `AC-scm-deeplink-open`: When the user invokes `/shepherd` or `/shepherd-review` in Buzz Mobile, Shepherd Mobile opens with the correct files and context loaded.

- [ ] **Callback delivers prompt** `AC-scm-callback-deliver`: When the user taps "Done" in Shepherd Mobile, the callback deep link is sent to Buzz Mobile, and the Buzz agent receives the prompt text correctly associated with the session ID.

- [ ] **Session ID matches** `AC-scm-session-match`: When multiple Shepherd Mobile sessions are open (different branches), the callback deep link delivers each prompt to the correct Buzz conversation based on session ID.

- [ ] **Offline queue works** `AC-scm-offline-queue`: When the callback fails due to network unavailability, the prompt is queued locally. When connectivity is restored, the queued prompt is sent successfully.

- [ ] **Timeout fallback** `AC-scm-timeout-fallback`: When Buzz Mobile does not acknowledge the callback within 5 seconds, Shepherd Mobile falls back to clipboard copy and shows a message to paste manually.

## Open Questions

None at this time.

## Dependencies

- Deep link protocol agreement between Buzz Mobile and Shepherd Mobile
- Buzz Mobile must handle the `buzz://shepherd-result` callback URI scheme
- Shepherd Mobile must register the `shepherd://review` URI scheme
