# Code Review Prompt Generator -- macOS Test Plan

> Based on requirements in `../../product/code-review-prompt.md`
> See also `../../product/macos/code-review-prompt.md` for macOS-specific requirements.
> See also `../../design/macos/code-review-prompt.md` for macOS design spec.

## Test Strategy Overview

This test plan covers the macOS native (SwiftUI + TCA) implementation of the Code Review Prompt Generator. Tests are organized into five layers:

| Layer | Framework | Scope |
|---|---|---|
| **Unit** | Swift Testing + TCA `TestStore` | Reducer logic, state mutations, effects, prompt generation, file parsing |
| **Snapshot** | Point-Free SnapshotTesting | Visual appearance of key view states across light/dark mode |
| **Integration** | Swift Testing + TCA `TestStore` | Multi-step flows within TCA reducers (load -> comment -> generate -> copy) |
| **UI** | XCUITest | End-to-end user flows exercised through the real application |
| **Manual** | Human verification | macOS-specific behaviors: window management, Finder drag-and-drop, system appearance, Gatekeeper |

### Test Environment

- **OS**: macOS 14+ (Sonoma)
- **IDE**: Xcode 16+
- **Unit/Integration**: Swift Testing framework with TCA `TestStore`
- **Snapshots**: Point-Free SnapshotTesting (image-based)
- **UI Automation**: XCUITest
- **Fixtures**: Sample source files in all 13 supported languages, binary test files, sample session data in `~/.shepherd/sessions/test-session/`
- **CI**: Tests run on macOS runners; snapshot tests require consistent display scaling (2x Retina)

---

## Coverage Matrix

### Shared Acceptance Criteria

| Requirement | Test Cases | Status |
|---|---|---|
| `AC-crp-load-paste` | `TC-crp-macos-load-paste-happy`, `TC-crp-macos-load-paste-empty-clipboard` | Not started |
| `AC-crp-load-upload` | `TC-crp-macos-load-open-panel-single`, `TC-crp-macos-load-open-panel-multi` | Not started |
| `AC-crp-load-drag-drop` | `TC-crp-macos-load-drag-drop-single`, `TC-crp-macos-load-drag-drop-multi` | Not started |
| `AC-crp-syntax-highlight-detected` | `TC-crp-macos-syntax-highlight-detected`, `TC-crp-macos-syntax-highlight-fallback` | Not started |
| `AC-crp-add-comment-single-line` | `TC-crp-macos-add-comment-single-line`, `TC-crp-macos-add-comment-gutter-indicator` | Not started |
| `AC-crp-add-comment-line-range` | `TC-crp-macos-add-comment-line-range`, `TC-crp-macos-add-comment-line-range-gutter` | Not started |
| `AC-crp-edit-comment` | `TC-crp-macos-edit-comment-happy`, `TC-crp-macos-edit-comment-stays-on-line` | Not started |
| `AC-crp-delete-comment` | `TC-crp-macos-delete-comment-happy`, `TC-crp-macos-delete-comment-gutter-clears` | Not started |
| `AC-crp-generate-prompt-structure` | `TC-crp-macos-prompt-structure-happy`, `TC-crp-macos-prompt-structure-no-preamble` | Not started |
| `AC-crp-generate-prompt-no-comments` | `TC-crp-macos-prompt-no-comments-placeholder`, `TC-crp-macos-prompt-clears-after-delete-all` | Not started |
| `AC-crp-copy-clipboard` | `TC-crp-macos-copy-clipboard-happy`, `TC-crp-macos-copy-toolbar-animation` | Not started |
| `AC-crp-preview-matches-copy` | `TC-crp-macos-preview-matches-copy` | Not started |
| `AC-crp-clear-confirmation` | `TC-crp-macos-clear-confirmation-dialog`, `TC-crp-macos-clear-cancel-preserves` | Not started |
| `AC-crp-clear-no-confirm-empty` | `TC-crp-macos-clear-no-confirm-empty` | Not started |
| `AC-crp-empty-state` | `TC-crp-macos-empty-state-instructions`, `TC-crp-macos-empty-state-buttons-disabled` | Not started |
| `AC-crp-large-file-scroll` | `TC-crp-macos-large-file-scroll-smooth` | Not started |
| `AC-crp-comment-navigation-next` | `TC-crp-macos-comment-nav-next`, `TC-crp-macos-comment-nav-prev`, `TC-crp-macos-comment-nav-wrap`, `TC-crp-macos-comment-nav-cross-file`, `TC-crp-macos-comment-nav-cross-file-wrap` | Not started |
| `AC-crp-keyboard-add-comment` | `TC-crp-macos-keyboard-add-comment` | Not started |
| `AC-crp-binary-file-rejected` | `TC-crp-macos-binary-rejected-open-panel`, `TC-crp-macos-binary-rejected-drag-drop` | Not started |
| `AC-crp-done-sends-prompt` | `TC-crp-macos-done-sends-prompt` | Not started |
| `AC-crp-done-auto-close` | `TC-crp-macos-done-auto-close-reliable` | Not started |
| `AC-crp-done-confirmation` | N/A on macOS — native window close is always reliable per `FR-crp-macos-auto-close`; no fallback confirmation state is needed | N/A |
| `AC-crp-done-fallback-clipboard` | `TC-crp-macos-done-fallback-clipboard` | Not started |
| `AC-crp-done-disabled-no-comments` | `TC-crp-macos-done-disabled-no-comments` | Not started |
| `AC-crp-done-standalone-hidden` | `TC-crp-macos-done-hidden-standalone` | Not started |
| `AC-crp-multi-file-load-adds` | `TC-crp-macos-multi-file-load-adds` | Not started |
| `AC-crp-multi-file-drop-multiple` | `TC-crp-macos-multi-file-drop-multiple` | Not started |
| `AC-crp-multi-file-nav-preserves-state` | `TC-crp-macos-multi-file-switch-preserves` | Not started |
| `AC-crp-multi-file-remove-with-comments` | `TC-crp-macos-multi-file-remove-with-comments` | Not started |
| `AC-crp-multi-file-remove-no-comments` | `TC-crp-macos-multi-file-remove-no-comments` | Not started |
| `AC-crp-multi-file-prompt-structure` | `TC-crp-macos-multi-file-prompt-structure` | Not started |
| `AC-crp-multi-file-prompt-omits-uncommented` | `TC-crp-macos-multi-file-prompt-omits-uncommented` | Not started |
| `AC-crp-multi-file-comment-count` | `TC-crp-macos-multi-file-comment-count-global` | Not started |
| `AC-crp-multi-file-clear-all` | `TC-crp-macos-multi-file-clear-all` | Not started |
| `AC-crp-multi-file-empty-after-remove-last` | `TC-crp-macos-multi-file-remove-last-empty` | Not started |
| `AC-crp-file-path-display` | `TC-crp-macos-file-tree-disambiguates-same-name` | Not started |
| `AC-crp-file-path-single-dir` | `TC-crp-macos-file-tree-single-dir` | Not started |
| `AC-crp-context-overall-visible` | `TC-crp-macos-context-overall-visible` | Not started |
| `AC-crp-context-per-file-visible` | `TC-crp-macos-context-per-file-visible` | Not started |
| `AC-crp-context-per-file-switches` | `TC-crp-macos-context-per-file-switches` | Not started |
| `AC-crp-context-neutral-vs-review` | `TC-crp-macos-context-neutral-vs-review` | Not started |
| `AC-crp-context-graceful-missing` | `TC-crp-macos-context-graceful-missing` | Not started |
| `AC-crp-context-readonly` | `TC-crp-macos-context-readonly` | Not started |
| `AC-crp-context-sidebar-collapse` | `TC-crp-macos-context-sidebar-collapse` | Not started |
| `AC-crp-overall-comment-label` | `TC-crp-macos-overall-comment-label` | Not started |
| `AC-crp-overall-comment-in-prompt` | `TC-crp-macos-overall-comment-in-prompt` | Not started |
| `AC-crp-comment-summary-shows-all` | `TC-crp-macos-comment-summary-shows-all` | Not started |
| `AC-crp-comment-summary-realtime` | `TC-crp-macos-comment-summary-realtime` | Not started |
| `AC-crp-comment-summary-empty` | `TC-crp-macos-comment-summary-empty` | Not started |
| `AC-crp-file-mark-reviewed` | `TC-crp-macos-mark-reviewed-happy` | Not started |
| `AC-crp-file-unmark-reviewed` | `TC-crp-macos-unmark-reviewed-happy` | Not started |
| `AC-crp-file-reviewed-grouping` | `TC-crp-macos-reviewed-grouping-tree` | Not started |
| `AC-crp-file-reviewed-progress-count` | `TC-crp-macos-reviewed-progress-count` | Not started |
| `AC-crp-file-reviewed-survives-tab-switch` | `TC-crp-macos-reviewed-survives-tab-switch` | Not started |
| `AC-crp-file-reviewed-with-comments` | `TC-crp-macos-reviewed-independent-of-comments` | Not started |
| `AC-crp-file-reviewed-clear-session` | `TC-crp-macos-reviewed-clear-session-resets` | Not started |
| `AC-crp-panel-resize-drag` | `TC-crp-macos-panel-resize-drag` | Not started |
| `AC-crp-panel-resize-bounds` | `TC-crp-macos-panel-resize-min-max` | Not started |
| `AC-crp-panel-resize-double-click` | `TC-crp-macos-panel-resize-double-click-reset` | Not started |
| `AC-crp-panel-resize-persists` | `TC-crp-macos-panel-resize-persists-file-switch` | Not started |
| `AC-crp-active-file-path-visible` | `TC-crp-macos-active-file-path-visible` | Not started |
| `AC-crp-active-file-path-switches` | `TC-crp-macos-active-file-path-switches` | Not started |
| `AC-crp-active-file-path-single-file` | `TC-crp-macos-active-file-path-hidden-single` | Not started |
| `AC-crp-file-tooltip-full-path` | `TC-crp-macos-file-tooltip-full-path` | Not started |
| `AC-crp-file-tooltip-reviewed` | `TC-crp-macos-file-tooltip-reviewed-status` | Not started |
| `AC-crp-line-wrap-toggle` | `TC-crp-macos-line-wrap-toggle-on`, `TC-crp-macos-line-wrap-toggle-off` | Not started |
| `AC-crp-line-wrap-preserves-line-numbers` | `TC-crp-macos-line-wrap-preserves-line-numbers` | Not started |
| `AC-crp-line-wrap-comment-target` | `TC-crp-macos-line-wrap-comment-target` | Not started |
| `AC-crp-line-wrap-default-on` | `TC-crp-macos-line-wrap-default-on` | Not started |
| `AC-crp-line-wrap-persists-session` | `TC-crp-macos-line-wrap-persists-session` | Not started |

### macOS-Specific Acceptance Criteria

| Requirement | Test Cases | Status |
|---|---|---|
| `AC-crp-macos-window-open` | `TC-crp-macos-window-multi-session` | Not started |
| `AC-crp-macos-window-restore` | `TC-crp-macos-window-restore-geometry` | Not started |
| `AC-crp-macos-window-deduplicate` | `TC-crp-macos-window-deduplicate` | Not started |
| `AC-crp-macos-menu-copy-disabled` | `TC-crp-macos-menu-copy-disabled` | Not started |
| `AC-crp-macos-menu-shortcuts` | `TC-crp-macos-menu-shortcuts-displayed` | Not started |
| `AC-crp-macos-open-panel-multi` | `TC-crp-macos-load-open-panel-multi` | Not started |
| `AC-crp-macos-drag-drop-finder-path` | `TC-crp-macos-drag-drop-finder-path` | Not started |
| `AC-crp-macos-appearance-follows-system` | `TC-crp-macos-appearance-follows-system` | Not started |
| `AC-crp-macos-no-appearance-toggle` | `TC-crp-macos-no-appearance-toggle` | Not started |
| `AC-crp-macos-auto-close-reliable` | `TC-crp-macos-done-auto-close-reliable` | Not started |
| `AC-crp-macos-slash-command-launch-session` | `TC-crp-macos-slash-command-launch-session` | Not started |
| `AC-crp-macos-standalone-no-done` | `TC-crp-macos-done-hidden-standalone` | Not started |
| `AC-crp-macos-standalone-open-panel` | `TC-crp-macos-standalone-open-panel` | Not started |
| `AC-crp-macos-file-permission-error` | `TC-crp-macos-file-permission-error` | Not started |
| `AC-crp-macos-signed-notarized` | `TC-crp-macos-signed-notarized` | Not started |
| `AC-crp-macos-launch-cold` | `TC-crp-macos-launch-cold-time` | Not started |
| `AC-crp-macos-memory-typical` | `TC-crp-macos-memory-typical-session` | Not started |
| `AC-crp-macos-min-version-enforced` | `TC-crp-macos-min-version-enforced` | Not started |
| `AC-crp-macos-multi-window-independent` | `TC-crp-macos-multi-window-independent` | Not started |
| `AC-crp-macos-close-last-window` | `TC-crp-macos-close-last-window-keeps-running` | Not started |

### Functional Requirement Coverage

| Requirement | Test Cases | Status |
|---|---|---|
| `FR-crp-file-load` | `TC-crp-macos-load-paste-happy`, `TC-crp-macos-load-open-panel-single`, `TC-crp-macos-load-drag-drop-single`, `TC-crp-macos-binary-rejected-open-panel` | Not started |
| `FR-crp-file-display` | `TC-crp-macos-file-display-line-numbers`, `TC-crp-macos-file-display-preserves-whitespace` | Not started |
| `FR-crp-syntax-highlight` | `TC-crp-macos-syntax-highlight-detected`, `TC-crp-macos-syntax-highlight-all-languages`, `TC-crp-macos-syntax-highlight-fallback` | Not started |
| `FR-crp-line-wrap` | `TC-crp-macos-line-wrap-toggle-on`, `TC-crp-macos-line-wrap-toggle-off`, `TC-crp-macos-line-wrap-default-on`, `TC-crp-macos-line-wrap-persists-session` | Not started |
| `FR-crp-line-comment-create` | `TC-crp-macos-add-comment-single-line`, `TC-crp-macos-add-comment-gutter-indicator` | Not started |
| `FR-crp-line-comment-edit` | `TC-crp-macos-edit-comment-happy`, `TC-crp-macos-edit-comment-stays-on-line` | Not started |
| `FR-crp-line-comment-delete` | `TC-crp-macos-delete-comment-happy`, `TC-crp-macos-delete-comment-gutter-clears` | Not started |
| `FR-crp-comment-indicator` | `TC-crp-macos-add-comment-gutter-indicator`, `TC-crp-macos-delete-comment-gutter-clears` | Not started |
| `FR-crp-comment-count` | `TC-crp-macos-multi-file-comment-count-global`, `TC-crp-macos-comment-count-increments` | Not started |
| `FR-crp-line-range-comment` | `TC-crp-macos-add-comment-line-range`, `TC-crp-macos-add-comment-line-range-gutter` | Not started |
| `FR-crp-comment-navigation` | `TC-crp-macos-comment-nav-next`, `TC-crp-macos-comment-nav-prev`, `TC-crp-macos-comment-nav-wrap` | Not started |
| `FR-crp-prompt-preamble` | `TC-crp-macos-overall-comment-label`, `TC-crp-macos-overall-comment-in-prompt` | Not started |
| `FR-crp-prompt-generate` | `TC-crp-macos-prompt-structure-happy`, `TC-crp-macos-prompt-auto-regenerates`, `TC-crp-macos-prompt-out-of-range-comment` | Not started |
| `FR-crp-prompt-preview` | `TC-crp-macos-prompt-preview-live`, `TC-crp-macos-prompt-no-comments-placeholder` | Not started |
| `FR-crp-prompt-copy` | `TC-crp-macos-copy-clipboard-happy`, `TC-crp-macos-copy-toolbar-animation` | Not started |
| `FR-crp-prompt-format` | `TC-crp-macos-prompt-structure-happy`, `TC-crp-macos-prompt-structure-no-preamble` | Not started |
| `FR-crp-done-action` | `TC-crp-macos-done-sends-prompt`, `TC-crp-macos-done-auto-close-reliable`, `TC-crp-macos-done-disabled-no-comments`, `TC-crp-macos-done-hidden-standalone` | Not started |
| `FR-crp-prompt-handoff` | `TC-crp-macos-done-sends-prompt`, `TC-crp-macos-done-fallback-clipboard` | Not started |
| `FR-crp-session-identity` | `TC-crp-macos-session-identity-title`, `TC-crp-macos-session-identity-standalone` | Not started |
| `FR-crp-clear-session` | `TC-crp-macos-clear-confirmation-dialog`, `TC-crp-macos-clear-no-confirm-empty`, `TC-crp-macos-multi-file-clear-all` | Not started |
| `FR-crp-multi-file-load` | `TC-crp-macos-multi-file-load-adds`, `TC-crp-macos-multi-file-drop-multiple` | Not started |
| `FR-crp-multi-file-nav` | `TC-crp-macos-multi-file-switch-preserves`, `TC-crp-macos-file-tree-disambiguates-same-name`, `TC-crp-macos-file-tree-collapse-expand` | Not started |
| `FR-crp-multi-file-remove` | `TC-crp-macos-multi-file-remove-with-comments`, `TC-crp-macos-multi-file-remove-no-comments`, `TC-crp-macos-multi-file-remove-last-empty` | Not started |
| `FR-crp-multi-file-prompt` | `TC-crp-macos-multi-file-prompt-structure` | Not started |
| `FR-crp-multi-file-prompt-format` | `TC-crp-macos-multi-file-prompt-structure`, `TC-crp-macos-multi-file-prompt-omits-uncommented` | Not started |
| `FR-crp-review-context-receive` | `TC-crp-macos-context-overall-visible`, `TC-crp-macos-context-graceful-missing` | Not started |
| `FR-crp-review-context-display` | `TC-crp-macos-context-overall-visible`, `TC-crp-macos-context-per-file-visible`, `TC-crp-macos-context-neutral-vs-review` | Not started |
| `FR-crp-review-context-overall` | `TC-crp-macos-context-overall-visible`, `TC-crp-macos-context-sidebar-collapse` | Not started |
| `FR-crp-review-context-per-file` | `TC-crp-macos-context-per-file-visible`, `TC-crp-macos-context-per-file-switches` | Not started |
| `FR-crp-review-context-collapsible` | `TC-crp-macos-context-sidebar-collapse` | Not started |
| `FR-crp-comment-summary` | `TC-crp-macos-comment-summary-shows-all`, `TC-crp-macos-comment-summary-realtime`, `TC-crp-macos-comment-summary-empty` | Not started |
| `FR-crp-panel-resize` | `TC-crp-macos-panel-resize-drag`, `TC-crp-macos-panel-resize-min-max`, `TC-crp-macos-panel-resize-double-click-reset` | Not started |
| `FR-crp-active-file-path` | `TC-crp-macos-active-file-path-visible`, `TC-crp-macos-active-file-path-switches`, `TC-crp-macos-active-file-path-hidden-single` | Not started |
| `FR-crp-file-tooltip` | `TC-crp-macos-file-tooltip-full-path`, `TC-crp-macos-file-tooltip-reviewed-status` | Not started |
| `FR-crp-file-reviewed-toggle` | `TC-crp-macos-mark-reviewed-happy`, `TC-crp-macos-unmark-reviewed-happy` | Not started |
| `FR-crp-file-reviewed-visual` | `TC-crp-macos-mark-reviewed-happy`, `TC-crp-macos-unmark-reviewed-happy` | Not started |
| `FR-crp-file-reviewed-grouping` | `TC-crp-macos-reviewed-grouping-tree` | Not started |
| `FR-crp-file-reviewed-progress` | `TC-crp-macos-reviewed-progress-count` | Not started |
| `FR-crp-file-reviewed-persistence` | `TC-crp-macos-reviewed-survives-tab-switch`, `TC-crp-macos-reviewed-clear-session-resets` | Not started |
| `FR-crp-macos-window-management` | `TC-crp-macos-window-multi-session`, `TC-crp-macos-window-restore-geometry`, `TC-crp-macos-window-min-size`, `TC-crp-macos-close-last-window-keeps-running` | Not started |
| `FR-crp-macos-menu-bar` | `TC-crp-macos-menu-copy-disabled`, `TC-crp-macos-menu-shortcuts-displayed`, `TC-crp-macos-menu-standard-items` | Not started |
| `FR-crp-macos-keyboard-shortcuts` | `TC-crp-macos-keyboard-open-file`, `TC-crp-macos-keyboard-copy-prompt`, `TC-crp-macos-keyboard-close-window`, `TC-crp-macos-keyboard-undo-redo` | Not started |
| `FR-crp-macos-file-open-panel` | `TC-crp-macos-load-open-panel-single`, `TC-crp-macos-load-open-panel-multi` | Not started |
| `FR-crp-macos-drag-drop-finder` | `TC-crp-macos-load-drag-drop-single`, `TC-crp-macos-load-drag-drop-multi`, `TC-crp-macos-drag-drop-finder-path` | Not started |
| `FR-crp-macos-clipboard` | `TC-crp-macos-copy-clipboard-happy` | Not started |
| `FR-crp-macos-system-appearance` | `TC-crp-macos-appearance-follows-system`, `TC-crp-macos-no-appearance-toggle` | Not started |
| `FR-crp-macos-auto-close` | `TC-crp-macos-done-auto-close-reliable` | Not started |
| `FR-crp-macos-slash-command-launch` | `TC-crp-macos-slash-command-launch-session`, `TC-crp-macos-window-deduplicate` | Not started |
| `FR-crp-macos-standalone-mode` | `TC-crp-macos-done-hidden-standalone`, `TC-crp-macos-standalone-open-panel` | Not started |
| `FR-crp-macos-sandboxed-file-access` | `TC-crp-macos-file-permission-error` | Not started |
| `FR-crp-macos-distribution` | `TC-crp-macos-signed-notarized` | Not started |
| `NFR-crp-large-file-perf` | `TC-crp-macos-large-file-scroll-smooth`, `TC-crp-macos-large-file-load-time` | Not started |
| `NFR-crp-render-time` | `TC-crp-macos-render-time-under-500ms` | Not started |
| `NFR-crp-prompt-gen-time` | `TC-crp-macos-prompt-gen-time-under-300ms` | Not started |
| `NFR-crp-client-only` | `TC-crp-macos-no-network-traffic` | Not started |
| `NFR-crp-accessibility-keyboard` | `TC-crp-macos-keyboard-add-comment`, `TC-crp-macos-keyboard-open-file`, `TC-crp-macos-keyboard-copy-prompt` | Not started |
| `NFR-crp-macos-launch-time` | `TC-crp-macos-launch-cold-time` | Not started |
| `NFR-crp-macos-memory` | `TC-crp-macos-memory-typical-session`, `TC-crp-macos-memory-idle` | Not started |
| `NFR-crp-macos-min-version` | `TC-crp-macos-min-version-enforced` | Not started |
| `NFR-crp-no-data-persistence` | `TC-crp-macos-session-data-not-persisted` | Not started |

---

## Test Cases

---

### A. File Loading

---

#### `TC-crp-macos-load-open-panel-single` -- Load a single file via native open panel
- **Type**: UI
- **Traces**: `FR-crp-file-load`, `FR-crp-macos-file-open-panel`, `AC-crp-load-upload`
- **Preconditions**: Application is running in the empty state.
- **Steps**:
  1. Click the Open toolbar button (or press Cmd+O).
  2. In the native file open panel, navigate to a directory containing a test TypeScript file.
  3. Select a single `.ts` file and click Open.
- **Expected**: The file is loaded into the code viewer with line numbers starting at 1. The FileHeader displays the file name. Syntax highlighting is applied for TypeScript. The toolbar Copy Prompt button remains disabled (no comments yet).
- **Status**: Not started

---

#### `TC-crp-macos-load-open-panel-multi` -- Load multiple files via native open panel
- **Type**: UI
- **Traces**: `FR-crp-macos-file-open-panel`, `AC-crp-macos-open-panel-multi`, `AC-crp-multi-file-load-adds`
- **Preconditions**: Application is running in the empty state.
- **Steps**:
  1. Press Cmd+O to open the file open panel.
  2. Select 3 files (e.g., `utils.ts`, `helpers.py`, `config.json`) using Shift+click or Cmd+click.
  3. Click Open.
- **Expected**: All 3 files are loaded into the session. The file browser sidebar appears on the left. Each file appears in the directory tree. The last file in the selection becomes the active file. Per-file comment counts show 0 for all files.
- **Status**: Not started

---

#### `TC-crp-macos-load-drag-drop-single` -- Load a single file via Finder drag-and-drop
- **Type**: Manual
- **Traces**: `FR-crp-macos-drag-drop-finder`, `AC-crp-load-drag-drop`
- **Preconditions**: Application is running in the empty state. A text file is visible in a Finder window.
- **Steps**:
  1. Drag a text file from Finder over the application window.
  2. Observe the drag hover visual indicator (accent color border, translucent overlay reading "Drop to load files").
  3. Drop the file onto the application window.
- **Expected**: The drag hover indicator appears while dragging over the window. On drop, the file is loaded into the code viewer with line numbers and the file name from Finder. The drag hover indicator disappears after the drop.
- **Status**: Not started

---

#### `TC-crp-macos-load-drag-drop-multi` -- Load multiple files via Finder drag-and-drop
- **Type**: Manual
- **Traces**: `FR-crp-macos-drag-drop-finder`, `AC-crp-load-drag-drop`, `AC-crp-multi-file-drop-multiple`
- **Preconditions**: Application is running in the empty state. Multiple text files are visible in Finder.
- **Steps**:
  1. Select 3 files in Finder.
  2. Drag all 3 files over the application window.
  3. Drop them onto the window.
- **Expected**: All 3 files are loaded into the session. The file browser sidebar appears. Each file is listed with its correct name and path.
- **Status**: Not started

---

#### `TC-crp-macos-drag-drop-finder-path` -- Drag-and-drop preserves file path
- **Type**: Manual
- **Traces**: `FR-crp-macos-drag-drop-finder`, `AC-crp-macos-drag-drop-finder-path`
- **Preconditions**: Application is running.
- **Steps**:
  1. Drag a file from Finder at a known path (e.g., `/Users/dev/project/src/utils.ts`).
  2. Drop it onto the application window.
  3. Add a comment on any line.
  4. Check the generated prompt.
- **Expected**: The file is loaded with its full path displayed. The generated prompt's File heading includes the file path (e.g., `## File: src/utils.ts (typescript)`). The file browser shows the file under its directory hierarchy.
- **Status**: Not started

---

#### `TC-crp-macos-load-paste-happy` -- Load file content via paste (Cmd+V)
- **Type**: UI
- **Traces**: `FR-crp-file-load`, `AC-crp-load-paste`
- **Preconditions**: Application is in the empty state. The system clipboard contains plain text content (e.g., a short code snippet).
- **Steps**:
  1. Copy a code snippet to the system clipboard.
  2. Press Cmd+V while the application has focus.
- **Expected**: The pasted text is loaded as a new file named "Untitled" in the code viewer. Line numbers start at 1. The FileHeader displays "Untitled".
- **Status**: Not started

---

#### `TC-crp-macos-load-paste-empty-clipboard` -- Paste with non-text clipboard does nothing
- **Type**: Unit
- **Traces**: `FR-crp-file-load`, `AC-crp-load-paste`
- **Preconditions**: Application is in the empty state. The system clipboard contains non-text content (e.g., an image).
- **Steps**:
  1. Copy an image to the system clipboard.
  2. Press Cmd+V while the application has focus.
- **Expected**: Nothing happens. The application remains in the empty state. No error is shown.
- **Status**: Not started

---

#### `TC-crp-macos-binary-rejected-open-panel` -- Binary file rejected via open panel
- **Type**: Integration
- **Traces**: `FR-crp-file-load`, `AC-crp-binary-file-rejected`
- **Preconditions**: Application is running. A binary test file (e.g., compiled executable or image) is available.
- **Steps**:
  1. Press Cmd+O to open the file open panel.
  2. Select a binary file.
  3. Click Open.
- **Expected**: A native alert appears with title "Cannot Open File" and message indicating only plain-text files are supported. The file is not loaded. The application state is unchanged.
- **Status**: Not started

---

#### `TC-crp-macos-binary-rejected-drag-drop` -- Binary file rejected via drag-and-drop
- **Type**: Manual
- **Traces**: `FR-crp-file-load`, `AC-crp-binary-file-rejected`, `FR-crp-macos-drag-drop-finder`
- **Preconditions**: Application is running. A binary file is visible in Finder.
- **Steps**:
  1. Drag a binary file from Finder and drop it onto the application window.
- **Expected**: A native alert appears rejecting the binary file. The file is not loaded. If other valid text files were dropped simultaneously, only the valid files are loaded; each binary file gets its own rejection alert.
- **Status**: Not started

---

#### `TC-crp-macos-file-permission-error` -- File with insufficient permissions shows error
- **Type**: Manual
- **Traces**: `FR-crp-macos-sandboxed-file-access`, `AC-crp-macos-file-permission-error`
- **Preconditions**: A text file exists with read permissions revoked (e.g., `chmod 000 test-file.txt`).
- **Steps**:
  1. Attempt to open the permission-restricted file via the file open panel.
- **Expected**: A native alert appears with title "Cannot Read File" and a message indicating the file could not be read due to permissions. The application does not crash. The state is unchanged.
- **Status**: Not started

---

### B. Code Viewer

---

#### `TC-crp-macos-file-display-line-numbers` -- File displays with sequential line numbers
- **Type**: Unit
- **Traces**: `FR-crp-file-display`
- **Preconditions**: A test file with 50 lines is available.
- **Steps**:
  1. Load the test file via the TCA `TestStore` (send `.fileLoaded` action).
  2. Assert the state contains the file with 50 lines.
- **Expected**: The state reflects 50 lines, numbered 1 through 50. Each line's content matches the source file exactly.
- **Status**: Not started

---

#### `TC-crp-macos-file-display-preserves-whitespace` -- File preserves original whitespace and indentation
- **Type**: Snapshot
- **Traces**: `FR-crp-file-display`
- **Preconditions**: A test file with mixed indentation (tabs, spaces, blank lines) is available.
- **Steps**:
  1. Load the test file.
  2. Take a snapshot of the code viewer.
- **Expected**: The snapshot shows preserved indentation, tab characters, blank lines, and trailing whitespace. No normalization has occurred.
- **Status**: Not started

---

#### `TC-crp-macos-syntax-highlight-detected` -- Syntax highlighting applies for known languages
- **Type**: Unit
- **Traces**: `FR-crp-syntax-highlight`, `AC-crp-syntax-highlight-detected`
- **Preconditions**: A TypeScript test file with keywords, strings, and comments is available.
- **Steps**:
  1. Load a file named `test.ts` with TypeScript content.
  2. Assert the detected language is TypeScript.
- **Expected**: The file state records the detected language as "TypeScript". Keywords, string literals, and comments receive syntax-appropriate highlighting tokens.
- **Status**: Not started

---

#### `TC-crp-macos-syntax-highlight-all-languages` -- Syntax highlighting works for all 13 required languages
- **Type**: Unit
- **Traces**: `FR-crp-syntax-highlight`
- **Preconditions**: Sample files for each of the 13 languages are available as test fixtures.
- **Steps**:
  1. For each language (JavaScript, TypeScript, Python, Go, Rust, Java, C, C++, HTML, CSS, JSON, YAML, Markdown), load a sample file with the correct extension.
  2. Assert the language is correctly detected.
- **Expected**: All 13 languages are detected and highlighted. Extension mappings work (`.js`, `.jsx`, `.mjs`, `.cjs` all map to JavaScript; `.ts`, `.tsx` map to TypeScript; etc.).
- **Status**: Not started

---

#### `TC-crp-macos-syntax-highlight-fallback` -- Unknown language falls back to plain text
- **Type**: Unit
- **Traces**: `FR-crp-syntax-highlight`
- **Preconditions**: A file with an unknown extension (e.g., `data.xyz`) is available.
- **Steps**:
  1. Load `data.xyz`.
  2. Assert the detected language.
- **Expected**: The language is detected as "Plain Text". No syntax highlighting is applied. The file content is still displayed correctly with line numbers.
- **Status**: Not started

---

#### `TC-crp-macos-line-wrap-toggle-on` -- Enabling line wrapping wraps long lines
- **Type**: UI
- **Traces**: `FR-crp-line-wrap`, `AC-crp-line-wrap-toggle`
- **Preconditions**: A file with lines exceeding 200 characters is loaded. Line wrapping is currently off.
- **Steps**:
  1. Click the Line Wrap toggle in the toolbar (or use the keyboard shortcut).
- **Expected**: Long lines wrap within the code content area. No horizontal scrollbar appears for the code. The gutter and line numbers remain unaffected.
- **Status**: Not started

---

#### `TC-crp-macos-line-wrap-toggle-off` -- Disabling line wrapping enables horizontal scroll
- **Type**: UI
- **Traces**: `FR-crp-line-wrap`, `AC-crp-line-wrap-toggle`
- **Preconditions**: A file with long lines is loaded. Line wrapping is currently on.
- **Steps**:
  1. Click the Line Wrap toggle in the toolbar to disable wrapping.
- **Expected**: Long lines extend beyond the visible area. A horizontal scrollbar appears for the code content area. The gutter and line numbers remain fixed.
- **Status**: Not started

---

#### `TC-crp-macos-line-wrap-preserves-line-numbers` -- Wrapped lines display a single line number
- **Type**: Snapshot
- **Traces**: `FR-crp-line-wrap`, `AC-crp-line-wrap-preserves-line-numbers`
- **Preconditions**: A file with a line that wraps to 3+ visual rows is loaded. Line wrapping is enabled.
- **Steps**:
  1. Take a snapshot of the code viewer area showing the wrapped line.
- **Expected**: The wrapped line shows only one line number, aligned to the first visual row. The next logical line's number follows sequentially with no gaps or duplicates.
- **Status**: Not started

---

#### `TC-crp-macos-line-wrap-comment-target` -- Clicking any visual row of a wrapped line targets the correct logical line
- **Type**: Integration
- **Traces**: `FR-crp-line-wrap`, `AC-crp-line-wrap-comment-target`
- **Preconditions**: A file with a long line that wraps is loaded. Line wrapping is enabled.
- **Steps**:
  1. Click on the second visual row of a wrapped line (logical line 5).
  2. Add a comment.
- **Expected**: The comment is attached to logical line 5, not to a different line number. The gutter indicator appears at line 5.
- **Status**: Not started

---

#### `TC-crp-macos-line-wrap-default-on` -- Line wrapping is on by default
- **Type**: Unit
- **Traces**: `FR-crp-line-wrap`, `AC-crp-line-wrap-default-on`
- **Preconditions**: Fresh application state via `TestStore`.
- **Steps**:
  1. Initialize a new `AppState`.
  2. Assert the line wrap preference.
- **Expected**: The `lineWrapEnabled` state is `true` by default.
- **Status**: Not started

---

#### `TC-crp-macos-line-wrap-persists-session` -- Line wrap preference persists across file switches
- **Type**: Integration
- **Traces**: `FR-crp-line-wrap`, `AC-crp-line-wrap-persists-session`
- **Preconditions**: Two files are loaded.
- **Steps**:
  1. Disable line wrapping.
  2. Switch from file A to file B.
  3. Switch back to file A.
  4. Assert the line wrapping state.
- **Expected**: Line wrapping remains disabled after switching files and switching back. The preference is session-global, not per-file.
- **Status**: Not started

---

#### `TC-crp-macos-large-file-scroll-smooth` -- Large file scrolls without jank
- **Type**: Manual
- **Traces**: `NFR-crp-large-file-perf`, `AC-crp-large-file-scroll`
- **Preconditions**: A file with 10,000 lines is loaded.
- **Steps**:
  1. Scroll through the file using the trackpad with fast momentum scrolling.
  2. Scroll using the scroll bar drag.
  3. Observe frame rate using Instruments (Core Animation FPS instrument).
- **Expected**: Scrolling is smooth with no visible stutter or frame drops exceeding 200ms. The FPS stays above 30fps during scrolling.
- **Status**: Not started

---

#### `TC-crp-macos-large-file-load-time` -- Large file loads within render time threshold
- **Type**: Integration
- **Traces**: `NFR-crp-render-time`, `NFR-crp-large-file-perf`
- **Preconditions**: A file with 1,000 lines is available.
- **Steps**:
  1. Measure the time from file load action to the state being fully populated (via `TestStore` clock).
- **Expected**: The file state is fully populated within 500ms. Syntax highlighting may load progressively but line content and numbers are available within the 500ms window.
- **Status**: Not started

---

#### `TC-crp-macos-render-time-under-500ms` -- File renders within 500ms
- **Type**: Integration
- **Traces**: `NFR-crp-render-time`
- **Preconditions**: A file with 1,000 lines of TypeScript is available.
- **Steps**:
  1. Load the file via `TestStore`.
  2. Measure the time for the state to reflect the loaded file with syntax tokens.
- **Expected**: The loaded state (lines with line numbers and syntax tokens) is available within 500ms.
- **Status**: Not started

---

### C. Comments

---

#### `TC-crp-macos-add-comment-single-line` -- Add a comment to a single line
- **Type**: Unit
- **Traces**: `FR-crp-line-comment-create`, `AC-crp-add-comment-single-line`
- **Preconditions**: A file is loaded in the `TestStore`.
- **Steps**:
  1. Send the action to open a comment editor on line 5.
  2. Send the action to submit the comment with text "Rename this variable".
- **Expected**: The state contains one comment on line 5 with text "Rename this variable". The comment count is 1. The gutter state for line 5 shows a comment indicator.
- **Status**: Not started

---

#### `TC-crp-macos-add-comment-gutter-indicator` -- Comment indicator appears in the gutter
- **Type**: Snapshot
- **Traces**: `FR-crp-comment-indicator`, `AC-crp-add-comment-single-line`
- **Preconditions**: A file is loaded with a comment on line 5.
- **Steps**:
  1. Render the code viewer with the comment state.
  2. Take a snapshot of the gutter area around line 5.
- **Expected**: Line 5 shows a visible comment indicator in the gutter (colored marker or icon). Adjacent lines without comments show no indicator.
- **Status**: Not started

---

#### `TC-crp-macos-add-comment-line-range` -- Add a comment to a line range
- **Type**: Unit
- **Traces**: `FR-crp-line-range-comment`, `AC-crp-add-comment-line-range`
- **Preconditions**: A file with at least 20 lines is loaded in the `TestStore`.
- **Steps**:
  1. Send the action to select lines 10 through 15.
  2. Send the action to submit a comment with text "Extract this to a helper function".
- **Expected**: The state contains one comment on range 10-15 with the specified text. The generated prompt references the code from lines 10-15.
- **Status**: Not started

---

#### `TC-crp-macos-add-comment-line-range-gutter` -- Line range comment shows gutter indicators for entire range
- **Type**: Snapshot
- **Traces**: `FR-crp-line-range-comment`, `FR-crp-comment-indicator`, `AC-crp-add-comment-line-range`
- **Preconditions**: A file is loaded with a comment on lines 10-15.
- **Steps**:
  1. Render the code viewer showing lines 8-18.
  2. Take a snapshot.
- **Expected**: Gutter indicators are visible for lines 10 through 15. Lines 8-9 and 16-18 show no indicators.
- **Status**: Not started

---

#### `TC-crp-macos-edit-comment-happy` -- Edit an existing comment
- **Type**: Unit
- **Traces**: `FR-crp-line-comment-edit`, `AC-crp-edit-comment`
- **Preconditions**: A file is loaded with a comment "Fix this" on line 3.
- **Steps**:
  1. Send the action to begin editing the comment on line 3.
  2. Send the action to save with new text "Fix this null check".
- **Expected**: The comment text updates to "Fix this null check". The comment remains on line 3. The comment count remains 1.
- **Status**: Not started

---

#### `TC-crp-macos-edit-comment-stays-on-line` -- Edited comment retains line association
- **Type**: Unit
- **Traces**: `FR-crp-line-comment-edit`, `AC-crp-edit-comment`
- **Preconditions**: A file is loaded with a comment on line 7.
- **Steps**:
  1. Edit the comment, changing its text.
  2. Assert the comment's line number.
- **Expected**: The comment's line association is line 7 after editing. It has not moved.
- **Status**: Not started

---

#### `TC-crp-macos-delete-comment-happy` -- Delete a comment
- **Type**: Unit
- **Traces**: `FR-crp-line-comment-delete`, `AC-crp-delete-comment`
- **Preconditions**: A file is loaded with a comment on line 7. Comment count is 1.
- **Steps**:
  1. Send the action to delete the comment on line 7.
- **Expected**: The comment is removed from the state. The comment count decrements to 0. The prompt preview clears (no comments remain).
- **Status**: Not started

---

#### `TC-crp-macos-delete-comment-gutter-clears` -- Gutter indicator clears after deleting the last comment on a line
- **Type**: Unit
- **Traces**: `FR-crp-comment-indicator`, `AC-crp-delete-comment`
- **Preconditions**: A file is loaded with exactly one comment on line 7.
- **Steps**:
  1. Delete the comment on line 7.
  2. Check the gutter state for line 7.
- **Expected**: Line 7 no longer has a comment indicator in the gutter.
- **Status**: Not started

---

#### `TC-crp-macos-comment-count-increments` -- Comment count updates on add and delete
- **Type**: Unit
- **Traces**: `FR-crp-comment-count`
- **Preconditions**: A file is loaded with no comments.
- **Steps**:
  1. Add a comment on line 1. Assert count is 1.
  2. Add a comment on line 5. Assert count is 2.
  3. Delete the comment on line 1. Assert count is 1.
  4. Delete the comment on line 5. Assert count is 0.
- **Expected**: The comment count accurately reflects the total number of comments at each step.
- **Status**: Not started

---

#### `TC-crp-macos-comment-nav-next` -- Navigate to next comment
- **Type**: Unit
- **Traces**: `FR-crp-comment-navigation`, `AC-crp-comment-navigation-next`
- **Preconditions**: A file is loaded with comments on lines 5, 20, and 100. The current focus is on line 5's comment.
- **Steps**:
  1. Send the "next comment" action.
- **Expected**: The active comment moves to line 20. The scroll position targets line 20.
- **Status**: Not started

---

#### `TC-crp-macos-comment-nav-prev` -- Navigate to previous comment
- **Type**: Unit
- **Traces**: `FR-crp-comment-navigation`, `AC-crp-comment-navigation-next`
- **Preconditions**: A file is loaded with comments on lines 5, 20, and 100. The current focus is on line 20's comment.
- **Steps**:
  1. Send the "previous comment" action.
- **Expected**: The active comment moves to line 5. The scroll position targets line 5.
- **Status**: Not started

---

#### `TC-crp-macos-comment-nav-wrap` -- Comment navigation wraps around
- **Type**: Unit
- **Traces**: `FR-crp-comment-navigation`, `AC-crp-comment-navigation-next`
- **Preconditions**: A file is loaded with comments on lines 5, 20, and 100. The current focus is on line 100's comment.
- **Steps**:
  1. Send the "next comment" action.
- **Expected**: The active comment wraps to line 5 (the first comment). Conversely, pressing "previous" on line 5 wraps to line 100.
- **Status**: Not started

---

#### `TC-crp-macos-comment-nav-cross-file` -- Navigate to next comment in a different file
- **Type**: Integration
- **Traces**: `FR-crp-comment-navigation`, `AC-crp-comment-navigation-next`, `FR-crp-multi-file-nav`
- **Preconditions**: Two files are loaded. File A (`utils.ts`) has comments on lines 5 and 20. File B (`helpers.ts`) has a comment on line 10. File A is the active file with focus on line 20's comment (the last comment in file A).
- **Steps**:
  1. Send the "next comment" action.
- **Expected**: The active file switches to File B (`helpers.ts`), the code viewer displays File B, and the active comment moves to line 10. The file browser sidebar updates to show File B as active. Pressing "previous" from File B line 10 switches back to File A line 20.
- **Status**: Not started

---

#### `TC-crp-macos-comment-nav-cross-file-wrap` -- Cross-file comment navigation wraps around
- **Type**: Integration
- **Traces**: `FR-crp-comment-navigation`, `AC-crp-comment-navigation-next`, `FR-crp-multi-file-nav`
- **Preconditions**: Two files are loaded. File A has a comment on line 5. File B has a comment on line 10. File B is active with focus on line 10's comment (the last comment globally).
- **Steps**:
  1. Send the "next comment" action.
- **Expected**: The active file switches to File A, and the active comment wraps to line 5 (the first comment globally across all files).
- **Status**: Not started

---

#### `TC-crp-macos-keyboard-add-comment` -- Add a comment via keyboard only
- **Type**: UI
- **Traces**: `NFR-crp-accessibility-keyboard`, `AC-crp-keyboard-add-comment`
- **Preconditions**: A file is loaded in the application.
- **Steps**:
  1. Use Tab/arrow keys to navigate focus to a line in the code viewer.
  2. Press the designated keyboard shortcut to add a comment (e.g., Return or a defined shortcut).
  3. Type "Keyboard comment" and press Cmd+Return to submit.
- **Expected**: The comment "Keyboard comment" is created on the focused line. No mouse interaction was required throughout the flow.
- **Status**: Not started

---

### D. Prompt Generation

---

#### `TC-crp-macos-prompt-structure-happy` -- Generated prompt has correct structure
- **Type**: Unit
- **Traces**: `FR-crp-prompt-generate`, `FR-crp-prompt-format`, `AC-crp-generate-prompt-structure`
- **Preconditions**: A file named "utils.ts" is loaded with comments on lines 3, 10-12, and 25, and an Overall Comment "Refactor for readability".
- **Steps**:
  1. Assert the generated prompt text.
- **Expected**: The prompt contains: (1) an "Instructions" section with the overall comment, (2) a "File" heading with "utils.ts" and "typescript", (3) a "Requested Changes" section with 3 comments each preceded by a fenced code block of the referenced source code, (4) comments in source order (line 3, 10-12, 25).
- **Status**: Not started

---

#### `TC-crp-macos-prompt-structure-no-preamble` -- Prompt structure without Overall Comment
- **Type**: Unit
- **Traces**: `FR-crp-prompt-format`, `AC-crp-generate-prompt-structure`
- **Preconditions**: A file is loaded with one comment. No Overall Comment is provided.
- **Steps**:
  1. Assert the generated prompt text.
- **Expected**: The prompt does not contain an "Instructions" section. It starts with the File heading and Requested Changes.
- **Status**: Not started

---

#### `TC-crp-macos-prompt-no-comments-placeholder` -- No prompt when no comments exist
- **Type**: Unit
- **Traces**: `FR-crp-prompt-generate`, `AC-crp-generate-prompt-no-comments`
- **Preconditions**: A file is loaded but no comments exist.
- **Steps**:
  1. Assert the prompt state.
- **Expected**: The prompt text is nil or empty. The prompt preview shows a placeholder message: "Add comments to the code to generate your AI prompt."
- **Status**: Not started

---

#### `TC-crp-macos-prompt-clears-after-delete-all` -- Prompt clears when all comments are deleted
- **Type**: Unit
- **Traces**: `FR-crp-prompt-generate`, `AC-crp-generate-prompt-no-comments`
- **Preconditions**: A file is loaded with 2 comments. A prompt is generated.
- **Steps**:
  1. Delete the first comment. Assert prompt still exists (1 comment remains).
  2. Delete the second comment.
- **Expected**: After deleting the last comment, the prompt clears. The preview returns to the placeholder state.
- **Status**: Not started

---

#### `TC-crp-macos-prompt-auto-regenerates` -- Prompt auto-regenerates on comment changes
- **Type**: Unit
- **Traces**: `FR-crp-prompt-generate`
- **Preconditions**: A file is loaded with one comment on line 5 with text "Fix this".
- **Steps**:
  1. Record the generated prompt.
  2. Edit the comment text to "Fix this null check".
  3. Record the new prompt.
- **Expected**: The prompt text changes to reflect the updated comment. No manual regeneration step is needed.
- **Status**: Not started

---

#### `TC-crp-macos-prompt-out-of-range-comment` -- Prompt generation is crash-safe for out-of-range comment lines
- **Type**: Unit
- **Traces**: `FR-crp-prompt-generate`
- **Preconditions**: A file is loaded whose current content has fewer lines than a comment references (e.g. a 2-line file with a comment on lines 5-6), or a comment whose `endLine` precedes its `startLine`.
- **Steps**:
  1. Build a prompt for a file + an out-of-range comment.
  2. Build a prompt for a file + a comment with `endLine` < `startLine`.
- **Expected**: Neither call crashes (no "Range requires lowerBound <= upperBound" fatal error). The out-of-range comment's referenced-code snippet is empty, but its comment text is still present in the prompt.
- **Status**: Pass

#### Test Execution Results
- **Status**: Pass
- **TC slug**: `TC-crp-macos-prompt-out-of-range-comment`
- **Observed**: `PromptBuilder.build` returns a non-nil prompt containing the comment text; snippet is empty. Covered by `outOfRangeCommentDoesNotCrash` and `invertedCommentRangeDoesNotCrash` in `PromptBuilderTests`.

---

#### `TC-crp-macos-prompt-gen-time-under-300ms` -- Prompt generation completes within 300ms
- **Type**: Integration
- **Traces**: `NFR-crp-prompt-gen-time`
- **Preconditions**: A file with 10,000 lines and 200 comments is loaded.
- **Steps**:
  1. Add one more comment.
  2. Measure the time for the prompt state to update.
- **Expected**: The prompt regeneration completes within 300ms.
- **Status**: Not started

---

#### `TC-crp-macos-prompt-preview-live` -- Prompt preview updates in real-time
- **Type**: UI
- **Traces**: `FR-crp-prompt-preview`
- **Preconditions**: A file is loaded with the inspector sidebar visible.
- **Steps**:
  1. Add a comment on line 5.
  2. Observe the prompt preview panel in the inspector sidebar.
- **Expected**: The prompt preview immediately shows the generated prompt including the new comment. No manual refresh or button press is required.
- **Status**: Not started

---

#### `TC-crp-macos-copy-clipboard-happy` -- Copy prompt to clipboard
- **Type**: UI
- **Traces**: `FR-crp-prompt-copy`, `FR-crp-macos-clipboard`, `AC-crp-copy-clipboard`
- **Preconditions**: A file is loaded with at least one comment. A prompt is generated.
- **Steps**:
  1. Click the Copy Prompt toolbar button (or press Cmd+Shift+C).
  2. Open a text editor and paste.
- **Expected**: The prompt text is placed on the system clipboard. Pasting in the text editor produces the exact prompt text.
- **Status**: Not started

---

#### `TC-crp-macos-copy-toolbar-animation` -- Copy confirmation animates the toolbar icon
- **Type**: Manual
- **Traces**: `FR-crp-prompt-copy`, `AC-crp-copy-clipboard`
- **Preconditions**: A prompt has been generated.
- **Steps**:
  1. Click the Copy Prompt toolbar button.
  2. Observe the toolbar icon.
- **Expected**: The Copy Prompt icon briefly animates (a checkmark replaces the copy icon for approximately 2 seconds), then reverts to the copy icon. No toast or overlay is shown.
- **Status**: Not started

---

#### `TC-crp-macos-preview-matches-copy` -- Preview matches clipboard content
- **Type**: Integration
- **Traces**: `AC-crp-preview-matches-copy`
- **Preconditions**: A file is loaded with comments and an Overall Comment.
- **Steps**:
  1. Record the prompt text displayed in the preview.
  2. Copy to clipboard.
  3. Compare the clipboard content to the preview text.
- **Expected**: The clipboard content is byte-for-byte identical to the preview text.
- **Status**: Not started

---

### E. Multi-File

---

#### `TC-crp-macos-multi-file-load-adds` -- Loading a second file adds it to the session
- **Type**: Unit
- **Traces**: `FR-crp-multi-file-load`, `AC-crp-multi-file-load-adds`
- **Preconditions**: A file "utils.ts" is loaded.
- **Steps**:
  1. Load a second file "helpers.ts".
- **Expected**: Both files exist in the state. The file browser sidebar appears. The user can switch between them.
- **Status**: Not started

---

#### `TC-crp-macos-multi-file-drop-multiple` -- Multiple files dropped simultaneously
- **Type**: Integration
- **Traces**: `FR-crp-multi-file-load`, `AC-crp-multi-file-drop-multiple`
- **Preconditions**: Application is in the empty state.
- **Steps**:
  1. Send an action simulating a drop of 3 files at once.
- **Expected**: All 3 files are loaded into the session. The file browser appears. The last dropped file is the active file.
- **Status**: Not started

---

#### `TC-crp-macos-multi-file-switch-preserves` -- Switching files preserves comments and state
- **Type**: Unit
- **Traces**: `FR-crp-multi-file-nav`, `AC-crp-multi-file-nav-preserves-state`
- **Preconditions**: "utils.ts" has 3 comments and "helpers.ts" has 2 comments.
- **Steps**:
  1. Switch from "utils.ts" to "helpers.ts".
  2. Switch back to "utils.ts".
- **Expected**: All 3 comments on "utils.ts" are still present. All 2 comments on "helpers.ts" are still present. No state loss occurred.
- **Status**: Not started

---

#### `TC-crp-macos-multi-file-remove-with-comments` -- Removing a file with comments asks for confirmation
- **Type**: Unit
- **Traces**: `FR-crp-multi-file-remove`, `AC-crp-multi-file-remove-with-comments`
- **Preconditions**: "utils.ts" is loaded with 2 comments.
- **Steps**:
  1. Send the remove file action for "utils.ts".
- **Expected**: A confirmation dialog state is triggered (the state includes a pending confirmation). On confirm, the file and its comments are removed. On cancel, the file remains.
- **Status**: Not started

---

#### `TC-crp-macos-multi-file-remove-no-comments` -- Removing a file without comments requires no confirmation
- **Type**: Unit
- **Traces**: `FR-crp-multi-file-remove`, `AC-crp-multi-file-remove-no-comments`
- **Preconditions**: "helpers.ts" is loaded with no comments.
- **Steps**:
  1. Send the remove file action for "helpers.ts".
- **Expected**: The file is removed immediately without a confirmation step.
- **Status**: Not started

---

#### `TC-crp-macos-multi-file-remove-last-empty` -- Removing the last file returns to empty state
- **Type**: Unit
- **Traces**: `FR-crp-multi-file-remove`, `AC-crp-multi-file-empty-after-remove-last`
- **Preconditions**: Only one file is loaded (no comments).
- **Steps**:
  1. Remove the file.
- **Expected**: The application returns to the empty state. No files, no comments, no prompt. The file browser sidebar is hidden.
- **Status**: Not started

---

#### `TC-crp-macos-file-tree-disambiguates-same-name` -- Directory tree distinguishes same-named files
- **Type**: Unit
- **Traces**: `FR-crp-multi-file-nav`, `AC-crp-file-path-display`
- **Preconditions**: Two files are loaded: `src/utils/helpers.ts` and `lib/helpers.ts`.
- **Steps**:
  1. Assert the file tree structure.
- **Expected**: The file tree shows both files under their respective directory nodes (`src/utils/` and `lib/`), making them immediately distinguishable.
- **Status**: Not started

---

#### `TC-crp-macos-file-tree-single-dir` -- Directory tree shown for files in the same directory
- **Type**: Unit
- **Traces**: `FR-crp-multi-file-nav`, `AC-crp-file-path-single-dir`
- **Preconditions**: Two files in the same directory are loaded: `src/a.ts` and `src/b.ts`.
- **Steps**:
  1. Assert the file tree structure.
- **Expected**: Both files appear under the `src/` directory node in the tree. The directory structure is shown regardless of having only one directory.
- **Status**: Not started

---

#### `TC-crp-macos-file-tree-collapse-expand` -- Directory tree nodes can be collapsed and expanded
- **Type**: UI
- **Traces**: `FR-crp-multi-file-nav`
- **Preconditions**: Multiple files from different directories are loaded.
- **Steps**:
  1. Click the disclosure triangle on a directory node to collapse it.
  2. Verify the files within are hidden.
  3. Click again to expand.
  4. Expand/collapse several directory nodes repeatedly and observe the rows.
  5. Switch files and return.
- **Expected**: The collapse state toggles correctly. Files within a collapsed directory are hidden. The collapse state persists across file switches within the session. Rows render cleanly with **no ghosting/overlapping labels, flicker, or re-layout churn** (regression: the directory `DisclosureGroup` binding writes the exact expanded value via `directoryExpandedChanged(path:isExpanded:)` and must not feed back on itself).
- **Status**: Not started

---

#### `TC-crp-macos-multi-file-prompt-structure` -- Combined multi-file prompt has correct structure
- **Type**: Unit
- **Traces**: `FR-crp-multi-file-prompt`, `FR-crp-multi-file-prompt-format`, `AC-crp-multi-file-prompt-structure`
- **Preconditions**: "utils.ts" has comments on lines 3 and 10. "helpers.ts" has a comment on line 5. Overall Comment is "Refactor for consistency".
- **Steps**:
  1. Assert the generated prompt text.
- **Expected**: The prompt contains: (1) an Instructions section with the overall comment (once, not per-file), (2) a File section for "utils.ts" with 2 comments, (3) a File section for "helpers.ts" with 1 comment. Files ordered by load order.
- **Status**: Not started

---

#### `TC-crp-macos-multi-file-prompt-omits-uncommented` -- Files without comments omitted from prompt
- **Type**: Unit
- **Traces**: `FR-crp-multi-file-prompt-format`, `AC-crp-multi-file-prompt-omits-uncommented`
- **Preconditions**: 3 files loaded. Files A and C have comments. File B has no comments.
- **Steps**:
  1. Assert the generated prompt text.
- **Expected**: The prompt includes File sections for A and C only. File B is not mentioned in the prompt.
- **Status**: Not started

---

#### `TC-crp-macos-multi-file-comment-count-global` -- Comment count spans all files
- **Type**: Unit
- **Traces**: `FR-crp-comment-count`, `AC-crp-multi-file-comment-count`
- **Preconditions**: "utils.ts" has 3 comments and "helpers.ts" has 2 comments.
- **Steps**:
  1. Assert the global comment count.
- **Expected**: The total comment count is 5.
- **Status**: Not started

---

#### `TC-crp-macos-multi-file-clear-all` -- Clear session removes all files
- **Type**: Unit
- **Traces**: `FR-crp-clear-session`, `AC-crp-multi-file-clear-all`
- **Preconditions**: 3 files are loaded with various comments.
- **Steps**:
  1. Send the clear session action with confirmation.
- **Expected**: All files, comments, and the Overall Comment are removed. The state returns to the empty state.
- **Status**: Not started

---

### F. Review Status

---

#### `TC-crp-macos-mark-reviewed-happy` -- Mark a file as reviewed
- **Type**: Unit
- **Traces**: `FR-crp-file-reviewed-toggle`, `FR-crp-file-reviewed-visual`, `AC-crp-file-mark-reviewed`
- **Preconditions**: A file is loaded and currently unreviewed.
- **Steps**:
  1. Send the toggle-reviewed action for the file.
- **Expected**: The file's reviewed state is `true`. The file browser entry shows the reviewed visual treatment (e.g., checkmark). The file remains in its directory tree position.
- **Status**: Not started

---

#### `TC-crp-macos-unmark-reviewed-happy` -- Unmark a reviewed file
- **Type**: Unit
- **Traces**: `FR-crp-file-reviewed-toggle`, `FR-crp-file-reviewed-visual`, `AC-crp-file-unmark-reviewed`
- **Preconditions**: A file is marked as reviewed.
- **Steps**:
  1. Send the toggle-reviewed action for the file again.
- **Expected**: The file's reviewed state reverts to `false`. The visual treatment returns to unreviewed.
- **Status**: Not started

---

#### `TC-crp-macos-reviewed-grouping-tree` -- Reviewed files show indicators in the directory tree
- **Type**: Snapshot
- **Traces**: `FR-crp-file-reviewed-grouping`, `AC-crp-file-reviewed-grouping`
- **Preconditions**: 5 files are loaded across multiple directories. 2 are marked as reviewed.
- **Steps**:
  1. Render the file browser sidebar.
  2. Take a snapshot.
- **Expected**: All files appear in their directory positions. Reviewed files have visual indicators (checkmark, muted text). Unreviewed files appear before reviewed files within each directory. No "To Review" / "Reviewed" section headers exist.
- **Status**: Not started

---

#### `TC-crp-macos-reviewed-progress-count` -- Progress indicator shows correct count
- **Type**: Unit
- **Traces**: `FR-crp-file-reviewed-progress`, `AC-crp-file-reviewed-progress-count`
- **Preconditions**: 7 files loaded.
- **Steps**:
  1. Mark 3 files as reviewed. Assert progress is "3/7".
  2. Mark a 4th. Assert "4/7".
  3. Unmark one. Assert "3/7".
  4. Remove a reviewed file from the session. Assert "2/6".
  5. Add a new file. Assert "2/7".
- **Expected**: The progress indicator correctly reflects the reviewed/total count at each step.
- **Status**: Not started

---

#### `TC-crp-macos-reviewed-survives-tab-switch` -- Reviewed status persists across file switches
- **Type**: Unit
- **Traces**: `FR-crp-file-reviewed-persistence`, `AC-crp-file-reviewed-survives-tab-switch`
- **Preconditions**: "utils.ts" is marked as reviewed. "helpers.ts" is not.
- **Steps**:
  1. Switch from "utils.ts" to "helpers.ts".
  2. Switch back to "utils.ts".
  3. Assert both files' reviewed states.
- **Expected**: "utils.ts" is still reviewed. "helpers.ts" is still unreviewed.
- **Status**: Not started

---

#### `TC-crp-macos-reviewed-independent-of-comments` -- Reviewed status is independent of comments
- **Type**: Unit
- **Traces**: `FR-crp-file-reviewed-toggle`, `AC-crp-file-reviewed-with-comments`
- **Preconditions**: A file has 5 comments and is marked as reviewed.
- **Steps**:
  1. Delete all 5 comments from the file.
  2. Assert the file's reviewed state.
- **Expected**: The file remains marked as reviewed. Deleting comments does not change reviewed status.
- **Status**: Not started

---

#### `TC-crp-macos-reviewed-clear-session-resets` -- Clear session resets reviewed statuses
- **Type**: Unit
- **Traces**: `FR-crp-file-reviewed-persistence`, `AC-crp-file-reviewed-clear-session`
- **Preconditions**: 3 files are marked as reviewed.
- **Steps**:
  1. Send the clear session action with confirmation.
- **Expected**: All files are removed. If new files are loaded, they all start as unreviewed.
- **Status**: Not started

---

### G. Review Context (Shepherd Review Mode)

---

#### `TC-crp-macos-context-overall-visible` -- Overall changeset context is visible
- **Type**: Snapshot
- **Traces**: `FR-crp-review-context-receive`, `FR-crp-review-context-display`, `FR-crp-review-context-overall`, `AC-crp-context-overall-visible`
- **Preconditions**: Application is launched with session data that includes overall context (neutral + review feedback).
- **Steps**:
  1. Render the inspector sidebar.
  2. Take a snapshot.
- **Expected**: The ReviewContextSection is visible in the inspector sidebar. Both neutral context and review feedback sections are displayed with visually distinct styling.
- **Status**: Not started

---

#### `TC-crp-macos-context-per-file-visible` -- Per-file context is visible
- **Type**: Snapshot
- **Traces**: `FR-crp-review-context-per-file`, `AC-crp-context-per-file-visible`
- **Preconditions**: A file loaded via shepherd-review has per-file context data (neutral + review feedback).
- **Steps**:
  1. View the file in the code viewer.
  2. Take a snapshot of the ReviewContextPanel area.
- **Expected**: The per-file context panel is visible below the ActiveFilePath (multi-file) or FileHeader (single-file). Both neutral context and review feedback are displayed with distinct styling.
- **Status**: Not started

---

#### `TC-crp-macos-context-per-file-switches` -- Per-file context updates when switching files
- **Type**: Unit
- **Traces**: `FR-crp-review-context-per-file`, `AC-crp-context-per-file-switches`
- **Preconditions**: Files A and B both have per-file context data.
- **Steps**:
  1. View file A. Record its context data.
  2. Switch to file B.
  3. Assert the displayed context data.
- **Expected**: The per-file context updates to show file B's context, not file A's.
- **Status**: Not started

---

#### `TC-crp-macos-context-neutral-vs-review` -- Neutral context and review feedback are visually distinct
- **Type**: Snapshot
- **Traces**: `FR-crp-review-context-display`, `AC-crp-context-neutral-vs-review`
- **Preconditions**: Context data with both neutral and review feedback sections is loaded.
- **Steps**:
  1. Render the context panel.
  2. Take a snapshot.
- **Expected**: The neutral context section and review feedback section have distinct visual treatments (different headers, styling, or containers). A user can immediately distinguish factual description from agent opinion.
- **Status**: Not started

---

#### `TC-crp-macos-context-graceful-missing` -- No context panel when context data is absent
- **Type**: Unit
- **Traces**: `FR-crp-review-context-receive`, `AC-crp-context-graceful-missing`
- **Preconditions**: A file is loaded via paste/upload with no context data.
- **Steps**:
  1. Assert the state for the context panel visibility.
- **Expected**: No context panel is shown for the file. No empty or placeholder context state appears. The code viewer uses the full available space.
- **Status**: Not started

---

#### `TC-crp-macos-context-readonly` -- Context is read-only
- **Type**: UI
- **Traces**: `AC-crp-context-readonly`
- **Preconditions**: Context data is displayed (neutral context and review feedback).
- **Steps**:
  1. Attempt to click on and type into the neutral context text.
  2. Attempt to click on and type into the review feedback text.
- **Expected**: Neither section is editable. No cursor appears and no text can be entered. The context is strictly read-only.
- **Status**: Not started

---

#### `TC-crp-macos-context-sidebar-collapse` -- Sidebar review context can be collapsed and expanded
- **Type**: UI
- **Traces**: `FR-crp-review-context-collapsible`, `AC-crp-context-sidebar-collapse`
- **Preconditions**: Overall changeset context is displayed in the inspector sidebar.
- **Steps**:
  1. Click the collapse control on the review context section.
  2. Verify the content collapses to just a header bar.
  3. Switch to another file and back.
  4. Verify the collapse state persists.
  5. Click to expand again.
  6. Verify the full content reappears.
  7. Expand and collapse repeatedly (including the per-file panel over the code viewer) and observe the window.
- **Expected**: Collapse and expand toggle works. Collapse state persists across file switches. Content fully collapses to save vertical space and fully restores on expand. Each expand/collapse settles immediately in the requested state with **no flicker, no continuous re-layout, and no loss of scrolling** in any pane (regression: the `DisclosureGroup` binding writes the exact expanded value and must not feed back on itself — see `expandedChanged(Bool)` in the engineering spec).
- **Status**: Not started

---

### H. macOS-Specific: Window Management

---

#### `TC-crp-macos-window-multi-session` -- Each session opens in its own window
- **Type**: Manual
- **Traces**: `FR-crp-macos-window-management`, `AC-crp-macos-window-open`
- **Preconditions**: Application is running with one session window open.
- **Steps**:
  1. Launch a new session via the CLI with a different session ID.
  2. Observe the windows.
- **Expected**: A new window opens for the new session. Both windows are visible and operate independently. Each shows its own session context in the title bar.
- **Status**: Not started

---

#### `TC-crp-macos-window-restore-geometry` -- Window position and size are remembered
- **Type**: Manual
- **Traces**: `FR-crp-macos-window-management`, `AC-crp-macos-window-restore`
- **Preconditions**: Application is running.
- **Steps**:
  1. Resize the window to a non-default size (e.g., 1200x800).
  2. Move the window to a specific position on screen.
  3. Quit the application (Cmd+Q).
  4. Relaunch the application.
- **Expected**: The new window opens at the previously saved position and size (approximately 1200x800 at the saved position).
- **Status**: Not started

---

#### `TC-crp-macos-window-deduplicate` -- Duplicate session raises existing window
- **Type**: Manual
- **Traces**: `FR-crp-macos-slash-command-launch`, `AC-crp-macos-window-deduplicate`
- **Preconditions**: A session with ID "abc123" is already open in a window.
- **Steps**:
  1. Via the CLI, launch the application again with session ID "abc123".
- **Expected**: No new window opens. The existing window for session "abc123" is brought to the front. Focus moves to the existing window.
- **Status**: Not started

---

#### `TC-crp-macos-multi-window-independent` -- Windows operate independently
- **Type**: Manual
- **Traces**: `FR-crp-macos-window-management`, `AC-crp-macos-multi-window-independent`
- **Preconditions**: Two session windows are open.
- **Steps**:
  1. Load a file and add a comment in window A.
  2. Check window B.
- **Expected**: Window B is unaffected. Its files, comments, and state remain unchanged. Actions in one window do not affect the other.
- **Status**: Not started

---

#### `TC-crp-macos-close-last-window-keeps-running` -- Closing the last window keeps app running
- **Type**: Manual
- **Traces**: `FR-crp-macos-auto-close`, `AC-crp-macos-close-last-window`
- **Preconditions**: Only one window is open.
- **Steps**:
  1. Close the window (click the close button or press Cmd+W).
  2. Check the Dock.
  3. Click the application icon in the Dock.
- **Expected**: After closing, the application remains running (visible in the Dock with an indicator dot). Clicking the Dock icon can reactivate the application (though no window opens unless a new session is launched).
- **Status**: Not started

---

#### `TC-crp-macos-window-min-size` -- Window respects minimum size
- **Type**: Manual
- **Traces**: `FR-crp-macos-window-management`
- **Preconditions**: Application is running with a file loaded.
- **Steps**:
  1. Attempt to resize the window to very small dimensions by dragging the corner.
- **Expected**: The window stops resizing at a minimum size where all panels (file browser, code viewer, inspector sidebar) remain usable. The window cannot be made smaller than this minimum.
- **Status**: Not started

---

### I. macOS-Specific: Menu Bar & Keyboard

---

#### `TC-crp-macos-menu-copy-disabled` -- Copy Prompt menu item disabled without comments
- **Type**: UI
- **Traces**: `FR-crp-macos-menu-bar`, `AC-crp-macos-menu-copy-disabled`
- **Preconditions**: A file is loaded but no comments exist.
- **Steps**:
  1. Open the Review menu.
  2. Locate the Copy Prompt menu item.
- **Expected**: The Copy Prompt menu item is disabled (grayed out). After adding a comment, the menu item becomes enabled.
- **Status**: Not started

---

#### `TC-crp-macos-menu-shortcuts-displayed` -- Menu items show keyboard shortcuts
- **Type**: Manual
- **Traces**: `FR-crp-macos-menu-bar`, `AC-crp-macos-menu-shortcuts`
- **Preconditions**: Application is running.
- **Steps**:
  1. Open the File menu. Verify Open shows Cmd+O.
  2. Open the Edit menu. Verify Copy shows Cmd+C.
  3. Check other menus for shortcut display.
- **Expected**: Every menu item that has a keyboard shortcut displays the shortcut key combination alongside the item name (right-aligned, in the standard macOS format).
- **Status**: Not started

---

#### `TC-crp-macos-menu-standard-items` -- Application menu includes standard items
- **Type**: Manual
- **Traces**: `FR-crp-macos-menu-bar`
- **Preconditions**: Application is running.
- **Steps**:
  1. Click the application name in the menu bar.
  2. Inspect the menu items.
- **Expected**: The application menu includes About, Preferences (Settings), and Quit items, following standard macOS conventions.
- **Status**: Not started

---

#### `TC-crp-macos-keyboard-open-file` -- Open file via keyboard shortcut
- **Type**: UI
- **Traces**: `FR-crp-macos-keyboard-shortcuts`, `NFR-crp-accessibility-keyboard`
- **Preconditions**: Application is running.
- **Steps**:
  1. Press Cmd+O.
- **Expected**: The native file open panel appears.
- **Status**: Not started

---

#### `TC-crp-macos-keyboard-copy-prompt` -- Copy prompt via keyboard shortcut
- **Type**: UI
- **Traces**: `FR-crp-macos-keyboard-shortcuts`, `NFR-crp-accessibility-keyboard`
- **Preconditions**: A file is loaded with at least one comment.
- **Steps**:
  1. Press Cmd+Shift+C.
- **Expected**: The prompt is copied to the system clipboard. The toolbar Copy icon shows the checkmark animation.
- **Status**: Not started

---

#### `TC-crp-macos-keyboard-close-window` -- Close window via keyboard shortcut
- **Type**: UI
- **Traces**: `FR-crp-macos-keyboard-shortcuts`
- **Preconditions**: Application is running with one window open.
- **Steps**:
  1. Press Cmd+W.
- **Expected**: The current window closes. The application continues running (no windows visible, Dock indicator remains).
- **Status**: Not started

---

#### `TC-crp-macos-keyboard-undo-redo` -- Undo and redo work for comment editing
- **Type**: UI
- **Traces**: `FR-crp-macos-keyboard-shortcuts`
- **Preconditions**: A file is loaded. The user has just added a comment.
- **Steps**:
  1. Press Cmd+Z (Undo).
  2. Press Cmd+Shift+Z (Redo).
- **Expected**: Undo removes the comment (or reverts the last edit). Redo restores it. Undo and Redo work within the context of comment editing.
- **Status**: Not started

---

### J. macOS-Specific: System Integration

---

#### `TC-crp-macos-appearance-follows-system` -- Appearance follows system setting
- **Type**: Manual
- **Traces**: `FR-crp-macos-system-appearance`, `AC-crp-macos-appearance-follows-system`
- **Preconditions**: Application is running.
- **Steps**:
  1. Set macOS System Settings to dark appearance.
  2. Observe the application.
  3. Switch the system to light appearance.
  4. Observe the application again.
- **Expected**: The application renders with dark appearance when the system is dark, and light appearance when the system is light. The switch happens without restarting the application.
- **Status**: Not started

---

#### `TC-crp-macos-no-appearance-toggle` -- No in-app appearance toggle exists
- **Type**: Manual
- **Traces**: `FR-crp-macos-system-appearance`, `AC-crp-macos-no-appearance-toggle`
- **Preconditions**: Application is running.
- **Steps**:
  1. Inspect the toolbar, menus, and preferences for any light/dark mode toggle.
- **Expected**: No in-app appearance toggle or setting exists. The appearance is controlled solely by the macOS system setting.
- **Status**: Not started

---

#### `TC-crp-macos-slash-command-launch-session` -- CLI launch opens session with data
- **Type**: Integration
- **Traces**: `FR-crp-macos-slash-command-launch`, `AC-crp-macos-slash-command-launch-session`
- **Preconditions**: Session data exists at `~/.shepherd/sessions/test-session/` with file data and context.
- **Steps**:
  1. Launch the application from the CLI with session ID "test-session".
  2. Observe the window.
- **Expected**: The application opens a new window. Files from the session directory are loaded. Context data is displayed. The window title reflects the session context. The Done button is visible in the toolbar.
- **Status**: Not started

---

#### `TC-crp-macos-standalone-open-panel` -- Standalone mode supports file open panel
- **Type**: UI
- **Traces**: `FR-crp-macos-standalone-mode`, `AC-crp-macos-standalone-open-panel`
- **Preconditions**: Application is launched without a session ID (standalone mode).
- **Steps**:
  1. Press Cmd+O.
  2. Select a file and click Open.
- **Expected**: The native file open panel appears. Files can be loaded. The Done button is not visible. The Copy button is the primary action.
- **Status**: Not started

---

#### `TC-crp-macos-signed-notarized` -- Application passes Gatekeeper
- **Type**: Manual
- **Traces**: `FR-crp-macos-distribution`, `AC-crp-macos-signed-notarized`
- **Preconditions**: The application has been downloaded from the distribution channel (not built locally from Xcode).
- **Steps**:
  1. Download the application bundle.
  2. Double-click to open it for the first time.
- **Expected**: macOS does not show an "unidentified developer" warning. The application opens normally. Gatekeeper verification passes.
- **Status**: Not started

---

#### `TC-crp-macos-no-network-traffic` -- No network traffic leaves the machine
- **Type**: Manual
- **Traces**: `NFR-crp-client-only`
- **Preconditions**: Application is running. A network monitoring tool (e.g., `nettop`, Little Snitch, or Wireshark) is active.
- **Steps**:
  1. Load files, add comments, generate a prompt, and copy it.
  2. Monitor outbound network traffic from the application process.
- **Expected**: Zero outbound network connections are made by the application. In slash command mode, the only local I/O is reading/writing to `~/.shepherd/sessions/`.
- **Status**: Not started

---

### K. macOS-Specific: Performance

---

#### `TC-crp-macos-launch-cold-time` -- Cold launch within 1 second
- **Type**: Manual
- **Traces**: `NFR-crp-macos-launch-time`, `AC-crp-macos-launch-cold`
- **Preconditions**: Application is not running (force-quit if necessary). No other heavy processes are running.
- **Steps**:
  1. Time the launch from double-clicking the app icon (or CLI invocation) to when the window is visible and interactive.
- **Expected**: The window is visible and interactive within 1 second. The user can immediately begin loading files or viewing session data.
- **Status**: Not started

---

#### `TC-crp-macos-memory-typical-session` -- Memory under 200MB for typical session
- **Type**: Manual
- **Traces**: `NFR-crp-macos-memory`, `AC-crp-macos-memory-typical`
- **Preconditions**: Application is running.
- **Steps**:
  1. Load 10 files with a total of 50 comments spread across the files.
  2. Open Activity Monitor and check the application's memory usage.
- **Expected**: Memory usage does not exceed 200 MB.
- **Status**: Not started

---

#### `TC-crp-macos-memory-idle` -- Memory under 80MB when idle
- **Type**: Manual
- **Traces**: `NFR-crp-macos-memory`
- **Preconditions**: Application is running with no files loaded (empty state).
- **Steps**:
  1. Open Activity Monitor and check the application's memory usage.
- **Expected**: Memory usage is under 80 MB.
- **Status**: Not started

---

#### `TC-crp-macos-min-version-enforced` -- Application requires macOS 14+
- **Type**: Manual
- **Traces**: `NFR-crp-macos-min-version`, `AC-crp-macos-min-version-enforced`
- **Preconditions**: Access to a machine running macOS 13 or earlier (or a build configuration check).
- **Steps**:
  1. Verify the application's deployment target is set to macOS 14.
  2. Attempt to launch on macOS 13 (if available).
- **Expected**: On macOS 13, the application does not launch (or shows an informative error). On macOS 14+, it launches normally.
- **Status**: Not started

---

### L. Done Action & Session

---

#### `TC-crp-macos-done-sends-prompt` -- Done action sends prompt to session directory
- **Type**: Integration
- **Traces**: `FR-crp-done-action`, `FR-crp-prompt-handoff`, `AC-crp-done-sends-prompt`
- **Preconditions**: Application is running in slash command mode with session ID "test-session". At least one comment exists.
- **Steps**:
  1. Send the Done action.
  2. Check `~/.shepherd/sessions/test-session/prompt-output.md`.
- **Expected**: The generated prompt text is written to `~/.shepherd/sessions/test-session/prompt-output.md`. The prompt is also placed on the system clipboard.
- **Status**: Not started

---

#### `TC-crp-macos-done-auto-close-reliable` -- Done action reliably closes the window
- **Type**: Integration
- **Traces**: `FR-crp-macos-auto-close`, `AC-crp-macos-auto-close-reliable`, `AC-crp-done-auto-close`
- **Preconditions**: Application is running in slash command mode with a file and comments.
- **Steps**:
  1. Click Done.
  2. Observe the window.
- **Expected**: The window closes after the handoff succeeds. Focus returns to the previously active application (typically the terminal). No fallback confirmation state is shown because the close is always reliable on macOS.
- **Status**: Not started

---

#### `TC-crp-macos-done-fallback-clipboard` -- Done falls back to clipboard on handoff failure
- **Type**: Integration
- **Traces**: `FR-crp-prompt-handoff`, `AC-crp-done-fallback-clipboard`
- **Preconditions**: Application is running in slash command mode. The session directory is not writable (simulated write failure).
- **Steps**:
  1. Click Done.
- **Expected**: A native alert appears: "Could Not Send to Agent" / "The prompt was copied to your clipboard instead. Switch to your terminal and paste manually." The prompt is on the system clipboard.
- **Status**: Not started

---

#### `TC-crp-macos-done-disabled-no-comments` -- Done button disabled when no comments exist
- **Type**: Unit
- **Traces**: `FR-crp-done-action`, `AC-crp-done-disabled-no-comments`
- **Preconditions**: Application is in slash command mode with a file loaded but no comments.
- **Steps**:
  1. Assert the Done button enabled state.
- **Expected**: The Done button is disabled. After adding a comment, it becomes enabled.
- **Status**: Not started

---

#### `TC-crp-macos-done-hidden-standalone` -- Done button hidden in standalone mode
- **Type**: Unit
- **Traces**: `FR-crp-macos-standalone-mode`, `AC-crp-done-standalone-hidden`, `AC-crp-macos-standalone-no-done`
- **Preconditions**: Application is launched without a session ID.
- **Steps**:
  1. Assert whether the Done button is present in the toolbar.
- **Expected**: The Done button is not shown. The Copy button is the primary action.
- **Status**: Not started

---

#### `TC-crp-macos-session-identity-title` -- Session context shown in window title
- **Type**: UI
- **Traces**: `FR-crp-session-identity`
- **Preconditions**: Application is launched via slash command with session context "myproject".
- **Steps**:
  1. Observe the window title bar.
- **Expected**: The window title displays "Shepherd -- myproject" (or similar format reflecting the session context).
- **Status**: Not started

---

#### `TC-crp-macos-session-identity-standalone` -- Standalone mode shows generic title
- **Type**: UI
- **Traces**: `FR-crp-session-identity`
- **Preconditions**: Application is launched without a session ID.
- **Steps**:
  1. Observe the window title bar.
- **Expected**: The window title displays "Shepherd" (generic label).
- **Status**: Not started

---

#### `TC-crp-macos-clear-confirmation-dialog` -- Clear session shows confirmation dialog
- **Type**: Unit
- **Traces**: `FR-crp-clear-session`, `AC-crp-clear-confirmation`
- **Preconditions**: A file is loaded with at least one comment.
- **Steps**:
  1. Send the clear session action.
- **Expected**: A confirmation state is triggered. On confirm, all files, comments, and the Overall Comment are removed. On cancel, everything is preserved.
- **Status**: Not started

---

#### `TC-crp-macos-clear-cancel-preserves` -- Canceling clear preserves all state
- **Type**: Unit
- **Traces**: `FR-crp-clear-session`, `AC-crp-clear-confirmation`
- **Preconditions**: A file is loaded with comments and an Overall Comment.
- **Steps**:
  1. Send the clear session action.
  2. Cancel the confirmation.
- **Expected**: All files, comments, and the Overall Comment remain intact. No state was lost.
- **Status**: Not started

---

#### `TC-crp-macos-clear-no-confirm-empty` -- Clear skips confirmation when no comments exist
- **Type**: Unit
- **Traces**: `FR-crp-clear-session`, `AC-crp-clear-no-confirm-empty`
- **Preconditions**: A file is loaded but no comments exist.
- **Steps**:
  1. Send the clear session action.
- **Expected**: The session clears immediately without a confirmation step.
- **Status**: Not started

---

### M. Overall Comment & Comment Summary

---

#### `TC-crp-macos-overall-comment-label` -- Overall Comment field is correctly labeled
- **Type**: Snapshot
- **Traces**: `FR-crp-prompt-preamble`, `AC-crp-overall-comment-label`
- **Preconditions**: A file is loaded. The inspector sidebar is visible.
- **Steps**:
  1. Take a snapshot of the Overall Comment section in the inspector sidebar.
- **Expected**: The field is labeled "Overall Comment" (not "Preamble"). Placeholder text indicates it applies to all files and will be included at the top of the generated prompt.
- **Status**: Not started

---

#### `TC-crp-macos-overall-comment-in-prompt` -- Overall Comment appears once in multi-file prompt
- **Type**: Unit
- **Traces**: `FR-crp-prompt-preamble`, `AC-crp-overall-comment-in-prompt`
- **Preconditions**: Two files are loaded with comments. An Overall Comment "Refactor for readability" is entered.
- **Steps**:
  1. Assert the generated prompt text.
- **Expected**: The overall comment text appears exactly once at the top of the prompt in the "Instructions" section. It is not duplicated per file.
- **Status**: Not started

---

#### `TC-crp-macos-comment-summary-shows-all` -- All Comments summary shows comments organized by file
- **Type**: Unit
- **Traces**: `FR-crp-comment-summary`, `AC-crp-comment-summary-shows-all`
- **Preconditions**: File A has 2 comments, file B has 3 comments, file C has 0 comments.
- **Steps**:
  1. Switch to the "All Comments" tab in the inspector sidebar.
  2. Assert the summary content.
- **Expected**: All 5 comments are shown, organized under file A (2) and file B (3). File C is not listed.
- **Status**: Not started

---

#### `TC-crp-macos-comment-summary-realtime` -- All Comments summary updates in real-time
- **Type**: Unit
- **Traces**: `FR-crp-comment-summary`, `AC-crp-comment-summary-realtime`
- **Preconditions**: The All Comments view is active. A file is loaded.
- **Steps**:
  1. Add a comment on line 5 of the active file.
  2. Assert the summary state.
- **Expected**: The summary immediately reflects the new comment without a manual refresh.
- **Status**: Not started

---

#### `TC-crp-macos-comment-summary-empty` -- All Comments summary shows empty state
- **Type**: Unit
- **Traces**: `FR-crp-comment-summary`, `AC-crp-comment-summary-empty`
- **Preconditions**: Files are loaded but no comments exist.
- **Steps**:
  1. Switch to the "All Comments" tab.
  2. Assert the summary state.
- **Expected**: A message like "No comments yet" is displayed instead of an empty list.
- **Status**: Not started

---

### N. Empty State & Miscellaneous

---

#### `TC-crp-macos-empty-state-instructions` -- Empty state displays load instructions
- **Type**: Snapshot
- **Traces**: `AC-crp-empty-state`
- **Preconditions**: Application is in the initial empty state.
- **Steps**:
  1. Take a snapshot of the empty state screen.
- **Expected**: A centered drop zone with an SF Symbol (doc.badge.plus), instructional text "Drop files here or press Cmd+O to open", and subtext "Accepts any plain-text file." is visible. The toolbar Copy Prompt is disabled. The Line Wrap toggle is disabled.
- **Status**: Not started

---

#### `TC-crp-macos-empty-state-buttons-disabled` -- Toolbar buttons disabled in empty state
- **Type**: Unit
- **Traces**: `AC-crp-empty-state`
- **Preconditions**: Application is in the empty state.
- **Steps**:
  1. Assert the enabled state of toolbar items.
- **Expected**: Open is enabled. Copy Prompt is disabled. Line Wrap toggle is disabled. Comment navigation is disabled. Done (if in slash command mode) is disabled.
- **Status**: Not started

---

### O. Panel Resize

---

#### `TC-crp-macos-panel-resize-drag` -- File browser sidebar resizes by dragging
- **Type**: UI
- **Traces**: `FR-crp-panel-resize`, `AC-crp-panel-resize-drag`
- **Preconditions**: Two or more files are loaded. The file browser sidebar is visible.
- **Steps**:
  1. Click and drag the split view divider between the file browser and code viewer to the right.
  2. Release.
- **Expected**: The file browser sidebar width increases smoothly following the mouse. The code viewer panel adjusts to fill the remaining space. No layout jank is visible.
- **Status**: Not started

---

#### `TC-crp-macos-panel-resize-min-max` -- Resize respects minimum and maximum width
- **Type**: UI
- **Traces**: `FR-crp-panel-resize`, `AC-crp-panel-resize-bounds`
- **Preconditions**: The file browser sidebar is visible.
- **Steps**:
  1. Drag the divider to the far left (toward minimum).
  2. Drag the divider to the far right (toward maximum).
- **Expected**: The sidebar stops shrinking at the minimum width. The sidebar stops growing at the maximum width. The code viewer always retains enough width to be usable.
- **Status**: Not started

---

#### `TC-crp-macos-panel-resize-double-click-reset` -- Double-click resets sidebar to default width
- **Type**: UI
- **Traces**: `FR-crp-panel-resize`, `AC-crp-panel-resize-double-click`
- **Preconditions**: The file browser sidebar has been resized to a non-default width.
- **Steps**:
  1. Double-click the split view divider.
- **Expected**: The sidebar returns to its default width (220pt).
- **Status**: Not started

---

#### `TC-crp-macos-panel-resize-persists-file-switch` -- Resize persists across file switches
- **Type**: UI
- **Traces**: `FR-crp-panel-resize`, `AC-crp-panel-resize-persists`
- **Preconditions**: Multiple files are loaded. The sidebar has been resized.
- **Steps**:
  1. Resize the file browser to approximately 350pt.
  2. Switch between files.
- **Expected**: The file browser remains at the resized width after switching files.
- **Status**: Not started

---

### P. Active File Path & Tooltips

---

#### `TC-crp-macos-active-file-path-visible` -- Active file path displayed in multi-file mode
- **Type**: Snapshot
- **Traces**: `FR-crp-active-file-path`, `AC-crp-active-file-path-visible`
- **Preconditions**: Two files are loaded. The active file is `src/components/FileBrowser.tsx`.
- **Steps**:
  1. Take a snapshot of the top of the code viewer panel.
- **Expected**: The full path `src/components/FileBrowser.tsx` is displayed at the top of the code viewer in a breadcrumb-style bar, above the code content.
- **Status**: Not started

---

#### `TC-crp-macos-active-file-path-switches` -- File path updates when switching files
- **Type**: Unit
- **Traces**: `FR-crp-active-file-path`, `AC-crp-active-file-path-switches`
- **Preconditions**: Two files are loaded: `src/utils.ts` and `src/helpers.ts`. Active file is `src/utils.ts`.
- **Steps**:
  1. Switch to `src/helpers.ts`.
  2. Assert the active file path display.
- **Expected**: The active file path immediately updates to `src/helpers.ts`.
- **Status**: Not started

---

#### `TC-crp-macos-active-file-path-hidden-single` -- Active file path not shown in single-file mode
- **Type**: Unit
- **Traces**: `FR-crp-active-file-path`, `AC-crp-active-file-path-single-file`
- **Preconditions**: Exactly one file is loaded.
- **Steps**:
  1. Assert whether the ActiveFilePath component is rendered.
- **Expected**: The ActiveFilePath is not rendered. The FileHeader is shown instead.
- **Status**: Not started

---

#### `TC-crp-macos-file-tooltip-full-path` -- Hover shows full path tooltip
- **Type**: UI
- **Traces**: `FR-crp-file-tooltip`, `AC-crp-file-tooltip-full-path`
- **Preconditions**: A file with a long path (e.g., `src/components/deeply/nested/VeryLongComponentName.tsx`) is loaded. The file name is truncated in the sidebar.
- **Steps**:
  1. Hover over the file's row in the file browser sidebar.
  2. Wait for the tooltip to appear.
- **Expected**: A tooltip displays the full untruncated path, the detected language (e.g., "TypeScript"), and the review status.
- **Status**: Not started

---

#### `TC-crp-macos-file-tooltip-reviewed-status` -- Tooltip reflects review status
- **Type**: UI
- **Traces**: `FR-crp-file-tooltip`, `AC-crp-file-tooltip-reviewed`
- **Preconditions**: A file is marked as reviewed.
- **Steps**:
  1. Hover over the reviewed file's row in the file browser sidebar.
- **Expected**: The tooltip includes "Reviewed" in the status (e.g., "src/utils.ts -- TypeScript -- Reviewed").
- **Status**: Not started

---

### Q. Contextual Paste & Session Non-Persistence

---

#### `TC-crp-macos-paste-contextual-file-load` -- Cmd+V loads file content when no text input is focused
- **Type**: UI
- **Traces**: `FR-crp-macos-keyboard-shortcuts`, `FR-crp-file-load`
- **Preconditions**: Application is in the empty state. Plain text content is on the system clipboard. No text input field is focused.
- **Steps**:
  1. Press Cmd+V.
- **Expected**: The clipboard content is loaded as a new file in the session (same as paste-to-load behavior). The code viewer displays the pasted content with line numbers.
- **Status**: Not started

---

#### `TC-crp-macos-paste-contextual-text-edit` -- Cmd+V pastes text when a text input is focused
- **Type**: UI
- **Traces**: `FR-crp-macos-keyboard-shortcuts`
- **Preconditions**: A file is loaded. The Overall Comment text editor is focused. Text is on the system clipboard.
- **Steps**:
  1. Press Cmd+V.
- **Expected**: The clipboard text is inserted into the Overall Comment editor (standard text paste behavior). No new file is loaded.
- **Status**: Not started

---

#### `TC-crp-macos-session-data-not-persisted` -- Session data is lost on quit and relaunch
- **Type**: Manual
- **Traces**: `NFR-crp-no-data-persistence`
- **Preconditions**: Application is running with 3 files loaded and 5 comments placed.
- **Steps**:
  1. Quit the application (Cmd+Q).
  2. Relaunch the application.
- **Expected**: The application opens in the empty state. No files, comments, or preamble text from the previous session are present. Window position and size ARE restored (per `FR-crp-macos-window-management`), but session content is not.
- **Status**: Not started

---

## Edge Cases & Error Scenarios

### Binary file mixed with text files in multi-drop
- **Trigger**: User drops 5 files from Finder, 2 of which are binary.
- **Expected behavior**: The 3 text files load successfully. Each binary file gets its own rejection alert. The session contains only the 3 valid files.
- **Test case**: `TC-crp-macos-binary-rejected-drag-drop`

### Empty clipboard paste
- **Trigger**: User presses Cmd+V with an empty clipboard or non-text clipboard content.
- **Expected behavior**: Nothing happens. The application remains in its current state. No error is shown.
- **Test case**: `TC-crp-macos-load-paste-empty-clipboard`

### Overall Comment with only whitespace
- **Trigger**: User types only spaces and newlines in the Overall Comment field.
- **Expected behavior**: The whitespace-only preamble is treated as empty and does not appear in the generated prompt (no "Instructions" section).
- **Test case**: `TC-crp-macos-overall-comment-in-prompt`

### Comment references a line beyond the current file
- **Trigger**: A comment's `startLine`/`endLine` fall outside the file's current line count (e.g. a stale comment after the file content shrank, or a malformed inverted range), then a prompt is generated.
- **Expected behavior**: Prompt generation does not crash. The referenced-code snippet for the out-of-range comment is empty; the comment text is still included. All in-range comments render normally.
- **Test case**: `TC-crp-macos-prompt-out-of-range-comment`

### Session directory write failure during Done
- **Trigger**: The session directory is not writable (e.g., permissions issue) when the user clicks Done.
- **Expected behavior**: The prompt is copied to the clipboard as a fallback. A native alert informs the user to paste manually.
- **Test case**: `TC-crp-macos-done-fallback-clipboard`

### File with Windows-style line endings
- **Trigger**: A file with `\r\n` line endings is loaded.
- **Expected behavior**: Line numbers are correct. No extra blank lines appear. The file renders identically to the Unix line-ending version.
- **Test case**: `TC-crp-macos-load-paste-happy` (edge case note)

### Rapid double-click on Done
- **Trigger**: User double-clicks the Done button quickly.
- **Expected behavior**: The handoff occurs exactly once. The window closes once. No duplicate writes to the session directory.
- **Test case**: Covered implicitly by `TC-crp-macos-done-sends-prompt`

### File loaded via paste with no name in multi-file mode
- **Trigger**: User pastes content (no file name) while other named files are loaded.
- **Expected behavior**: The pasted file appears at the root level of the file tree as "Untitled". The active file path shows "Untitled". Tooltip shows "Untitled".
- **Test case**: Covered by `TC-crp-macos-active-file-path-visible` (edge case), `TC-crp-macos-file-tooltip-full-path` (edge case)

### Removing the active file when multiple files exist
- **Trigger**: User removes the currently active file from a multi-file session.
- **Expected behavior**: The application switches to an adjacent file. The removed file's comments are discarded. If it was the last file, the application returns to the empty state.
- **Test case**: `TC-crp-macos-multi-file-remove-with-comments`, `TC-crp-macos-multi-file-remove-last-empty`

### All files in a directory marked as reviewed
- **Trigger**: Every file within a directory node is marked as reviewed.
- **Expected behavior**: The directory node itself shows a reviewed indicator (e.g., a checkmark) to communicate its status when collapsed.
- **Test case**: `TC-crp-macos-reviewed-grouping-tree`

---

## Regression Considerations

### File loading regressions
- Adding new file loading mechanisms (e.g., future URL-based loading) must not break existing paste, open panel, and drag-and-drop flows.
- Binary detection logic changes could cause false positives (rejecting valid text files) or false negatives (loading binary files).

### Prompt generation regressions
- Changes to the prompt format must be verified against `TC-crp-macos-prompt-structure-happy` and `TC-crp-macos-multi-file-prompt-structure`.
- The 300ms generation time threshold (`TC-crp-macos-prompt-gen-time-under-300ms`) must be re-verified after any prompt generation logic changes.

### Window management regressions
- Changes to window lifecycle must not break session deduplication (`TC-crp-macos-window-deduplicate`) or window geometry persistence (`TC-crp-macos-window-restore-geometry`).
- Adding features that modify window behavior could affect the close-last-window behavior (`TC-crp-macos-close-last-window-keeps-running`).

### TCA state regressions
- Any reducer refactoring must be verified against the full unit test suite. State mutations are the core of correctness in TCA.
- Changes to file state, comment state, or prompt generation state could cascade across all integration tests.

### Performance regressions
- Memory usage must be re-verified after adding new features or data structures (`TC-crp-macos-memory-typical-session`, `TC-crp-macos-memory-idle`).
- Launch time must be re-verified after adding new initialization code (`TC-crp-macos-launch-cold-time`).
- Large file scrolling must be re-verified after any code viewer rendering changes (`TC-crp-macos-large-file-scroll-smooth`).
