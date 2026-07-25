---
product-hash: 79cd3657d1229c6903ee9652d107c23493af4ce8c70046a4724c05da34c4fc0c
product-slugs: [AC-crp-active-file-path-single-file, AC-crp-active-file-path-switches, AC-crp-active-file-path-visible, AC-crp-add-comment-line-range, AC-crp-add-comment-single-line, AC-crp-binary-file-rejected, AC-crp-clear-confirmation, AC-crp-clear-no-confirm-empty, AC-crp-comment-navigation-next, AC-crp-comment-summary-empty, AC-crp-comment-summary-realtime, AC-crp-comment-summary-shows-all, AC-crp-context-graceful-missing, AC-crp-context-neutral-vs-review, AC-crp-context-overall-visible, AC-crp-context-per-file-switches, AC-crp-context-per-file-visible, AC-crp-context-readonly, AC-crp-context-sidebar-collapse, AC-crp-copy-clipboard, AC-crp-delete-comment, AC-crp-done-auto-close, AC-crp-done-confirmation, AC-crp-done-disabled-no-comments, AC-crp-done-fallback-clipboard, AC-crp-done-sends-prompt, AC-crp-done-standalone-hidden, AC-crp-edit-comment, AC-crp-empty-state, AC-crp-file-mark-reviewed, AC-crp-file-path-display, AC-crp-file-path-single-dir, AC-crp-file-reviewed-clear-session, AC-crp-file-reviewed-grouping, AC-crp-file-reviewed-progress-count, AC-crp-file-reviewed-survives-tab-switch, AC-crp-file-reviewed-with-comments, AC-crp-file-tooltip-full-path, AC-crp-file-tooltip-reviewed, AC-crp-file-unmark-reviewed, AC-crp-generate-prompt-no-comments, AC-crp-generate-prompt-structure, AC-crp-keyboard-add-comment, AC-crp-large-file-scroll, AC-crp-line-wrap-comment-target, AC-crp-line-wrap-default-on, AC-crp-line-wrap-persists-session, AC-crp-line-wrap-preserves-line-numbers, AC-crp-line-wrap-toggle, AC-crp-load-drag-drop, AC-crp-load-paste, AC-crp-load-upload, AC-crp-multi-file-clear-all, AC-crp-multi-file-comment-count, AC-crp-multi-file-drop-multiple, AC-crp-multi-file-empty-after-remove-last, AC-crp-multi-file-load-adds, AC-crp-multi-file-nav-preserves-state, AC-crp-multi-file-prompt-omits-uncommented, AC-crp-multi-file-prompt-structure, AC-crp-multi-file-remove-no-comments, AC-crp-multi-file-remove-with-comments, AC-crp-overall-comment-in-prompt, AC-crp-overall-comment-label, AC-crp-panel-resize-bounds, AC-crp-panel-resize-double-click, AC-crp-panel-resize-drag, AC-crp-panel-resize-keyboard, AC-crp-panel-resize-persists, AC-crp-preview-matches-copy, AC-crp-syntax-highlight-detected, FR-crp-active-file-path, FR-crp-clear-session, FR-crp-comment-count, FR-crp-comment-indicator, FR-crp-comment-navigation, FR-crp-comment-summary, FR-crp-done-action, FR-crp-file-display, FR-crp-file-load, FR-crp-file-reviewed-grouping, FR-crp-file-reviewed-persistence, FR-crp-file-reviewed-progress, FR-crp-file-reviewed-toggle, FR-crp-file-reviewed-visual, FR-crp-file-tooltip, FR-crp-filename-display, FR-crp-line-comment-create, FR-crp-line-comment-delete, FR-crp-line-comment-edit, FR-crp-line-range-comment, FR-crp-line-wrap, FR-crp-multi-file-load, FR-crp-multi-file-nav, FR-crp-multi-file-prompt, FR-crp-multi-file-prompt-format, FR-crp-multi-file-remove, FR-crp-panel-resize, FR-crp-prompt-copy, FR-crp-prompt-format, FR-crp-prompt-generate, FR-crp-prompt-handoff, FR-crp-prompt-preamble, FR-crp-prompt-preview, FR-crp-review-context-collapsible, FR-crp-review-context-display, FR-crp-review-context-overall, FR-crp-review-context-per-file, FR-crp-review-context-receive, FR-crp-session-identity, FR-crp-syntax-highlight, FR-sc-file-api, FR-sc-session-id, NFR-crp-accessibility-keyboard, NFR-crp-browser-support, NFR-crp-client-only, NFR-crp-large-file-perf, NFR-crp-no-data-persistence, NFR-crp-prompt-gen-time, NFR-crp-render-time, NFR-crp-responsive-layout]
---
# Code Review Prompt Generator — iOS Design Spec

> Based on requirements in `../../product/code-review-prompt.md`
> See also `../../product/ios/code-review-prompt.md` for iOS-specific requirements.
> The patch-open entry point and patch-thread surfaces are specified in `./shepherd-review.md`.

## What We're Designing

The native iOS presentation of the CRPG review surface, for iPhone and iPad. Content comes from an in-app opened NIP-34 patch (not the filesystem), so the empty state leads with "Open Patch". Once a patch is loaded, the reviewer navigates the patch's changed files as tabs, reads the diff with syntax highlighting, adds inline comments, and either copies the generated prompt or — for patch reviews — publishes comments to the Nostr patch thread (covered in `./shepherd-review.md`). The layout reflows between a compact single-pane form (iPhone) and an expanded split form (iPad).

## Screen Inventory

All states are presented within the same app scene; there are no separate routes. The layout is driven by the current size class, not the device model, so iPhone in landscape or iPad in Split View reflow identically.

| View State | Compact width (iPhone) | Expanded width (iPad) |
|---|---|---|
| **Empty State** | Centered "Open Patch" call-to-action fills the screen. | Same centered call-to-action. |
| **Review State** | A single focused pane with a file switcher; the code viewer and the inspector (patch metadata, thread, prompt, comments summary) are separate screens pushed onto a navigation stack. | Three-column split: file browser (left), code viewer (center), inspector (right). |

## Screen Definitions

### Empty State

The reviewer opens the app with no patch loaded. This is where they start a review.

- **Entry points**: App launch; clearing the session from the Review State.
- **Layout**: A single centered column. An app-icon mark, a one-line title (`Review a patch`), a short subtitle (`Open a NIP-34 patch to review and comment`), and a prominent `Open Patch` button. No "Open Files" or "Paste" affordances — local file loading is not offered on iOS (`FR-crp-ios-patch-only-entry`).
- **Components**:
  - `OpenPatchButton` — prominent filled button; opens the Open Patch entry sheet (see `./shepherd-review.md`).
- **States**: empty (default). No loading/error state here — fetch states live in the Open Patch sheet.
- **Actions**: Tap `Open Patch` → presents the Open Patch sheet.
- **Requirements satisfied**: `FR-crp-ios-patch-only-entry`, `AC-crp-ios-patch-only-entry`, `AC-crp-empty-state` (adapted: the empty state instructs how to start a review, i.e. open a patch).

### Review State — Compact (iPhone)

A patch is loaded with one or more changed-file tabs.

- **Entry points**: Open Patch sheet success.
- **Layout**: A navigation stack. The root is the code viewer for the active file. A file-switcher control in the navigation bar exposes the file list (as a sheet or a pull-down menu). The inspector surfaces (patch metadata, patch thread, prompt preview, all-comments summary, overall comment) are reached via a tab bar or a segmented control at the bottom, each pushing a detail screen. The active file path is shown as the navigation bar title (`FR-crp-active-file-path`).
- **Components**:
  - `FileSwitcher` — bar button presenting the file list as a sheet; each row shows file name, comment count, and reviewed marker. Honors the directory-tree grouping (`FR-crp-file-reviewed-grouping`) at a single level (compact width flattens deep nesting; full paths are revealed via the row detail, `FR-crp-file-tooltip`).
  - `CodeViewer` — see Component Specs.
  - `InspectorStack` — bottom segmented control switching between: Patch Info, Thread, Prompt, Comments. Each is a pushed detail screen. The `Prompt` tab is the live preview with a `Copy` button.
- **States**: populated (file + diff shown); loading (brief, while the diff parses); error (malformed tab — unlikely post-validation).
- **Actions**: Switch file; tap a line to comment; open inspector surfaces; copy prompt; mark file reviewed; clear session.
- **Requirements satisfied**: `FR-crp-file-display`, `FR-crp-active-file-path`, `FR-crp-multi-file-nav`, `FR-crp-file-reviewed-toggle`, `FR-crp-file-reviewed-visual`, `FR-crp-file-reviewed-progress`, `FR-crp-comment-count`, `FR-crp-prompt-preview`, `FR-crp-prompt-copy`, `FR-crp-comment-summary`, `FR-crp-prompt-preamble`, `FR-crp-clear-session`, `FR-crp-ios-adaptive-layout`.

### Review State — Expanded (iPad)

- **Entry points**: Open Patch sheet success.
- **Layout**: A three-column `NavigationSplitView`. File browser in the sidebar (left), code viewer in the content (center), inspector in the detail (right). The inspector is a scrollable vertical stack of collapsible sections: Patch Metadata, Patch Thread, Overall Comment, Prompt Preview, All Comments. The active file path sits atop the code viewer (`FR-crp-active-file-path`).
- **Components**: same `CodeViewer`; `FileBrowser` sidebar with full directory tree; `Inspector` right column.
- **States**: as compact, plus the sidebar may be collapsed to a compact representation and toggled back.
- **Actions**: as compact, with direct manipulation of all three columns at once.
- **Requirements satisfied**: as compact, plus `FR-crp-file-reviewed-grouping` (full tree), `FR-crp-review-context-collapsible` (when context present).

## Interaction Flows

### Comment on a line

A reviewer reading the diff wants to flag a specific line.

1. Reviewer taps the line number gutter on a line → an inline comment editor expands anchored to that line.
2. Reviewer types the comment and taps **Save** (or **Publish** in a patch review with identity loaded — see `./shepherd-review.md`).
3. The editor collapses; the gutter shows a comment indicator; the comment count and prompt preview update.

### Comment on a line range

1. Reviewer long-presses the start line, drags to the end line → a range is selected and a comment editor opens for the range.
2. On save, gutter indicators span the range and the prompt references the range.

### Navigate between comments

1. Reviewer opens the Comments inspector surface and taps a comment → the code viewer scrolls to and highlights its line.

### Copy the prompt

1. Reviewer opens the Prompt inspector surface → sees the live preview.
2. Taps **Copy** → the prompt is on the clipboard; a transient `Copied` confirmation appears.

### Clear the session

1. Reviewer taps **Clear** (in the file switcher or a menu) → if any comments exist, a confirmation alert asks to confirm; on confirm, all files/comments/preamble are discarded and the Empty State returns.

## Component Specs

### CodeViewer

The read-only diff/code viewer with numbered, addressable lines. Used as the center pane on both form factors.

- **Variants**: compact (fills the screen, inspector via stack); expanded (center column).
- **Inputs**: the active file's diff block (or full content when available); line-wrap toggle; comment annotations; patch-thread anchored replies (patch reviews only).
- **States**: empty (no file — not shown, Empty State used instead); populated; wrapping-on / wrapping-off.
- **Behavior**: line numbers in a tap-target gutter; tapping a line number opens the comment editor for that line; long-press-drag selects a range. Syntax highlighting per `FR-crp-syntax-highlight`. Line wrapping on by default (`FR-crp-line-wrap`); a wrap toggle in the viewer's toolbar. Wrapped lines keep a single line number aligned to the first visual row. Patch-thread replies anchored to a line render inline at that line, visually distinct from the reviewer's own editable comments (see `./shepherd-review.md`).
- **Requirements satisfied**: `FR-crp-file-display`, `FR-crp-line-wrap`, `FR-crp-syntax-highlight`, `FR-crp-line-comment-create`, `FR-crp-line-range-comment`, `FR-crp-comment-indicator`, `AC-crp-add-comment-single-line`, `AC-crp-add-comment-line-range`, `AC-crp-line-wrap-default-on`.

### FileBrowser (expanded) / FileSwitcher (compact)

The file list, organized as a directory tree with per-file comment count and reviewed state.

- **Variants**: expanded = sidebar tree; compact = sheet list (single-level grouping, full path on row detail).
- **Inputs**: loaded files (from the opened patch); per-file comment counts; reviewed flags; active file.
- **States**: empty (no patch); populated.
- **Behavior**: tap a row to switch the active file (preserves comments/state). Reviewed files show a checkmark and dimmed treatment; tapping a reviewed file still opens it. A directory fully reviewed shows a reviewed indicator. A progress line `N/M reviewed` appears at the top. Long-press a row to reveal full path + language + reviewed state (`FR-crp-file-tooltip`), mark/unmark reviewed, or remove the file.
- **Requirements satisfied**: `FR-crp-multi-file-nav`, `FR-crp-file-reviewed-toggle`, `FR-crp-file-reviewed-visual`, `FR-crp-file-reviewed-grouping`, `FR-crp-file-reviewed-progress`, `FR-crp-file-reviewed-persistence`, `FR-crp-file-tooltip`, `FR-crp-multi-file-remove`, `AC-crp-file-reviewed-survives-tab-switch`.

### Inspector (Prompt / Comments / Patch Info / Thread)

The right column (expanded) or stacked detail screens (compact) holding the non-code surfaces.

- **Variants**: expanded = vertical stack of collapsible sections; compact = segmented detail screens.
- **Inputs**: overall comment; prompt text; all-comments list; patch metadata + thread (patch reviews).
- **States**: prompt empty (placeholder until a comment exists); prompt populated; comments empty; thread empty/populated.
- **Behavior**: Overall Comment field (`FR-crp-prompt-preamble`, labeled "Overall Comment"); Prompt Preview read-only with **Copy**; All Comments summary grouped by file. Sections are collapsible; collapse state persists across file switches. The Patch Info and Thread sections are specified in `./shepherd-review.md`.
- **Requirements satisfied**: `FR-crp-prompt-preamble`, `FR-crp-prompt-preview`, `FR-crp-prompt-copy`, `FR-crp-prompt-generate`, `FR-crp-comment-summary`, `FR-crp-comment-count`, `FR-crp-review-context-collapsible`, `AC-crp-overall-comment-label`, `AC-crp-generate-prompt-no-comments`, `AC-crp-comment-summary-shows-all`, `AC-crp-copy-clipboard`.

## Responsive Behavior

The layout is selected by horizontal size class, not device:

- **Compact width** (`horizontalSizeClass == .compact`, e.g. iPhone portrait, iPhone landscape on small models, iPad in a narrow Split View): single-pane Review State with a navigation stack and a bottom segmented inspector. File switching via a sheet.
- **Expanded width** (`horizontalSizeClass == .regular`, e.g. iPad full-screen, iPad Split View wide, iPhone Pro Max landscape on some models): three-column split with a sidebar, code viewer, and inspector.

When the size class changes at runtime (rotation, Split View drag), the layout reflows in place and in-memory state (files, comments, reviewed flags, preamble) is preserved (`FR-crp-ios-adaptive-layout`, `AC-crp-ios-adaptive-layout`). No data is reloaded.

## Accessibility

- **VoiceOver**: line numbers, comment indicators, file rows, and inspector sections expose appropriate accessibility labels. The code viewer exposes each line as an accessibility element with its line number and text. Comment indicators announce "commented." The reviewed marker announces "reviewed."
- **Dynamic Type**: the UI respects the system text-size setting; the code viewer's monospace content scales within reason and falls back to horizontal scrolling when a line would overflow.
- **Attached keyboard**: when a hardware keyboard is present, core actions are reachable via keyboard shortcuts (open patch, copy prompt, next/previous comment, add comment on the focused line). Keyboard operation is a convenience, not a requirement — touch remains primary (`NFR-crp-accessibility-keyboard` modified for iOS).
- **Reduce Motion / Reduce Transparency**: respected for transitions and the comment editor expand/collapse.
- **Color contrast**: the diff syntax palette and the bot/human reply markers meet the platform's minimum contrast at standard and increased-contrast settings.

## iOS Platform Integration

- **System appearance**: follows the device light/dark setting; no in-app toggle (`FR-crp-ios-system-appearance`, `AC-crp-ios-system-appearance`).
- **Clipboard**: Copy uses the system clipboard (`FR-crp-ios-clipboard`).
- **Backgrounding**: on background→resume (no termination), in-memory state is preserved (`FR-crp-ios-background-handoff`, `AC-crp-ios-background-handoff`). On full termination, state may be lost (`NFR-crp-no-data-persistence`).
- **No menu bar / no file open panel / no drag-from-Finder**: these macOS concepts have no iOS equivalent and are not designed.

## Open Questions

1. **Inspector surface ordering on compact**: is the bottom segmented control ordered Patch Info → Thread → Prompt → Comments, or should Prompt be first (the most-used)? Design decision deferred to a visual prototype.
2. **File-switcher shape on compact**: sheet vs. pull-down menu. A sheet scales better to many files with the directory tree; a pull-down is faster for small patches. Deferred to prototype.
3. **Line-range selection gesture**: long-press-drag vs. a "select range" mode toggle. Long-press-drag risks colliding with scroll; a toggle is more discoverable but adds a mode. Deferred to prototype.
