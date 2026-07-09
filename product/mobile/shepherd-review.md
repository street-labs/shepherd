# Shepherd Review — Mobile Platform

> Mobile-specific requirements for Shepherd Review. See ../shepherd-review.md for shared requirements.

## Overview

On mobile, `/shepherd-review` is invoked from within the Buzz Mobile agent conversation. The agent still performs changeset detection and context generation server-side (unchanged from the shared spec), but instead of opening a local CRPG window, it launches Shepherd Mobile via deep link with all files and context pre-loaded.

## Relationship to Shared Spec

The shared product spec (`../shepherd-review.md`) defines the `/shepherd-review` workflow: changeset detection, file filtering, priority ordering, overall and per-file context generation, and batch opening all files in a single CRPG session. **All of those requirements apply to mobile unchanged.**

This supplement adds **only** the mobile-specific requirements:

- **Launch mechanism**: Deep link from Buzz Mobile instead of local server spawn
- **Context handoff**: Base64-encoded context data in deep link instead of file-based handoff

## User Stories

### US-SRM-1: Review my branch from my phone
**As a** developer using Buzz Mobile, **I want to** type `/shepherd-review` in the agent conversation and have Shepherd Mobile open with all my changed files ready to review, **so that** I can do code review from my phone while away from my desk.

### US-SRM-2: See agent context on mobile
**As a** mobile user, **I want** the agent's changeset overview and per-file review feedback to appear in the Shepherd Mobile UI just like on desktop, **so that** I have the same context available regardless of platform.

## Requirements

### Launch and Context Handoff

The core workflow (changeset detection, filtering, priority ordering, context generation) is unchanged. Only the handoff mechanism differs.

- **Mobile deep link launch** `FR-srm-deeplink-launch`: After generating the changeset overview and per-file context, the Buzz Mobile agent constructs a deep link containing: the session ID, base64-encoded diff content for each reviewable file, the overall context (neutral + review feedback), and per-file context (neutral + review feedback) keyed by file path. The deep link opens Shepherd Mobile, passing all data via the deep link payload. There is no local server, no file-based handoff — everything is in the deep link.

- **Deep link size limit handling** `FR-srm-deeplink-chunking`: Deep links have platform-specific size limits (iOS ~100KB, Android varies). If the total payload (all files + context) exceeds the limit, the agent must either: (a) split the payload into multiple deep links and launch Shepherd multiple times (one session per chunk), or (b) fall back to a file-based temporary storage mechanism (e.g., writing to a shared app group container on iOS, or using Android's FileProvider). Engineering will define the fallback mechanism. The agent must detect when the payload is too large and handle it gracefully — not silently truncate data or fail with a generic error.

- **Fallback for very large changesets** `FR-srm-large-fallback`: If the changeset is so large that even chunking/fallback mechanisms cannot pass it via deep link (e.g., 50+ files with large diffs), the agent presents the user with a message: "This changeset is too large for mobile review. Consider reviewing on desktop, or filter the changeset (e.g., `/shepherd-review --staged`)." The agent does not attempt to launch Shepherd Mobile in this case.

### Consistency with Desktop

Mobile uses the same CRPG UI as desktop, just launched differently. All existing CRPG features apply.

- **Mobile CRPG launch** `FR-srm-mobile-launch`: When launched via the `/shepherd-review` deep link, Shepherd Mobile opens with all files loaded as tabs, context visible in the collapsible panel (per `FR-crpm-mobile-context`), and the file list ordered by priority (per `FR-sr-priority-ordering` from the shared spec). The user can navigate between files, add comments, and tap "Done" to send the prompt back to Buzz Mobile via deep link callback (per `FR-crpm-deeplink-handoff`).

### Performance

Launching with many files on mobile must not hang the device.

- **Mobile launch time** `NFR-srm-launch-time`: When `/shepherd-review` launches Shepherd Mobile with 10 files, the app must become interactive (first file visible, UI responsive) within 3 seconds. Files are lazy-loaded as needed (per `NFR-crpm-mobile-lazy` from `code-review-prompt`).

## Acceptance Criteria

These are mobile-specific acceptance criteria. See `../shepherd-review.md` for shared acceptance criteria that also apply to mobile.

- [ ] **Deep link launches with all files** `AC-srm-deeplink-files`: When the user invokes `/shepherd-review` in Buzz Mobile, Shepherd Mobile opens with all reviewable files loaded as tabs, in priority order, with context visible.

- [ ] **Context appears in mobile UI** `AC-srm-context-display`: The overall changeset context (neutral + review feedback) is visible in the collapsible context panel. Per-file context is visible when viewing each file.

- [ ] **Large payload chunks** `AC-srm-chunking`: When the changeset payload exceeds the deep link size limit, the agent either chunks it into multiple launches or uses the fallback mechanism, and all files still load correctly in Shepherd Mobile.

- [ ] **Very large changeset blocked** `AC-srm-large-blocked`: When the changeset is too large for mobile (50+ files), the agent shows a clear message explaining the limitation and suggesting desktop review instead of silently failing.

## Open Questions

None at this time.

## Dependencies

- Deep link protocol between Buzz Mobile and Shepherd Mobile (same dependency as `product/mobile/code-review-prompt.md`)
- Fallback mechanism for large payloads (shared app group container on iOS, FileProvider on Android)
