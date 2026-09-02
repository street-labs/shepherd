---
product-hash: 355368b5aabc0322e5d807625fd9c99326660d646f1a834bd1454d3c4ff06d2e
product-slugs: [AC-crp-active-file-path-single-file, AC-crp-active-file-path-switches, AC-crp-active-file-path-visible, AC-crp-add-comment-line-range, AC-crp-add-comment-single-line, AC-crp-binary-file-rejected, AC-crp-clear-confirmation, AC-crp-clear-no-confirm-empty, AC-crp-comment-navigation-next, AC-crp-comment-summary-empty, AC-crp-comment-summary-realtime, AC-crp-comment-summary-shows-all, AC-crp-context-graceful-missing, AC-crp-context-neutral-vs-review, AC-crp-context-overall-visible, AC-crp-context-per-file-switches, AC-crp-context-per-file-visible, AC-crp-context-readonly, AC-crp-context-sidebar-collapse, AC-crp-copy-clipboard, AC-crp-delete-comment, AC-crp-done-auto-close, AC-crp-done-confirmation, AC-crp-done-disabled-no-comments, AC-crp-done-fallback-clipboard, AC-crp-done-sends-prompt, AC-crp-done-standalone-hidden, AC-crp-edit-comment, AC-crp-empty-state, AC-crp-file-mark-reviewed, AC-crp-file-path-display, AC-crp-file-path-single-dir, AC-crp-file-reviewed-clear-session, AC-crp-file-reviewed-grouping, AC-crp-file-reviewed-progress-count, AC-crp-file-reviewed-survives-tab-switch, AC-crp-file-reviewed-with-comments, AC-crp-file-tooltip-full-path, AC-crp-file-tooltip-reviewed, AC-crp-file-unmark-reviewed, AC-crp-generate-prompt-no-comments, AC-crp-generate-prompt-structure, AC-crp-keyboard-add-comment, AC-crp-large-file-scroll, AC-crp-line-wrap-comment-target, AC-crp-line-wrap-default-on, AC-crp-line-wrap-persists-session, AC-crp-line-wrap-preserves-line-numbers, AC-crp-line-wrap-toggle, AC-crp-load-drag-drop, AC-crp-load-paste, AC-crp-load-upload, AC-crp-multi-file-clear-all, AC-crp-multi-file-comment-count, AC-crp-multi-file-drop-multiple, AC-crp-multi-file-empty-after-remove-last, AC-crp-multi-file-load-adds, AC-crp-multi-file-nav-preserves-state, AC-crp-multi-file-prompt-omits-uncommented, AC-crp-multi-file-prompt-structure, AC-crp-multi-file-remove-no-comments, AC-crp-multi-file-remove-with-comments, AC-crp-overall-comment-in-prompt, AC-crp-overall-comment-label, AC-crp-panel-resize-bounds, AC-crp-panel-resize-double-click, AC-crp-panel-resize-drag, AC-crp-panel-resize-keyboard, AC-crp-panel-resize-persists, AC-crp-preview-matches-copy, AC-crp-syntax-highlight-detected, FR-crp-active-file-path, FR-crp-clear-session, FR-crp-comment-count, FR-crp-comment-indicator, FR-crp-comment-navigation, FR-crp-comment-summary, FR-crp-done-action, FR-crp-file-display, FR-crp-file-load, FR-crp-file-reviewed-grouping, FR-crp-file-reviewed-persistence, FR-crp-file-reviewed-progress, FR-crp-file-reviewed-toggle, FR-crp-file-reviewed-visual, FR-crp-file-tooltip, FR-crp-filename-display, FR-crp-line-comment-create, FR-crp-line-comment-delete, FR-crp-line-comment-edit, FR-crp-line-range-comment, FR-crp-line-wrap, FR-crp-multi-file-load, FR-crp-multi-file-nav, FR-crp-multi-file-prompt, FR-crp-multi-file-prompt-format, FR-crp-multi-file-remove, FR-crp-panel-resize, FR-crp-prompt-copy, FR-crp-prompt-format, FR-crp-prompt-generate, FR-crp-prompt-handoff, FR-crp-prompt-preamble, FR-crp-prompt-preview, FR-crp-review-context-collapsible, FR-crp-review-context-display, FR-crp-review-context-overall, FR-crp-review-context-per-file, FR-crp-review-context-receive, FR-crp-session-identity, FR-crp-syntax-highlight, FR-sc-file-api, FR-sc-session-id, NFR-crp-accessibility-keyboard, NFR-crp-browser-support, NFR-crp-client-only, NFR-crp-large-file-perf, NFR-crp-no-data-persistence, NFR-crp-prompt-gen-time, NFR-crp-render-time, NFR-crp-responsive-layout]
---
# Code Review Prompt Generator — iOS Test Plan

> Based on requirements in `../../product/code-review-prompt.md`
> See also `../../product/ios/code-review-prompt.md` for iOS-specific requirements.
> Based on design in `../../design/ios/code-review-prompt.md`
> Based on engineering in `../../engineering/ios/code-review-prompt.md`

## What We're Testing

The iOS presentation of the CRPG review surface on iPhone and iPad: the adaptive layout, the patch-only entry scoping, commenting on a loaded patch's diff tabs, prompt preview/copy, file navigation + reviewed tracking, and iOS platform integration (system appearance, clipboard, backgrounding, accessibility). The patch-open entry and patch-thread publishing are covered in `./shepherd-review.md`; this plan covers the CRPG review surface once a patch is loaded, plus the iOS-specific divergences from the shared spec.

The shared CRPG acceptance criteria that apply unchanged on iOS (commenting, prompt generation, file nav, reviewed tracking) are tested here against the iOS UI; the macOS- and web-only criteria are out of scope.

## Test Approach

- **Automated (Swift Testing + TCA `TestStore`)**: reducer logic that is platform-agnostic — prompt generation (`PromptBuilder`), comment create/edit/delete, file-tree grouping, reviewed-toggle state, clear-session confirmation gating, comment navigation ordering. These reuse the macOS feature-module tests where the modules are shared.
- **Automated (unit)**: `PatchParser` per-file splitting (cross-ref `./shepherd-review.md`), adaptive-layout size-class selection logic.
- **Manual (iPhone + iPad, iOS 17+)**: layout reflow across form factors and rotation, touch interactions (tap-to-comment, long-press-drag range), VoiceOver, Dynamic Type, system appearance, background/resume, clipboard to another app.

## Coverage Matrix

### iOS-Specific Acceptance Criteria

| Requirement | Test Cases | Status |
|---|---|---|
| `AC-crp-ios-patch-only-entry` | `TC-crp-ios-patch-only-entry` | Not started |
| `AC-crp-ios-adaptive-layout` | `TC-crp-ios-adaptive-iphone`, `TC-crp-ios-adaptive-ipad`, `TC-crp-ios-adaptive-rotation` | Not started |
| `AC-crp-ios-system-appearance` | `TC-crp-ios-appearance-system`, `TC-crp-ios-no-appearance-toggle` | Not started |
| `AC-crp-ios-clipboard` | `TC-crp-ios-copy-clipboard` | Not started |
| `AC-crp-ios-background-handoff` | `TC-crp-ios-background-resume` | Not started |
| `AC-crp-ios-min-version` | `TC-crp-ios-min-version` | Not started |

### Shared Acceptance Criteria realized on iOS

| Requirement | Test Cases | Status |
|---|---|---|
| `AC-crp-add-comment-single-line` | `TC-crp-ios-comment-single-line` | Not started |
| `AC-crp-add-comment-line-range` | `TC-crp-ios-comment-line-range` | Not started |
| `AC-crp-edit-comment` | `TC-crp-ios-comment-edit` | Not started |
| `AC-crp-delete-comment` | `TC-crp-ios-comment-delete` | Not started |
| `AC-crp-comment-navigation-next` | `TC-crp-ios-comment-nav` | Not started |
| `AC-crp-generate-prompt-structure` | `TC-crp-ios-prompt-structure` | Not started |
| `AC-crp-generate-prompt-no-comments` | `TC-crp-ios-prompt-empty` | Not started |
| `AC-crp-copy-clipboard` | `TC-crp-ios-copy-clipboard` | Not started |
| `AC-crp-preview-matches-copy` | `TC-crp-ios-preview-matches-copy` | Not started |
| `AC-crp-multi-file-nav-preserves-state` | `TC-crp-ios-file-switch-preserves` | Not started |
| `AC-crp-multi-file-remove-with-comments` | `TC-crp-ios-remove-file-confirm` | Not started |
| `AC-crp-file-mark-reviewed` / `AC-crp-file-unmark-reviewed` | `TC-crp-ios-reviewed-toggle` | Not started |
| `AC-crp-file-reviewed-survives-tab-switch` | `TC-crp-ios-reviewed-survives-switch` | Not started |
| `AC-crp-file-reviewed-progress-count` | `TC-crp-ios-reviewed-progress` | Not started |
| `AC-crp-clear-confirmation` / `AC-crp-clear-no-confirm-empty` | `TC-crp-ios-clear-confirm` | Not started |
| `AC-crp-empty-state` | `TC-crp-ios-empty-state` | Not started |
| `AC-crp-line-wrap-default-on` / `AC-crp-line-wrap-toggle` | `TC-crp-ios-line-wrap` | Not started |
| `AC-crp-syntax-highlight-detected` | `TC-crp-ios-syntax-highlight` | Not started |
| `AC-crp-comment-summary-shows-all` | `TC-crp-ios-comment-summary` | Not started |
| `AC-crp-overall-comment-label` | `TC-crp-ios-overall-comment-label` | Not started |
| `AC-crp-active-file-path-visible` | `TC-crp-ios-active-file-path` | Not started |
| `AC-crp-file-tooltip-full-path` | `TC-crp-ios-file-tooltip` | Not started |

## Test Cases

### iOS-specific

#### `TC-crp-ios-patch-only-entry` — Patch is the only content source (Manual)
1. Launch the app to the empty state.
2. Attempt to paste text, upload, or drag a file.
- **Expected**: No paste/upload/drag affordance is present; none of these load content. The only entry is `Open Patch`. (`AC-crp-ios-patch-only-entry`)

#### `TC-crp-ios-adaptive-iphone` — Compact layout (Manual, iPhone)
1. Open a patch with ≥3 changed files on iPhone (portrait).
- **Expected**: A single focused code-viewer pane with a file switcher; inspector surfaces are detail screens reached via a bottom segmented control. All review capabilities reachable. (`AC-crp-ios-adaptive-layout`)

#### `TC-crp-ios-adaptive-ipad` — Expanded layout (Manual, iPad)
1. Open the same patch on iPad full-screen.
- **Expected**: Three columns — file browser (left), code viewer (center), inspector (right) — visible together. (`AC-crp-ios-adaptive-layout`)

#### `TC-crp-ios-adaptive-rotation` — Reflow preserves state (Manual)
1. Open a patch, add comments on two files, mark one reviewed, on iPad.
2. Rotate the device (or drag a Split View divider) to change the size class.
- **Expected**: The layout reflows between compact and expanded; all files, comments, reviewed flags, and the preamble are preserved. (`AC-crp-ios-adaptive-layout`)

#### `TC-crp-ios-appearance-system` — Appearance follows system (Manual)
1. Set the device to dark mode; launch the app.
2. Switch the system to light mode while the app is running.
- **Expected**: The app renders dark initially and updates to light without restarting. (`AC-crp-ios-system-appearance`)

#### `TC-crp-ios-no-appearance-toggle` — No in-app appearance toggle (Manual)
1. Search the app's settings and UI for an appearance/theme toggle.
- **Expected**: None exists. (`AC-crp-ios-system-appearance`)

#### `TC-crp-ios-copy-clipboard` — Copy uses system clipboard (Manual)
1. Open a patch, add a comment, open the Prompt inspector surface, tap **Copy**.
2. Switch to another app and paste.
- **Expected**: The pasted text matches the prompt preview; a `Copied` confirmation appeared. (`AC-crp-ios-clipboard`, `AC-crp-copy-clipboard`, `AC-crp-preview-matches-copy`)

#### `TC-crp-ios-background-resume` — Backgrounding preserves session (Manual)
1. Open a patch with comments; background the app (Home button/gesture).
2. Resume the app.
- **Expected**: The loaded files and comments are still present. (`AC-crp-ios-background-handoff`)

#### `TC-crp-ios-min-version` — Minimum version enforced (Manual)
1. Attempt to launch on an iOS 16 device/simulator.
- **Expected**: The app does not run and informs the user. On iOS 17+, it launches normally. (`AC-crp-ios-min-version`)

### Shared CRPG behavior on iOS

#### `TC-crp-ios-comment-single-line` — Add a single-line comment (Automated reducer + Manual)
1. Tap a line number in the diff viewer; type "Fix this"; save.
- **Expected**: A comment bubble appears anchored to the line; the gutter shows an indicator; the comment count increments. (`AC-crp-add-comment-single-line`)

#### `TC-crp-ios-comment-line-range` — Comment on a line range (Manual)
1. Long-press-drag to select lines 10–15; add "Extract this".
- **Expected**: The comment is anchored to 10–15; gutter indicators span the range; the prompt references 10–15. (`AC-crp-add-comment-line-range`)

#### `TC-crp-ios-comment-edit` / `TC-crp-ios-comment-delete` — Edit and delete (Automated reducer + Manual)
1. Edit an existing comment's text; delete another.
- **Expected**: Edit updates in place; delete removes the bubble and indicator (if last on the line) and decrements the count. (`AC-crp-edit-comment`, `AC-crp-delete-comment`)

#### `TC-crp-ios-comment-nav` — Next/previous comment navigation (Manual)
1. With comments on lines 5, 20, 100, use next-comment.
- **Expected**: The viewer scrolls to and highlights each in order, wrapping last→first. (`AC-crp-comment-navigation-next`)

#### `TC-crp-ios-prompt-structure` — Prompt structure (Automated, `PromptBuilder`)
1. Load a patch with comments on lines 3, 10–12, 25; set an Overall Comment.
- **Expected**: The prompt has an Instructions section (overall comment), a File heading per file with comments, and a Requested Changes section with each comment paired with its code snippet in source order; uncommented files omitted. (`AC-crp-generate-prompt-structure`, `AC-crp-multi-file-prompt-omits-uncommented`)

#### `TC-crp-ios-prompt-empty` — No prompt when no comments (Automated)
1. Load a patch with no comments.
- **Expected**: The prompt preview shows a placeholder; the prompt value is empty. Adding a comment generates it; deleting the last comment clears it. (`AC-crp-generate-prompt-no-comments`)

#### `TC-crp-ios-file-switch-preserves` — Switching files preserves state (Manual)
1. With two files loaded, add comments to file A, switch to B, switch back.
- **Expected**: A's comments and reviewed state are intact. (`AC-crp-multi-file-nav-preserves-state`)

#### `TC-crp-ios-remove-file-confirm` — Remove a file with comments confirms (Manual)
1. Remove a file that has comments.
- **Expected**: A confirmation is shown; on confirm the file and its comments are removed. Removing a file without comments does not confirm. (`AC-crp-multi-file-remove-with-comments`, `AC-crp-multi-file-remove-no-comments`)

#### `TC-crp-ios-reviewed-toggle` — Mark/unmark reviewed (Automated reducer + Manual)
1. Toggle a file's reviewed status; verify the visual marker.
- **Expected**: A checkmark/dim treatment appears; toggling again clears it. Reachable without leaving the current file. (`AC-crp-file-mark-reviewed`, `AC-crp-file-unmark-reviewed`)

#### `TC-crp-ios-reviewed-survives-switch` — Reviewed survives tab switch (Automated reducer)
1. Mark a file reviewed; switch files; switch back.
- **Expected**: The reviewed state persists across switches. (`AC-crp-file-reviewed-survives-tab-switch`)

#### `TC-crp-ios-reviewed-progress` — Progress indicator (Manual)
1. With 5 files loaded, mark 2 reviewed.
- **Expected**: A `2/5 reviewed` indicator is visible and updates immediately on each toggle. (`AC-crp-file-reviewed-progress-count`)

#### `TC-crp-ios-clear-confirm` — Clear session confirmation (Automated reducer + Manual)
1. With comments present, clear the session; confirm. Then clear again with no comments.
- **Expected**: Confirmation shown when comments exist; immediate clear when empty; returns to the empty state. (`AC-crp-clear-confirmation`, `AC-crp-clear-no-confirm-empty`)

#### `TC-crp-ios-empty-state` — Empty state shows how to start (Manual)
1. Launch with no patch.
- **Expected**: The empty state shows the `Open Patch` call-to-action (the iOS empty-state instructions). (`AC-crp-empty-state`, adapted)

#### `TC-crp-ios-line-wrap` — Line wrap default on and toggleable (Manual)
1. Open a patch with a long line; toggle wrapping.
- **Expected**: Wrapping is on by default; toggling off enables horizontal scroll; the line number appears once per logical line; wrap state persists across file switches. (`AC-crp-line-wrap-default-on`, `AC-crp-line-wrap-toggle`, `AC-crp-line-wrap-preserves-line-numbers`, `AC-crp-line-wrap-persists-session`)

#### `TC-crp-ios-syntax-highlight` — Syntax highlighting applies (Manual)
1. Open a patch containing a TypeScript file.
- **Expected**: Keywords, strings, and comments are syntax-colored. (`AC-crp-syntax-highlight-detected`)

#### `TC-crp-ios-comment-summary` — All Comments summary (Automated + Manual)
1. With comments across two files, open the Comments inspector surface.
- **Expected**: Every comment is listed grouped by file with its line/range and text; empty state shows when no comments. (`AC-crp-comment-summary-shows-all`, `AC-crp-comment-summary-empty`)

#### `TC-crp-ios-overall-comment-label` — Overall Comment label (Manual)
1. Inspect the preamble field label.
- **Expected**: The label reads "Overall Comment". (`AC-crp-overall-comment-label`)

#### `TC-crp-ios-active-file-path` — Active file path shown (Manual)
1. With multiple files loaded, note the path display; switch files.
- **Expected**: The full path of the active file is shown atop the code viewer and updates on switch. (`AC-crp-active-file-path-visible`, `AC-crp-active-file-path-switches`)

#### `TC-crp-ios-file-tooltip` — File row detail reveal (Manual)
1. Long-press a file row in the file browser/switcher.
- **Expected**: The full untruncated path, detected language, and reviewed state are revealed. (`AC-crp-file-tooltip-full-path`, `AC-crp-file-tooltip-reviewed`)

## Out of Scope

- macOS-only criteria (`AC-crp-macos-*`): window management, menu bar, Finder drag-drop, file open panel, auto-close, session-directory launch.
- Web-only criteria (`NFR-crp-browser-support`, `NFR-crp-responsive-layout`).
- Shared load criteria not applicable on iOS (no local file loading): `AC-crp-load-paste`, `AC-crp-load-upload`, `AC-crp-load-drag-drop`, `AC-crp-multi-file-drop-multiple`.
- `AC-crp-done-*`: no local server / no Done handoff on iOS.
- Patch-open and patch-thread publishing: `./shepherd-review.md`.
