---
product-hash: 4d299d7c5ee2df52aa23e260c53010af4520ba647a834ebf37da560ffd5ea957
product-slugs: [AC-sr-all-filtered, AC-sr-auto-open, AC-sr-batch-open, AC-sr-completion-summary, AC-sr-context-in-crpg, AC-sr-excludes-deleted, AC-sr-filters-binary, AC-sr-filters-generated, AC-sr-filters-lockfiles, AC-sr-happy-path, AC-sr-includes-config, AC-sr-install-global, AC-sr-interactive-prompt, AC-sr-invokes-shepherd, AC-sr-list-command, AC-sr-no-changes, AC-sr-not-git-repo, AC-sr-quit-early, AC-sr-skip-file, AC-sr-sorted-file-list, AC-sr-unified-prompt, FR-sc-session-id, FR-sc-session-scoped-output, FR-sr-changeset-detection, FR-sr-changeset-overview, FR-sr-command-file, FR-sr-completion-summary, FR-sr-context-handoff, FR-sr-feedback-collection, FR-sr-file-filtering, FR-sr-file-list-display, FR-sr-git-required, FR-sr-install, FR-sr-iteration-loop, FR-sr-multi-file-launch, FR-sr-per-file-context, FR-sr-priority-ordering, FR-sr-scope-argument, NFR-sr-agent-native, NFR-sr-cross-platform, NFR-sr-no-dependencies, NFR-sr-startup-speed]
---

# Shepherd Review — Mobile Engineering Spec

> Based on requirements in `../../product/shepherd-review.md`  
> See also `../../product/mobile/shepherd-review.md` for mobile-specific requirements.  
> See also `../../design/mobile/shepherd-review.md` for mobile UI design.

## What We're Building

The mobile launch mechanism for Shepherd Review. When a developer invokes `/shepherd-review` in Buzz Mobile, the agent performs changeset detection and context generation server-side (unchanged), then constructs a deep link payload containing all files and context data. Shepherd Mobile receives the deep link, decodes the payload, and initializes the CRPG (already designed in `code-review-prompt.md`) with all files pre-loaded as tabs. This spec defines the deep link protocol, payload encoding, size limit handling, and launch flow. The CRPG UI itself is out of scope — that's covered in `code-review-prompt.md`.

**Key decision:** Use URL-safe base64-encoded JSON in deep link query parameters, with iOS Universal Link / Android App Link as the transport. Size limit is ~100KB on iOS (lower bound), so payload must be detected and rejected before launch if it exceeds this threshold. Fallback mechanisms (shared app group, FileProvider) are deferred to v2 — v1 fails fast with a clear error message when the changeset is too large.

## Technical Approach

### Deep Link Protocol

Deep link scheme: `shepherd://review`

Query parameters (all URL-safe base64-encoded JSON):
- `session` — Session ID (plain string, not encoded)
- `files` — Array of file objects
- `context` — Overall context object
- `fileContext` — Per-file context object (keyed by file path)

**Example URL structure:**
```
shepherd://review?session=abc123&files=<base64>&context=<base64>&fileContext=<base64>
```

### Payload JSON Schemas

#### Files Array Schema

```typescript
interface FilePayload {
  path: string;           // Relative to repo root
  diff: string;           // Base64-encoded diff content
  changeType: 'added' | 'modified' | 'renamed';
}

type FilesPayload = FilePayload[];
```

#### Context Schema

```typescript
interface OverallContext {
  neutral: string;        // Factual description of changeset
  review: string;         // Agent's review feedback
}
```

#### File Context Schema

```typescript
interface FileContext {
  neutral: string;        // Factual description of this file's changes
  review: string;         // Agent's review feedback for this file
}

type FileContextMap = Record<string, FileContext>;  // Keyed by file path
```

### Payload Encoding

All JSON payloads are:
1. Stringified to JSON
2. UTF-8 encoded
3. Base64-encoded (URL-safe variant: `+` → `-`, `/` → `_`, no padding `=`)
4. Appended as query parameter value

**Buzz Mobile agent encodes.** Shepherd Mobile decodes.

### Size Limit Detection

Before constructing the deep link, Buzz Mobile agent computes the total URL length:
- Base URL: `shepherd://review?`
- `session=<id>` (plain text)
- `&files=<base64>` (encoded files array)
- `&context=<base64>` (encoded overall context)
- `&fileContext=<base64>` (encoded per-file context map)

**Size threshold:** 100KB (102,400 bytes)

If total URL length exceeds threshold:
- **Do NOT launch Shepherd Mobile**
- Display error message in Buzz conversation (per design spec)
- Suggest alternatives (desktop review, `--staged` filter, individual `/shepherd`)

**Requirements satisfied:** `FR-srm-deeplink-chunking`, `FR-srm-large-fallback`, `AC-srm-large-blocked`

### Launch Flow Implementation

**Buzz Mobile side:**
1. Changeset detection, filtering, priority ordering (shared behavior, server-side)
2. Context generation (neutral + review, overall + per-file) (server-side)
3. Construct payload JSON objects
4. Encode each payload to base64
5. Compute total URL length
6. If exceeds 100KB → abort, show error
7. Otherwise → construct deep link URL
8. Display brief summary in Buzz conversation
9. Trigger deep link via `UIApplication.open()` (iOS) or `Intent` (Android)

**Shepherd Mobile side:**
1. Receive deep link via `onOpenURL` (iOS) / `onNewIntent` (Android)
2. Parse URL, extract query parameters
3. Decode each base64 payload to JSON
4. Validate schema (basic sanity check: required fields present)
5. If validation fails → show error alert, do not proceed
6. Otherwise → initialize CRPG with:
   - Files array → tabs (in priority order as received)
   - Session ID → stored for completion callback
   - Overall context → passed to Review Context Drawer
   - Per-file context → passed to Review Context Drawer (keyed by path)
7. Display loading state while decoding (brief, <1s for typical payloads)
8. First file becomes visible as soon as decoded
9. Remaining files lazy-load if needed (per `NFR-crpm-mobile-lazy`)

**Requirements satisfied:** `FR-srm-deeplink-launch`, `FR-srm-mobile-launch`, `NFR-srm-launch-time`

### Progress Indication

For small changesets (≤5 files): Single loading spinner, no progress count.

For larger changesets (6+ files): Show progress count during decode phase:
```
Loading files... 3 / 10
```

Progress updates as each file is decoded. First file displays as soon as it's ready, even if others are still decoding. User can start reviewing immediately.

**Implementation:** Decode files sequentially in background, update progress label on main thread after each file. First file's tab becomes active and visible after first decode completes.

**Requirements satisfied:** Design spec "Large Changeset Load (With Progress)"

### Context Data Handoff

Context is passed as part of the initial deep link payload — no separate file-based handoff, no shared app group container (deferred to v2 when chunking support is added).

The CRPG Review Context Drawer (already implemented in `code-review-prompt.md`) receives:
- Overall neutral context → displayed in "Overall Context" section
- Overall review feedback → displayed in "Overall Context" section (visually distinct)
- Per-file context map → displayed in "File Context" section (updates when file tab changes)

Shepherd Mobile stores this data in memory during the review session. No persistence needed — if app is killed, the session is lost (acceptable for v1; offline persistence is covered by existing CRPG behavior).

**Requirements satisfied:** `FR-sr-context-handoff`, `AC-sr-context-in-crpg`, `AC-srm-context-display`

## Data Model

No new persistent data. All data is ephemeral (lives in memory during the review session).

In-memory state:
- `sessionId: String` — Session ID for completion callback
- `files: [FilePayload]` — Array of file objects with diffs
- `overallContext: OverallContext` — Overall neutral + review context
- `fileContextMap: [String: FileContext]` — Per-file context keyed by path
- `currentFileIndex: Int` — Currently active tab

## Component Architecture

**New components:**

- `DeepLinkHandler` (iOS: `SceneDelegate` / SwiftUI `onOpenURL`, Android: `MainActivity.onNewIntent`)
  - Receives deep link URL
  - Extracts query parameters
  - Decodes base64 payloads
  - Validates schema
  - Dispatches action to load review session

- `ReviewSessionLoader` (TCA Reducer / ViewModel)
  - Accepts decoded payload
  - Initializes CRPG state with files, context, session ID
  - Handles decode errors (shows alert)

- `PayloadDecoder` (Utility)
  - Base64 decoding (URL-safe variant)
  - JSON parsing
  - Schema validation

**Existing components reused:**

- `CodeReviewPromptView` (already exists) — Displays the CRPG UI with tabs, context drawer, comments
- `ReviewContextDrawer` (already exists) — Displays overall + per-file context with neutral/review separation

## Error Handling

### Payload Too Large (Detected by Buzz Mobile)

Buzz Mobile displays error in conversation:
```
This changeset is too large for mobile review (payload exceeds 100KB). 
Try one of these options:
- Review on desktop instead
- Filter the changeset: /shepherd-review --staged
- Review files individually: /shepherd <file>
```

Shepherd Mobile is never launched in this case.

### Invalid Deep Link URL

If deep link URL is malformed or missing required query parameters:
- `PayloadDecoder` returns error
- `ReviewSessionLoader` shows alert: "Invalid review link. Please try again."
- User taps OK → returns to home screen

### Decode Failure

If base64 decoding or JSON parsing fails:
- `PayloadDecoder` returns error
- `ReviewSessionLoader` shows alert: "Failed to load review session. Data may be corrupted."
- User taps OK → returns to home screen

### Missing Required Fields

If decoded JSON is missing required fields (e.g., `path` in a file object):
- `PayloadDecoder` validation returns error
- `ReviewSessionLoader` shows alert: "Invalid review data. Please try again."
- User taps OK → returns to home screen

All error states abort the session — no partial loading. This is acceptable for v1 since the typical case is agent-generated payload, which should always be well-formed.

## Performance Considerations

**Decode speed:** Base64 decoding + JSON parsing is fast (<100ms for typical payloads <50KB). No special optimization needed for v1.

**Lazy loading:** If changeset has 10+ files, decode and store all files initially, but only render the first file's diff view. Remaining diffs render on-demand when user switches tabs. This matches existing CRPG behavior (`NFR-crpm-mobile-lazy`).

**Memory:** Typical changeset (10 files, 500 lines each, diffs ~10KB each) = ~100KB in memory. iOS/Android can handle this easily. No memory pressure concerns for v1. If we add chunking support in v2, we'll need to reconsider.

## Security Considerations

**No sensitive data in deep link.** Session ID is ephemeral (random UUID, single-use). Diffs contain code, which is already in the user's local repo. Context is agent-generated text. No auth tokens, no API keys.

**Deep link validation:** Shepherd Mobile validates the session ID format (UUID) and rejects anything that doesn't match. This prevents injection attacks via malformed session IDs.

**No external data fetch.** All data comes from the deep link payload. No network requests during launch. This eliminates MITM concerns.

## Implementation Plan

1. **Define payload schemas in TypeScript** — Create `ReviewPayload.ts` with interfaces matching the schemas above. Export `FilePayload`, `OverallContext`, `FileContext`, and `FileContextMap` types. This provides type safety for both encoding (Buzz Mobile) and decoding (Shepherd Mobile).

2. **Implement `PayloadDecoder` utility** — Create `PayloadDecoder.swift` (iOS) / `PayloadDecoder.kt` (Android) with methods:
   - `decodeBase64URL(String) -> Data` — URL-safe base64 decode
   - `parseJSON<T>(Data) -> T` — Generic JSON parsing
   - `validateFiles([FilePayload])` — Check required fields present
   - `validateContext(OverallContext)` — Check required fields present
   Returns `Result<T, Error>` for error handling.

3. **Add deep link handler to app delegate / scene delegate** — Register `shepherd://review` URL scheme in `Info.plist` (iOS) / `AndroidManifest.xml` (Android). Implement `onOpenURL` / `onNewIntent` to extract query parameters and pass to `ReviewSessionLoader`.

4. **Implement `ReviewSessionLoader`** — TCA reducer (iOS) / ViewModel (Android) that:
   - Accepts decoded payload
   - Initializes CRPG state (files array, session ID, context data)
   - Triggers navigation to `CodeReviewPromptView`
   - Handles decode/validation errors (shows alert)
   Integrates with existing CRPG reducer/viewmodel.

5. **Update CRPG to accept initial payload** — Modify `CodeReviewPromptView` initialization to accept optional pre-loaded files and context data. If present, skip the usual single-file initialization and load all files as tabs. This is the integration point between the new launch flow and the existing CRPG.

6. **Add progress indicator for large payloads** — In `ReviewSessionLoader`, track decode progress (files decoded / total files) and update a `@Published` / `LiveData` property. Bind this to a loading view that shows "Loading files... X / Y". First file displays as soon as it's ready.

7. **Update Buzz Mobile agent to construct payload** — This is Buzz-side work, not Shepherd work, but noted here for completeness. Agent needs to encode payloads, compute URL length, check against 100KB threshold, and construct deep link URL. Reject if too large.

## Code Map

| Slug | Planned location | Status |
|---|---|---|
| FR-srm-deeplink-launch | apps/mobile/Shared/DeepLinkHandler.swift:10-50 | planned |
| FR-srm-deeplink-chunking | — | unimplemented |
| FR-srm-large-fallback | apps/mobile/Shared/ReviewSessionLoader.swift:60-75 | planned |
| FR-srm-mobile-launch | apps/mobile/Shared/ReviewSessionLoader.swift:20-45 | planned |
| NFR-srm-launch-time | apps/mobile/Shared/PayloadDecoder.swift:15-80; apps/mobile/Shared/ReviewSessionLoader.swift:30-40 | planned |
| AC-srm-deeplink-files | apps/mobile/Shared/ReviewSessionLoader.swift:25-30 | planned |
| AC-srm-context-display | apps/mobile/Features/CodeReview/ReviewContextDrawer.swift:40-60 | planned |
| AC-srm-chunking | — | unimplemented |
| AC-srm-large-blocked | apps/mobile/Shared/ReviewSessionLoader.swift:65-72 | planned |

**Note:** `FR-srm-deeplink-chunking` and `AC-srm-chunking` are explicitly `unimplemented` in v1. These require fallback mechanisms (shared app group, FileProvider) that are deferred. The audit will not flag these as missing coverage.

## Open Questions

None at this time. The deep link protocol is straightforward, and the CRPG UI already exists. Chunking/fallback support is deferred to v2, with a clear error path defined for v1.
