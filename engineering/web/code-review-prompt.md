# Code Review Prompt Generator -- Technical Spec

> Based on requirements in `../../product/code-review-prompt.md`
> Based on design in `../../design/web/code-review-prompt.md`

## Technical Approach

This is a client-side-only React + TypeScript single-page application (`NFR-crp-client-only`). There is no backend, no database, and no network calls. All file content and user annotations remain in the browser's memory for the lifetime of the session (`NFR-crp-no-data-persistence`).

The application is built with **Vite** as the build tool and dev server, using the `react-ts` template. It uses **Shiki** for syntax highlighting, **TanStack Virtual** for virtualized scrolling of large files, **Zustand** for state management, and **Tailwind CSS v4** for styling.

The core architectural idea is straightforward: the user loads one or more files, each file is parsed into an array of lines held in a Zustand store keyed by a unique file ID, the user attaches comments to line numbers on any loaded file, and a pure function assembles those inputs into a structured prompt string. Multiple files are supported simultaneously — the store maintains an ordered collection of files, an active file pointer, and per-file comment associations. The prompt is generated automatically and reactively — every comment or preamble mutation triggers `buildPrompt()` within the store, aggregating comments across all files so the displayed prompt is always current with no manual "generate" step. Every piece of this runs in-browser with no side effects beyond the clipboard write.

### Key Technical Decisions

| Decision | Choice | Rationale |
|---|---|---|
| Build tool | Vite | Fast HMR, native ESM, zero-config React/TS support. Industry standard for new React SPAs. |
| Syntax highlighting | Shiki | TextMate grammar-based highlighting identical to VS Code. Supports all 14+ required languages out of the box. Runs in the browser via WASM. Produces static HTML tokens -- no runtime editor overhead. Better accuracy than Prism for edge cases in languages like Rust and Go. |
| Virtualized scrolling | TanStack Virtual (v3) | Lightweight (~5 KB), headless (no DOM opinions), React-first. Handles 10,000+ rows easily. Simpler than react-window for our use case because we need variable-height rows (comment bubbles expand inline). |
| State management | Zustand | Minimal API surface, no boilerplate, works outside React components (useful for prompt generation logic). React Context would work for this app's complexity, but Zustand gives us better performance (fine-grained subscriptions avoid unnecessary re-renders in the code viewer) and cleaner separation of state logic from components. |
| CSS | Tailwind CSS v4 | Utility-first, no CSS naming collisions, good for component-scoped styling. v4 uses CSS-native cascade layers and the `@theme` directive, eliminating the PostCSS config of v3. Pairs well with the design spec's explicit color tokens. |
| Testing | Vitest + React Testing Library + Playwright | Vitest for unit/integration tests (native Vite integration, fast). React Testing Library for component tests. Playwright for E2E tests covering the full user flows. |
| Package manager | pnpm | Fast, disk-efficient, strict dependency resolution. |

---

## Data Model

All data lives in memory as TypeScript types. No persistence layer, no serialization format beyond the generated prompt string.

### Core Types

```typescript
/** Metadata about a loaded file. Each file in the session has its own FileInfo. */
interface FileInfo {
  /** Unique identifier. Generated via crypto.randomUUID(). */
  id: string;
  /** File name, or "Untitled" if pasted without a name. */
  name: string;
  /** Detected or inferred programming language identifier (e.g., "typescript", "python"). */
  language: string;
  /** The raw file content as a single string. */
  content: string;
  /** The content split into individual lines. Derived from `content`. */
  lines: string[];
}

/** A single inline comment attached to one or more lines of a specific file. */
interface Comment {
  /** Unique identifier. Generated via crypto.randomUUID(). */
  id: string;
  /** The file this comment belongs to. */
  fileId: string;
  /** First line of the commented range (1-indexed). */
  startLine: number;
  /** Last line of the commented range (1-indexed). Same as startLine for single-line comments. */
  endLine: number;
  /** The user's comment text. */
  text: string;
  /** ISO-8601 timestamp of creation. Used for stable ordering when line numbers are equal. */
  createdAt: string;
}

/** The full application state. */
interface AppState {
  /** All loaded files, keyed by file ID. Supports multiple simultaneous files. */
  files: Record<string, FileInfo>;
  /** Ordered array of file IDs reflecting load order (used for tab ordering and prompt output). */
  fileOrder: string[];
  /** The ID of the currently active (visible) file, or null if no files loaded. */
  activeFileId: string | null;
  /** All comments across all files, keyed by comment ID for O(1) lookup. */
  comments: Record<string, Comment>;
  /** Ordered array of comment IDs for the active file, sorted by startLine then createdAt. Recomputed on active file switch and comment mutations. */
  commentOrder: string[];
  /** The user's preamble text (global, not per-file). */
  preamble: string;
  /** The most recently generated prompt string, or null. Aggregates all files with comments. Auto-computed after every comment or preamble change. */
  generatedPrompt: string | null;
  /** The ID of the currently focused comment (via navigation), or null. */
  focusedCommentId: string | null;
  /** The currently selected line range for range-commenting, or null. */
  selectedRange: { start: number; end: number } | null;
  /** Whether the inline comment editor is open, and if so, in what mode. */
  editorState: EditorState | null;
  /** Scroll positions per file, so switching back restores position. */
  scrollPositions: Record<string, number>;
  // Slash-command fields
  isSlashCommandMode: boolean;
  doneState: 'idle' | 'sending' | 'sent';
  /** Session ID from the `?session=` URL parameter. Null when in standalone mode. Used to scope prompt output to `~/.shepherd/sessions/<session-id>/prompt-output.md` and to set `document.title` (`FR-sc-session-id`, `FR-crp-session-identity`). */
  sessionId: string | null;

  // Review context (from shepherd-review command)
  /** Structured review context data loaded from ~/.shepherd/sessions/<session-id>/review-context.json via GET /api/review-context?session=<id>. Null when no context is available (standalone mode, single /shepherd). */
  reviewContext: ReviewContext | null;
  /** Whether the ReviewContextPanel is collapsed. Session-level preference, not per-file. */
  isReviewContextCollapsed: boolean;
  /** Whether the ReviewContextSidebar (overall changeset context in the right sidebar) is collapsed. Separate from isReviewContextCollapsed which controls the per-file panel. Session-level preference. Default: false (expanded). */
  isReviewContextSidebarCollapsed: boolean;

  /** Set of file IDs that have been marked as reviewed. Files not in this set are unreviewed (the default). Tracked as a Set<string> for O(1) lookup; Zustand serialization uses a plain object internally, but the public API exposes Set semantics. Reset on clearSession. */
  reviewedFiles: Set<string>;

  /** Set of directory paths whose tree nodes are collapsed in the FileBrowser. Directories not in this set are expanded (the default). The path is the full directory prefix (e.g., "src/utils"). Reset on clearSession. */
  collapsedDirs: Set<string>;

  /** Active tab in the sidebar content area. 'preview' shows the PromptPreview, 'comments' shows the CommentSummary. Default: 'preview'. */
  sidebarTab: 'preview' | 'comments';

  /** Whether line wrapping is enabled in the CodeViewer. When true, long lines wrap visually instead of scrolling horizontally. Default: true (on). Session-level preference — applies to all files. */
  lineWrapEnabled: boolean;

  /** Current width of the FileBrowser sidebar in pixels. Default: 240. Min: 180. Max: min(50vw, 600px). Persists within session. Reset on clearSession. */
  fileBrowserWidth: number;
}

/** Structured review context data passed from the shepherd-review command. */
interface ReviewContext {
  /** Overall changeset context (neutral description + agent's review feedback). */
  overall: { neutral: string; review: string };
  /** Per-file context, keyed by absolute file path. */
  files: Record<string, { neutral: string; review: string }>;
}

/** A node in the FileBrowser directory tree. Produced by buildFileTree(). */
type FileTreeNode =
  | { type: 'directory'; name: string; path: string; children: FileTreeNode[] }
  | { type: 'file'; fileId: string; name: string };

/** State of the inline comment editor. */
type EditorState =
  | { mode: 'create'; anchorLine: number; endLine: number }
  | { mode: 'edit'; commentId: string };
```

### Derived Data

Several values are computed from the store rather than stored directly:

- **Comment count (global)**: `Object.values(state.comments).length` — total across all files. Used by the Toolbar (`FR-crp-comment-count`).
- **Comments per file**: `Map<string, number>` counting comments per `fileId`. Used by FileBrowser for per-file comment count badges.
- **Lines with comments (active file)**: A `Map<number, string[]>` mapping each line number to the IDs of comments covering that line, filtered to only comments where `fileId === state.activeFileId`. Computed via a selector that iterates `comments`, filters by active file, and expands each `[startLine, endLine]` range.
- **Current comment index**: Position of `focusedCommentId` within `commentOrder` (which is already filtered to the active file).
- **commentOrder recomputation**: The `commentOrder` array is recomputed whenever the active file changes (via `setActiveFile`) or when comments are mutated (`addComment`, `updateComment`, `deleteComment`). It filters `comments` to those matching `activeFileId`, then sorts by `startLine` ascending, then `createdAt` ascending for ties.

- **Per-file review context (active file)**: Derived from `state.reviewContext?.files[activeFilePath]` where `activeFilePath` is the `name` (full path) of the active file. Returns `{ neutral: string, review: string } | null`. Used by the ReviewContextPanel to display per-file context for the active tab.

- **reviewedCount**: `state.reviewedFiles.size` — number of files marked as reviewed. Used by the FileBrowser sidebar header's review progress indicator (`FR-crp-file-reviewed-progress`).
- **totalFileCount**: `state.fileOrder.length` — total number of loaded files. Used alongside `reviewedCount` for the "N/M reviewed" progress indicator.
- **fileTree**: Derived tree structure that organizes files from `fileOrder` into a nested directory hierarchy. Built by parsing each file's `FileInfo.name` into path segments, grouping files under shared directory prefixes, and sorting within each directory so that unreviewed files appear before reviewed files (maintaining load order within each status group). The result is a recursive tree: `FileTreeNode[]` where each node is either `{ type: 'directory'; name: string; path: string; children: FileTreeNode[] }` or `{ type: 'file'; fileId: string; name: string }`. Root-level files (no directory component) and pasted files appear as top-level file nodes. Computed via `buildFileTree(files, fileOrder, reviewedFiles)` utility function. Used by `FileBrowser` to render the directory tree (`FR-crp-file-reviewed-grouping`, `AC-crp-file-path-display`).
- **isActiveFileReviewed**: `state.activeFileId !== null && state.reviewedFiles.has(state.activeFileId)` — boolean for whether the currently active file is marked as reviewed. Used by the `ReviewStatusBar` component (`FR-crp-file-reviewed-toggle`).
- **activeFilePath**: Derived from `state.serverFilePaths[state.activeFileId]` (if present) or `state.files[state.activeFileId]?.name`. Returns the full file path for the currently active file. Used by the `ActiveFilePath` component (`FR-crp-active-file-path`) and the `ReviewContextPanel` for per-file context matching.
- **fileTooltip(fileId)**: Not a global selector — computed inline per file row in `FileBrowser`. Built as `${path} -- ${language}` or `${path} -- ${language} -- Reviewed` depending on `reviewedFiles.has(fileId)`. Used for the `title` attribute on each file row (`FR-crp-file-tooltip`).

These are implemented as Zustand selectors (or derived via `useMemo` in components) to avoid redundant state.

---

## Component Architecture

The component tree maps directly to the design spec's component inventory. Each design component becomes a React component. The tree is shallow -- there are no deeply nested component hierarchies.

```
App
 +-- Toolbar                          (design: Toolbar)
 +-- MainContent
      +-- [if no files] FileDropZone (full variant)   (design: FileDropZone)
      +-- [if files loaded]
           +-- FileBrowser (multi-file only, dynamic width sidebar) (design: FileBrowser)
           |    +-- ResizeHandle                       (design: ResizeHandle, drag handle on right edge)
           +-- CodeViewerPanel
           |    +-- ActiveFilePath (multi-file only, 2+ files)  (design: ActiveFilePath)
           |    +-- FileHeader (single-file only, hidden when FileBrowser active)
           |    +-- ReviewContextPanel                 (design: ReviewContextPanel, conditional on context data)
           |    |    +-- ContextSection (neutral)       (design: ContextSection, "What Changed" variant)
           |    |    +-- ContextSection (review)        (design: ContextSection, "Agent Review" variant)
           |    +-- ReviewStatusBar                    (design: ReviewStatusBar, always visible when file loaded)
           |    +-- CodeViewer         (design: CodeViewer)
           |         +-- VirtualRow (repeated, virtualized)
           |              +-- GutterCell
           |              +-- LineNumberCell
           |              +-- CodeContentCell
           |         +-- CommentBubble (design: CommentBubble, rendered inline between virtual rows)
           |         +-- InlineCommentEditor (design: InlineCommentEditor, rendered inline when editing)
           +-- SidebarPanel (360px fixed)
                +-- ReviewContextSidebar             (design: ReviewContextSidebar, collapsible, conditional on context data)
                +-- PreambleInput                    (design: PreambleInput, labeled "Overall Comment")
                +-- SidebarContentTabs               (design: SidebarContentTabs)
                     +-- [tab: Preview] PromptPreview   (design: PromptPreview)
                     +-- [tab: All Comments] CommentSummary  (design: CommentSummary)
 +-- FileDropZone (modal variant, rendered via portal when adding files)
 +-- ConfirmationDialog               (design: ConfirmationDialog, rendered via portal)
 +-- ToastNotification                (design: ToastNotification, rendered via portal)
```

### Component Responsibilities

#### `App`
Root component. Renders the top-level layout: Toolbar at top, MainContent below. Provides no context providers -- Zustand store is accessed directly by each component that needs it. Registers a global drag-and-drop listener on the entire window when files are loaded — dropping files anywhere on the app adds them to the session (calls `store.addFile()` for each valid file). This implements the design spec's "entire app window is a drop target" behavior.

#### `Toolbar`
Implements the persistent toolbar. Reads the global comment count (across all files via `Object.values(state.comments).length`), `focusedCommentId`, `commentOrder`, and `activeFileId` from the store to determine button states. Dispatches actions: `copyPrompt`, `clearSession`, `navigateComment('next' | 'prev')`, `toggleFileReviewed(activeFileId)`. Registers keyboard shortcuts (`Cmd+Shift+C`, `[`, `]`, `Cmd+Shift+R`) via a `useEffect` with `keydown` listener on `document`. Prompt generation is handled automatically by the store on comment/preamble mutation, so the Toolbar does not include a Generate button.

> **Note**: The review progress indicator ("N/M reviewed") has moved from the Toolbar to the FileBrowser sidebar header (`FR-crp-file-reviewed-progress`). It is only visible when the FileBrowser is rendered (2+ files loaded). See the FileBrowser component spec for details.

The `Cmd+Shift+R` / `Ctrl+Shift+R` keyboard shortcut is registered in the same `useEffect` keydown listener as other shortcuts. It is only active when at least one file is loaded (`activeFileId !== null`). It calls `toggleFileReviewed(activeFileId)` to toggle the active file's reviewed status.

The Toolbar also includes a **line wrap toggle** icon button. The button dispatches `store.toggleLineWrap()` and reflects the current `lineWrapEnabled` state visually (e.g., toggled/untoggled icon state). The `Alt+Z` keyboard shortcut (`FR-crp-line-wrap`) is registered in the same `useEffect` keydown listener as other Toolbar shortcuts. It is active whenever at least one file is loaded (`activeFileId !== null`). The shortcut calls `store.toggleLineWrap()`. The icon button displays a tooltip indicating the current state and shortcut ("Toggle line wrapping (Alt+Z)").

Maps to: `FR-crp-comment-count`, `FR-crp-comment-navigation`, `FR-crp-prompt-copy`, `FR-crp-clear-session`, `AC-crp-multi-file-comment-count`, `FR-crp-line-wrap`, `AC-crp-line-wrap-toggle`.

#### `FileDropZone`
Handles all three file-loading methods: paste, upload, drag-and-drop (`FR-crp-file-load`). Supports two variants:
- **`variant: 'full'`** — Original behavior: fills the main content area when no files are loaded. This is the empty-state drop zone.
- **`variant: 'modal'`** — Rendered as a portal modal overlay when adding files to an existing session (triggered by the "+ Add file" button in the FileBrowser sidebar or via `store.openAddFileModal()`). The existing file content remains visible behind the backdrop.

Manages its own local UI state (current variant: default, drag-hover, paste-mode, loading, error). On successful load, calls the store's `addFile(content, fileName, language)` action.

Multi-file drop: When `event.dataTransfer.files.length > 1`, iterates all files and calls `store.addFile()` for each (with per-file binary detection). Valid files are loaded; binary files trigger an error toast per file (e.g., "Loaded 3 files. 1 file was skipped (binary)."). This replaces the previous single-file-only behavior.

Binary detection: reads the first 8,192 bytes of the file as an `ArrayBuffer`, checks for null bytes (`0x00`). If found, surfaces the error state (`AC-crp-binary-file-rejected`).

Language detection: maps file extension to Shiki language ID using a static lookup table. Falls back to `"plaintext"`. Supports: `.js`/`.jsx` (javascript), `.ts`/`.tsx` (typescript), `.py` (python), `.go` (go), `.rs` (rust), `.java` (java), `.c`/`.h` (c), `.cpp`/`.cc`/`.cxx`/`.hpp` (cpp), `.html` (html), `.css` (css), `.json` (json), `.yaml`/`.yml` (yaml), `.md` (markdown).

Maps to: `FR-crp-file-load`, `FR-crp-multi-file-load`, `AC-crp-load-paste`, `AC-crp-load-upload`, `AC-crp-load-drag-drop`, `AC-crp-binary-file-rejected`, `AC-crp-multi-file-load-adds`, `AC-crp-multi-file-drop-multiple`.

#### `FileBrowser`
Renders a vertical sidebar panel on the left side of the layout for navigating between loaded files. The sidebar width is controlled by `state.fileBrowserWidth` (default 240px, user-resizable via the `ResizeHandle` component on its right edge — see `FR-crp-panel-resize`). Appears when two or more files are loaded, creating a three-column layout: `[FileBrowser {fileBrowserWidth}px | Code Viewer Panel | Sidebar 360px]`. The FileBrowser applies its width via `style={{ width: fileBrowserWidth }}` instead of a fixed Tailwind class, and the parent layout uses dynamic `grid-template-columns` or flex basis based on `fileBrowserWidth`. Reads `files`, `activeFileId`, `reviewedFiles`, `reviewedCount`, `totalFileCount`, `collapsedDirs`, `fileBrowserWidth`, per-file comment counts, and the `fileTree` derived selector from the store. Dispatches: `setActiveFile(fileId)`, `removeFile(fileId)`, `openAddFileModal()`, `toggleFileReviewed(fileId)`, `toggleDirCollapsed(dirPath)`.

The sidebar has a header area containing the review progress indicator ("N/M reviewed" text badge, visible only when `totalFileCount >= 2`, turns green when `reviewedCount === totalFileCount`) and a "+ Add file" button (`FR-crp-file-reviewed-progress`, `AC-crp-file-reviewed-progress-count`).

Below the header, the FileBrowser renders a **nested directory tree** derived from file paths. The tree is built by parsing each `FileInfo.name` into a directory hierarchy using a utility function `buildFileTree(files, fileOrder, reviewedFiles)`. This function splits each file path by `/`, groups files under shared directory prefixes, and produces a sorted/grouped tree data structure. The tree has two node types:

- **Directory nodes**: Collapsible containers. Each directory node displays a chevron toggle (right-pointing when collapsed, down-pointing when expanded) and the directory name (system sans-serif, 12px). Height is 28px. Clicking the chevron or the directory name toggles `toggleDirCollapsed(dirPath)`. Directory nodes are rendered at a left padding of `12px + nestingLevel * 16px`. When all files within a directory (including nested subdirectories) are reviewed, the directory node shows a green checkmark before the directory name and the name is muted — this is derived by checking `reviewedFiles` against all descendant file IDs. This is especially important for collapsed directories, where the checkmark is the only indicator that all contents are reviewed.
- **File nodes**: Leaf items. Each file node is 32px tall (single line) and displays: an optional green checkmark icon for reviewed files (`FR-crp-file-reviewed-visual`), the file name (monospace, 13px, truncated with ellipsis if needed), a comment count badge (if > 0 comments on that file), a review toggle icon button (visible on hover or when the row is active -- clicking toggles `toggleFileReviewed(fileId)` without switching to the file), and a close (X) button (visible on hover). File nodes are indented under their parent directory at `12px + nestingLevel * 16px` (`AC-crp-file-path-display`, `AC-crp-file-path-single-dir`).

Within each directory, unreviewed files sort before reviewed files; among files with the same review status, the original load order (position in `fileOrder`) is maintained (`FR-crp-file-reviewed-grouping`). There are no "TO REVIEW" / "REVIEWED" group headers -- the sorting is implicit within each directory.

Root-level files (those with no directory component in their path) and pasted files (named "Untitled") appear at the top level of the tree, outside any directory node. For pasted files, the display name is "Untitled" (shown in italics). Reviewed files with inactive rows display muted text color (`#94A3B8`) for additional visual distinction. The active file row has a white background and blue left border (per design spec). Each file row has a `title` attribute providing a tooltip on hover (`FR-crp-file-tooltip`). The tooltip string is built from the file's full path (`serverFilePaths[fileId]` for server-loaded files, or `files[fileId].name` for pasted/uploaded), the detected language (`files[fileId].language`), and the review status. Format: `<path> -- <language>` for unreviewed files, or `<path> -- <language> -- Reviewed` for reviewed files. This uses the browser's native `title` attribute — no custom tooltip component is needed.

The collapse state for directories is stored in the Zustand store as `collapsedDirs: Set<string>`. When a directory is collapsed, its child nodes (both nested directories and files) are hidden. The `toggleDirCollapsed(dirPath)` action toggles membership in the set. All directories default to expanded (not in the set). The `clearSession` action resets `collapsedDirs` to an empty set.

The "+ Add file" button in the sidebar header opens the FileDropZone in modal variant for adding additional files.

When the sidebar has only one file remaining (after removals), it collapses and the layout reverts to single-file mode with the FileHeader restored. The sidebar re-appears when a second file is loaded.

For pasted files named "Untitled", right-clicking the file row opens an inline rename input (matching the FileHeader's rename affordance).

Keyboard: The tree container uses `role="tree"` with `aria-label="Loaded files"`. Directory nodes use `role="treeitem"` with `aria-expanded="true|false"`. File nodes use `role="treeitem"` with `aria-selected="true|false"`. `ArrowUp`/`ArrowDown` moves focus between visible nodes (skipping hidden children of collapsed directories). `ArrowRight` on a collapsed directory expands it; on an expanded directory, moves focus to the first child; on a file node, does nothing. `ArrowLeft` on an expanded directory collapses it; on a child node, moves focus to the parent directory; on a root-level node, does nothing. `Enter` or `Space` on a file node activates it (calls `setActiveFile`); on a directory node, toggles expand/collapse. `r` on a focused file row toggles the reviewed state for that file (only when focus is on a file row element, not in a text input). `Delete` or `Backspace` on a focused file row triggers file removal (with confirmation if the file has comments).

Maps to: `FR-crp-multi-file-nav`, `FR-crp-multi-file-remove`, `FR-crp-file-reviewed-visual`, `FR-crp-file-reviewed-grouping`, `FR-crp-file-reviewed-progress`, `FR-crp-panel-resize`, `FR-crp-file-tooltip`, `AC-crp-multi-file-nav-preserves-state`, `AC-crp-file-reviewed-grouping`, `AC-crp-file-reviewed-progress-count`, `AC-crp-file-path-display`, `AC-crp-file-path-single-dir`, `AC-crp-file-tooltip-full-path`.

#### `ResizeHandle`
A thin interactive drag handle rendered on the right edge of the `FileBrowser` sidebar (`FR-crp-panel-resize`). Allows the user to resize the FileBrowser width by dragging.

**Hit target and visuals**: The handle is a 6px-wide `<div>` positioned absolutely on the right border of the FileBrowser. The cursor changes to `col-resize` on hover and during drag. On hover, a 3px-wide blue line appears (centered in the 6px hit target); this blue line persists during the drag operation.

**Drag interaction**: Uses the `onMouseDown` → document `mousemove`/`mouseup` pattern. On `mouseDown`, the component sets a `dragging` local ref/state and attaches `mousemove` and `mouseup` listeners to `document` (not the handle itself — this ensures drag continues even if the cursor leaves the handle). During `mousemove`, the handler calculates the new width from `event.clientX`, clamps it to `[180, min(50vw, 600)]`, and dispatches `store.setFileBrowserWidth(newWidth)`. The resize update is wrapped in `requestAnimationFrame` to avoid layout thrash — only one `setFileBrowserWidth` call per animation frame. On `mouseUp`, the listeners are removed and the `dragging` state is cleared. A cleanup function in a `useEffect` ensures listeners are removed if the component unmounts during a drag.

**Double-click reset**: A `onDoubleClick` handler on the resize handle calls `store.resetFileBrowserWidth()`, which resets the width to the 240px default. The FileBrowser applies a 150ms `ease-out` CSS transition on `width` when the reset occurs (but NOT during drag — the transition class is conditionally applied only during the double-click reset, then removed after the transition completes).

**Keyboard accessibility**: The handle has `role="separator"`, `aria-orientation="vertical"`, `aria-valuenow={fileBrowserWidth}`, `aria-valuemin={180}`, `aria-valuemax={maxWidth}`, and `tabindex="0"`. `ArrowLeft` decreases width by 10px, `ArrowRight` increases by 10px (both clamped). `Home` sets to min (180px), `End` sets to max (`min(50vw, 600)`).

Maps to: `FR-crp-panel-resize`, `AC-crp-panel-resize-drag`, `AC-crp-panel-resize-bounds`, `AC-crp-panel-resize-double-click`, `AC-crp-panel-resize-keyboard`.

#### `ActiveFilePath`
Displays the full file path of the currently active file at the top of the Code Viewer Panel (`FR-crp-active-file-path`). Only rendered when `fileOrder.length >= 2` (multi-file mode with 2+ files). Positioned above the ReviewContextPanel (or FileHeader, though FileHeader is hidden in multi-file mode).

The path is derived from `serverFilePaths[activeFileId]` for server-loaded files, or `files[activeFileId].name` for pasted/uploaded files. Pasted files display "Untitled".

**Styling**: 32px height, monospace font at 12px, muted text color, subtle background matching the FileHeader background. Long paths are left-truncated using CSS `direction: rtl; text-overflow: ellipsis; overflow: hidden; white-space: nowrap` — this ensures the filename at the end of the path remains visible when the path is truncated.

**Accessibility**: `role="status"` and `aria-live="polite"` so screen readers announce the path when the active file changes.

Maps to: `FR-crp-active-file-path`, `AC-crp-active-file-path-visible`, `AC-crp-active-file-path-switches`, `AC-crp-active-file-path-single-file`.

#### `FileHeader`
Displays file name and language badge (`FR-crp-filename-display`). Only rendered in single-file mode (when `fileOrder.length === 1`); in multi-file mode, the FileBrowser sidebar provides this information instead. When the file was pasted without a name, renders an inline-editable text input. Calls `store.updateFileName(fileId, name)` on change.

#### `CodeViewer`
The most complex component. Renders the virtualized list of code lines using TanStack Virtual (`NFR-crp-large-file-perf`, `AC-crp-large-file-scroll`). Each visible row is a `VirtualRow` containing the gutter, line number, and syntax-highlighted code content.

Comment bubbles and the inline editor are rendered as non-virtualized elements inserted between virtual rows at the correct positions. This is handled by computing "expanded" row data that interleaves code lines with comment/editor slots, and assigning each slot a dynamic height for the virtualizer.

Line selection for range comments (`FR-crp-line-range-comment`) is handled via `onMouseDown`/`onMouseMove`/`onMouseUp` on line number cells, with Shift+click support. Keyboard selection uses `Shift+ArrowUp/Down` as specified in the design.

Keyboard navigation (`NFR-crp-accessibility-keyboard`, `AC-crp-keyboard-add-comment`): The code viewer is a focusable container. Arrow keys move a `focusedLine` local state (distinct from the store's `focusedCommentId` which tracks comment navigation). `focusedLine` is local to the CodeViewer component; `focusedCommentId` is global store state. Enter or `c` on a focused line always opens the comment editor in create mode (even if the line already has comments). ARIA attributes match the design spec (role="grid", role="row", role="rowheader", role="gridcell").

**Line wrapping** (`FR-crp-line-wrap`): The CodeViewer reads `lineWrapEnabled` from the store. When `lineWrapEnabled` is `true` (default), the code content area uses `white-space: pre-wrap; overflow-wrap: break-word; overflow-x: hidden` — long lines wrap visually within the viewport. When `lineWrapEnabled` is `false`, the code content area switches to `white-space: pre; overflow-x: auto` — long lines scroll horizontally. Line number cells and gutter cells use `vertical-align: top` (or flex `align-self: start`) so they pin to the first visual row when a line wraps to multiple visual rows (`AC-crp-line-wrap-preserves-line-numbers`). Comment targeting is unaffected — clicking a wrapped line still targets the logical line number for comment creation (`AC-crp-line-wrap-comment-target`).

When `lineWrapEnabled` toggles, the virtualizer's size cache must be invalidated because all row heights may change. The CodeViewer component watches `lineWrapEnabled` in a `useEffect` and calls `virtualizer.measure()` to force re-measurement of all visible and overscan rows. Additionally, a `ResizeObserver` is attached to the code viewer panel container to detect width changes (from window resize or panel resize). When wrapping is active and the container width changes, the observer calls `virtualizer.measure()` to re-measure rows whose wrapped heights depend on the available width.

Maps to: `FR-crp-file-display`, `FR-crp-syntax-highlight`, `FR-crp-comment-indicator`, `FR-crp-line-range-comment`, `FR-crp-comment-navigation`, `FR-crp-line-wrap`, `NFR-crp-large-file-perf`, `NFR-crp-render-time`, `AC-crp-large-file-scroll`, `AC-crp-keyboard-add-comment`, `AC-crp-line-wrap-preserves-line-numbers`, `AC-crp-line-wrap-comment-target`.

#### `CommentBubble`
Displays a single comment. Shows edit/delete actions on hover. Dispatches `store.openEditor('edit', commentId)` and `store.deleteComment(commentId)`.

Maps to: `FR-crp-line-comment-edit`, `FR-crp-line-comment-delete`, `FR-crp-comment-indicator`, `AC-crp-edit-comment`, `AC-crp-delete-comment`.

#### `InlineCommentEditor`
The create/edit form rendered inline in the code viewer. Manages its own text state locally. On submit, calls `store.addComment(startLine, endLine, text)` (create mode) or `store.updateComment(commentId, text)` (edit mode). Auto-focuses the textarea on mount. Handles `Cmd+Enter`/`Ctrl+Enter` submit and `Escape` cancel.

Maps to: `FR-crp-line-comment-create`, `FR-crp-line-comment-edit`, `AC-crp-add-comment-single-line`, `AC-crp-add-comment-line-range`, `AC-crp-edit-comment`.

#### `PreambleInput`
Controlled textarea bound to `store.preamble`. Supports expanded/collapsed variants as described in the design. Calls `store.setPreamble(text)` on change, which automatically triggers prompt regeneration via `buildPrompt()` if comments exist.

The component name remains `PreambleInput` internally for code continuity, but the **user-facing label is "Overall Comment"** per `AC-crp-overall-comment-label`. Specifically:
- The toggle label reads "Overall Comment" (not "Preamble").
- The placeholder text reads "Add an overall comment for all files in this review..." (not the previous AI-reviewer phrasing).
- The collapsed preview text prefix is "Overall Comment" (not "Preamble").
- The `aria-label` on the textarea is "Overall comment" for accessibility.

No store changes are needed -- `preamble` as an internal state property name is fine for backward compatibility. No prompt builder changes are needed -- the generated prompt format remains the same (the `## Instructions` heading is kept).

Maps to: `FR-crp-prompt-preamble`, `AC-crp-overall-comment-label`.

#### `PromptPreview`
Read-only display of `store.generatedPrompt` rendered inside a `<pre>` element as a text node — no markdown processing is applied. The user sees the literal markdown syntax markers as plain text. Two variants: empty (no comments exist, prompt is null) and populated (comments exist, prompt is automatically current). The prompt preview always shows the current, automatically generated prompt — there is no stale state. The inline "Copy" button calls `store.copyPrompt()`.

Rendered as the content of the "Preview" tab in `SidebarContentTabs`. Visible when `sidebarTab === 'preview'`.

Maps to: `FR-crp-prompt-preview`, `FR-crp-prompt-format`, `AC-crp-generate-prompt-structure`, `AC-crp-preview-matches-copy`.

#### `ConfirmationDialog`
Generic modal. Rendered via a React portal to `document.body`. Traps focus while open. Used by:
- Clear session flow: Confirms removal of all files and comments (`AC-crp-clear-confirmation`, `AC-crp-clear-no-confirm-empty`).
- File removal flow: Confirms removal of an individual file that has comments (`AC-crp-multi-file-remove-with-comments`). Files without comments are removed immediately without confirmation (`AC-crp-multi-file-remove-no-comments`).

#### `ToastNotification`
Ephemeral notification rendered via a React portal. Auto-dismisses after the configured duration. Slide-up and fade-out animations via CSS transitions. Announced to screen readers via `role="status"` and `aria-live="polite"`.

Maps to: `AC-crp-copy-clipboard`.

#### `ReviewContextPanel`
Collapsible panel that displays structured review context data provided by the shepherd-review command. Positioned between the FileHeader (single-file mode) or the top of the Code Viewer Panel (multi-file mode, where the FileBrowser sidebar replaces the FileHeader) and the CodeViewer.

This component is **conditionally rendered** -- it only appears when `state.reviewContext` is non-null. When no context data is available (standalone mode, single `/shepherd`), the component is not rendered at all. There is no empty or placeholder state (`AC-crp-context-graceful-missing`).

The panel has two content groups:
1. **Overall section** ("CHANGESET OVERVIEW"): Always visible when the panel is expanded. Displays `state.reviewContext.overall.neutral` and `state.reviewContext.overall.review` via two `ContextSection` sub-components.
2. **Per-file section** ("FILE: [filename]"): Displays the per-file context for the currently active file. Derived from `state.reviewContext.files[activeFilePath]`. When the active file has no per-file context (e.g., file added via paste/upload), the per-file section is not rendered -- only the overall section shows. When the active file changes, the per-file section updates automatically via the Zustand selector (`AC-crp-context-per-file-switches`).

Collapse/expand state is stored in `state.isReviewContextCollapsed`. Default is `false` (expanded on first load). The collapse state persists across file switches -- it is a session-level preference, not per-file. The `clearSession` action resets it to `false`.

The entire panel content is read-only (`AC-crp-context-readonly`). Max-height is 40% of the Code Viewer Panel height with vertical scroll overflow.

Maps to: `FR-crp-review-context-receive`, `FR-crp-review-context-display`, `FR-crp-review-context-overall`, `FR-crp-review-context-per-file`, `AC-crp-context-overall-visible`, `AC-crp-context-per-file-visible`, `AC-crp-context-per-file-switches`, `AC-crp-context-graceful-missing`, `AC-crp-context-readonly`.

#### `ReviewStatusBar`
A compact horizontal bar positioned inside the CodeViewerPanel, below the ReviewContextPanel (if present) or below the FileHeader (single-file mode) / the top of the panel (multi-file mode), and above the CodeViewer. Always visible when at least one file is loaded, regardless of whether review context data is available.

Reads `isActiveFileReviewed` and `activeFileId` from the store. Dispatches `toggleFileReviewed(activeFileId)` when the user clicks the bar or presses the keyboard shortcut. Renders a checkbox + label: "Mark as reviewed" (unreviewed state) or "Reviewed" with a filled green checkmark (reviewed state). The entire bar is clickable. The bar also displays the keyboard shortcut hint (`Cmd+Shift+R` / `Ctrl+Shift+R`).

When the active file changes (via `setActiveFile`), the bar automatically reflects the new file's reviewed state via the `isActiveFileReviewed` selector.

Maps to: `FR-crp-file-reviewed-toggle`, `FR-crp-file-reviewed-persistence`, `AC-crp-file-mark-reviewed`, `AC-crp-file-unmark-reviewed`, `AC-crp-file-reviewed-survives-tab-switch`.

#### `ContextSection`
A single section within the ReviewContextPanel that displays either neutral context or review feedback. Two variants with distinct visual treatment per the design spec.

- **`neutral` variant** ("What Changed"): Info circle icon (blue), blue left border, white background. Factual/objective content.
- **`review` variant** ("Agent Review"): Sparkle/AI icon (violet), violet left border, faint violet background. Subjective agent content.

Both variants render their `content` prop as plain text with `white-space: pre-wrap` in a read-only `<div>`. No markdown rendering. If the content string is empty or undefined, the section is not rendered (no empty placeholder).

The visual distinction between the two variants is achieved through four cues: left border color (blue vs violet), background color (white vs violet tint), icon (info circle vs sparkle), and label text ("What Changed" vs "Agent Review"). These work together so even color-blind users can distinguish them via icon shape and label.

Maps to: `AC-crp-context-neutral-vs-review`, `AC-crp-context-readonly`.

#### `ReviewContextSidebar`
Collapsible section in the right sidebar that displays **overall changeset context** provided by the shepherd-review command. Positioned at the top of the Sidebar Panel, above the PreambleInput (Overall Comment).

This component is **conditionally rendered** -- it only appears when `state.reviewContext` is non-null and the overall context has non-empty content. When no context data is available (standalone mode, single `/shepherd`), this component is not rendered at all. There is no empty or placeholder state (`AC-crp-context-graceful-missing`).

The component has a clickable header bar with a chevron icon that toggles between collapsed and expanded states. The collapse/expand pattern mirrors `ReviewContextPanel`:
- **Header bar**: Full-width clickable button with chevron icon (right-pointing when collapsed, down-pointing when expanded) and label "Changeset Overview". Background matches the design spec's context header styling.
- **Expanded content**: Two `ContextSection` sub-components — one for `reviewContext.overall.neutral` ("What Changed") and one for `reviewContext.overall.review` ("Agent Review"). Max-height with vertical scroll overflow.
- **Collapsed state**: Only the header bar is visible. Content is hidden with CSS transition for smooth animation.

Collapse/expand state is stored in `state.isReviewContextSidebarCollapsed` (separate from the per-file panel's `isReviewContextCollapsed`). Default is `false` (expanded on first load). The `clearSession` action resets it to `false`.

The entire section content is read-only (`AC-crp-context-readonly`).

Maps to: `FR-crp-review-context-collapsible`, `FR-crp-review-context-overall`, `AC-crp-context-sidebar-collapse`, `AC-crp-context-neutral-vs-review`, `AC-crp-context-graceful-missing`, `AC-crp-context-readonly`.

#### `SidebarContentTabs`
A segmented tab control within the Sidebar Panel that switches between the Prompt Preview and the All Comments summary. Positioned below the PreambleInput (Overall Comment) and above the active tab content.

- **Tabs**: Two tabs — "Preview" (default) and "All Comments". The "All Comments" tab shows a count badge with the total comment count across all files when comments exist (e.g., "All Comments (5)").
- **State**: Reads `sidebarTab` from the store and dispatches `setSidebarTab` to switch tabs. Alternatively, tab state can be managed locally in `App.tsx` via `useState` if the tab state does not need to persist across re-renders triggered by other state changes.
- **Rendering**: When the "Preview" tab is active, renders the `PromptPreview` component. When "All Comments" is active, renders the `CommentSummary` component.
- **Visual**: Horizontal segmented control with two pill-shaped buttons. The active tab has a filled background. The inactive tab has text-only styling. The tab bar spans the full width of the sidebar content area.

Maps to: `FR-crp-comment-summary`, `FR-crp-prompt-preview`.

#### `CommentSummary`
Read-only summary of all comments across all loaded files, displayed in the "All Comments" tab of `SidebarContentTabs`. Reads `comments`, `files`, `fileOrder` from the store.

- **Data**: Groups comments by `fileId`. Filters to files that have at least one comment. Orders files by their position in `fileOrder`. Within each file group, sorts comments by `startLine` ascending, then `createdAt` ascending.
- **Rendering**:
  - For each file with comments, renders the file name as a section header.
  - Under each file header, renders each comment as a compact entry showing: a line reference (e.g., "Line 5:" or "Lines 10-15:") and the comment text (truncated with ellipsis if it exceeds one line).
  - The empty state (no comments on any file) shows a centered placeholder message: "No comments yet. Add comments to code lines to see them here."
- **Click behavior**: Clicking a comment entry navigates to that file and comment — calls `store.setActiveFile(fileId)` (if not already the active file) then `store.setFocusedComment(commentId)`. The code viewer scrolls to the comment and briefly highlights it (same highlight animation used by comment navigation).
- **Real-time updates**: The summary updates immediately when comments are added, edited, or deleted on any file, since it reads directly from the Zustand store. No explicit refresh is needed.
- **Read-only**: No editing is possible within the CommentSummary — it is a navigation aid only.

Maps to: `FR-crp-comment-summary`, `AC-crp-comment-summary-shows-all`, `AC-crp-comment-summary-realtime`, `AC-crp-comment-summary-empty`.

---

## State Management

### Zustand Store

A single Zustand store holds all application state. The store is defined in `src/store/appStore.ts`.

#### Store Structure

The store exposes state (matching the `AppState` type above) and actions:

```typescript
interface AppStore extends AppState {
  // File actions (multi-file)
  addFile: (content: string, fileName: string, language: string) => void;
  removeFile: (fileId: string) => void;
  setActiveFile: (fileId: string) => void;
  updateFileName: (fileId: string, name: string) => void;

  // Comment actions (comments now have fileId)
  addComment: (startLine: number, endLine: number, text: string) => void;
  updateComment: (commentId: string, text: string) => void;
  deleteComment: (commentId: string) => void;

  // Editor actions
  openEditor: (mode: 'create', startLine: number, endLine: number) => void;
  openEditor: (mode: 'edit', commentId: string) => void;
  closeEditor: () => void;

  // Navigation (within active file's comments)
  navigateComment: (direction: 'next' | 'prev') => void;
  setFocusedComment: (commentId: string | null) => void;

  // Line selection (unchanged)
  setSelectedRange: (range: { start: number; end: number } | null) => void;

  // Preamble (unchanged)
  setPreamble: (text: string) => void;

  // Prompt (unchanged)
  copyPrompt: () => Promise<void>;

  // Session
  clearSession: () => void;

  // Add file modal
  isAddFileModalOpen: boolean;
  openAddFileModal: () => void;
  closeAddFileModal: () => void;

  // Scroll position
  saveScrollPosition: (fileId: string, scrollOffset: number) => void;

  // Slash command
  setSlashCommandMode: (mode: boolean) => void;
  setSessionId: (id: string | null) => void;
  sendPromptToAgent: () => Promise<void>;

  // Review context
  setReviewContext: (context: ReviewContext | null) => void;
  toggleReviewContextCollapsed: () => void;
  toggleReviewContextSidebarCollapsed: () => void;

  // Sidebar tabs
  setSidebarTab: (tab: 'preview' | 'comments') => void;

  // File reviewed tracking
  toggleFileReviewed: (fileId: string) => void;

  // Line wrapping
  toggleLineWrap: () => void;

  // Directory collapse (FileBrowser tree)
  toggleDirCollapsed: (dirPath: string) => void;

  // FileBrowser sidebar resize (FR-crp-panel-resize)
  setFileBrowserWidth: (width: number) => void;
  resetFileBrowserWidth: () => void;
}
```

#### Action Semantics

- **`addFile`** (replaces `loadFile`): Creates a new `FileInfo` with `crypto.randomUUID()` as `id` and parsed lines (`content.split('\n')`). Appends to `files` map and `fileOrder` array. Sets `activeFileId` to the new file. Does NOT reset comments or preamble — existing files and comments are preserved (`AC-crp-multi-file-load-adds`). Does NOT add the new file to `reviewedFiles` — new files default to unreviewed (`FR-crp-file-reviewed-persistence`). Recomputes `commentOrder` for the new active file (which will be empty). Triggers `buildPrompt()`. Closes the add file modal if open.
- **`removeFile`**: Removes the file from `files` map and `fileOrder` array. Removes all comments with matching `fileId` from the `comments` map. Removes the file ID from `reviewedFiles` if present (`FR-crp-file-reviewed-persistence`). If the removed file was active, sets `activeFileId` to the next file in `fileOrder` (or previous, or `null` if no files remain). If no files remain, returns to empty state (`AC-crp-multi-file-empty-after-remove-last`). Removes the file's entry from `scrollPositions`. Triggers `buildPrompt()`. Recomputes `commentOrder` for the new active file.
- **`setActiveFile`**: Saves the current file's scroll position via `saveScrollPosition`. Updates `activeFileId`. Recomputes `commentOrder` for the newly active file. Clears `focusedCommentId`, `selectedRange`, and `editorState` (switching files cancels any in-progress editing).
- **`updateFileName`**: Now takes `(fileId, name)` instead of just `(name)`. Updates the `name` field on the specified file.
- **`addComment`**: Creates a `Comment` with `crypto.randomUUID()`, automatically sets `fileId` to `state.activeFileId` on the new comment. Inserts into `comments` map, recomputes `commentOrder`. Automatically regenerates the prompt via `buildPrompt()`.
- **`updateComment`**: Updates the `text` field on an existing comment. Automatically regenerates the prompt via `buildPrompt()`.
- **`deleteComment`**: Removes from `comments` map and `commentOrder`. If the deleted comment was `focusedCommentId`, clears focus. Automatically regenerates the prompt via `buildPrompt()` (sets `generatedPrompt` to `null` if no comments remain on any file).
- **`navigateComment`**: Advances or retreats `focusedCommentId` within `commentOrder` (filtered to active file only), wrapping at boundaries.
- **`setPreamble`**: Updates the preamble text. Automatically regenerates the prompt via `buildPrompt()` if comments exist on any file.
- **`copyPrompt`**: Calls `navigator.clipboard.writeText(generatedPrompt)`. Returns a promise; the component handles success/failure UI.
- **`clearSession`**: Resets the entire store to its initial state — removes all files, all comments, preamble, and clears `generatedPrompt` to `null`. Resets `activeFileId` to `null`, `fileOrder` to `[]`, `files` to `{}`, `scrollPositions` to `{}`, `reviewedFiles` to an empty `Set`, `collapsedDirs` to an empty `Set`, `sessionId` to `null`. Also resets `reviewContext` to `null`, `isReviewContextCollapsed` to `false`, `isReviewContextSidebarCollapsed` to `false`, `sidebarTab` to `'preview'`, `lineWrapEnabled` to `true`, and `fileBrowserWidth` to `240`. Resets `document.title` to the default ("Shepherd") (`AC-crp-multi-file-clear-all`, `AC-crp-file-reviewed-clear-session`, `AC-crp-line-wrap-default-on`).
- **`saveScrollPosition`**: Stores the given scroll offset for the specified file ID in `scrollPositions`. Called automatically by `setActiveFile` before switching.
- **`setReviewContext`**: Sets the `reviewContext` field. Called once on mount by the `useFileFromUrl` hook after loading files, if context data is available from `GET /api/review-context`. Setting this to a non-null value causes the `ReviewContextPanel` to render.
- **`toggleReviewContextCollapsed`**: Toggles `isReviewContextCollapsed`. This is a session-level preference — persists across file switches.
- **`toggleReviewContextSidebarCollapsed`**: Toggles `isReviewContextSidebarCollapsed`. This controls the overall changeset context section in the right sidebar, independent of the per-file panel collapse state. Session-level preference. Maps to: `FR-crp-review-context-collapsible`, `AC-crp-context-sidebar-collapse`.
- **`setSidebarTab`**: Sets the `sidebarTab` field to `'preview'` or `'comments'`. Controls which content is displayed in the sidebar below the PreambleInput. Default is `'preview'`. Maps to: `FR-crp-comment-summary`.
- **`toggleFileReviewed`**: Toggles the given file's membership in `reviewedFiles`. If the file ID is currently in the set, removes it (unmark as reviewed); if not in the set, adds it (mark as reviewed). Does not change `activeFileId` or any other state — the toggle is orthogonal to file selection, comments, and scroll position (`AC-crp-file-reviewed-with-comments`, `AC-crp-file-reviewed-survives-tab-switch`). Triggers no prompt regeneration (reviewed status is not reflected in the generated prompt). Maps to: `FR-crp-file-reviewed-toggle`, `AC-crp-file-mark-reviewed`, `AC-crp-file-unmark-reviewed`.
- **`toggleLineWrap`**: Toggles `lineWrapEnabled` between `true` and `false`. After toggling, the CodeViewer component detects the change via its Zustand subscription and calls `virtualizer.measure()` in a `useEffect` to invalidate the virtualizer's size cache and force re-measurement of all visible rows. The toggle does not affect scroll position, comments, or any other state — it is purely a display preference. The preference persists for the session but is reset on `clearSession` (`AC-crp-line-wrap-default-on`, `AC-crp-line-wrap-persists-session`). Maps to: `FR-crp-line-wrap`, `AC-crp-line-wrap-toggle`.
- **`toggleDirCollapsed`**: Toggles the given directory path's membership in `collapsedDirs`. If the path is currently in the set, removes it (expand); if not in the set, adds it (collapse). Used by the FileBrowser tree to show/hide children of directory nodes. Does not affect file selection or any other state.
- **`setFileBrowserWidth`**: Sets `fileBrowserWidth` to the given value, clamped to `[180, min(window.innerWidth * 0.5, 600)]`. Called by the `ResizeHandle` during drag. The clamping is applied in the action, not the component, so all consumers get consistent behavior. Maps to: `FR-crp-panel-resize`, `AC-crp-panel-resize-bounds`.
- **`resetFileBrowserWidth`**: Resets `fileBrowserWidth` to the default value (240). Called by `ResizeHandle` on double-click. Maps to: `FR-crp-panel-resize`, `AC-crp-panel-resize-double-click`.

#### Selectors

Zustand selectors with shallow equality checks minimize re-renders:

```typescript
// Example: CodeViewer only re-renders when the active file's lines/language change
const { lines, language } = useAppStore(
  (s) => {
    const activeFile = s.activeFileId ? s.files[s.activeFileId] : null;
    return { lines: activeFile?.lines, language: activeFile?.language };
  },
  shallow
);

// Derived: map of line numbers to comment arrays (active file only)
const commentsByLine = useAppStore((s) => {
  const map = new Map<number, Comment[]>();
  for (const id of s.commentOrder) {
    const comment = s.comments[id];
    // commentOrder is already filtered to activeFileId, but guard just in case
    if (comment.fileId !== s.activeFileId) continue;
    for (let line = comment.startLine; line <= comment.endLine; line++) {
      const existing = map.get(line) || [];
      existing.push(comment);
      map.set(line, existing);
    }
  }
  return map;
});

// Derived: per-file comment counts for FileBrowser badges
const commentCountsByFile = useAppStore((s) => {
  const counts = new Map<string, number>();
  for (const comment of Object.values(s.comments)) {
    counts.set(comment.fileId, (counts.get(comment.fileId) || 0) + 1);
  }
  return counts;
});

// Derived: per-file review context for the active file (ReviewContextPanel)
const perFileContext = useAppStore((s) => {
  if (!s.reviewContext || !s.activeFileId) return null;
  const activeFile = s.files[s.activeFileId];
  if (!activeFile) return null;
  // Match by file name (which is the absolute path when loaded via ?file= URL params)
  return s.reviewContext.files[activeFile.name] ?? null;
});

// Derived: whether the active file is reviewed (ReviewStatusBar)
const isActiveFileReviewed = useAppStore(
  (s) => s.activeFileId !== null && s.reviewedFiles.has(s.activeFileId)
);

// Derived: reviewed count and total file count (Toolbar progress indicator)
const reviewedCount = useAppStore((s) => s.reviewedFiles.size);
const totalFileCount = useAppStore((s) => s.fileOrder.length);

// Derived: file tree for FileBrowser (FR-crp-file-reviewed-grouping, AC-crp-file-path-display)
// Builds a nested directory hierarchy from file paths, sorting unreviewed before reviewed within each dir.
const fileTree = useAppStore(
  (s) => buildFileTree(s.files, s.fileOrder, s.reviewedFiles),
  shallow
);

// Derived: collapsed directories for FileBrowser tree
const collapsedDirs = useAppStore((s) => s.collapsedDirs);
const toggleDirCollapsed = useAppStore((s) => s.toggleDirCollapsed);

// Derived: comments grouped by file for CommentSummary (FR-crp-comment-summary)
const commentsByFile = useAppStore((s) => {
  const groups: { fileId: string; fileName: string; comments: Comment[] }[] = [];
  for (const fileId of s.fileOrder) {
    const fileComments = Object.values(s.comments)
      .filter((c) => c.fileId === fileId)
      .sort((a, b) => {
        if (a.startLine !== b.startLine) return a.startLine - b.startLine;
        return a.createdAt.localeCompare(b.createdAt);
      });
    if (fileComments.length > 0) {
      groups.push({
        fileId,
        fileName: s.files[fileId]?.name ?? 'Unknown',
        comments: fileComments,
      });
    }
  }
  return groups;
});

// Derived: sidebar tab state (SidebarContentTabs)
const sidebarTab = useAppStore((s) => s.sidebarTab);
const setSidebarTab = useAppStore((s) => s.setSidebarTab);

// Line wrap state (CodeViewer, Toolbar)
const lineWrapEnabled = useAppStore((s) => s.lineWrapEnabled);
const toggleLineWrap = useAppStore((s) => s.toggleLineWrap);

// FileBrowser sidebar width (FileBrowser, ResizeHandle, App layout)
const fileBrowserWidth = useAppStore((s) => s.fileBrowserWidth);
const setFileBrowserWidth = useAppStore((s) => s.setFileBrowserWidth);
const resetFileBrowserWidth = useAppStore((s) => s.resetFileBrowserWidth);
```

### Data Flow Summary

```
User interaction (click, keyboard, drop)
  --> Component event handler
    --> Zustand action (mutates store)
      --> Subscribed components re-render with new state
```

There is no prop drilling beyond one level. Components reach into the store directly. The only exceptions are leaf components like `CommentBubble` which receive their `Comment` object as a prop from `CodeViewer` to avoid each bubble subscribing to the store independently (performance optimization for large comment counts).

---

## Syntax Highlighting

### Shiki Integration

Shiki runs in the browser via its WASM-based engine. The integration works as follows:

1. **Initialization**: On app load, create a Shiki highlighter instance. Load only the theme and languages needed. Use Shiki's `createHighlighter()` with lazy language loading -- start with just `plaintext` and load additional grammars on demand when a file is loaded.

2. **Highlighting**: When a file is loaded, call `highlighter.codeToTokens(content, { lang })` to get an array of token lines. Each token has a color and text value. Store the tokenized output alongside the raw lines.

3. **Rendering**: Each `VirtualRow` renders its line's tokens as `<span>` elements with inline `style={{ color }}`. This is static HTML -- no contenteditable, no editor runtime.

4. **Progressive highlighting** (`NFR-crp-render-time`): For files over 500 lines, display the raw text with line numbers immediately (within the 500ms budget), then apply syntax highlighting in a microtask or `requestIdleCallback`. The visual effect is that the text appears immediately in monochrome and colors "paint in" shortly after. For files under 500 lines, highlighting completes within the initial render.

5. **Language loading**: Languages are loaded lazily from Shiki's bundled WASM grammars. The initial bundle includes only the highlighter core (~200 KB gzipped). Each language grammar adds ~10-50 KB loaded on demand. This keeps the initial page load fast.

### Supported Languages

Per `FR-crp-syntax-highlight`, the following Shiki language identifiers are supported:

| Language | Shiki ID | Extensions |
|---|---|---|
| JavaScript | `javascript` | `.js`, `.jsx`, `.mjs`, `.cjs` |
| TypeScript | `typescript` | `.ts`, `.tsx`, `.mts`, `.cts` |
| Python | `python` | `.py`, `.pyw` |
| Go | `go` | `.go` |
| Rust | `rust` | `.rs` |
| Java | `java` | `.java` |
| C | `c` | `.c`, `.h` |
| C++ | `cpp` | `.cpp`, `.cc`, `.cxx`, `.hpp`, `.hxx` |
| HTML | `html` | `.html`, `.htm` |
| CSS | `css` | `.css` |
| JSON | `json` | `.json` |
| YAML | `yaml` | `.yaml`, `.yml` |
| Markdown | `markdown` | `.md`, `.mdx` |
| Plain Text | `plaintext` | (fallback) |

### Theme

Use a single Shiki theme that works well on the white code viewer background. The `github-light` theme is a good match for the design spec's color palette. This is a fixed choice -- no theme switching in v1.

---

## Virtualized Scrolling

### TanStack Virtual Integration

The code viewer uses TanStack Virtual to render only the visible rows plus an overscan buffer. This satisfies `NFR-crp-large-file-perf` and `AC-crp-large-file-scroll`.

#### Row Model

The virtualizer operates on a "display items" array, not directly on the file's lines array. Display items interleave code lines with comment bubbles and the editor:

```typescript
type DisplayItem =
  | { type: 'code-line'; lineNumber: number; tokens: Token[] }
  | { type: 'comment-bubble'; comment: Comment }
  | { type: 'editor'; anchorLine: number; endLine: number; mode: 'create' | 'edit' };
```

This array is recomputed whenever comments or the editor state change. The computation is O(lines + comments) which is well within the performance budget even for 10,000-line files with 200 comments.

#### Height Estimation

- Code lines: fixed height of 20px when line wrapping is off (matching the design spec's 13px font, 20px line-height). When line wrapping is on, code line heights are variable — short lines remain at 20px, while long lines expand based on how many visual rows they wrap to. The 20px estimate is still used as the initial estimate; `measureElement` corrects it after render.
- Comment bubbles: estimated at 60px initially, measured after render via `ResizeObserver` and fed back to TanStack Virtual for accurate scroll positioning.
- Editor: estimated at 160px initially, measured dynamically.

TanStack Virtual supports dynamic row heights natively via its `measureElement` callback. The virtualizer recalculates positions when measured heights differ from estimates. When `lineWrapEnabled` toggles, the component calls `virtualizer.measure()` to invalidate all cached measurements and force re-measurement of visible rows.

#### Overscan

Configure an overscan of 20 rows above and below the viewport. This provides smooth scrolling at typical scroll speeds without rendering too many DOM nodes. For a 10,000-line file visible at ~50 lines per viewport, this means ~90 DOM nodes at any time instead of 10,000.

#### Scroll-to-Line

Comment navigation (`FR-crp-comment-navigation`, `AC-crp-comment-navigation-next`) uses TanStack Virtual's `scrollToIndex()` method to center the target comment's display item in the viewport.

---

## Prompt Generation

### `buildPrompt()` Pure Function

Prompt generation (`FR-crp-prompt-generate`, `FR-crp-prompt-format`, `FR-crp-multi-file-prompt`, `FR-crp-multi-file-prompt-format`) is implemented as a pure function with no side effects. The store calls `buildPrompt()` automatically after every comment mutation (`addComment`, `updateComment`, `deleteComment`), preamble change (`setPreamble`), and file change (`addFile`, `removeFile`), so the prompt is always up to date without user-triggered generation:

```typescript
function buildPrompt(
  files: Record<string, FileInfo>,
  fileOrder: string[],
  comments: Record<string, Comment>,
  preamble: string
): string | null
```

The function:

1. Groups comments by `fileId`.
2. Filters to only files that have at least one comment. Files without comments are omitted from the prompt (`AC-crp-multi-file-prompt-omits-uncommented`).
3. Orders the included files by their position in `fileOrder` (load order).
4. For each file with comments, sorts its comments by `startLine` ascending, then `createdAt` ascending for ties.
5. Returns `null` if no comments exist on any file.
6. Assembles the sections per `FR-crp-prompt-format` and `FR-crp-multi-file-prompt-format`:
   - **Instructions section** (only if preamble is non-empty after trimming -- whitespace-only preambles are treated as empty): `## Instructions` followed by the preamble text. The preamble is global, not per-file.
   - **For each file with comments**:
     - `## File: <fileName> (<language>)` heading (e.g., `## File: utils.ts (typescript)`).
     - `### Requested Changes` subheading.
     - Each comment formatted as a fenced code snippet + comment text:
       ```
       - **Code:**
         ```
         <extracted code snippet>
         ```
         <comment text>
       ```
   - For each comment, extracts the code snippet from the file's `lines` spanning `[startLine, endLine]` (1-indexed, inclusive). The snippet is the actual source lines the comment references, preserving original indentation.

The prompt does **not** include the full file content or line numbers. Each comment is paired directly with the code snippet it references. This design ensures the prompt remains accurate even if line numbers shift as the file is edited between prompt generation and AI consumption.

For single-file sessions, the output format is identical to the previous single-file format (one file heading, one Requested Changes section). The multi-file format is a natural extension with additional file sections.

This function is unit-testable in isolation. It satisfies `AC-crp-generate-prompt-structure`, `AC-crp-multi-file-prompt-structure`, `AC-crp-multi-file-prompt-omits-uncommented`, and `AC-crp-preview-matches-copy` (the same string is stored, displayed, and copied).

### Performance (`NFR-crp-prompt-gen-time`)

For a session with multiple files totaling 10,000+ lines and 200 comments across all files, this function performs:
- One grouping pass over all comments: O(total_comments)
- Per-file sort of comments: O(total_comments * log(max_comments_per_file))
- One pass per file to extract snippets and format comments: O(total_comments * average_snippet_lines)
- String concatenation via array join: O(total characters)

The output size scales with the number of comments and their snippet sizes rather than the total file length. This is well under the 300ms budget. Expected real-world time: <5ms.

---

## File Loading

### Binary Detection

Per the design spec and `AC-crp-binary-file-rejected`:

1. Read the file as an `ArrayBuffer` first.
2. Scan the first 8,192 bytes for any `0x00` byte.
3. If found, surface the error state. Do not attempt to decode.
4. If clean, decode the `ArrayBuffer` as UTF-8 via `TextDecoder`.

This two-step approach avoids garbled content from reaching the viewer.

### File Reading

- **Upload / drag-and-drop**: Use `FileReader.readAsArrayBuffer()` on the `File` object. After the binary check, decode with `new TextDecoder('utf-8')`.
- **Paste**: The pasted string is already decoded text. Skip binary detection (clipboard paste cannot produce binary data in standard browsers).

### Large File Warning

When a file's `lines.length > 10_000`, the `CodeViewer` renders a dismissible yellow banner per the design spec. Each file tracks its own warning dismissal state independently — dismissing the warning for one file does not affect other files. Dismissal state is stored per file ID in the store (session-only, reset on `clearSession`). The file is still loaded and functional.

---

## Clipboard Integration

### Copy Implementation (`FR-crp-prompt-copy`, `AC-crp-copy-clipboard`)

```typescript
async function copyToClipboard(text: string): Promise<boolean> {
  try {
    await navigator.clipboard.writeText(text);
    return true;
  } catch {
    // Fallback for older browsers or denied permissions
    return fallbackCopy(text);
  }
}

function fallbackCopy(text: string): boolean {
  const textarea = document.createElement('textarea');
  textarea.value = text;
  textarea.style.position = 'fixed';
  textarea.style.opacity = '0';
  document.body.appendChild(textarea);
  textarea.select();
  const success = document.execCommand('copy');
  document.body.removeChild(textarea);
  return success;
}
```

The modern Clipboard API is preferred. The `execCommand` fallback handles Safari edge cases and permission-denied scenarios. Both paths are covered by `NFR-crp-browser-support`.

---

## Error Handling

| Error Case | Detection | User Impact | Recovery |
|---|---|---|---|
| Binary file uploaded | Null byte in first 8,192 bytes | Error message in FileDropZone | Dismiss and try another file |
| File read failure | `FileReader.onerror` | Error message in FileDropZone | Dismiss and try again |
| Clipboard write failure | Caught promise rejection from `navigator.clipboard.writeText` | Error toast: "Failed to copy. Try selecting the text manually." | User can manually select text in the preview |
| Shiki grammar load failure | Caught error from `highlighter.loadLanguage()` | File renders as plain text (no highlighting). Info toast: "Syntax highlighting unavailable for this file. Displaying as plain text." | Automatic fallback |
| Binary file in multi-drop | Per-file binary detection during multi-file drop | Valid files are loaded; binary files are skipped. Summary toast: "Loaded N files. M file(s) skipped (binary)." | Valid files added to session; binary files ignored |
| File exceeds 10,000 lines | `lines.length > 10_000` | Dismissible warning banner | User acknowledges and continues |

All errors are caught at the component level and rendered in the UI. No errors should reach the console unhandled in production. No errors crash the application -- every error path has a defined recovery.

---

## Performance Considerations

### Rendering Budget (`NFR-crp-render-time`)

Target: text with line numbers visible within 500ms for files under 1,000 lines.

Strategy:
1. Parse lines immediately on file load (string split is <1ms even for large files).
2. Render the virtualized list with raw text immediately (first paint).
3. Kick off Shiki highlighting asynchronously.
4. Once tokens are ready, update the store. The virtualizer re-renders visible rows with colored tokens.

For files under 500 lines, Shiki completes fast enough to be part of the initial render. For larger files, the progressive approach ensures the 500ms budget is met.

### Scroll Performance (`NFR-crp-large-file-perf`, `AC-crp-large-file-scroll`)

Target: no jank (no frame drops exceeding 200ms) for files up to 10,000 lines.

Strategy:
- Virtualization limits DOM nodes to ~90 at any time.
- Code line rows have fixed height (20px) when line wrapping is off, avoiding layout thrashing.
- Comment bubbles use `ResizeObserver` for height measurement but this only fires when bubbles enter/exit the viewport, not on every scroll frame.
- Syntax-highlighted tokens are pre-computed `<span>` elements with inline styles -- no CSS class lookups or computed styles during scroll.
- No `useEffect` subscriptions that fire on scroll. The virtualizer handles all scroll-position-to-rendered-rows logic internally.

### Line Wrapping Performance (`FR-crp-line-wrap`)

When line wrapping is enabled, row heights become variable — short lines remain at 20px while long lines expand to multiple visual rows. This piggybacks on the existing `ResizeObserver`-based dynamic height infrastructure already used for comment bubbles, so no new measurement pattern is needed.

- **Toggling wrap** invalidates the virtualizer's measurement cache via `virtualizer.measure()`, triggering re-measurement of all visible + overscan rows. For most files (under 5,000 lines) this is imperceptible. For 10,000+ line files there may be a brief re-layout (estimated <100ms) while the browser recalculates wrapped heights for visible rows.
- **Viewport/panel resize** while wrapping is active changes the available width, which changes wrapped line heights. A `ResizeObserver` on the code viewer panel container detects width changes and calls `virtualizer.measure()`. This fires only on actual resize events, not on every frame.
- **Scroll performance with wrapping on** remains smooth because TanStack Virtual still only renders ~90 DOM nodes. Most lines in a typical file are short enough not to wrap, so the majority of rows retain their 20px height even with wrapping enabled. The virtualizer's overscan strategy is unaffected.
- **No pre-computation**: Wrapped heights are not pre-calculated. They are measured after render by the existing `measureElement` / `ResizeObserver` pipeline. This is the same strategy used for comment bubbles and the inline editor.

### Prompt Generation (`NFR-crp-prompt-gen-time`)

Target: under 300ms for 10,000 lines with 200 comments.

Strategy: Pure string computation as described above. No DOM interaction, no async, no layout. Expected real-world time: <5ms.

### Memory

A 10,000-line file with 100-character average lines is ~1 MB of text. Syntax tokens roughly double this. 200 comments add negligible overhead. Total memory for the largest expected workload is well under 10 MB, which is trivial for a browser tab.

---

## Done Action & Prompt Handoff

> Implements: `FR-crp-done-action`, `FR-crp-prompt-handoff`
> See requirements in `../../product/code-review-prompt.md`
> See design in `../../design/web/code-review-prompt.md`

This section covers the "Done" button feature that sends the generated prompt back to the Claude Code agent via a file-based handoff through the Vite dev server.

### State Management Changes

The existing Zustand store (`src/store/appStore.ts`) gains two new state fields and two new actions.

#### New State Fields

```typescript
// Added to AppState interface
isSlashCommandMode: boolean;    // true when file was loaded via ?file= URL param
doneState: 'idle' | 'sending' | 'sent';  // Done button lifecycle state
```

- **`isSlashCommandMode`**: Set to `true` by the `useFileFromUrl` hook when it successfully loads a file from the `?file=` URL parameter. Reset to `false` when the session is cleared via `clearSession`. This determines whether the Done button is visible. In standalone mode (file loaded via paste/upload/drag-drop), this remains `false` and the Done button is hidden (`AC-crp-done-standalone-hidden`).
- **`doneState`**: Tracks the Done button's lifecycle. Transitions: `'idle'` -> `'sending'` -> `'sent'`. Resets to `'idle'` whenever comments or preamble change (hooked into the existing `addComment`, `updateComment`, `deleteComment`, and `setPreamble` actions). This reset ensures the user knows they need to re-send after making changes.
- **`sessionId`**: The session ID from the `?session=` URL parameter. Set by `useFileFromUrl` on mount via `store.setSessionId(sessionId)`. Reset to `null` by `clearSession`. Used by `sendPromptToAgent()` to include the session ID in the POST URL (`POST /api/prompt-output?session=<id>`). Also used to set `document.title` to include the project name when present (`FR-sc-session-id`, `FR-crp-session-identity`).

#### New Actions

```typescript
// Added to AppStore interface
setSlashCommandMode: (mode: boolean) => void;
sendPromptToAgent: () => Promise<void>;
```

- **`setSlashCommandMode(mode)`**: Simple setter for `isSlashCommandMode`. Called by `useFileFromUrl` on successful file load (`true`) and by `clearSession` (`false`).
- **`setSessionId(id)`**: Simple setter for `sessionId`. Called by `useFileFromUrl` when a `?session=` parameter is present in the URL. Called with `null` by `clearSession`. When set to a non-null value, also updates `document.title` to include the project/directory name derived from the loaded file paths (e.g., `"Shepherd — myproject"`) (`FR-crp-session-identity`).
- **`sendPromptToAgent()`**: Orchestrates the Done action. Implementation:
  1. Set `doneState` to `'sending'`.
  2. In parallel (`Promise.all`):
     - POST the current `generatedPrompt` to `/api/prompt-output?session=<sessionId>` as `text/plain`, where `<sessionId>` is read from `state.sessionId` (`FR-sc-session-scoped-output`). The `fetch` call uses an `AbortController` with a 10-second timeout to prevent the Done button from being stuck in the 'Sending...' state if the local server hangs.
     - Copy the prompt to clipboard via the existing `clipboard.ts` module.
  3. If POST succeeds:
     a. Set `doneState` to `'sent'`.
     b. Call `window.close()` to close the app-mode window (`AC-crp-done-auto-close`). In a Chrome app-mode window (opened via `--app` flag), `window.close()` is permitted because the window was opened programmatically by the shell, not by user navigation. If the close succeeds, the JS context is destroyed immediately -- no further code executes, and the user is returned to their terminal.
     c. Set a 500ms `setTimeout` fallback. If `window.close()` did not work (e.g., the CRPG is running in a regular browser tab where `window.close()` is blocked), the timeout fires and shows a success toast ("Prompt sent to agent! Switch back to your terminal."). This detection works because if `window.close()` succeeds, the JS context is destroyed and the timeout callback never fires.
     d. No further state updates are needed after calling `window.close()` if the close succeeds -- the JS context is destroyed along with the Zustand store.
  4. If POST fails: set `doneState` to `'idle'`, show warning toast ("Could not send to agent. Prompt copied to clipboard — paste it manually."). The clipboard copy happens in parallel and is fire-and-forget, so the prompt is on the clipboard regardless of the POST result (`AC-crp-done-fallback-clipboard`).

  The `window.close()` + fallback pattern in code:

  ```typescript
  // After successful POST:
  store.setState({ doneState: 'sent' });
  window.close();
  // If we're still here after 500ms, the close didn't work — show fallback
  setTimeout(() => {
    showToast('Prompt sent to agent! Switch back to your terminal.', 'success');
  }, 500);
  ```

#### doneState Reset Logic

The `doneState` field resets to `'idle'` inside these existing actions:
- `addComment` — after inserting the comment and rebuilding the prompt
- `updateComment` — after updating the text and rebuilding the prompt
- `deleteComment` — after removing the comment and rebuilding the prompt
- `setPreamble` — after updating the preamble and rebuilding the prompt

This ensures the Done button returns to its actionable state whenever the prompt content changes, signaling to the user that the new prompt has not yet been sent (`AC-crp-done-confirmation`).

### Toolbar Component Changes

The existing `Toolbar` component gains:

- **Store subscriptions**: Read `isSlashCommandMode`, `doneState`, and `sendPromptToAgent` from the store (in addition to existing subscriptions).
- **Conditional rendering**: The Done button renders only when `isSlashCommandMode` is `true` (`AC-crp-done-standalone-hidden`).
- **Button priority swap**: When Done is visible, Done uses primary styling (filled) and Copy uses secondary styling (outlined/ghost). When Done is not visible, Copy retains its existing primary styling. This follows the design spec's visual hierarchy for slash command mode.
- **Done button disabled state**: Disabled when `commentCount === 0` (same condition as Copy) (`AC-crp-done-disabled-no-comments`), or when `doneState === 'sent'` (already sent, awaiting change).
- **Done button label states**:
  - `doneState === 'idle'`: "Done" (or "Done" with the send icon)
  - `doneState === 'sending'`: "Sending..." with a spinner, disabled
  - `doneState === 'sent'`: "Sent" with a check icon, disabled, green tint. **Note**: In app-mode windows, the user typically never sees this state because `window.close()` closes the window immediately after `doneState` transitions to `'sent'`. The "Sent" UI is a fallback for when the CRPG is running in a regular browser tab where `window.close()` is blocked (`AC-crp-done-auto-close`).
- **Keyboard shortcut**: Register `Cmd+Shift+D` (macOS) / `Ctrl+Shift+D` (Windows/Linux) via the existing `useEffect` keydown listener on `document`. Only active when `isSlashCommandMode` is `true`. Calls `sendPromptToAgent()`.

Maps to: `FR-crp-done-action`, `AC-crp-done-sends-prompt`, `AC-crp-done-confirmation`, `AC-crp-done-auto-close`, `AC-crp-done-disabled-no-comments`, `AC-crp-done-standalone-hidden`.

### useFileFromUrl Hook Changes

> See existing hook spec in `../engineering/slash-command.md`

After successfully loading a file from the URL parameter (after calling `store.addFile()`):
1. Read the `?session=` URL parameter and call `store.setSessionId(sessionId)` if present (`FR-sc-session-id`). This stores the session ID for use by `sendPromptToAgent()`.
2. Call `store.setSlashCommandMode(true)`. This is the signal that places the CRPG into slash command mode for the duration of the session.
3. If a session ID is present, update `document.title` to include the project name derived from the file path(s) (e.g., `"Shepherd — myproject"`) (`FR-crp-session-identity`).

The `clearSession` action resets `isSlashCommandMode` to `false`, `sessionId` to `null`, and `document.title` to the default, so clearing the session returns the app to standalone mode.

### POST /api/prompt-output Client-Side Call

The `sendPromptToAgent` store action makes the following call, including the session ID as a query parameter (`FR-sc-session-scoped-output`):

```typescript
const sessionParam = state.sessionId ? `?session=${encodeURIComponent(state.sessionId)}` : '';
const response = await fetch(`/api/prompt-output${sessionParam}`, {
  method: 'POST',
  headers: { 'Content-Type': 'text/plain; charset=utf-8' },
  body: generatedPrompt,
});
```

This is a same-origin request (the CRPG and the Vite dev server share the same origin). No special CORS headers or authentication are needed. The server-side endpoint is defined in `../engineering/slash-command.md`. The session parameter ensures the prompt output is written to the correct session-scoped directory (`~/.shepherd/sessions/<session-id>/prompt-output.md`), preventing concurrent sessions from interfering with each other.

Error handling:
- Network error (fetch throws): catch, set `doneState` to `'idle'`, show warning toast.
- Non-200 response: treat as failure, set `doneState` to `'idle'`, show warning toast.
- In both failure cases, the clipboard copy has already completed (it runs in parallel), so the prompt is available for manual paste (`AC-crp-done-fallback-clipboard`).

---

## Review Context Loading

> Implements: `FR-crp-review-context-receive`, `FR-crp-review-context-display`
> See requirements in `../../product/code-review-prompt.md`
> See design in `../../design/web/code-review-prompt.md`

This section covers how the CRPG receives and displays structured review context data from the shepherd-review command.

### Vite Plugin Endpoint: `GET /api/review-context?session=<session-id>`

A new endpoint is added to the Vite dev server plugin (in `vite.config.ts`, alongside the existing `/api/file` and `/api/prompt-output` endpoints). This endpoint reads the session-scoped context data file written by the shepherd-review command.

```typescript
// In the Vite plugin's configureServer hook:
server.middlewares.use('/api/review-context', (req, res) => {
  if (req.method !== 'GET') {
    res.statusCode = 405;
    res.end('Method not allowed');
    return;
  }

  const url = new URL(req.url!, `http://${req.headers.host}`);
  const sessionId = url.searchParams.get('session');
  if (!sessionId) {
    res.statusCode = 400;
    res.end(JSON.stringify({ error: 'Missing session parameter' }));
    return;
  }

  const contextPath = path.join(os.homedir(), '.shepherd', 'sessions', sessionId, 'review-context.json');

  try {
    const content = fs.readFileSync(contextPath, 'utf-8');
    const parsed = JSON.parse(content);
    res.setHeader('Content-Type', 'application/json');
    res.end(JSON.stringify(parsed));
  } catch (err) {
    // File not found or invalid JSON — return 404
    // This is the normal case for standalone mode or single /shepherd usage
    res.statusCode = 404;
    res.end('No review context available');
  }
});
```

Key details:
- The `session` query parameter is required. Returns 400 if missing. This ensures each request is scoped to a specific session (`FR-sc-session-scoped-output`).
- The endpoint reads `~/.shepherd/sessions/<session-id>/review-context.json` from disk each time it is called. No caching.
- Returns the JSON content as-is (the agent wrote valid JSON matching the `ReviewContext` TypeScript interface).
- Returns 404 if the file does not exist or is invalid JSON. The CRPG treats 404 as "no context available" and simply does not render the ReviewContextPanel (`AC-crp-context-graceful-missing`).
- Same-origin request (same as `/api/file` and `/api/prompt-output`). No CORS headers needed.

### Context Loading in `useFileFromUrl` Hook

The existing `useFileFromUrl` hook is updated to also load review context data after loading files from URL parameters. The loading sequence:

1. Read all `file` params from the URL (existing behavior).
2. Read the `session` param from the URL. Store it via `store.setSessionId(sessionId)` (`FR-sc-session-id`).
3. For each file, fetch via `GET /api/file?path=<encoded-path>` and call `store.addFile()` (existing behavior).
4. Set slash command mode: `store.setSlashCommandMode(true)` (existing behavior).
5. **NEW**: After all files are loaded, if a session ID is present, fetch `GET /api/review-context?session=<session-id>`:
   - On success (200 with valid JSON): call `store.setReviewContext(data)`.
   - On failure (400, 404, network error, invalid JSON): do nothing. `reviewContext` remains `null` and the ReviewContextPanel is not rendered. This is the graceful degradation path (`AC-crp-context-graceful-missing`).
6. Clean URL params (existing behavior).

The context fetch is non-blocking with respect to file loading -- files load and render first, then context data populates the ReviewContextPanel. In practice, the context file is small (a few KB of JSON) and the fetch is same-origin to localhost, so it completes in <10ms.

```typescript
// In useFileFromUrl, after loading all files and setting slash command mode:
const sessionId = params.get('session');
if (sessionId) {
  store.setSessionId(sessionId);
  try {
    const contextRes = await fetch(`/api/review-context?session=${encodeURIComponent(sessionId)}`);
    if (contextRes.ok) {
      const contextData: ReviewContext = await contextRes.json();
      store.setReviewContext(contextData);
    }
    // 404 or other failure: silently ignore, no context panel shown
  } catch {
    // Network error: silently ignore
  }
}
```

### File Path Matching

The per-file context in `reviewContext.files` is keyed by **absolute file path** (e.g., `/Users/dev/my-project/src/utils.ts`). The files loaded via `?file=` URL parameters also use absolute paths. The CRPG matches per-file context to loaded files by comparing the file's `name` property (which is the absolute path when loaded via URL params) against the keys in `reviewContext.files`.

This matching is exact-string. No normalization or fuzzy matching is needed because both the context file and the URL parameters are generated by the same agent using the same `git rev-parse --show-toplevel` + relative path construction.

---

## Security Considerations

### Privacy (`NFR-crp-client-only`)

- In standalone mode, no file content leaves the browser. There are no `fetch` calls, no analytics, no telemetry.
- In slash command mode, the network calls are limited to same-origin requests to the local Vite dev server: `GET /api/file` (file loading), `POST /api/prompt-output?session=<id>` (session-scoped prompt handoff), and `GET /api/review-context?session=<id>` (session-scoped context data loading). All data stays on the developer's machine -- the context file is read from `~/.shepherd/sessions/<session-id>/review-context.json` on the local filesystem. This is consistent with the spirit of `NFR-crp-client-only`.
- Content Security Policy headers should be configured to block all outbound network requests except those needed to load the app's own assets and the same-origin API endpoints (`/api/file`, `/api/prompt-output?session=<id>`, `/api/review-context?session=<id>`).
- Shiki WASM grammars are bundled with the application and served from the same origin -- no CDN dependency at runtime.

### Input Safety

- File content is rendered as text nodes, never as `innerHTML`. Shiki produces token objects that are rendered as React elements with `textContent` -- no XSS vector.
- The preamble and comment text are rendered the same way.
- The prompt preview renders its content inside a `<pre>` element as a text node.
- No `dangerouslySetInnerHTML` is used anywhere in the application.

### Clipboard

- The Clipboard API write is gated behind a user gesture (button click), which is required by browser security policies.
- No clipboard read is performed. The application only writes to the clipboard.

---

## Project Structure

```
engineering/
  code-review-prompt.md        (this file)
  pnpm-workspace.yaml          Workspace config for multi-app monorepo
  apps/
    web/                        Web application (Vite + React)
      index.html                Entry point
      package.json
      vite.config.ts
      tsconfig.json
      src/
        main.tsx                React root mount
        App.tsx                 Root component (includes global drop target for multi-file)
        store/
          appStore.ts           Zustand store definition (multi-file state)
        components/
          Toolbar.tsx
          FileBrowser.tsx        Sidebar panel with nested directory tree for multi-file navigation (resizable)
          ResizeHandle.tsx      NEW — Drag handle for resizing FileBrowser sidebar (FR-crp-panel-resize)
          ActiveFilePath.tsx    NEW — Active file path header in Code Viewer Panel (FR-crp-active-file-path)
          FileDropZone.tsx      (updated: full + modal variants)
          FileHeader.tsx
          CodeViewer.tsx
          CommentBubble.tsx
          InlineCommentEditor.tsx
          ReviewContextPanel.tsx — Collapsible panel for overall + per-file review context
          ContextSection.tsx    — Neutral/review variant sub-component
          ReviewStatusBar.tsx   NEW — Checkbox bar for toggling file reviewed status
          ReviewContextSidebar.tsx — Collapsible overall changeset context in sidebar
          SidebarContentTabs.tsx NEW — Tab control switching between Preview and All Comments
          CommentSummary.tsx    NEW — All comments summary view grouped by file
          PreambleInput.tsx
          PromptPreview.tsx
          ConfirmationDialog.tsx
          ToastNotification.tsx
        lib/
          highlighter.ts        Shiki highlighter initialization and caching
          languageDetect.ts     File extension to language mapping
          binaryDetect.ts       Null-byte binary detection
          buildFileTree.ts      Pure utility: parses file paths into nested FileTreeNode[] for FileBrowser
          promptBuilder.ts      Pure buildPrompt() function (multi-file)
          clipboard.ts          Clipboard write with fallback
        types/
          index.ts              Shared TypeScript type definitions
        styles/
          app.css               Tailwind directives and custom theme tokens
        __tests__/
          unit/
            buildFileTree.test.ts     Tree building, nesting, sorting, edge cases
            promptBuilder.test.ts     (includes multi-file prompt tests)
            binaryDetect.test.ts
            languageDetect.test.ts
            appStore.test.ts          (includes Done action, slash command mode, and multi-file store tests)
          component/
            FileBrowser.test.tsx       Sidebar rendering, interaction, badges, resize, tooltip
            ResizeHandle.test.tsx     NEW — Drag, clamp, double-click reset, keyboard accessibility
            ActiveFilePath.test.tsx   NEW — Path display, truncation, conditional rendering
            FileDropZone.test.tsx     (includes modal variant tests)
            CodeViewer.test.tsx
            CommentBubble.test.tsx
            InlineCommentEditor.test.tsx
            ReviewContextPanel.test.tsx — Conditional rendering, collapse/expand, per-file switching
            ContextSection.test.tsx    — Neutral/review variant styling, empty content hiding
            ReviewStatusBar.test.tsx   NEW — Toggle state, visual states, keyboard interaction
            ReviewContextSidebar.test.tsx — Collapse/expand, conditional rendering, content display
            SidebarContentTabs.test.tsx NEW — Tab switching, active state, count badge
            CommentSummary.test.tsx    NEW — Comment grouping, empty state, click navigation, real-time updates
            Toolbar.test.tsx          (includes Done button rendering/state tests)
            PromptPreview.test.tsx
          e2e/
            load-file.spec.ts
            add-comment.spec.ts
            auto-prompt.spec.ts
            keyboard-navigation.spec.ts
            done-action.spec.ts       Done button E2E flow in slash command mode
            multi-file.spec.ts        Multi-file load, switch, comment, prompt, remove flows
            review-context.spec.ts    — Context loading, display, per-file switching, collapse/expand, graceful missing
            file-reviewed.spec.ts     NEW — Mark/unmark, grouping transitions, progress indicator, persistence, keyboard shortcut
            sidebar-features.spec.ts  NEW — Sidebar collapse, preamble label, tabs, comment summary navigation
            panel-resize.spec.ts      NEW — FileBrowser sidebar resize drag, limits, double-click reset, keyboard
            active-file-path.spec.ts  NEW — Active file path display, truncation, file switch, untitled
```

> **Multi-platform note**: The `apps/` directory is structured as a pnpm workspace monorepo. Future platform targets (macOS, iOS) would be added as sibling directories to `apps/web/`. When shared logic is needed across platforms, it can be extracted into a `packages/core/` workspace package containing types, promptBuilder, binaryDetect, languageDetect, and other platform-agnostic modules.

---

## Testing Strategy

### Unit Tests (Vitest)

Pure logic functions tested in isolation:

| Module | Key Test Cases |
|---|---|
| `promptBuilder.ts` | Correct format with preamble; without preamble; single-line comments; range comments; line number padding; ascending sort order; empty edge cases. **Multi-file tests**: multiple files with comments produce combined prompt; single file with comments among multiple loaded files; files without comments omitted from prompt; file ordering matches `fileOrder`; returns `null` when no comments on any file. Validates `FR-crp-prompt-format`, `FR-crp-multi-file-prompt-format`, `AC-crp-generate-prompt-structure`, `AC-crp-multi-file-prompt-structure`, `AC-crp-multi-file-prompt-omits-uncommented`. |
| `binaryDetect.ts` | Detects null bytes; passes clean UTF-8; handles empty input; handles exactly 8,192 bytes boundary. Validates `AC-crp-binary-file-rejected`. |
| `languageDetect.ts` | Maps all 14+ extensions correctly; returns "plaintext" for unknown; case-insensitive extension matching. Validates `FR-crp-syntax-highlight`. |
| `buildFileTree.ts` | Builds nested directory tree from file paths; groups files under shared directory prefixes; root-level files appear at top level; pasted files ("Untitled") appear at top level; within each directory, unreviewed files sort before reviewed files; maintains load order among same-status files; handles deeply nested paths (e.g., `src/components/ui/Button.tsx`); handles mixed depths (some files nested, some at root); single shared directory still produces a directory node. Validates `AC-crp-file-path-display`, `AC-crp-file-path-single-dir`, `FR-crp-file-reviewed-grouping`. |
| `appStore.ts` | `addFile` creates file with unique ID and preserves existing files; `addFile` sets new file as active; `addFile` does NOT add to `reviewedFiles`; `removeFile` removes file and its comments; `removeFile` removes file from `reviewedFiles`; `removeFile` switches active file when removed file was active; `removeFile` returns to empty state when last file removed; `setActiveFile` preserves comments on previous file; `setActiveFile` recomputes `commentOrder` for new active file; `setActiveFile` saves and restores scroll positions; `addComment` auto-sets `fileId` to active file; `addComment` increments count and regenerates prompt automatically; `updateComment` regenerates prompt automatically; `deleteComment` decrements count and regenerates prompt automatically (clears prompt when last comment on any file removed); `navigateComment` wraps correctly within active file; `setPreamble` triggers prompt regeneration; `clearSession` resets everything including all files, all comments, `generatedPrompt` to null, `reviewContext` to null, `isReviewContextCollapsed` to false, and `reviewedFiles` to empty set; `setSlashCommandMode` sets the flag; `setSessionId` stores session ID; `sendPromptToAgent` posts to `/api/prompt-output?session=<id>` and copies to clipboard; `doneState` transitions correctly through `idle` -> `sending` -> `sent`; `doneState` resets to `idle` on comment/preamble changes; `clearSession` resets `isSlashCommandMode` to `false` and `sessionId` to `null`; `setReviewContext` stores context data; `toggleReviewContextCollapsed` toggles collapse state; `toggleReviewContextSidebarCollapsed` toggles sidebar collapse state independently of panel collapse; `setSidebarTab` switches between `'preview'` and `'comments'`; `clearSession` resets `isReviewContextSidebarCollapsed` to `false` and `sidebarTab` to `'preview'`; `toggleFileReviewed` adds file to `reviewedFiles` when unreviewed; `toggleFileReviewed` removes file from `reviewedFiles` when reviewed; `toggleFileReviewed` does not affect comments or active file; `toggleDirCollapsed` adds directory path to `collapsedDirs` when expanded; `toggleDirCollapsed` removes directory path from `collapsedDirs` when collapsed; `clearSession` resets `collapsedDirs` to empty set. Validates store-level behavior for most FR and AC slugs including `AC-crp-multi-file-load-adds`, `AC-crp-multi-file-nav-preserves-state`, `AC-crp-multi-file-clear-all`, `AC-crp-multi-file-empty-after-remove-last`, `AC-crp-file-mark-reviewed`, `AC-crp-file-unmark-reviewed`, `AC-crp-file-reviewed-with-comments`, `AC-crp-file-reviewed-clear-session`, `AC-crp-context-sidebar-collapse`, `FR-crp-comment-summary`. |

### Component Tests (React Testing Library)

Components tested with mocked store state:

| Component | Key Test Cases |
|---|---|
| `FileBrowser` | **Tree structure tests**: renders nested directory tree from file paths via `buildFileTree`; directory nodes display chevron and directory name at correct nesting indentation; file nodes are leaf items at correct indentation (`12px + nestingLevel * 16px`); root-level files (no directory) appear at top level of tree; pasted files ("Untitled") appear at top level in italics; clicking a directory node toggles `toggleDirCollapsed(dirPath)`; collapsed directory hides its children; shows comment count badges for files with comments; active file row has correct styling (white background, blue left border); click file row calls `setActiveFile`; click X calls `removeFile`; "+ Add file" button calls `openAddFileModal`; file row for pasted file supports rename on right-click; sidebar header shows review progress ("N/M reviewed"); uses `role="tree"` container with `role="treeitem"` for directories (`aria-expanded`) and files (`aria-selected`); **keyboard tests**: `ArrowUp`/`ArrowDown` traverses visible nodes (skips hidden children of collapsed dirs); `ArrowRight` expands collapsed directory or enters expanded directory; `ArrowLeft` collapses expanded directory or moves to parent; `Enter`/`Space` activates file or toggles directory; **file-reviewed tests**: within each directory, unreviewed files sort before reviewed files (no group headers); shows green checkmark for reviewed files; mutes text color for inactive reviewed file rows; click review toggle button calls `toggleFileReviewed`; `r` key on focused file row toggles reviewed state; review progress indicator turns green when all files reviewed. Validates `FR-crp-multi-file-nav`, `FR-crp-multi-file-remove`, `FR-crp-file-reviewed-visual`, `FR-crp-file-reviewed-grouping`, `FR-crp-file-reviewed-progress`, `AC-crp-file-reviewed-grouping`, `AC-crp-file-reviewed-progress-count`, `AC-crp-file-path-display`, `AC-crp-file-path-single-dir`. |
| `FileDropZone` | Renders empty state instructions (`AC-crp-empty-state`); file upload triggers `addFile` (`AC-crp-load-upload`); paste mode works (`AC-crp-load-paste`); binary file shows error (`AC-crp-binary-file-rejected`); **modal variant**: renders as overlay; multi-file drop loads all valid files (`AC-crp-multi-file-drop-multiple`); binary files in multi-drop are skipped with toast. |
| `CodeViewer` | Renders line numbers; click on gutter opens editor (`AC-crp-add-comment-single-line`); Shift+click selects range (`AC-crp-add-comment-line-range`); keyboard navigation works (`AC-crp-keyboard-add-comment`). |
| `Toolbar` | Copy button disabled until prompt exists (auto-generated when comments present); comment count displays correctly as global total across all files (`AC-crp-multi-file-comment-count`); no Generate button (prompt auto-generates); Done button hidden when `isSlashCommandMode` is false (`AC-crp-done-standalone-hidden`); Done button visible when `isSlashCommandMode` is true; Done button disabled when no comments (`AC-crp-done-disabled-no-comments`); Done button shows "Sending..." during send; Done button shows "Sent" after successful send (`AC-crp-done-confirmation`); Done button triggers `sendPromptToAgent`; Copy becomes secondary when Done is visible; Cmd+Shift+D keyboard shortcut fires `sendPromptToAgent` (`FR-crp-done-action`); Cmd+Shift+R keyboard shortcut calls `toggleFileReviewed(activeFileId)`. Note: review progress indicator has moved to FileBrowser sidebar -- Toolbar no longer renders it. |
| `ReviewContextPanel` | Not rendered when `reviewContext` is null (`AC-crp-context-graceful-missing`); renders overall section when context data is available (`AC-crp-context-overall-visible`); renders per-file section when active file has per-file context (`AC-crp-context-per-file-visible`); hides per-file section when active file has no per-file context; updates per-file section on file switch (`AC-crp-context-per-file-switches`); collapse/expand toggle works; collapse state persists across mock tab switches; all content is read-only (`AC-crp-context-readonly`). |
| `ReviewStatusBar` | Renders "Mark as reviewed" with unchecked checkbox when file is unreviewed; renders "Reviewed" with green checkmark when file is reviewed; clicking bar calls `toggleFileReviewed(activeFileId)`; keyboard Enter/Space on checkbox toggles state; displays correct keyboard shortcut hint; updates when active file changes. Validates `FR-crp-file-reviewed-toggle`, `AC-crp-file-mark-reviewed`, `AC-crp-file-unmark-reviewed`. |
| `ContextSection` | Neutral variant renders with blue styling, info icon, and "What Changed" label; review variant renders with violet styling, sparkle icon, and "Agent Review" label (`AC-crp-context-neutral-vs-review`); hidden when content is empty; content rendered as plain text with `pre-wrap`; content is not editable. |
| `ReviewContextSidebar` | Not rendered when `reviewContext` is null; renders when overall context is available; collapse/expand toggle works via `toggleReviewContextSidebarCollapsed`; collapsed state hides content but shows header; expanded state shows both ContextSections; collapse state persists across mock tab switches; all content is read-only. Validates `FR-crp-review-context-collapsible`, `AC-crp-context-sidebar-collapse`. |
| `PreambleInput` | Label reads "Overall Comment" (not "Preamble") (`AC-crp-overall-comment-label`); placeholder reads "Add an overall comment for all files in this review..."; collapsed preview text says "Overall Comment"; expanded textarea has correct `aria-label`. |
| `SidebarContentTabs` | Renders two tabs "Preview" and "All Comments"; default active tab is "Preview"; clicking "All Comments" tab switches content; count badge on "All Comments" tab shows total comment count; count badge hidden when no comments. Validates `FR-crp-comment-summary`. |
| `CommentSummary` | Shows empty state when no comments exist (`AC-crp-comment-summary-empty`); groups comments by file in `fileOrder` order; shows file names as section headers; shows line references and truncated comment text; clicking a comment entry calls `setActiveFile` and `setFocusedComment` (`AC-crp-comment-summary-shows-all`); updates immediately when comments are added/edited/deleted (`AC-crp-comment-summary-realtime`); files without comments are omitted. |
| `PromptPreview` | Shows empty variant when no comments (prompt is null); shows populated variant with current prompt text when comments exist; prompt always reflects latest comments and preamble. |
| `ConfirmationDialog` | Renders with correct text; confirm button triggers callback; cancel closes dialog; escape closes dialog (`AC-crp-clear-confirmation`). |

### End-to-End Tests (Playwright)

Full user flows tested in a real browser:

| Flow | Coverage |
|---|---|
| Load file via upload, add comment, verify prompt auto-generates, copy to clipboard | `AC-crp-load-upload`, `AC-crp-add-comment-single-line`, `AC-crp-generate-prompt-structure`, `AC-crp-copy-clipboard`, `AC-crp-preview-matches-copy` |
| Load file via paste, add range comment, verify prompt auto-generates | `AC-crp-load-paste`, `AC-crp-add-comment-line-range` |
| Edit and delete comments | `AC-crp-edit-comment`, `AC-crp-delete-comment` |
| Clear session with confirmation | `AC-crp-clear-confirmation`, `AC-crp-clear-no-confirm-empty` |
| Keyboard-only comment flow | `AC-crp-keyboard-add-comment` |
| Large file scroll performance | `AC-crp-large-file-scroll` (measure frame timing) |
| Comment navigation | `AC-crp-comment-navigation-next` |
| Done button sends prompt in slash command mode, shows confirmation | `FR-crp-done-action`, `AC-crp-done-sends-prompt`, `AC-crp-done-confirmation` |
| Done button hidden in standalone mode | `AC-crp-done-standalone-hidden` |
| Done button disabled with no comments | `AC-crp-done-disabled-no-comments` |
| Done fallback copies to clipboard on POST failure | `AC-crp-done-fallback-clipboard` |
| Keyboard shortcut Cmd+Shift+D sends prompt | `FR-crp-done-action` |
| Multi-file: load two files, switch between them, verify comments preserved | `FR-crp-multi-file-load`, `FR-crp-multi-file-nav`, `AC-crp-multi-file-load-adds`, `AC-crp-multi-file-nav-preserves-state` |
| Multi-file: add comments on multiple files, verify combined prompt structure | `FR-crp-multi-file-prompt`, `AC-crp-multi-file-prompt-structure`, `AC-crp-multi-file-prompt-omits-uncommented` |
| Multi-file: remove file with comments (confirmation), remove file without comments (no confirmation) | `FR-crp-multi-file-remove`, `AC-crp-multi-file-remove-with-comments`, `AC-crp-multi-file-remove-no-comments` |
| Multi-file: remove last file returns to empty state | `AC-crp-multi-file-empty-after-remove-last` |
| Multi-file: drag and drop multiple files simultaneously | `AC-crp-multi-file-drop-multiple` |
| Multi-file: comment count in toolbar spans all files | `AC-crp-multi-file-comment-count` |
| Multi-file: clear session removes all files and comments | `AC-crp-multi-file-clear-all` |
| Multi-file: FileBrowser renders nested directory tree from file paths; directories are collapsible with chevron toggles; files are indented under parent directories; unreviewed files sort before reviewed within each directory; root-level files and pasted files appear at top level; ArrowRight/ArrowLeft keyboard navigation expands/collapses directories | `FR-crp-multi-file-nav`, `AC-crp-file-path-display`, `AC-crp-file-path-single-dir` |
| Review context: context panel visible when context data exists | `FR-crp-review-context-display`, `AC-crp-context-overall-visible` |
| Review context: context panel hidden when no context data (standalone) | `AC-crp-context-graceful-missing` |
| Review context: per-file context switches when changing files | `AC-crp-context-per-file-switches`, `AC-crp-context-per-file-visible` |
| Review context: neutral vs review sections visually distinct | `AC-crp-context-neutral-vs-review` |
| Review context: collapse/expand persists across file switches | `FR-crp-review-context-display` |
| Review context: content is read-only (not editable) | `AC-crp-context-readonly` |
| File reviewed: mark file as reviewed via ReviewStatusBar, verify FileBrowser visual update and group change | `FR-crp-file-reviewed-toggle`, `AC-crp-file-mark-reviewed`, `FR-crp-file-reviewed-visual` |
| File reviewed: unmark a reviewed file, verify file re-sorts to unreviewed position within its directory in FileBrowser | `AC-crp-file-unmark-reviewed` |
| File reviewed: within each directory in the FileBrowser tree, unreviewed files sort before reviewed files (no group headers) | `FR-crp-file-reviewed-grouping`, `AC-crp-file-reviewed-grouping` |
| File reviewed: FileBrowser sidebar header progress indicator shows correct "N/M reviewed" count, updates on toggle/add/remove | `FR-crp-file-reviewed-progress`, `AC-crp-file-reviewed-progress-count` |
| File reviewed: reviewed status survives file switch | `AC-crp-file-reviewed-survives-tab-switch`, `FR-crp-file-reviewed-persistence` |
| File reviewed: marking is independent of comment presence | `AC-crp-file-reviewed-with-comments` |
| File reviewed: clear session resets all reviewed statuses | `AC-crp-file-reviewed-clear-session` |
| File reviewed: Cmd+Shift+R keyboard shortcut toggles active file reviewed state | `FR-crp-file-reviewed-toggle` |
| Sidebar: ReviewContextSidebar collapse/expand toggles content visibility | `FR-crp-review-context-collapsible`, `AC-crp-context-sidebar-collapse` |
| Sidebar: PreambleInput label shows "Overall Comment", placeholder text matches spec | `FR-crp-prompt-preamble`, `AC-crp-overall-comment-label` |
| Sidebar: Tab switching between Preview and All Comments | `FR-crp-comment-summary` |
| Sidebar: CommentSummary shows all comments grouped by file, empty state when no comments | `FR-crp-comment-summary`, `AC-crp-comment-summary-shows-all`, `AC-crp-comment-summary-empty` |
| Sidebar: Clicking a comment in CommentSummary navigates to the file and highlights the comment | `AC-crp-comment-summary-shows-all` |
| Sidebar: CommentSummary updates in real time when comments are added/edited/deleted | `AC-crp-comment-summary-realtime` |

### Cross-Browser Testing (`NFR-crp-browser-support`)

Playwright tests run against Chrome, Firefox, and WebKit (Safari proxy). Edge is not separately tested since it uses the Chromium engine, but a manual smoke test is performed before release.

---

## Implementation Plan

The work is divided into four phases. Each phase produces a deployable increment. Earlier phases focus on core structure; later phases add polish and optimization.

### Phase 1: Foundation (estimated 3-4 days)

**Goal**: Vite project scaffolding, Zustand store, file loading, and basic code display.

1. Initialize Vite project with `react-ts` template. Install dependencies: `react`, `react-dom`, `zustand`, `tailwindcss`, `shiki`, `@tanstack/react-virtual`.
2. Configure Tailwind CSS v4 with the design spec's color tokens as custom theme values.
3. Define TypeScript types in `src/types/index.ts` (matches the Data Model section above).
4. Implement the Zustand store (`src/store/appStore.ts`) with all actions and initial state.
5. Implement `binaryDetect.ts` and `languageDetect.ts` utility modules. Write unit tests.
6. Build the `FileDropZone` component with all three loading methods (paste, upload, drag-and-drop). Include binary detection and language detection.
7. Build the `App` layout shell: Toolbar (placeholder buttons) + MainContent area switching between FileDropZone (empty state) and code viewer panel (file loaded state).
8. Build the `FileHeader` component (file name, language badge, inline editable name for paste).
9. Build a basic (non-virtualized) `CodeViewer` that renders lines with line numbers and monospace formatting. No syntax highlighting yet.

**Delivers**: User can load a file via any method and see it displayed with line numbers. Binary files are rejected. File name and language are shown.

**Slug coverage**: `FR-crp-file-load`, `FR-crp-file-display`, `FR-crp-filename-display`, `AC-crp-load-paste`, `AC-crp-load-upload`, `AC-crp-load-drag-drop`, `AC-crp-binary-file-rejected`, `AC-crp-empty-state`, `NFR-crp-client-only`, `NFR-crp-no-data-persistence`.

### Phase 2: Comments and Prompt Generation (estimated 4-5 days)

**Goal**: Full comment CRUD, prompt generation, copy to clipboard, and sidebar.

1. Build the `InlineCommentEditor` component (create and edit variants).
2. Integrate comment creation into `CodeViewer`: gutter click opens editor, submit creates comment in store.
3. Build the `CommentBubble` component with edit/delete actions.
4. Implement line range selection (mouse drag, Shift+click) in the CodeViewer.
5. Build the `PreambleInput` component (expanded and collapsed variants).
6. Implement the `promptBuilder.ts` module. Write comprehensive unit tests.
7. Build the `PromptPreview` component (empty and populated variants).
8. Implement `clipboard.ts` with fallback. Build the `ToastNotification` component.
9. Wire up the Toolbar: Copy, comment count, comment navigation (next/prev). Wire auto-generation in the store so that `addComment`, `updateComment`, `deleteComment`, and `setPreamble` call `buildPrompt()` after mutation.
10. Build the `ConfirmationDialog` component. Wire up the Clear button.

**Delivers**: Complete core workflow: load file, add/edit/delete comments on single lines and ranges, write preamble, generate prompt, preview prompt, copy to clipboard, clear session.

**Slug coverage**: `FR-crp-line-comment-create`, `FR-crp-line-comment-edit`, `FR-crp-line-comment-delete`, `FR-crp-comment-indicator`, `FR-crp-comment-count`, `FR-crp-prompt-preamble`, `FR-crp-prompt-generate`, `FR-crp-prompt-preview`, `FR-crp-prompt-copy`, `FR-crp-prompt-format`, `FR-crp-clear-session`, `FR-crp-line-range-comment`, `FR-crp-comment-navigation`, `AC-crp-add-comment-single-line`, `AC-crp-add-comment-line-range`, `AC-crp-edit-comment`, `AC-crp-delete-comment`, `AC-crp-generate-prompt-structure`, `AC-crp-generate-prompt-no-comments`, `AC-crp-copy-clipboard`, `AC-crp-preview-matches-copy`, `AC-crp-clear-confirmation`, `AC-crp-clear-no-confirm-empty`, `AC-crp-comment-navigation-next`.

### Phase 3: Syntax Highlighting and Virtualization (estimated 3-4 days)

**Goal**: Shiki syntax highlighting, virtualized scrolling for large files, and performance validation.

1. Implement `highlighter.ts`: Shiki initialization, lazy language loading, `codeToTokens` wrapper.
2. Integrate Shiki tokens into `CodeViewer` rendering. Implement progressive highlighting for large files.
3. Replace the basic list rendering in `CodeViewer` with TanStack Virtual. Implement the display-items model with interleaved code lines and comment bubbles.
4. Implement dynamic row height measurement for comment bubbles and the editor.
5. Implement `scrollToIndex` for comment navigation.
6. Add the large file warning banner (>10,000 lines).
7. Performance testing: load a 10,000-line file, measure initial render time and scroll smoothness. Iterate until targets are met.

**Delivers**: Syntax highlighting for all 14 languages. Smooth scrolling for files up to 10,000+ lines. Progressive highlighting for large files.

**Slug coverage**: `FR-crp-syntax-highlight`, `AC-crp-syntax-highlight-detected`, `NFR-crp-large-file-perf`, `NFR-crp-render-time`, `NFR-crp-prompt-gen-time`, `AC-crp-large-file-scroll`.

### Phase 4: Accessibility, Responsiveness, and Polish (estimated 2-3 days)

**Goal**: Keyboard accessibility, responsive layout, ARIA attributes, cross-browser testing, and final polish.

1. Implement keyboard navigation in `CodeViewer`: ArrowUp/Down line focus, Enter/`c` to open editor, Shift+ArrowDown for range selection.
2. Add all keyboard shortcuts: `Cmd+Shift+C` (copy), `[`/`]` (comment nav), `Cmd+Enter`/`Ctrl+Enter` (submit), `Escape` (cancel/close).
3. Add ARIA attributes to all components per the design spec's accessibility section.
4. Implement focus management: focus trapping in modals, focus return after editor close, focus move on comment navigation.
5. Implement responsive behavior: sidebar width adjustment at 1024-1279px, sub-1024px overlay message.
6. Implement sticky gutter and line numbers with horizontal scrolling for the code content area.
7. Cross-browser testing with Playwright (Chrome, Firefox, WebKit). Fix any browser-specific issues.
8. Visual polish: hover states, transitions, toast animations, comment pulse animation.
9. Write remaining component tests and E2E tests. Achieve full AC coverage.

**Delivers**: Fully accessible, responsive, polished application meeting all FR, NFR, and AC requirements.

**Slug coverage**: `NFR-crp-accessibility-keyboard`, `NFR-crp-responsive-layout`, `NFR-crp-browser-support`, `AC-crp-keyboard-add-comment`.

### Phase 5: Multi-File Support (estimated 4-5 days)

**Goal**: Full multi-file session support — load, navigate, remove, and generate combined prompts.

1. Refactor data model: Update TypeScript types for multi-file (`FileInfo` gets `id`, `Comment` gets `fileId`, `AppState` gets `files`/`fileOrder`/`activeFileId`/`scrollPositions`).
2. Refactor Zustand store: Replace `loadFile` with `addFile`, add `removeFile`, `setActiveFile`, `saveScrollPosition`, `openAddFileModal`/`closeAddFileModal`. Update all actions that reference `state.file` to use `state.files[state.activeFileId]`.
3. Build `FileBrowser` component as a 240px fixed-width sidebar panel rendering a nested directory tree. Implement `buildFileTree(files, fileOrder, reviewedFiles)` utility that parses `FileInfo.name` paths into a recursive `FileTreeNode[]` structure. Directory nodes (28px, collapsible with chevron, 12px system sans-serif) group files by shared path prefixes. File nodes (32px, single line, monospace 13px) are leaf items indented under parent directories at `12px + nestingLevel * 16px`. Within each directory, unreviewed files sort before reviewed. Root-level files and pasted files appear at the top level. Add `collapsedDirs: Set<string>` to the store and `toggleDirCollapsed(dirPath)` action. Include close buttons, comment count badges, "+ Add file" button, review progress indicator in the sidebar header, and rename affordance for pasted files. Use `role="tree"` / `role="treeitem"` ARIA pattern with `ArrowUp`/`ArrowDown` for traversal and `ArrowRight`/`ArrowLeft` for expand/collapse navigation.
4. Update `FileDropZone` to support `modal` variant (portal overlay). Update multi-file drop logic to iterate all files and call `addFile()` for each (with per-file binary detection and summary toast).
5. Add global drop target on `App` — register drag-and-drop listener on the entire window when files are loaded so dropping files anywhere adds them to the session.
6. Update `promptBuilder.ts` for multi-file: accept `files`, `fileOrder`, `comments`, and `preamble`. Group comments by `fileId`, filter to files with comments, order by `fileOrder`, produce combined output with per-file sections.
7. Update `CodeViewer` to restore scroll position on file switch (read from `scrollPositions` when `activeFileId` changes).
8. Update `Toolbar` to read global comment count across all files (`Object.values(state.comments).length`).
9. Update `ConfirmationDialog` to handle both "clear session" (remove all files) and "remove file" (remove individual file with comments) use cases.
10. Write unit tests for multi-file `promptBuilder` and store. Write component tests for `FileBrowser`. Write E2E tests for multi-file flows.

**Delivers**: Complete multi-file workflow: load multiple files via any method, navigate between files via FileBrowser sidebar, add/edit/delete comments per file, generate combined prompt, remove individual files or clear entire session.

**Slug coverage**: `FR-crp-multi-file-load`, `FR-crp-multi-file-nav`, `FR-crp-multi-file-remove`, `FR-crp-multi-file-prompt`, `FR-crp-multi-file-prompt-format`, `AC-crp-multi-file-load-adds`, `AC-crp-multi-file-drop-multiple`, `AC-crp-multi-file-nav-preserves-state`, `AC-crp-multi-file-remove-with-comments`, `AC-crp-multi-file-remove-no-comments`, `AC-crp-multi-file-prompt-structure`, `AC-crp-multi-file-prompt-omits-uncommented`, `AC-crp-multi-file-comment-count`, `AC-crp-multi-file-clear-all`, `AC-crp-multi-file-empty-after-remove-last`.

### Phase 6: Review Context Display (estimated 3-4 days)

**Goal**: Receive structured review context data from the shepherd-review command and display it alongside diffs in the CRPG.

1. Add `GET /api/review-context?session=<id>` Vite plugin endpoint that reads `~/.shepherd/sessions/<session-id>/review-context.json` and returns the JSON content (400 if session missing, 404 if the file doesn't exist).
2. Add `ReviewContext` type and `reviewContext`/`isReviewContextCollapsed` fields to the Zustand store. Add `setReviewContext` and `toggleReviewContextCollapsed` actions. Update `clearSession` to reset these fields.
3. Update `useFileFromUrl` hook: after loading files from URL params, read session ID from `?session=` param, fetch `GET /api/review-context?session=<id>`. On success, call `store.setReviewContext(data)`. On failure (400/404/error), silently ignore.
4. Build `ContextSection` component with two variants: neutral ("What Changed", blue styling, info icon) and review ("Agent Review", violet styling, sparkle icon). Render content as plain text with `white-space: pre-wrap`. Hide when content is empty.
5. Build `ReviewContextPanel` component: collapsible panel containing overall and per-file sections, each with neutral + review `ContextSection` sub-components. Position between FileHeader (single-file) or top of Code Viewer Panel (multi-file, where FileBrowser replaces FileHeader) and CodeViewer. Conditionally rendered only when `state.reviewContext` is non-null. Per-file section derived from `state.reviewContext.files[activeFilePath]` -- updates on file switch via Zustand selector. Max-height 40% of Code Viewer Panel with overflow scroll.
6. Wire the ReviewContextPanel into the CodeViewerPanel layout. Verify it appears in both single-file and multi-file modes when context data is available, and is absent when not.
7. Write unit tests for store changes. Write component tests for `ReviewContextPanel` and `ContextSection`. Write E2E tests for context loading, display, per-file switching, collapse/expand, and graceful missing.

**Delivers**: When launched via `/shepherd-review`, the CRPG displays overall changeset context and per-file context alongside each diff. Neutral ("What Changed") and review ("Agent Review") sections are visually distinct. The context panel is collapsible and updates per-file context on file switch. When launched standalone or via `/shepherd`, no context panel is shown.

**Slug coverage**: `FR-crp-review-context-receive`, `FR-crp-review-context-display`, `FR-crp-review-context-overall`, `FR-crp-review-context-per-file`, `AC-crp-context-overall-visible`, `AC-crp-context-per-file-visible`, `AC-crp-context-per-file-switches`, `AC-crp-context-neutral-vs-review`, `AC-crp-context-graceful-missing`, `AC-crp-context-readonly`.

### Phase 7: File Reviewed Tracking (estimated 2-3 days)

**Goal**: Allow users to mark files as reviewed, visually group files by review status, and display review progress.

1. Add `reviewedFiles: Set<string>` to the Zustand store's `AppState`. Add `toggleFileReviewed(fileId)` action. Update `clearSession` to reset `reviewedFiles` to empty set. Update `removeFile` to remove file ID from `reviewedFiles`. Verify `addFile` does NOT add to `reviewedFiles`.
2. Add derived selectors: `reviewedCount`, `totalFileCount`, `fileTree` (builds nested directory tree with within-directory unreviewed-before-reviewed sorting), and `isActiveFileReviewed`.
3. Build `ReviewStatusBar` component: compact bar with checkbox + label, positioned below ReviewContextPanel (or at top of code viewer area). Reads `isActiveFileReviewed`, dispatches `toggleFileReviewed(activeFileId)`. Displays keyboard shortcut hint.
4. Update `FileBrowser` to read the `fileTree` selector. Within each directory in the tree, unreviewed files sort before reviewed files (no group headers or dividers). Add reviewed indicator (green checkmark) and review toggle icon button per file row. Apply muted text for inactive reviewed file rows. Add review progress indicator ("N/M reviewed") to the FileBrowser sidebar header, visible only when `totalFileCount >= 2`.
5. Register `Cmd+Shift+R` / `Ctrl+Shift+R` keyboard shortcut in the Toolbar for toggling active file's reviewed state.
6. Write unit tests for store changes (`toggleFileReviewed`, `clearSession` reset, `removeFile` cleanup, `addFile` default). Write component tests for `ReviewStatusBar` (toggle, visual states). Update `FileBrowser` tests for grouping and progress indicator.
7. Write E2E tests: mark/unmark files, verify grouping transitions, verify progress count updates, verify reviewed state survives file switches, verify clear session resets.

**Delivers**: Users can mark files as reviewed with a checkbox bar, keyboard shortcut, or FileBrowser sidebar icon. Files are visually grouped by review status in the FileBrowser. A progress indicator in the FileBrowser sidebar header shows review progress. Reviewed state persists within the session and resets on clear.

**Slug coverage**: `FR-crp-file-reviewed-toggle`, `FR-crp-file-reviewed-visual`, `FR-crp-file-reviewed-grouping`, `FR-crp-file-reviewed-progress`, `FR-crp-file-reviewed-persistence`, `AC-crp-file-mark-reviewed`, `AC-crp-file-unmark-reviewed`, `AC-crp-file-reviewed-grouping`, `AC-crp-file-reviewed-progress-count`, `AC-crp-file-reviewed-survives-tab-switch`, `AC-crp-file-reviewed-with-comments`, `AC-crp-file-reviewed-clear-session`.

### Phase 8: Sidebar Enhancements — Collapsible Context, Overall Comment, and Comment Summary (estimated 2-3 days)

**Goal**: Add collapsible toggle to ReviewContextSidebar, rename "Preamble" UI labels to "Overall Comment", and add an All Comments summary view with tab navigation in the sidebar.

1. Add `isReviewContextSidebarCollapsed: boolean` (default `false`) and `sidebarTab: 'preview' | 'comments'` (default `'preview'`) to the Zustand store. Add `toggleReviewContextSidebarCollapsed` and `setSidebarTab` actions. Update `clearSession` to reset both fields.
2. Update `ReviewContextSidebar.tsx`: Read `isReviewContextSidebarCollapsed` from the store. Add a clickable header bar with chevron icon (same pattern as `ReviewContextPanel`). Conditionally render content based on collapse state. Apply CSS transition for smooth collapse/expand animation (`FR-crp-review-context-collapsible`, `AC-crp-context-sidebar-collapse`).
3. Update `PreambleInput.tsx`: Change the toggle label from "Preamble" to "Overall Comment". Change the placeholder text to "Add an overall comment for all files in this review...". Change the collapsed preview text prefix to "Overall Comment". Update the `aria-label` to "Overall comment" (`FR-crp-prompt-preamble`, `AC-crp-overall-comment-label`). No store or prompt builder changes needed — `preamble` as an internal name is fine.
4. Build `CommentSummary.tsx`: Read `comments`, `files`, `fileOrder` from the store. Group comments by `fileId`, filter to files that have comments, order by `fileOrder`. Render file names as section headers, then each comment with line reference and truncated text. Show empty state when no comments exist. On click, navigate to file/comment via `setActiveFile` and `setFocusedComment` (`FR-crp-comment-summary`, `AC-crp-comment-summary-shows-all`, `AC-crp-comment-summary-realtime`, `AC-crp-comment-summary-empty`).
5. Build `SidebarContentTabs.tsx`: Two-tab segmented control — "Preview" and "All Comments" (with count badge). Reads `sidebarTab` from store, dispatches `setSidebarTab`. Renders `PromptPreview` or `CommentSummary` based on active tab.
6. Update `App.tsx` sidebar section: Replace the direct rendering of `PreambleInput` + `PromptPreview` with `ReviewContextSidebar` + `PreambleInput` + `SidebarContentTabs` (which internally renders `PromptPreview` or `CommentSummary`).
7. Write unit tests for new store actions. Write component tests for `ReviewContextSidebar` (collapse/expand), updated `PreambleInput` (label text), `SidebarContentTabs` (tab switching), and `CommentSummary` (grouping, click navigation, empty state, real-time updates). Write E2E tests for sidebar collapse, overall comment label, tab navigation, and comment summary navigation.

**Delivers**: ReviewContextSidebar is collapsible with a toggle. PreambleInput shows "Overall Comment" labels. A new "All Comments" tab in the sidebar shows all comments across all files with click-to-navigate functionality.

**Slug coverage**: `FR-crp-review-context-collapsible`, `FR-crp-prompt-preamble`, `FR-crp-comment-summary`, `AC-crp-context-sidebar-collapse`, `AC-crp-overall-comment-label`, `AC-crp-overall-comment-in-prompt`, `AC-crp-comment-summary-shows-all`, `AC-crp-comment-summary-realtime`, `AC-crp-comment-summary-empty`.

### Phase 9: Line Wrapping (estimated 1-2 days)

**Goal**: Add a line wrap toggle to the Toolbar that switches the CodeViewer between horizontal scrolling and visual line wrapping.

1. Add `lineWrapEnabled: boolean` (default `true`) and `toggleLineWrap` action to the Zustand store. Update `clearSession` to reset `lineWrapEnabled` to `true`.
2. Update `CodeViewer.tsx`: Read `lineWrapEnabled` from the store. When true, apply `white-space: pre-wrap; overflow-wrap: break-word; overflow-x: hidden` to code content cells (replacing `white-space: pre; overflow-x: auto`). Apply `vertical-align: top` / `align-self: start` to line number and gutter cells so they pin to the first visual row when text wraps (`AC-crp-line-wrap-preserves-line-numbers`).
3. Add a `useEffect` in `CodeViewer` that watches `lineWrapEnabled` and calls `virtualizer.measure()` on change to invalidate the size cache and trigger re-measurement of all visible rows.
4. Add a `ResizeObserver` on the code viewer panel container that calls `virtualizer.measure()` when the container width changes and `lineWrapEnabled` is true. This handles viewport resize and panel resize scenarios.
5. Update `Toolbar.tsx`: Add a line wrap toggle icon button that reads `lineWrapEnabled` and dispatches `toggleLineWrap()`. Register the `Alt+Z` keyboard shortcut in the existing `useEffect` keydown listener (`FR-crp-line-wrap`, `AC-crp-line-wrap-toggle`).
6. Write unit tests for the `toggleLineWrap` store action (toggle on/off, reset on clearSession). Write component tests for the Toolbar wrap button (click toggles state, reflects icon state). Write component tests for CodeViewer (CSS class changes based on `lineWrapEnabled`). Write E2E tests for the full toggle flow and `Alt+Z` shortcut.

**Delivers**: Users can toggle line wrapping on/off via an icon button or `Alt+Z`. Long lines wrap visually when enabled. Line numbers stay aligned. The virtualizer handles variable row heights. The preference persists for the session.

**Slug coverage**: `FR-crp-line-wrap`, `AC-crp-line-wrap-toggle`, `AC-crp-line-wrap-preserves-line-numbers`, `AC-crp-line-wrap-comment-target`, `AC-crp-line-wrap-default-on`, `AC-crp-line-wrap-persists-session`.

### Phase 10: Panel Resize, Active File Path, and File Tooltip (estimated 2-3 days)

**Goal**: Resizable FileBrowser sidebar, active file path header in the code viewer, and file row tooltips.

1. Add `fileBrowserWidth: number` (default `240`), `setFileBrowserWidth(width)`, and `resetFileBrowserWidth()` to the Zustand store. `setFileBrowserWidth` clamps to `[180, min(50vw, 600)]`. `resetFileBrowserWidth` sets to `240`. Update `clearSession` to reset `fileBrowserWidth` to `240`.
2. Build `ResizeHandle.tsx` component: 6px hit-target `<div>` positioned on the right edge of the FileBrowser. Implement the `onMouseDown` → document `mousemove`/`mouseup` drag pattern. Wrap `setFileBrowserWidth` calls in `requestAnimationFrame` during drag. Implement double-click detection via `onDoubleClick` calling `resetFileBrowserWidth()` with a 150ms `ease-out` CSS transition on the FileBrowser width. Add `role="separator"` keyboard support: `ArrowLeft`/`ArrowRight` ±10px, `Home`/`End` for min/max (`FR-crp-panel-resize`, `AC-crp-panel-resize-drag`, `AC-crp-panel-resize-bounds`, `AC-crp-panel-resize-double-click`, `AC-crp-panel-resize-keyboard`).
3. Update `FileBrowser.tsx`: Replace fixed `w-60` class with `style={{ width: fileBrowserWidth }}`. Read `fileBrowserWidth` from the store. Render `ResizeHandle` as a child positioned on the right edge.
4. Update `App.tsx` main layout: Use `fileBrowserWidth` from the store to set dynamic `grid-template-columns` (e.g., `${fileBrowserWidth}px 1fr 360px`) or equivalent flex basis instead of a fixed 240px column. The CodeViewer's `ResizeObserver` (added in Phase 9 for line wrapping) will automatically detect the width change and call `virtualizer.measure()`.
5. Build `ActiveFilePath.tsx` component: Reads `activeFileId`, `serverFilePaths`, `files`, and `fileOrder` from the store. Only renders when `fileOrder.length >= 2`. Derives path from `serverFilePaths[activeFileId]` or `files[activeFileId].name`. Applies CSS `direction: rtl` for left-truncation. 32px height, monospace 12px, muted color, subtle background. `role="status"` and `aria-live="polite"` (`FR-crp-active-file-path`, `AC-crp-active-file-path-visible`, `AC-crp-active-file-path-switches`, `AC-crp-active-file-path-single-file`).
6. Wire `ActiveFilePath` into `App.tsx` Code Viewer Panel layout: render above `ReviewContextPanel` when `fileOrder.length >= 2`.
7. Update `FileBrowser.tsx` file rows: Add `title` attribute to each file row `<div>`. Build tooltip string from `serverFilePaths[fileId]` (or `files[fileId].name`), `files[fileId].language`, and `reviewedFiles.has(fileId)`. Format: `<path> -- <language>` or `<path> -- <language> -- Reviewed` (`FR-crp-file-tooltip`, `AC-crp-file-tooltip-full-path`).
8. Write unit tests for new store actions (`setFileBrowserWidth` clamping, `resetFileBrowserWidth`, `clearSession` reset). Write component tests for `ResizeHandle` (drag simulation, clamp boundaries, double-click reset, keyboard navigation). Write component tests for `ActiveFilePath` (path display, truncation, conditional rendering, untitled files). Update `FileBrowser` tests for tooltip attribute and dynamic width. Write E2E tests for resize drag, double-click reset, active file path display, and tooltip content.

**Delivers**: Users can resize the FileBrowser sidebar by dragging its right edge, double-click to reset to default width. The active file's full path is displayed at the top of the code viewer in multi-file mode. File rows show a tooltip with full path, language, and review status on hover.

**Slug coverage**: `FR-crp-panel-resize`, `FR-crp-active-file-path`, `FR-crp-file-tooltip`, `AC-crp-panel-resize-drag`, `AC-crp-panel-resize-bounds`, `AC-crp-panel-resize-double-click`, `AC-crp-panel-resize-persists`, `AC-crp-active-file-path-visible`, `AC-crp-active-file-path-switches`, `AC-crp-active-file-path-single-file`, `AC-crp-file-tooltip-full-path`, `AC-crp-file-tooltip-reviewed`.

---

## Requirement Traceability

This section maps every requirement and acceptance criterion to the engineering components and modules that implement it.

### Functional Requirements

| Slug | Engineering Coverage |
|---|---|
| `FR-crp-file-load` | `FileDropZone` component (full + modal variants); `binaryDetect.ts`; `languageDetect.ts`; store `addFile` action; global drop target on `App` |
| `FR-crp-file-display` | `CodeViewer` component; `VirtualRow` component; TanStack Virtual integration |
| `FR-crp-syntax-highlight` | `highlighter.ts` (Shiki); `languageDetect.ts`; `CodeViewer` token rendering |
| `FR-crp-line-comment-create` | `InlineCommentEditor` component; store `addComment` action; `CodeViewer` gutter click handler |
| `FR-crp-line-comment-edit` | `InlineCommentEditor` (edit variant); `CommentBubble` edit button; store `updateComment` action |
| `FR-crp-line-comment-delete` | `CommentBubble` delete button; store `deleteComment` action |
| `FR-crp-comment-indicator` | `CodeViewer` gutter rendering (blue dot for commented lines) |
| `FR-crp-comment-count` | `Toolbar` component (reads global `commentCount` across all files from store) |
| `FR-crp-prompt-preamble` | `PreambleInput` component (labeled "Overall Comment"); store `preamble` state and `setPreamble` action |
| `FR-crp-prompt-generate` | `promptBuilder.ts`; Zustand store auto-generation on comment/preamble mutation |
| `FR-crp-prompt-preview` | `PromptPreview` component (reads `generatedPrompt` from store) |
| `FR-crp-prompt-copy` | `clipboard.ts`; store `copyPrompt` action; `Toolbar` Copy button; `ToastNotification` |
| `FR-crp-prompt-format` | `promptBuilder.ts` (format assembly logic) |
| `FR-crp-clear-session` | `ConfirmationDialog` component (clear session variant); store `clearSession` action (resets all files, comments, preamble); `Toolbar` Clear button |
| `FR-crp-filename-display` | `FileHeader` component (single-file); `FileBrowser` component (multi-file); store `files[activeFileId].name` |
| `FR-crp-line-range-comment` | `CodeViewer` range selection (mouse drag, Shift+click); `InlineCommentEditor` with range anchor |
| `FR-crp-comment-navigation` | `Toolbar` prev/next buttons; store `navigateComment` action; `CodeViewer` `scrollToIndex` |
| `FR-crp-done-action` | `Toolbar` Done button (conditional render, state display, keyboard shortcut); store `doneState` field, `sendPromptToAgent` action, `isSlashCommandMode` field; `useFileFromUrl` hook (sets slash command mode) |
| `FR-crp-prompt-handoff` | Store `sendPromptToAgent` action (POST to `/api/prompt-output`); Vite plugin endpoint (see `../engineering/slash-command.md`) |
| `FR-crp-multi-file-load` | `FileDropZone` (full + modal variants); global drop target on `App`; store `addFile` action |
| `FR-crp-multi-file-nav` | `FileBrowser` component (nested directory tree with collapsible directory nodes and file leaf nodes); `buildFileTree` utility; store `setActiveFile` action; `collapsedDirs` state; `toggleDirCollapsed` action; `scrollPositions` state |
| `FR-crp-multi-file-remove` | `FileBrowser` close button; `ConfirmationDialog` (file removal variant); store `removeFile` action |
| `FR-crp-multi-file-prompt` | `promptBuilder.ts` (multi-file mode); store auto-generation on any comment change across any file |
| `FR-crp-multi-file-prompt-format` | `promptBuilder.ts` (multi-file format assembly with per-file sections) |
| `FR-crp-review-context-receive` | `ReviewContextPanel` component (conditional rendering based on `state.reviewContext`); `useFileFromUrl` hook (fetches `GET /api/review-context?session=<id>` after loading files); Vite plugin endpoint (`GET /api/review-context?session=<id>` reads `~/.shepherd/sessions/<session-id>/review-context.json`); store `setReviewContext` action |
| `FR-crp-review-context-display` | `ReviewContextPanel` component; `ContextSection` component (neutral/review variants); Code Viewer Panel layout (positioned between FileHeader and CodeViewer in single-file mode; at top of Code Viewer Panel in multi-file mode where FileBrowser replaces FileHeader) |
| `FR-crp-review-context-overall` | `ReviewContextPanel` component (overall "CHANGESET OVERVIEW" section using `state.reviewContext.overall`); `ReviewContextSidebar` component (overall changeset context in sidebar) |
| `FR-crp-review-context-collapsible` | `ReviewContextSidebar` component (collapsible header bar with chevron toggle); store `isReviewContextSidebarCollapsed` state and `toggleReviewContextSidebarCollapsed` action |
| `FR-crp-comment-summary` | `CommentSummary` component (all comments grouped by file); `SidebarContentTabs` component ("All Comments" tab); store `sidebarTab` state and `setSidebarTab` action |
| `FR-crp-review-context-per-file` | `ReviewContextPanel` component (per-file section derived from `state.reviewContext.files[activeFilePath]`); updates on `setActiveFile` via Zustand selector |
| `FR-crp-file-reviewed-toggle` | `ReviewStatusBar` component (primary toggle); `FileBrowser` review toggle icon button; `Toolbar` keyboard shortcut `Cmd+Shift+R`; store `toggleFileReviewed` action; store `reviewedFiles` state |
| `FR-crp-file-reviewed-visual` | `FileBrowser` component (green checkmark icon, muted text for inactive reviewed file rows); `ReviewStatusBar` component (checked/unchecked visual states) |
| `FR-crp-file-reviewed-grouping` | `FileBrowser` component (reads `fileTree` selector); within each directory node, unreviewed files sort before reviewed files; no group headers or dividers |
| `FR-crp-file-reviewed-progress` | `FileBrowser` component sidebar header (review progress indicator badge "N/M reviewed"); `reviewedCount` and `totalFileCount` derived selectors |
| `FR-crp-file-reviewed-persistence` | Store `reviewedFiles` state (in-memory `Set<string>`); `clearSession` resets to empty set; `removeFile` removes from set; `addFile` does not add to set |
| `FR-crp-line-wrap` | `Toolbar` wrap toggle icon button and `Alt+Z` keyboard shortcut; store `lineWrapEnabled` state and `toggleLineWrap` action; `CodeViewer` CSS switching (`pre` vs `pre-wrap`), line number/gutter `align-self: start`, `virtualizer.measure()` on toggle, `ResizeObserver` for width changes |
| `FR-crp-panel-resize` | `ResizeHandle` component (drag handle on FileBrowser right edge); store `fileBrowserWidth` state, `setFileBrowserWidth` and `resetFileBrowserWidth` actions; `FileBrowser` dynamic `style={{ width: fileBrowserWidth }}`; `App.tsx` dynamic `grid-template-columns` layout |
| `FR-crp-active-file-path` | `ActiveFilePath` component (rendered in Code Viewer Panel when `fileOrder.length >= 2`); reads `serverFilePaths[activeFileId]` or `files[activeFileId].name`; CSS `direction: rtl` for left-truncation; `role="status"` with `aria-live="polite"` |
| `FR-crp-file-tooltip` | `FileBrowser` file row `title` attribute; tooltip string built from `serverFilePaths[fileId]`, `files[fileId].language`, and `reviewedFiles.has(fileId)` |

### Non-Functional Requirements

| Slug | Engineering Coverage |
|---|---|
| `NFR-crp-large-file-perf` | TanStack Virtual (virtualized rendering); overscan configuration; fixed row heights for code lines |
| `NFR-crp-render-time` | Progressive Shiki highlighting; immediate raw-text render; async token application |
| `NFR-crp-prompt-gen-time` | `promptBuilder.ts` is O(lines + comments log comments); pure computation, no DOM |
| `NFR-crp-client-only` | No `fetch` calls; all dependencies bundled; Shiki WASM served from same origin; CSP headers |
| `NFR-crp-browser-support` | Clipboard fallback; standard DOM APIs only; Playwright cross-browser E2E tests |
| `NFR-crp-responsive-layout` | Tailwind responsive utilities; sidebar width breakpoint; sub-1024px overlay |
| `NFR-crp-accessibility-keyboard` | `CodeViewer` keyboard navigation; global keyboard shortcuts; focus management; ARIA attributes |
| `NFR-crp-no-data-persistence` | Zustand store is in-memory only; no localStorage, no IndexedDB, no cookies |

### Acceptance Criteria

| Slug | Engineering Coverage |
|---|---|
| `AC-crp-load-paste` | `FileDropZone` paste-mode variant; store `addFile` |
| `AC-crp-load-upload` | `FileDropZone` file picker; `binaryDetect.ts`; store `addFile` |
| `AC-crp-load-drag-drop` | `FileDropZone` HTML5 drag-and-drop; `binaryDetect.ts`; store `addFile`; global drop target on `App` |
| `AC-crp-syntax-highlight-detected` | `highlighter.ts` (Shiki); `languageDetect.ts`; `CodeViewer` token rendering |
| `AC-crp-add-comment-single-line` | `CodeViewer` gutter click; `InlineCommentEditor` create variant; store `addComment` |
| `AC-crp-add-comment-line-range` | `CodeViewer` range selection; `InlineCommentEditor` with range; store `addComment` |
| `AC-crp-edit-comment` | `CommentBubble` edit button; `InlineCommentEditor` edit variant; store `updateComment` |
| `AC-crp-delete-comment` | `CommentBubble` delete button; store `deleteComment` |
| `AC-crp-generate-prompt-structure` | `promptBuilder.ts` format; unit tests validate structure |
| `AC-crp-generate-prompt-no-comments` | Store clears `generatedPrompt` when last comment is deleted; `PromptPreview` shows empty variant |
| `AC-crp-copy-clipboard` | `clipboard.ts`; `ToastNotification`; `Toolbar` Copy button state |
| `AC-crp-preview-matches-copy` | Single `generatedPrompt` string used for both preview display and clipboard write |
| `AC-crp-clear-confirmation` | `ConfirmationDialog` shown when `commentCount > 0`; store `clearSession` |
| `AC-crp-clear-no-confirm-empty` | Direct `clearSession` when `commentCount === 0` (no dialog) |
| `AC-crp-empty-state` | `FileDropZone` default variant; `Toolbar` disabled states |
| `AC-crp-large-file-scroll` | TanStack Virtual; Playwright scroll performance test |
| `AC-crp-comment-navigation-next` | Store `navigateComment('next')`; `CodeViewer` `scrollToIndex`; `Toolbar` nav buttons |
| `AC-crp-keyboard-add-comment` | `CodeViewer` keyboard handlers (ArrowUp/Down, Enter/`c`); `InlineCommentEditor` Cmd+Enter |
| `AC-crp-binary-file-rejected` | `binaryDetect.ts`; `FileDropZone` error variant |
| `AC-crp-done-sends-prompt` | Store `sendPromptToAgent` action (POST + clipboard in parallel); `Toolbar` Done button click handler |
| `AC-crp-done-confirmation` | Store `doneState` transitions (`idle` -> `sending` -> `sent`); `Toolbar` Done button label/icon states; `doneState` reset on comment/preamble change |
| `AC-crp-done-fallback-clipboard` | Store `sendPromptToAgent` error handling (clipboard copy succeeds even if POST fails); warning toast with manual paste instructions |
| `AC-crp-done-disabled-no-comments` | `Toolbar` Done button disabled state (same `commentCount === 0` check as Copy) |
| `AC-crp-done-auto-close` | Store `sendPromptToAgent` action calls `window.close()` after successful POST; 500ms `setTimeout` fallback detects if close was blocked and shows toast instead. App-mode windows (opened via Chrome `--app` flag) permit `window.close()`. Regular browser tabs fall back to toast notification. |
| `AC-crp-done-standalone-hidden` | `Toolbar` conditional render (`isSlashCommandMode === false` hides Done); `useFileFromUrl` sets mode; `clearSession` resets mode |
| `AC-crp-multi-file-load-adds` | Store `addFile` (preserves existing files and comments when adding a new file) |
| `AC-crp-multi-file-drop-multiple` | `FileDropZone` multi-file drop handling; `App` global drop target; per-file binary detection with summary toast |
| `AC-crp-multi-file-nav-preserves-state` | Store `setActiveFile` (preserves comments and scroll position per file); `FileBrowser` file row selection |
| `AC-crp-file-path-display` | `FileBrowser` component (nested directory tree hierarchy derived from `FileInfo.name` paths via `buildFileTree`; files organized under collapsible directory nodes at `12px + nestingLevel * 16px` indentation; pasted files appear at top level in italics; root-level files appear at top level) |
| `AC-crp-file-path-single-dir` | `FileBrowser` component (directory tree hierarchy always rendered even when all loaded files share the same directory — the shared directory node is still shown as a collapsible parent) |
| `AC-crp-multi-file-remove-with-comments` | `ConfirmationDialog` (file removal variant with comment count); store `removeFile` |
| `AC-crp-multi-file-remove-no-comments` | Store `removeFile` (skips confirmation when 0 comments on file) |
| `AC-crp-multi-file-prompt-structure` | `promptBuilder.ts` multi-file output (per-file sections with headings); unit tests |
| `AC-crp-multi-file-prompt-omits-uncommented` | `promptBuilder.ts` filters files without comments from prompt output |
| `AC-crp-multi-file-comment-count` | `Toolbar` reads global comment count from store (`Object.values(state.comments).length`) |
| `AC-crp-multi-file-clear-all` | Store `clearSession` resets all files, all comments, preamble, and all derived state |
| `AC-crp-multi-file-empty-after-remove-last` | Store `removeFile` returns to empty state (`activeFileId: null`, `fileOrder: []`, `files: {}`) when last file removed |
| `AC-crp-context-overall-visible` | `ReviewContextPanel` component (expanded state renders overall "CHANGESET OVERVIEW" section with neutral and review ContextSections) |
| `AC-crp-context-per-file-visible` | `ReviewContextPanel` component (expanded state renders per-file section when active file has per-file context in `reviewContext.files`) |
| `AC-crp-context-per-file-switches` | `ReviewContextPanel` per-file section updates via Zustand selector when `setActiveFile` changes the active file; per-file section hidden if new active file has no context |
| `AC-crp-context-neutral-vs-review` | `ContextSection` component (two variants: neutral with blue styling/info icon/"What Changed" label, review with violet styling/sparkle icon/"Agent Review" label) |
| `AC-crp-context-graceful-missing` | `ReviewContextPanel` not rendered when `state.reviewContext` is null; `useFileFromUrl` silently handles 404 from `GET /api/review-context`; no empty placeholder state |
| `AC-crp-context-readonly` | `ReviewContextPanel` and `ContextSection` render content in read-only `<div>` elements with `white-space: pre-wrap`; no `contenteditable`, no input elements |
| `AC-crp-file-mark-reviewed` | `ReviewStatusBar` component (checkbox transitions to checked/green state); `FileBrowser` (file row shows green checkmark, moves to "Reviewed" group); store `toggleFileReviewed` action |
| `AC-crp-file-unmark-reviewed` | `ReviewStatusBar` component (checkbox transitions back to unchecked); `FileBrowser` (file row returns to "To Review" group); store `toggleFileReviewed` action |
| `AC-crp-file-reviewed-grouping` | `FileBrowser` component (within each directory in the `fileTree`, unreviewed files sort before reviewed files; no group headers or dividers) |
| `AC-crp-file-reviewed-progress-count` | `FileBrowser` sidebar header progress indicator (reads `reviewedCount` and `totalFileCount`; updates on toggle, add, remove; green text when all reviewed) |
| `AC-crp-file-reviewed-survives-tab-switch` | Store `reviewedFiles` state persists across `setActiveFile` calls; `ReviewStatusBar` re-reads `isActiveFileReviewed` on active file change |
| `AC-crp-file-reviewed-with-comments` | Store `toggleFileReviewed` is orthogonal to comment state; no interaction between `reviewedFiles` and `comments` |
| `AC-crp-file-reviewed-clear-session` | Store `clearSession` resets `reviewedFiles` to empty `Set` |
| `AC-crp-context-sidebar-collapse` | `ReviewContextSidebar` component (clickable header bar with chevron toggle); store `isReviewContextSidebarCollapsed` and `toggleReviewContextSidebarCollapsed` action; `clearSession` resets to `false` |
| `AC-crp-overall-comment-label` | `PreambleInput` component (label "Overall Comment", placeholder "Add an overall comment for all files in this review...", collapsed preview "Overall Comment", `aria-label` "Overall comment") |
| `AC-crp-overall-comment-in-prompt` | `promptBuilder.ts` — no change needed (the `## Instructions` heading is preserved); the preamble content appears at the top of the generated prompt unchanged |
| `AC-crp-comment-summary-shows-all` | `CommentSummary` component (groups comments by file in `fileOrder` order; shows file name headers, line references, truncated comment text; clicking navigates to file/comment) |
| `AC-crp-comment-summary-realtime` | `CommentSummary` component (reads directly from Zustand store; updates immediately on comment add/edit/delete) |
| `AC-crp-comment-summary-empty` | `CommentSummary` component (centered placeholder message "No comments yet. Add comments to code lines to see them here." when no comments exist on any file) |
| `AC-crp-line-wrap-toggle` | `Toolbar` wrap toggle icon button (dispatches `toggleLineWrap`); `Alt+Z` keyboard shortcut registered in Toolbar `useEffect` |
| `AC-crp-line-wrap-preserves-line-numbers` | `CodeViewer` line number and gutter cells use `vertical-align: top` / `align-self: start` to pin to first visual row when text wraps |
| `AC-crp-line-wrap-comment-target` | `CodeViewer` click handler targets logical line number regardless of visual wrapping; no change to comment creation logic |
| `AC-crp-line-wrap-default-on` | Store `lineWrapEnabled` initialized to `true`; `clearSession` resets to `true` |
| `AC-crp-line-wrap-persists-session` | Store `lineWrapEnabled` persists in Zustand for the session lifetime; not reset on file switch or file add/remove |
| `AC-crp-panel-resize-drag` | `ResizeHandle` `onMouseDown` → document `mousemove`/`mouseup` pattern; `requestAnimationFrame` throttling; store `setFileBrowserWidth` |
| `AC-crp-panel-resize-bounds` | Store `setFileBrowserWidth` clamps to `[180, min(50vw, 600)]`; `ResizeHandle` enforces limits during drag and keyboard |
| `AC-crp-panel-resize-double-click` | `ResizeHandle` `onDoubleClick` → store `resetFileBrowserWidth()` (240px); 150ms `ease-out` transition on FileBrowser width |
| `AC-crp-panel-resize-keyboard` | `ResizeHandle` `role="separator"` with `ArrowLeft`/`ArrowRight` ±10px, `Home`/`End` for min/max; ARIA value attributes |
| `AC-crp-active-file-path-visible` | `ActiveFilePath` component rendered above CodeViewer when `fileOrder.length >= 2`; reads path from store; CSS `direction: rtl` for left-truncation; `role="status"` and `aria-live="polite"` |
| `AC-crp-active-file-path-switches` | `ActiveFilePath` derives path from `serverFilePaths[activeFileId]` or `files[activeFileId].name`; reactively updates when `activeFileId` changes in the store |
| `AC-crp-active-file-path-single-file` | `ActiveFilePath` conditionally rendered only when `fileOrder.length >= 2`; hidden in single-file mode where `FileHeader` is shown instead |
| `AC-crp-file-tooltip-full-path` | `FileBrowser` file row `title` attribute: `<path> -- <language>` or `<path> -- <language> -- Reviewed`; uses native browser tooltip |
