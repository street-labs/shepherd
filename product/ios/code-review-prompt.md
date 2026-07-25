# Code Review Prompt Generator — iOS Platform

> iOS-specific requirements for the CRPG. See `../code-review-prompt.md` for shared requirements.
> See also `../shepherd-review.md` and `./shepherd-review.md` for the patch review and thread-publishing behavior that is the iOS entry point.

## Shared Requirements — Applicability on iOS

The iOS variant is a port of the macOS native app to iPhone and iPad. Its content does not come from the local filesystem; it comes from an in-app opened NIP-34 patch (see `./shepherd-review.md`, In-app patch open). The reviewing and commenting surface itself is unchanged in behavior.

### Apply as-is (no iOS-specific changes needed)

The following shared requirements apply identically on iOS. The commenting, prompt-generation, and file-navigation behavior is platform-neutral:

- `FR-crp-file-display` — Display file with line numbers
- `FR-crp-line-wrap` — Toggle line wrapping in the code viewer
- `FR-crp-syntax-highlight` — Syntax highlighting
- `FR-crp-line-comment-create` — Create an inline comment
- `FR-crp-line-comment-edit` — Edit an existing comment
- `FR-crp-line-comment-delete` — Delete a comment
- `FR-crp-comment-indicator` — Visual indicators for commented lines
- `FR-crp-comment-count` — Display total comment count
- `FR-crp-prompt-preamble` — Overall Comment
- `FR-crp-prompt-generate` — Automatically generated aggregated prompt
- `FR-crp-prompt-preview` — Live prompt preview
- `FR-crp-prompt-copy` — Copy prompt to clipboard
- `FR-crp-prompt-format` — Structured prompt format
- `FR-crp-clear-session` — Clear / reset session
- `FR-crp-filename-display` — Display file name
- `FR-crp-line-range-comment` — Comment on a range of lines
- `FR-crp-comment-navigation` — Navigate between comments
- `FR-crp-multi-file-nav` — Navigate between loaded files (the patch's changed files are the tabs)
- `FR-crp-multi-file-remove` — Remove a file from the session
- `FR-crp-multi-file-prompt` — Combined multi-file prompt generation
- `FR-crp-multi-file-prompt-format` — Multi-file prompt format
- `FR-crp-review-context-receive` — Receive context data (graceful when absent; see modified)
- `FR-crp-review-context-display` — Display review context (shown only when present)
- `FR-crp-review-context-overall` — Display overall changeset context
- `FR-crp-review-context-per-file` — Display per-file context
- `FR-crp-review-context-collapsible` — Collapsible review context
- `FR-crp-comment-summary` — All Comments summary view
- `FR-crp-active-file-path` — Display active file path at top of code viewer
- `FR-crp-file-tooltip` — File row detail reveal with full path and metadata
- `FR-crp-file-reviewed-toggle` — Mark/unmark a file as reviewed
- `FR-crp-file-reviewed-visual` — Visual distinction for reviewed files
- `FR-crp-file-reviewed-grouping` — Review status within the directory tree
- `FR-crp-file-reviewed-progress` — Review progress indicator
- `FR-crp-file-reviewed-persistence` — Review status session persistence
- `NFR-crp-large-file-perf` — Large file performance
- `NFR-crp-render-time` — Initial render time
- `NFR-crp-prompt-gen-time` — Prompt generation time
- `NFR-crp-client-only` — Client-side only architecture (data leaves the device only as published patch-thread replies; see `./shepherd-review.md`)
- `NFR-crp-no-data-persistence` — No data persistence requirement

### Modified on iOS

- **`FR-crp-file-load`** — Does not apply in its shared form. On iOS the CRPG loads content from an in-app opened NIP-34 patch rather than from local files. See `FR-crp-ios-patch-only-entry`.
- **`FR-crp-multi-file-load`** — Multiple files come from a single opened patch (one tab per changed file in the patch's diff). The reviewer does not load additional files into the session beyond what the patch contains. See `FR-sri-patch-open-load` in `./shepherd-review.md`.
- **`FR-crp-done-action`** — Does not apply in its shared form. There is no local server and no terminal AI agent to hand a prompt back to. The reviewer's comments are published to the patch thread instead (see `./shepherd-review.md`). The Copy action remains as the local-export path.
- **`FR-crp-prompt-handoff`** — Does not apply. No local server handoff exists on iOS.
- **`FR-crp-session-identity`** — Does not apply in its shared form. There is no slash-command session id or working-directory title. The window context is the opened patch (author, message, short event id); see `FR-sri-patch-open-load` and `FR-sr-patch-metadata-display`.
- **`FR-crp-panel-resize`** — Does not apply in its shared form (user-drag panel resizing is not a touch interaction). The file browser and code viewer layout adapts to the form factor instead. See `FR-crp-ios-adaptive-layout`.
- **`NFR-crp-accessibility-keyboard`** — Modified. Core workflows are achievable via the platform's assistive technology (e.g. VoiceOver) and an attached keyboard when present, rather than keyboard-only operation as on desktop.
- **`FR-crp-review-context-receive`** (in practice) — For an in-app opened patch there is no agent-generated neutral/review context (no LLM runs in this path), so per-file review context is simply absent and the context panel hides per the graceful-missing contract. The requirement applies as-is; this note records why context is usually absent on iOS.

### Do not apply on iOS

- **`NFR-crp-browser-support`** — Not applicable. This is a native application, not browser-based.
- **`NFR-crp-responsive-layout`** — Not applicable. Replaced by `FR-crp-ios-adaptive-layout` (native adaptive layout, not a variable browser display width).
- **`FR-sc-file-api`** — Not applicable. No local server serves files.
- **`FR-sc-session-id`** — Not applicable in its shared form. There is no slash-command session routing.

## iOS-Specific Functional Requirements

### Entry and content source

#### `FR-crp-ios-patch-only-entry` — Content comes from an opened NIP-34 patch
The iOS CRPG's only content source is an in-app opened NIP-34 patch event. The reviewer does not paste text, upload files, or drag files into the app. The empty state exposes the patch-open entry point (see `./shepherd-review.md`, In-app patch open); on success the patch's changed files become the review tabs. This scoping is deliberate: local file review is the macOS workflow, and the iOS value is reviewing and commenting on patches received over Nostr while away from a machine.

### Layout and platform integration

#### `FR-crp-ios-adaptive-layout` — Review layout adapts to iPhone and iPad form factors
The review layout adapts to the available screen size. On compact widths (iPhone) the file browser and code viewer collapse to a single focused pane with navigation between them; on expanded widths (iPad) the file browser and code viewer are shown together. The layout choice is automatic from the current size class and reflows when the size changes (e.g. rotation, Split View). All review capabilities — file navigation, commenting, comment summary, prompt preview, patch thread — remain reachable on both form factors. The specific arrangement is a design decision.

#### `FR-crp-ios-system-appearance` — Appearance follows the system setting
The application follows the device's system appearance setting (light or dark) automatically and updates when the system setting changes, with no in-app appearance toggle.

#### `FR-crp-ios-clipboard` — Native clipboard integration
Copy operations use the system clipboard. The "Copy Prompt" action places the prompt text on the system clipboard, available to other apps.

#### `FR-crp-ios-background-handoff` — Backgrounding does not lose in-progress comments
When the app is backgrounded and resumed (without being terminated), the in-memory session — loaded patch files, comments, and preamble — is preserved. Consistent with `NFR-crp-no-data-persistence`, a full termination (the OS reclaiming the app) may lose unsaved state; backgrounding alone must not.

## iOS-Specific Non-Functional Requirements

#### `NFR-crp-ios-min-version` — Minimum iOS version
The application requires iOS 17 or later. Users on earlier versions cannot run it and are informed clearly.

#### `NFR-crp-ios-launch-time` — Application launch time
The application must launch and be ready for interaction within 1.5 seconds from a cold start.

#### `NFR-crp-ios-memory` — Memory usage
The application must use less than 200 MB of RAM for a typical patch review (a patch with up to 10 changed files and 50 comments). Idle memory (no patch loaded) must be under 80 MB.

## iOS-Specific Acceptance Criteria

- [ ] **Patch is the only content source** `AC-crp-ios-patch-only-entry`: Given the app is in its empty state, then the only way to load content is opening a NIP-34 patch; pasting text, uploading, or dragging files is not offered and does not load content.
- [ ] **Layout adapts to form factor** `AC-crp-ios-adaptive-layout`: Given the app runs on iPhone, then the file browser and code viewer present as a single focused pane with navigation between them; given the app runs on iPad, then both are shown together; and rotating or changing size class reflows the layout without losing state.
- [ ] **Appearance follows system** `AC-crp-ios-system-appearance`: Given the device is in dark mode, then the app renders dark; when the user switches the system to light, then the app updates without restarting; and there is no in-app appearance toggle.
- [ ] **Copy uses system clipboard** `AC-crp-ios-clipboard`: Given comments exist and the user copies the prompt, then the prompt text is on the system clipboard and available to other apps.
- [ ] **Backgrounding preserves session** `AC-crp-ios-background-handoff`: Given a patch review is open with comments, when the user backgrounds the app and resumes it, then the loaded files and comments are still present.
- [ ] **Minimum version enforced** `AC-crp-ios-min-version`: Given a device running iOS 16, then the app does not run and informs the user; given iOS 17+, then it launches normally.

## Open Questions

1. **Paste-from-clipboard as a secondary entry**: The shared `FR-crp-file-load` paste path is scoped out for v1. Should the iOS empty state also accept pasted file content as a fallback for ad-hoc review without a patch? Deferred — the patch-open entry is the focus; paste can be revisited if reviewers ask for it.

2. **Persistence across termination**: `NFR-crp-no-data-persistence` is inherited as-is (in-memory only). iOS apps are frequently terminated by the OS in the background. Should the iOS variant persist the in-progress review to restore after termination? Deferred to roadmap; v1 keeps the shared no-persistence scope.

3. **Diff-as-tabs vs full-file view**: Same open question as the macOS in-app path (`../macos/shepherd-review.md` Open Question 4). v1 ships the diff-as-tabs view (one tab per changed file, content is that file's diff block). Full-file reconstruction is a shared roadmap item (`../../roadmap/patch-watcher.md`).

## Dependencies

- Shared CRPG requirements (`../code-review-prompt.md`) — commenting, prompt generation, file navigation.
- iOS shepherd-review requirements (`./shepherd-review.md`) — in-app patch open, patch metadata, live patch thread, and reply publishing, which are the iOS entry point and the output path for comments.
- Shared shepherd-review patch-thread requirements (`../shepherd-review.md`) — patch metadata display, live replies, reply publishing contracts the iOS variant reuses.
