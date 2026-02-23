# Code Review Prompt Generator -- Technical Spec

> Based on requirements in `../product/code-review-prompt.md`
> Based on design in `../design/code-review-prompt.md`

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
}

/** State of the inline comment editor. */
type EditorState =
  | { mode: 'create'; anchorLine: number; endLine: number }
  | { mode: 'edit'; commentId: string };
```

### Derived Data

Several values are computed from the store rather than stored directly:

- **Comment count (global)**: `Object.values(state.comments).length` — total across all files. Used by the Toolbar (`FR-crp-comment-count`).
- **Comments per file**: `Map<string, number>` counting comments per `fileId`. Used by FileTabBar for per-file comment count badges.
- **Lines with comments (active file)**: A `Map<number, string[]>` mapping each line number to the IDs of comments covering that line, filtered to only comments where `fileId === state.activeFileId`. Computed via a selector that iterates `comments`, filters by active file, and expands each `[startLine, endLine]` range.
- **Current comment index**: Position of `focusedCommentId` within `commentOrder` (which is already filtered to the active file).
- **commentOrder recomputation**: The `commentOrder` array is recomputed whenever the active file changes (via `setActiveFile`) or when comments are mutated (`addComment`, `updateComment`, `deleteComment`). It filters `comments` to those matching `activeFileId`, then sorts by `startLine` ascending, then `createdAt` ascending for ties.

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
           +-- FileTabBar                              NEW (design: FileTabBar)
           +-- CodeViewerPanel
           |    +-- FileHeader (single-file only, hidden when tab bar active)
           |    +-- CodeViewer         (design: CodeViewer)
           |         +-- VirtualRow (repeated, virtualized)
           |              +-- GutterCell
           |              +-- LineNumberCell
           |              +-- CodeContentCell
           |         +-- CommentBubble (design: CommentBubble, rendered inline between virtual rows)
           |         +-- InlineCommentEditor (design: InlineCommentEditor, rendered inline when editing)
           +-- SidebarPanel
                +-- PreambleInput     (design: PreambleInput)
                +-- PromptPreview     (design: PromptPreview)
 +-- FileDropZone (modal variant, rendered via portal when adding files)
 +-- ConfirmationDialog               (design: ConfirmationDialog, rendered via portal)
 +-- ToastNotification                (design: ToastNotification, rendered via portal)
```

### Component Responsibilities

#### `App`
Root component. Renders the top-level layout: Toolbar at top, MainContent below. Provides no context providers -- Zustand store is accessed directly by each component that needs it. Registers a global drag-and-drop listener on the entire window when files are loaded — dropping files anywhere on the app adds them to the session (calls `store.addFile()` for each valid file). This implements the design spec's "entire app window is a drop target" behavior.

#### `Toolbar`
Implements the persistent toolbar. Reads the global comment count (across all files via `Object.values(state.comments).length`), `focusedCommentId`, `commentOrder`, and `activeFileId` from the store to determine button states. Dispatches actions: `copyPrompt`, `clearSession`, `navigateComment('next' | 'prev')`. Registers keyboard shortcuts (`Cmd+Shift+C`, `[`, `]`) via a `useEffect` with `keydown` listener on `document`. Prompt generation is handled automatically by the store on comment/preamble mutation, so the Toolbar does not include a Generate button.

Maps to: `FR-crp-comment-count`, `FR-crp-comment-navigation`, `FR-crp-prompt-copy`, `FR-crp-clear-session`, `AC-crp-multi-file-comment-count`.

#### `FileDropZone`
Handles all three file-loading methods: paste, upload, drag-and-drop (`FR-crp-file-load`). Supports two variants:
- **`variant: 'full'`** — Original behavior: fills the main content area when no files are loaded. This is the empty-state drop zone.
- **`variant: 'modal'`** — Rendered as a portal modal overlay when adding files to an existing session (triggered by the "+" button in FileTabBar or via `store.openAddFileModal()`). The existing file content remains visible behind the backdrop.

Manages its own local UI state (current variant: default, drag-hover, paste-mode, loading, error). On successful load, calls the store's `addFile(content, fileName, language)` action.

Multi-file drop: When `event.dataTransfer.files.length > 1`, iterates all files and calls `store.addFile()` for each (with per-file binary detection). Valid files are loaded; binary files trigger an error toast per file (e.g., "Loaded 3 files. 1 file was skipped (binary)."). This replaces the previous single-file-only behavior.

Binary detection: reads the first 8,192 bytes of the file as an `ArrayBuffer`, checks for null bytes (`0x00`). If found, surfaces the error state (`AC-crp-binary-file-rejected`).

Language detection: maps file extension to Shiki language ID using a static lookup table. Falls back to `"plaintext"`. Supports: `.js`/`.jsx` (javascript), `.ts`/`.tsx` (typescript), `.py` (python), `.go` (go), `.rs` (rust), `.java` (java), `.c`/`.h` (c), `.cpp`/`.cc`/`.cxx`/`.hpp` (cpp), `.html` (html), `.css` (css), `.json` (json), `.yaml`/`.yml` (yaml), `.md` (markdown).

Maps to: `FR-crp-file-load`, `FR-crp-multi-file-load`, `AC-crp-load-paste`, `AC-crp-load-upload`, `AC-crp-load-drag-drop`, `AC-crp-binary-file-rejected`, `AC-crp-multi-file-load-adds`, `AC-crp-multi-file-drop-multiple`.

#### `FileTabBar`
Renders the horizontal tab bar for navigating between loaded files. Appears between the Toolbar and the code viewer panel when two or more files are loaded. Reads `files`, `fileOrder`, `activeFileId`, and per-file comment counts from the store. Dispatches: `setActiveFile(fileId)`, `removeFile(fileId)`, `openAddFileModal()`.

Tab order matches `fileOrder` (load order). Each tab displays: the file name (truncated with ellipsis if needed), a comment count badge (if > 0 comments on that file), and a close (X) button. The active tab has distinct styling (per design spec). A "+" button at the end of the tab row opens the FileDropZone in modal variant for adding additional files.

When the tab bar has only one file remaining (after removals), it collapses and the FileHeader is shown instead (single-file layout). The tab bar re-appears when a second file is loaded.

For pasted files named "Untitled", right-clicking the tab opens an inline rename input (matching the FileHeader's rename affordance).

Maps to: `FR-crp-multi-file-nav`, `FR-crp-multi-file-remove`, `AC-crp-multi-file-nav-preserves-state`.

#### `FileHeader`
Displays file name and language badge (`FR-crp-filename-display`). Only rendered in single-file mode (when `fileOrder.length === 1`); in multi-file mode, the FileTabBar provides this information instead. When the file was pasted without a name, renders an inline-editable text input. Calls `store.updateFileName(fileId, name)` on change.

#### `CodeViewer`
The most complex component. Renders the virtualized list of code lines using TanStack Virtual (`NFR-crp-large-file-perf`, `AC-crp-large-file-scroll`). Each visible row is a `VirtualRow` containing the gutter, line number, and syntax-highlighted code content.

Comment bubbles and the inline editor are rendered as non-virtualized elements inserted between virtual rows at the correct positions. This is handled by computing "expanded" row data that interleaves code lines with comment/editor slots, and assigning each slot a dynamic height for the virtualizer.

Line selection for range comments (`FR-crp-line-range-comment`) is handled via `onMouseDown`/`onMouseMove`/`onMouseUp` on line number cells, with Shift+click support. Keyboard selection uses `Shift+ArrowUp/Down` as specified in the design.

Keyboard navigation (`NFR-crp-accessibility-keyboard`, `AC-crp-keyboard-add-comment`): The code viewer is a focusable container. Arrow keys move a `focusedLine` local state (distinct from the store's `focusedCommentId` which tracks comment navigation). `focusedLine` is local to the CodeViewer component; `focusedCommentId` is global store state. Enter or `c` on a focused line always opens the comment editor in create mode (even if the line already has comments). ARIA attributes match the design spec (role="grid", role="row", role="rowheader", role="gridcell").

Maps to: `FR-crp-file-display`, `FR-crp-syntax-highlight`, `FR-crp-comment-indicator`, `FR-crp-line-range-comment`, `FR-crp-comment-navigation`, `NFR-crp-large-file-perf`, `NFR-crp-render-time`, `AC-crp-large-file-scroll`, `AC-crp-keyboard-add-comment`.

#### `CommentBubble`
Displays a single comment. Shows edit/delete actions on hover. Dispatches `store.openEditor('edit', commentId)` and `store.deleteComment(commentId)`.

Maps to: `FR-crp-line-comment-edit`, `FR-crp-line-comment-delete`, `FR-crp-comment-indicator`, `AC-crp-edit-comment`, `AC-crp-delete-comment`.

#### `InlineCommentEditor`
The create/edit form rendered inline in the code viewer. Manages its own text state locally. On submit, calls `store.addComment(startLine, endLine, text)` (create mode) or `store.updateComment(commentId, text)` (edit mode). Auto-focuses the textarea on mount. Handles `Cmd+Enter`/`Ctrl+Enter` submit and `Escape` cancel.

Maps to: `FR-crp-line-comment-create`, `FR-crp-line-comment-edit`, `AC-crp-add-comment-single-line`, `AC-crp-add-comment-line-range`, `AC-crp-edit-comment`.

#### `PreambleInput`
Controlled textarea bound to `store.preamble`. Supports expanded/collapsed variants as described in the design. Calls `store.setPreamble(text)` on change, which automatically triggers prompt regeneration via `buildPrompt()` if comments exist.

Maps to: `FR-crp-prompt-preamble`.

#### `PromptPreview`
Read-only display of `store.generatedPrompt` rendered inside a `<pre>` element as a text node — no markdown processing is applied. The user sees the literal markdown syntax markers as plain text. Two variants: empty (no comments exist, prompt is null) and populated (comments exist, prompt is automatically current). The prompt preview always shows the current, automatically generated prompt — there is no stale state. The inline "Copy" button calls `store.copyPrompt()`.

Maps to: `FR-crp-prompt-preview`, `FR-crp-prompt-format`, `AC-crp-generate-prompt-structure`, `AC-crp-preview-matches-copy`.

#### `ConfirmationDialog`
Generic modal. Rendered via a React portal to `document.body`. Traps focus while open. Used by:
- Clear session flow: Confirms removal of all files and comments (`AC-crp-clear-confirmation`, `AC-crp-clear-no-confirm-empty`).
- File removal flow: Confirms removal of an individual file that has comments (`AC-crp-multi-file-remove-with-comments`). Files without comments are removed immediately without confirmation (`AC-crp-multi-file-remove-no-comments`).

#### `ToastNotification`
Ephemeral notification rendered via a React portal. Auto-dismisses after the configured duration. Slide-up and fade-out animations via CSS transitions. Announced to screen readers via `role="status"` and `aria-live="polite"`.

Maps to: `AC-crp-copy-clipboard`.

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

  // Slash command (unchanged)
  setSlashCommandMode: (mode: boolean) => void;
  sendPromptToAgent: () => Promise<void>;
}
```

#### Action Semantics

- **`addFile`** (replaces `loadFile`): Creates a new `FileInfo` with `crypto.randomUUID()` as `id` and parsed lines (`content.split('\n')`). Appends to `files` map and `fileOrder` array. Sets `activeFileId` to the new file. Does NOT reset comments or preamble — existing files and comments are preserved (`AC-crp-multi-file-load-adds`). Recomputes `commentOrder` for the new active file (which will be empty). Triggers `buildPrompt()`. Closes the add file modal if open.
- **`removeFile`**: Removes the file from `files` map and `fileOrder` array. Removes all comments with matching `fileId` from the `comments` map. If the removed file was active, sets `activeFileId` to the next file in `fileOrder` (or previous, or `null` if no files remain). If no files remain, returns to empty state (`AC-crp-multi-file-empty-after-remove-last`). Removes the file's entry from `scrollPositions`. Triggers `buildPrompt()`. Recomputes `commentOrder` for the new active file.
- **`setActiveFile`**: Saves the current file's scroll position via `saveScrollPosition`. Updates `activeFileId`. Recomputes `commentOrder` for the newly active file. Clears `focusedCommentId`, `selectedRange`, and `editorState` (switching files cancels any in-progress editing).
- **`updateFileName`**: Now takes `(fileId, name)` instead of just `(name)`. Updates the `name` field on the specified file.
- **`addComment`**: Creates a `Comment` with `crypto.randomUUID()`, automatically sets `fileId` to `state.activeFileId` on the new comment. Inserts into `comments` map, recomputes `commentOrder`. Automatically regenerates the prompt via `buildPrompt()`.
- **`updateComment`**: Updates the `text` field on an existing comment. Automatically regenerates the prompt via `buildPrompt()`.
- **`deleteComment`**: Removes from `comments` map and `commentOrder`. If the deleted comment was `focusedCommentId`, clears focus. Automatically regenerates the prompt via `buildPrompt()` (sets `generatedPrompt` to `null` if no comments remain on any file).
- **`navigateComment`**: Advances or retreats `focusedCommentId` within `commentOrder` (filtered to active file only), wrapping at boundaries.
- **`setPreamble`**: Updates the preamble text. Automatically regenerates the prompt via `buildPrompt()` if comments exist on any file.
- **`copyPrompt`**: Calls `navigator.clipboard.writeText(generatedPrompt)`. Returns a promise; the component handles success/failure UI.
- **`clearSession`**: Resets the entire store to its initial state — removes all files, all comments, preamble, and clears `generatedPrompt` to `null`. Resets `activeFileId` to `null`, `fileOrder` to `[]`, `files` to `{}`, `scrollPositions` to `{}` (`AC-crp-multi-file-clear-all`).
- **`saveScrollPosition`**: Stores the given scroll offset for the specified file ID in `scrollPositions`. Called automatically by `setActiveFile` before switching.

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

// Derived: per-file comment counts for FileTabBar badges
const commentCountsByFile = useAppStore((s) => {
  const counts = new Map<string, number>();
  for (const comment of Object.values(s.comments)) {
    counts.set(comment.fileId, (counts.get(comment.fileId) || 0) + 1);
  }
  return counts;
});
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

- Code lines: fixed height of 20px (matching the design spec's 13px font, 20px line-height).
- Comment bubbles: estimated at 60px initially, measured after render via `ResizeObserver` and fed back to TanStack Virtual for accurate scroll positioning.
- Editor: estimated at 160px initially, measured dynamically.

TanStack Virtual supports dynamic row heights natively via its `measureElement` callback. The virtualizer recalculates positions when measured heights differ from estimates.

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
- Code line rows have fixed height (20px), avoiding layout thrashing.
- Comment bubbles use `ResizeObserver` for height measurement but this only fires when bubbles enter/exit the viewport, not on every scroll frame.
- Syntax-highlighted tokens are pre-computed `<span>` elements with inline styles -- no CSS class lookups or computed styles during scroll.
- No `useEffect` subscriptions that fire on scroll. The virtualizer handles all scroll-position-to-rendered-rows logic internally.

### Prompt Generation (`NFR-crp-prompt-gen-time`)

Target: under 300ms for 10,000 lines with 200 comments.

Strategy: Pure string computation as described above. No DOM interaction, no async, no layout. Expected real-world time: <5ms.

### Memory

A 10,000-line file with 100-character average lines is ~1 MB of text. Syntax tokens roughly double this. 200 comments add negligible overhead. Total memory for the largest expected workload is well under 10 MB, which is trivial for a browser tab.

---

## Done Action & Prompt Handoff

> Implements: `FR-crp-done-action`, `FR-crp-prompt-handoff`
> See requirements in `../product/code-review-prompt.md`
> See design in `../design/code-review-prompt.md`

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

#### New Actions

```typescript
// Added to AppStore interface
setSlashCommandMode: (mode: boolean) => void;
sendPromptToAgent: () => Promise<void>;
```

- **`setSlashCommandMode(mode)`**: Simple setter for `isSlashCommandMode`. Called by `useFileFromUrl` on successful file load (`true`) and by `clearSession` (`false`).
- **`sendPromptToAgent()`**: Orchestrates the Done action. Implementation:
  1. Set `doneState` to `'sending'`.
  2. In parallel (`Promise.all`):
     - POST the current `generatedPrompt` to `/api/prompt-output` as `text/plain`. The `fetch` call uses an `AbortController` with a 10-second timeout to prevent the Done button from being stuck in the 'Sending...' state if the local server hangs.
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

Minor addition: after successfully loading a file from the URL parameter (after calling `store.addFile()`), also call `store.setSlashCommandMode(true)`. This is the single signal that places the CRPG into slash command mode for the duration of the session.

The `clearSession` action resets `isSlashCommandMode` to `false`, so clearing the session returns the app to standalone mode.

### POST /api/prompt-output Client-Side Call

The `sendPromptToAgent` store action makes the following call:

```typescript
const response = await fetch('/api/prompt-output', {
  method: 'POST',
  headers: { 'Content-Type': 'text/plain; charset=utf-8' },
  body: generatedPrompt,
});
```

This is a same-origin request (the CRPG and the Vite dev server share the same origin). No special CORS headers or authentication are needed. The server-side endpoint is defined in `../engineering/slash-command.md`.

Error handling:
- Network error (fetch throws): catch, set `doneState` to `'idle'`, show warning toast.
- Non-200 response: treat as failure, set `doneState` to `'idle'`, show warning toast.
- In both failure cases, the clipboard copy has already completed (it runs in parallel), so the prompt is available for manual paste (`AC-crp-done-fallback-clipboard`).

---

## Security Considerations

### Privacy (`NFR-crp-client-only`)

- In standalone mode, no file content leaves the browser. There are no `fetch` calls, no analytics, no telemetry.
- In slash command mode, the only network call is `POST /api/prompt-output` to the same-origin Vite dev server on localhost. The prompt text is written to a local file (`~/.shepherd/prompt-output.md`) and never transmitted over the network. This is consistent with the spirit of `NFR-crp-client-only` -- all data stays on the developer's machine.
- Content Security Policy headers should be configured to block all outbound network requests except those needed to load the app's own assets and the same-origin API endpoints (`/api/file`, `/api/prompt-output`).
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
          FileTabBar.tsx        NEW — Tab bar for multi-file navigation
          FileDropZone.tsx      (updated: full + modal variants)
          FileHeader.tsx
          CodeViewer.tsx
          CommentBubble.tsx
          InlineCommentEditor.tsx
          PreambleInput.tsx
          PromptPreview.tsx
          ConfirmationDialog.tsx
          ToastNotification.tsx
        lib/
          highlighter.ts        Shiki highlighter initialization and caching
          languageDetect.ts     File extension to language mapping
          binaryDetect.ts       Null-byte binary detection
          promptBuilder.ts      Pure buildPrompt() function (multi-file)
          clipboard.ts          Clipboard write with fallback
        types/
          index.ts              Shared TypeScript type definitions
        styles/
          app.css               Tailwind directives and custom theme tokens
        __tests__/
          unit/
            promptBuilder.test.ts     (includes multi-file prompt tests)
            binaryDetect.test.ts
            languageDetect.test.ts
            appStore.test.ts          (includes Done action, slash command mode, and multi-file store tests)
          component/
            FileTabBar.test.tsx       NEW — Tab bar rendering, interaction, badges
            FileDropZone.test.tsx     (includes modal variant tests)
            CodeViewer.test.tsx
            CommentBubble.test.tsx
            InlineCommentEditor.test.tsx
            Toolbar.test.tsx          (includes Done button rendering/state tests)
            PromptPreview.test.tsx
          e2e/
            load-file.spec.ts
            add-comment.spec.ts
            auto-prompt.spec.ts
            keyboard-navigation.spec.ts
            done-action.spec.ts       Done button E2E flow in slash command mode
            multi-file.spec.ts        NEW — Multi-file load, switch, comment, prompt, remove flows
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
| `appStore.ts` | `addFile` creates file with unique ID and preserves existing files; `addFile` sets new file as active; `removeFile` removes file and its comments; `removeFile` switches active file when removed file was active; `removeFile` returns to empty state when last file removed; `setActiveFile` preserves comments on previous file; `setActiveFile` recomputes `commentOrder` for new active file; `setActiveFile` saves and restores scroll positions; `addComment` auto-sets `fileId` to active file; `addComment` increments count and regenerates prompt automatically; `updateComment` regenerates prompt automatically; `deleteComment` decrements count and regenerates prompt automatically (clears prompt when last comment on any file removed); `navigateComment` wraps correctly within active file; `setPreamble` triggers prompt regeneration; `clearSession` resets everything including all files, all comments, and `generatedPrompt` to null; `setSlashCommandMode` sets the flag; `sendPromptToAgent` posts to `/api/prompt-output` and copies to clipboard; `doneState` transitions correctly through `idle` -> `sending` -> `sent`; `doneState` resets to `idle` on comment/preamble changes; `clearSession` resets `isSlashCommandMode` to `false`. Validates store-level behavior for most FR and AC slugs including `AC-crp-multi-file-load-adds`, `AC-crp-multi-file-nav-preserves-state`, `AC-crp-multi-file-clear-all`, `AC-crp-multi-file-empty-after-remove-last`. |

### Component Tests (React Testing Library)

Components tested with mocked store state:

| Component | Key Test Cases |
|---|---|
| `FileTabBar` | Renders tabs for all files in `fileOrder`; shows comment count badges for files with comments; active tab has correct styling; click tab calls `setActiveFile`; click X calls `removeFile`; "+" button calls `openAddFileModal`; tab for pasted file supports rename on right-click. Validates `FR-crp-multi-file-nav`, `FR-crp-multi-file-remove`. |
| `FileDropZone` | Renders empty state instructions (`AC-crp-empty-state`); file upload triggers `addFile` (`AC-crp-load-upload`); paste mode works (`AC-crp-load-paste`); binary file shows error (`AC-crp-binary-file-rejected`); **modal variant**: renders as overlay; multi-file drop loads all valid files (`AC-crp-multi-file-drop-multiple`); binary files in multi-drop are skipped with toast. |
| `CodeViewer` | Renders line numbers; click on gutter opens editor (`AC-crp-add-comment-single-line`); Shift+click selects range (`AC-crp-add-comment-line-range`); keyboard navigation works (`AC-crp-keyboard-add-comment`). |
| `Toolbar` | Copy button disabled until prompt exists (auto-generated when comments present); comment count displays correctly as global total across all files (`AC-crp-multi-file-comment-count`); no Generate button (prompt auto-generates); Done button hidden when `isSlashCommandMode` is false (`AC-crp-done-standalone-hidden`); Done button visible when `isSlashCommandMode` is true; Done button disabled when no comments (`AC-crp-done-disabled-no-comments`); Done button shows "Sending..." during send; Done button shows "Sent" after successful send (`AC-crp-done-confirmation`); Done button triggers `sendPromptToAgent`; Copy becomes secondary when Done is visible; Cmd+Shift+D keyboard shortcut fires `sendPromptToAgent` (`FR-crp-done-action`). |
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
3. Build `FileTabBar` component with tab rendering, close buttons, comment count badges, "+" button, and rename affordance for pasted files.
4. Update `FileDropZone` to support `modal` variant (portal overlay). Update multi-file drop logic to iterate all files and call `addFile()` for each (with per-file binary detection and summary toast).
5. Add global drop target on `App` — register drag-and-drop listener on the entire window when files are loaded so dropping files anywhere adds them to the session.
6. Update `promptBuilder.ts` for multi-file: accept `files`, `fileOrder`, `comments`, and `preamble`. Group comments by `fileId`, filter to files with comments, order by `fileOrder`, produce combined output with per-file sections.
7. Update `CodeViewer` to restore scroll position on file switch (read from `scrollPositions` when `activeFileId` changes).
8. Update `Toolbar` to read global comment count across all files (`Object.values(state.comments).length`).
9. Update `ConfirmationDialog` to handle both "clear session" (remove all files) and "remove file" (remove individual file with comments) use cases.
10. Write unit tests for multi-file `promptBuilder` and store. Write component tests for `FileTabBar`. Write E2E tests for multi-file flows.

**Delivers**: Complete multi-file workflow: load multiple files via any method, navigate between files via tab bar, add/edit/delete comments per file, generate combined prompt, remove individual files or clear entire session.

**Slug coverage**: `FR-crp-multi-file-load`, `FR-crp-multi-file-nav`, `FR-crp-multi-file-remove`, `FR-crp-multi-file-prompt`, `FR-crp-multi-file-prompt-format`, `AC-crp-multi-file-load-adds`, `AC-crp-multi-file-drop-multiple`, `AC-crp-multi-file-nav-preserves-state`, `AC-crp-multi-file-remove-with-comments`, `AC-crp-multi-file-remove-no-comments`, `AC-crp-multi-file-prompt-structure`, `AC-crp-multi-file-prompt-omits-uncommented`, `AC-crp-multi-file-comment-count`, `AC-crp-multi-file-clear-all`, `AC-crp-multi-file-empty-after-remove-last`.

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
| `FR-crp-prompt-preamble` | `PreambleInput` component; store `preamble` state and `setPreamble` action |
| `FR-crp-prompt-generate` | `promptBuilder.ts`; Zustand store auto-generation on comment/preamble mutation |
| `FR-crp-prompt-preview` | `PromptPreview` component (reads `generatedPrompt` from store) |
| `FR-crp-prompt-copy` | `clipboard.ts`; store `copyPrompt` action; `Toolbar` Copy button; `ToastNotification` |
| `FR-crp-prompt-format` | `promptBuilder.ts` (format assembly logic) |
| `FR-crp-clear-session` | `ConfirmationDialog` component (clear session variant); store `clearSession` action (resets all files, comments, preamble); `Toolbar` Clear button |
| `FR-crp-filename-display` | `FileHeader` component (single-file); `FileTabBar` component (multi-file); store `files[activeFileId].name` |
| `FR-crp-line-range-comment` | `CodeViewer` range selection (mouse drag, Shift+click); `InlineCommentEditor` with range anchor |
| `FR-crp-comment-navigation` | `Toolbar` prev/next buttons; store `navigateComment` action; `CodeViewer` `scrollToIndex` |
| `FR-crp-done-action` | `Toolbar` Done button (conditional render, state display, keyboard shortcut); store `doneState` field, `sendPromptToAgent` action, `isSlashCommandMode` field; `useFileFromUrl` hook (sets slash command mode) |
| `FR-crp-prompt-handoff` | Store `sendPromptToAgent` action (POST to `/api/prompt-output`); Vite plugin endpoint (see `../engineering/slash-command.md`) |
| `FR-crp-multi-file-load` | `FileDropZone` (full + modal variants); global drop target on `App`; store `addFile` action |
| `FR-crp-multi-file-nav` | `FileTabBar` component; store `setActiveFile` action; `scrollPositions` state |
| `FR-crp-multi-file-remove` | `FileTabBar` close button; `ConfirmationDialog` (file removal variant); store `removeFile` action |
| `FR-crp-multi-file-prompt` | `promptBuilder.ts` (multi-file mode); store auto-generation on any comment change across any file |
| `FR-crp-multi-file-prompt-format` | `promptBuilder.ts` (multi-file format assembly with per-file sections) |

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
| `AC-crp-multi-file-nav-preserves-state` | Store `setActiveFile` (preserves comments and scroll position per file); `FileTabBar` tab switching |
| `AC-crp-multi-file-remove-with-comments` | `ConfirmationDialog` (file removal variant with comment count); store `removeFile` |
| `AC-crp-multi-file-remove-no-comments` | Store `removeFile` (skips confirmation when 0 comments on file) |
| `AC-crp-multi-file-prompt-structure` | `promptBuilder.ts` multi-file output (per-file sections with headings); unit tests |
| `AC-crp-multi-file-prompt-omits-uncommented` | `promptBuilder.ts` filters files without comments from prompt output |
| `AC-crp-multi-file-comment-count` | `Toolbar` reads global comment count from store (`Object.values(state.comments).length`) |
| `AC-crp-multi-file-clear-all` | Store `clearSession` resets all files, all comments, preamble, and all derived state |
| `AC-crp-multi-file-empty-after-remove-last` | Store `removeFile` returns to empty state (`activeFileId: null`, `fileOrder: []`, `files: {}`) when last file removed |
