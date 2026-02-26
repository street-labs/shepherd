# Markdown Rendered View -- Technical Spec

> Based on requirements in `../../product/markdown-render.md`
> Based on design in `../../design/web/markdown-render.md`

## Technical Approach

The markdown rendered view is an alternative display mode for markdown files in the existing CRPG code viewer panel. When active, it replaces the `CodeViewer` (or `DiffViewer`) component with a `RenderedViewer` (or `RenderedDiffViewer`) that displays the markdown source as formatted HTML with element-level comment anchoring.

The implementation adds four concerns to the existing architecture:

1. **Markdown parsing and rendering**: A unified/remark pipeline parses markdown into an mdast (Markdown Abstract Syntax Tree), transforms it to hast (HTML AST), sanitizes it, and serializes it to HTML. This replaces line-by-line syntax highlighting with full document rendering.

2. **Element identification and comment anchoring**: Each block-level AST node is assigned a stable positional identifier (e.g., `heading-0`, `paragraph-3`, `list-1-item-2`). Comments anchor to these element IDs instead of line numbers. A separate comment store holds rendered-mode comments, parallel to the existing file-mode and diff-mode comment stores.

3. **AST-level diffing**: For the rendered diff view, both the HEAD and working copy versions are parsed into ASTs, the ASTs are diffed at the block level using a Longest Common Subsequence (LCS) algorithm, and modified blocks receive word-level inline diff annotations.

4. **Rendered-mode prompt generation**: A new `buildRenderedPrompt` function maps element-anchored comments back to the raw markdown source lines (via AST-to-source-line mapping) and produces prompts with element-type annotations instead of line numbers.

### Key Technical Decisions

| Decision | Choice | Rationale |
|---|---|---|
| Markdown parser | unified + remark-parse + remark-gfm | The unified ecosystem provides a composable pipeline: parse to AST (remark-parse), apply GFM extensions (remark-gfm), transform AST to HTML AST (remark-rehype), sanitize (rehype-sanitize), and serialize to HTML (rehype-stringify). This is the most flexible approach because we need AST access for element ID assignment, AST-to-source-line mapping, and AST diffing. markdown-it is faster for simple render-to-HTML but lacks a clean AST manipulation API, making element identification and diff computation significantly harder. The unified ecosystem is the standard for AST-based markdown processing (~10M weekly npm downloads for remark-parse). |
| HTML sanitization | rehype-sanitize | Integrates natively into the unified pipeline as a rehype plugin, so sanitization happens as part of the AST-to-HTML transformation -- no separate DOM-level sanitization step. Uses a declarative schema (based on GitHub's sanitization rules) rather than DOM manipulation, making it faster and more predictable. DOMPurify would work but requires serializing to HTML first and then re-parsing the DOM, which is an unnecessary round-trip when we already have the hast (HTML AST). |
| AST diffing | Custom LCS-based block diff | No existing npm package provides markdown-AST-level diffing with the granularity we need (block-level matching + word-level inline diffs for modified blocks). Tree edit distance algorithms (Zhang-Shasha) are theoretically optimal but are O(n^2) and overkill for our use case -- markdown documents are relatively flat (most content is at depth 1-2). A simpler LCS approach on flattened block sequences is O(n*m) in the worst case but fast in practice and produces human-readable diffs. The implementation is straightforward (~200 lines) and avoids a heavy dependency. |
| Word-level diffing | `diff` (jsdiff) -- `diffWords` | Already a project dependency (used by the diff view feature). `diffWords()` produces exactly the word-level change annotations needed for modified blocks. No additional dependency. |
| Rendered code block highlighting | Shiki (existing) | Fenced code blocks in rendered markdown use the same Shiki highlighter already initialized for the raw view (`FR-crp-syntax-highlight`). The rendered pipeline extracts fenced code blocks from the AST, highlights them via the existing `highlighter.ts` module, and injects the highlighted HTML back into the rendered output. No new highlighting dependency. |
| Rendered view scrolling | Native scroll + `content-visibility: auto` | The rendered view does not use TanStack Virtual. Rendered markdown elements are heterogeneous (headings, paragraphs, tables, code blocks of varying heights) and cannot be easily virtualized. Instead, the full rendered document is in the DOM, with `content-visibility: auto` on top-level block elements for files > 5,000 lines to enable browser-native rendering optimization (`NFR-mdr-render-scroll-perf`). |
| Rendered-mode comment store | Separate store fields in Zustand | Consistent with the diff view's approach (separate `diffComments` store). Rendered-mode comments use element IDs instead of line numbers. A third set of store fields (`renderedComments`, `renderedCommentOrder`, etc.) is added alongside the existing file-mode and diff-mode stores. |

---

## Data Model

### New Types

The following types are added to `src/types/index.ts`. They extend the existing type definitions without modifying them.

```typescript
// Implements: FR-mdr-element-id, FR-mdr-rendered-comment-create

/** Identifies a block-level element in the rendered markdown AST. */
export interface ElementId {
  /** The full element identifier string (e.g., "heading-0", "paragraph-3", "list-1-item-2"). */
  id: string;
  /** The element type for display labels. */
  type: 'heading' | 'paragraph' | 'list-item' | 'code-block' | 'table' | 'blockquote' | 'thematic-break' | 'image';
  /** Content preview for display labels (first 60 characters of text content). */
  contentPreview: string;
}

/** Mapping from an element ID to its source line range in the raw markdown. */
export interface ElementSourceMapping {
  /** The element identifier. */
  elementId: string;
  /** First line of the source range (1-indexed). */
  startLine: number;
  /** Last line of the source range (1-indexed). */
  endLine: number;
}

/** A comment anchored to a rendered element. */
export interface RenderedComment {
  /** Unique identifier. Generated via crypto.randomUUID(). */
  id: string;
  /** The element this comment is anchored to. */
  elementId: string;
  /** The element type for display labels. */
  elementType: string;
  /** Content preview of the element for display labels (max 60 chars). */
  elementPreview: string;
  /** The user's comment text. */
  text: string;
  /** ISO-8601 timestamp of creation. */
  createdAt: string;
}

/** A comment anchored to a rendered diff element. */
export interface RenderedDiffComment {
  /** Unique identifier. Generated via crypto.randomUUID(). */
  id: string;
  /** The element this comment is anchored to (with change-type prefix). */
  elementId: string;
  /** The change type of the element. */
  changeType: 'added' | 'removed' | 'modified' | 'unchanged';
  /** The element type for display labels. */
  elementType: string;
  /** Content preview of the element for display labels (max 60 chars). */
  elementPreview: string;
  /** The user's comment text. */
  text: string;
  /** ISO-8601 timestamp of creation. */
  createdAt: string;
}

/** A block-level element from the markdown AST with its metadata. */
export interface AstBlockElement {
  /** The stable element identifier. */
  elementId: string;
  /** The element type. */
  type: ElementId['type'];
  /** Heading depth (1-6) if type is 'heading', undefined otherwise. */
  headingDepth?: number;
  /** The raw text content of this element (for previews and diff). */
  textContent: string;
  /** Source line range in the raw markdown (1-indexed, inclusive). */
  startLine: number;
  /** Source line range end. */
  endLine: number;
  /** The raw markdown source for this element. */
  rawSource: string;
  /** Child elements (e.g., list items within a list). */
  children?: AstBlockElement[];
}

/** Result of diffing two markdown ASTs at the block level. */
export interface AstDiffResult {
  /** The list of diff entries in document order. */
  entries: AstDiffEntry[];
  /** Whether the fallback threshold was exceeded (> 80% blocks changed). */
  exceedsFallbackThreshold: boolean;
}

/** A single entry in the AST diff result. */
export type AstDiffEntry =
  | { type: 'added'; element: AstBlockElement }
  | { type: 'removed'; element: AstBlockElement }
  | { type: 'modified'; oldElement: AstBlockElement; newElement: AstBlockElement; wordDiff: WordDiffSegment[] }
  | { type: 'unchanged'; element: AstBlockElement };

/** A segment of a word-level diff within a modified block. */
export interface WordDiffSegment {
  /** The type of this segment. */
  type: 'added' | 'removed' | 'unchanged';
  /** The text content of this segment. */
  text: string;
}

/** The render mode state. */
export type RenderMode = 'raw' | 'rendered';
```

### Modified Types

The `AppState` interface is extended with new fields for render mode state. Existing fields are not changed.

```typescript
/** Additions to AppState (merged into the existing interface). */
export interface RenderedState {
  /** Current render mode: 'raw' for syntax-highlighted source, 'rendered' for formatted HTML. */
  renderMode: RenderMode;
  /** Whether the loaded file is a markdown file (controls toggle visibility). */
  isMarkdownFile: boolean;
  /** Parsed AST block elements for the current file (null if not a markdown file or not in rendered mode). */
  astElements: AstBlockElement[] | null;
  /** Element-to-source-line mapping for prompt generation. */
  elementSourceMap: ElementSourceMapping[] | null;
  /** All rendered-mode comments, keyed by comment ID. Separate from file-mode and diff-mode comments. */
  renderedComments: Record<string, RenderedComment>;
  /** Ordered array of rendered comment IDs sorted by element position then createdAt. */
  renderedCommentOrder: string[];
  /** The ID of the currently focused rendered comment (via navigation), or null. */
  focusedRenderedCommentId: string | null;
  /** Editor state for rendered-mode comment editing. */
  renderedEditorState: RenderedEditorState | null;
  /** AST diff result for rendered diff view (null if not computed). */
  astDiffResult: AstDiffResult | null;
  /** Whether the AST diff is currently being computed. */
  isAstDiffComputing: boolean;
  /** All rendered-diff-mode comments, keyed by comment ID. */
  renderedDiffComments: Record<string, RenderedDiffComment>;
  /** Ordered array of rendered diff comment IDs. */
  renderedDiffCommentOrder: string[];
  /** The ID of the currently focused rendered diff comment, or null. */
  focusedRenderedDiffCommentId: string | null;
  /** Editor state for rendered-diff-mode comment editing. */
  renderedDiffEditorState: RenderedDiffEditorState | null;
}

/** State of the inline comment editor in rendered mode. */
export type RenderedEditorState =
  | { mode: 'create'; elementId: string }
  | { mode: 'edit'; commentId: string };

/** State of the inline comment editor in rendered diff mode. */
export type RenderedDiffEditorState =
  | { mode: 'create'; elementId: string; changeType: AstDiffEntry['type'] }
  | { mode: 'edit'; commentId: string };
```

### Derived Data

Computed from the store via selectors:

- **Rendered HTML string**: Computed by the rendering pipeline from `file.content` when `renderMode === 'rendered'`. Cached and recomputed only when `file.content` changes.
- **Active comment count**: Extended to include rendered and rendered-diff counts based on the active view mode combination.
- **Elements with comments**: A `Map<string, RenderedComment[]>` mapping each element ID to the comments anchored to it. Computed similarly to file-mode `commentsByLine`.
- **Is rendered view available**: `isMarkdownFile === true`. Determines whether the render toggle is visible.

---

## Component Architecture

The component tree is extended with new components for the rendered view. Existing components are unchanged -- the rendered components are parallel alternatives that render based on the combined `viewMode` and `renderMode` state.

```
App
 +-- Toolbar                          MODIFIED -- adds RenderToggle
 |    +-- ViewModeToggle              (unchanged)
 |    +-- RenderToggle                NEW -- segmented Raw/Rendered toggle
 |    +-- RefreshButton               (unchanged)
 +-- MainContent
      +-- [if no file] FileDropZone   (unchanged)
      +-- [if file loaded]
           +-- CodeViewerPanel
           |    +-- FileHeader        (unchanged)
           |    +-- [if raw + file]
           |    |    +-- CodeViewer   (unchanged)
           |    +-- [if raw + diff]
           |    |    +-- DiffViewer   (unchanged)
           |    +-- [if rendered + file]
           |    |    +-- RenderedViewer              NEW
           |    |         +-- RenderedBlockElement    NEW (repeated per block)
           |    |              +-- ElementCommentAnchor   NEW
           |    |         +-- CommentBubble           (reused, with element-aware labels)
           |    |         +-- InlineCommentEditor     (reused)
           |    +-- [if rendered + diff, loading]
           |    |    +-- RenderedDiffLoadingState     NEW
           |    +-- [if rendered + diff, populated]
           |         +-- RenderedDiffViewer           NEW
           |              +-- RenderedDiffBlock       NEW (repeated per diff entry)
           |              |    +-- ElementCommentAnchor   (reused)
           |              +-- RenderedDiffFallbackBanner  NEW
           |              +-- CommentBubble           (reused)
           |              +-- InlineCommentEditor     (reused)
           +-- SidebarPanel
                +-- PreambleInput     (unchanged)
                +-- PromptPreview     (unchanged)
 +-- ConfirmationDialog               REUSED -- same destructive variant, new dialog content for render mode switch
 +-- ToastNotification                (unchanged)
```

### Component Responsibilities

#### `RenderToggle` (new)

> Implements: `FR-mdr-render-toggle`, `FR-mdr-detect-markdown`, `AC-mdr-toggle-appears`, `AC-mdr-toggle-hidden-non-md`

A segmented control with "Raw" and "Rendered" segments. Placed in the `Toolbar` after the `ViewModeToggle` (or after the title if the File/Diff toggle is not visible), separated by a 12px gap.

**Props**:
- `activeMode: 'raw' | 'rendered'` -- current render mode from store.
- `isVisible: boolean` -- true only when `isMarkdownFile === true`.
- `onModeChange: (mode: 'raw' | 'rendered') => void` -- callback. The parent handles confirmation dialogs before dispatching the store action.

**Behavior**:
- Renders two segments in a horizontal group with `role="tablist"`.
- Each segment is `role="tab"` with `aria-selected`.
- Arrow keys move focus between segments; Enter/Space activates.
- When `isVisible` is false, the component returns null (not rendered in DOM).
- The component is purely presentational. Mode-switch side effects (confirmation dialogs) are handled by the parent.

**Dimensions**: "Raw" segment 48px wide, "Rendered" segment 80px wide, both 32px tall. Same styling pattern as ViewModeToggle from `../../design/web/diff-view.md` and `../engineering/diff-view.md`.

#### `RenderedViewer` (new)

> Implements: `FR-mdr-render-commonmark`, `FR-mdr-render-styling`, `FR-mdr-element-id`, `FR-mdr-rendered-comment-create`, `NFR-mdr-render-perf`, `NFR-mdr-render-scroll-perf`, `NFR-mdr-accessibility`

The rendered markdown display component. Replaces CodeViewer when `renderMode === 'rendered'` and `viewMode === 'file'`.

**Props**:
- `markdownSource: string` -- the raw markdown source text.
- `comments: RenderedComment[]` -- rendered-mode comments.
- `focusedCommentId: string | null` -- currently focused comment.
- `onElementClick: (elementId: string) => void` -- callback when user clicks comment affordance.
- `onCommentEdit: (commentId: string) => void`
- `onCommentDelete: (commentId: string) => void`

**Internal processing**:
1. Parse markdown source into mdast using `remark-parse` + `remark-gfm`.
2. Walk the AST and assign stable element identifiers to each block-level node (`FR-mdr-element-id`).
3. Build the element-to-source-line mapping (`ElementSourceMapping[]`).
4. Transform mdast to hast via `remark-rehype`.
5. Sanitize hast via `rehype-sanitize` (`NFR-mdr-xss-safety`).
6. Serialize hast to HTML via `rehype-stringify`.
7. Post-process: apply Shiki syntax highlighting to fenced code blocks.
8. Render into the DOM with `data-element-id` attributes on each block element.
9. Attach hover and click handlers for comment affordance on each block element.

**Layout**: Comment affordance column (32px, sticky left) + rendered content (max-width 80ch, centered). No virtualization. For files > 5,000 lines, `content-visibility: auto` is applied to top-level block elements.

**Keyboard accessibility** (`NFR-mdr-accessibility`, `AC-mdr-keyboard-comment`):
- The rendered content area is `role="document"`, `aria-label="Rendered markdown content"`, `tabindex="0"`.
- Each commentable block element has `tabindex="0"`, `role="article"`, and descriptive `aria-label`.
- Tab cycles through commentable elements in document order.
- Enter or `c` on a focused element opens the InlineCommentEditor.

#### `RenderedDiffViewer` (new)

> Implements: `FR-mdr-rendered-diff-display`, `FR-mdr-rendered-diff-comment`, `NFR-mdr-rendered-diff-perf`, `NFR-mdr-accessibility`

The rendered markdown diff display component. Replaces CodeViewer/DiffViewer when `renderMode === 'rendered'` and `viewMode === 'diff'`.

**Props**:
- `oldMarkdownSource: string` -- HEAD version markdown source.
- `newMarkdownSource: string` -- working copy markdown source.
- `diffResult: AstDiffResult` -- computed AST diff.
- `comments: RenderedDiffComment[]` -- rendered-diff-mode comments.
- `focusedCommentId: string | null`
- `onElementClick: (elementId: string) => void`
- `onCommentEdit: (commentId: string) => void`
- `onCommentDelete: (commentId: string) => void`
- `onFallbackToRawDiff: () => void`

**Internal processing**:
1. Receive pre-computed `AstDiffResult` (computed asynchronously by the store).
2. Render each diff entry: added blocks get green background + "ADDED" badge, removed blocks get red background + strikethrough + "REMOVED" badge, modified blocks get word-level inline diff annotations, unchanged blocks render normally.
3. Assign element IDs with change-type qualifiers (e.g., `added:heading-3`, `removed:paragraph-5`).
4. Sanitize and render all HTML.
5. If `diffResult.exceedsFallbackThreshold`, show the RenderedDiffFallbackBanner.

**Loading state**: While `isAstDiffComputing === true`, display `RenderedDiffLoadingState` (centered spinner with "Computing rendered diff..." text).

**Timeout**: If computation exceeds 5 seconds, auto-switch to Raw + Diff with info toast.

#### `RenderedBlockElement` (new)

A wrapper component for each block-level element in the rendered view. Handles hover state, focus state, comment affordance positioning, and comment bubble rendering.

**Props**:
- `elementId: string`
- `elementType: string`
- `htmlContent: string` -- sanitized HTML for this block.
- `hasComments: boolean`
- `commentCount: number`
- `isHovered: boolean`
- `isFocused: boolean`
- `onCommentClick: () => void`
- `children: ReactNode` -- comment bubbles and editor, rendered below the element.

**Behavior**:
- Sets `data-element-id` attribute on the wrapper `<div>`.
- Manages hover highlight (background `#F8FAFC`, 150ms transition).
- Renders `ElementCommentAnchor` in the C column at the element's vertical center.

#### `ElementCommentAnchor` (new)

> Implements: `FR-mdr-rendered-comment-create`, `FR-mdr-element-id`

The hover affordance for commenting on a rendered element. Appears in the comment affordance column (32px wide).

**Props**:
- `elementId: string`
- `elementType: string` -- The element type label (e.g., "Heading", "Paragraph") for the aria-label.
- `contentPreview: string` -- A truncated content preview (max 60 chars) for the aria-label.
- `hasComments: boolean`
- `isHovered: boolean`
- `isFocused: boolean`
- `onClick: () => void`

**Behavior**:
- Hidden by default. Shows comment icon (speech bubble, 16px, `#94A3B8`) when parent element is hovered or focused.
- Elements with comments show a blue dot (8px, `#3B82F6`).
- On hover of the icon itself, color changes to `#2563EB`.
- Click fires `onClick`, opening the InlineCommentEditor.
- `role="button"`, `aria-label="Add comment on ${elementType}: ${contentPreview}"`, `tabindex="0"`.

#### `RenderedDiffFallbackBanner` (new)

> Implements: `AC-mdr-diff-fallback`

A dismissible warning banner shown when the AST diff result exceeds the fallback threshold (> 80% blocks changed).

**Props**:
- `onSwitchToRawDiff: () => void`
- `onDismiss: () => void`

**Behavior**:
- Amber background (`#FEF3C7`), info icon, dismissible via close button.
- "Switch to Raw Diff" link calls `onSwitchToRawDiff`.
- `role="alert"`, `aria-label="Rendered diff fallback notice"`.

#### `RenderedDiffLoadingState` (new)

Displayed while the AST diff is being computed. Centered spinner (24px, `#2563EB`) with "Computing rendered diff..." text.

**Behavior**: `role="status"`, `aria-label="Computing rendered diff"`.

#### `Toolbar` (modified)

The existing `Toolbar` component is extended to render the `RenderToggle` when a markdown file is loaded.

**Changes**:
- After `ViewModeToggle`, render `RenderToggle` when `isMarkdownFile === true`.
- Comment count reads from the active comment store based on the combined `viewMode + renderMode` state.
- Comment navigation dispatches the appropriate navigate action based on the active mode.
- Prompt auto-generates via the appropriate builder based on the active mode.

#### `App` (modified)

> Implements: `FR-mdr-switch-comments`, `AC-mdr-switch-clears-comments`, `AC-mdr-switch-no-comments`

Extended to:
1. Conditionally render `RenderedViewer` or `RenderedDiffViewer` based on the combined `renderMode + viewMode` state.
2. Handle render-mode-switch confirmation dialogs (same pattern as view-mode-switch confirmations).
3. Set `isMarkdownFile` when a file is loaded (based on extension detection).
4. Trigger AST diff computation when entering rendered + diff mode.

#### Reused Components

**InlineCommentEditor**: Reused as-is. The `lineLabel` prop receives element type labels ("Heading", "Paragraph", "Modified Paragraph") instead of line numbers.

**CommentBubble**: Reused with extended label formatting. In rendered mode, shows "Heading: ## API Reference" (element type + content preview). In rendered diff mode, includes change type: "Added Heading: ## Rate Limiting".

**ConfirmationDialog**: Reused for render mode switch confirmation (same destructive variant). Dialog body explains that comments will be lost because rendered and raw views use different anchoring systems.

---

## State Management

### Zustand Store Additions

The store at `src/store/appStore.ts` is extended with new state and actions. Existing state and actions are unchanged.

#### New State Fields

Added to `initialState`:

```typescript
const initialRenderedState = {
  renderMode: 'raw' as RenderMode,
  isMarkdownFile: false,
  astElements: null as AstBlockElement[] | null,
  elementSourceMap: null as ElementSourceMapping[] | null,
  renderedComments: {} as Record<string, RenderedComment>,
  renderedCommentOrder: [] as string[],
  focusedRenderedCommentId: null as string | null,
  renderedEditorState: null as RenderedEditorState | null,
  astDiffResult: null as AstDiffResult | null,
  isAstDiffComputing: false,
  renderedDiffComments: {} as Record<string, RenderedDiffComment>,
  renderedDiffCommentOrder: [] as string[],
  focusedRenderedDiffCommentId: null as string | null,
  renderedDiffEditorState: null as RenderedDiffEditorState | null,
};
```

When `loadFile` is called, these fields are reset. When `clearSession` is called, all state (including rendered state) is reset.

#### New Actions

```typescript
interface RenderedActions {
  // Render mode
  setRenderMode: (mode: RenderMode) => void;

  // AST parsing
  parseMarkdownAst: () => void;

  // AST diff
  computeAstDiff: () => Promise<void>;

  // Rendered comments
  addRenderedComment: (elementId: string, elementType: string, elementPreview: string, text: string) => void;
  updateRenderedComment: (commentId: string, text: string) => void;
  deleteRenderedComment: (commentId: string) => void;
  clearRenderedComments: () => void;

  // Rendered comment navigation
  navigateRenderedComment: (direction: 'next' | 'prev') => void;
  setFocusedRenderedComment: (commentId: string | null) => void;

  // Rendered editor
  openRenderedEditor: (state: RenderedEditorState) => void;
  closeRenderedEditor: () => void;

  // Rendered diff comments
  addRenderedDiffComment: (elementId: string, changeType: string, elementType: string, elementPreview: string, text: string) => void;
  updateRenderedDiffComment: (commentId: string, text: string) => void;
  deleteRenderedDiffComment: (commentId: string) => void;
  clearRenderedDiffComments: () => void;

  // Rendered diff comment navigation
  navigateRenderedDiffComment: (direction: 'next' | 'prev') => void;
  setFocusedRenderedDiffComment: (commentId: string | null) => void;

  // Rendered diff editor
  openRenderedDiffEditor: (state: RenderedDiffEditorState) => void;
  closeRenderedDiffEditor: () => void;

  // Rendered prompt generation
  generateRenderedPrompt: () => void;
  generateRenderedDiffPrompt: () => void;
}
```

#### Action Semantics

- **`setRenderMode(mode)`**: Sets `renderMode`. Does NOT clear comments -- the caller is responsible for calling the appropriate clear function after showing a confirmation dialog if needed. When switching to `'rendered'`, triggers `parseMarkdownAst()` if `astElements` is null. When switching to `'rendered'` while `viewMode === 'diff'`, also triggers `computeAstDiff()`.

- **`parseMarkdownAst()`**: Parses `file.content` via the remark pipeline. Stores the flattened `AstBlockElement[]` in `astElements` and the `ElementSourceMapping[]` in `elementSourceMap`. This is a synchronous operation for files under 5,000 lines. For larger files, it runs in a Web Worker (see Performance Strategy).

- **`computeAstDiff()`**: Sets `isAstDiffComputing: true`. Parses both `baselineContent` and `file.content` into ASTs, diffs them via the LCS algorithm, computes word-level diffs for modified blocks, and stores the result in `astDiffResult`. Sets `isAstDiffComputing: false` on completion. If computation exceeds 5 seconds, cancels and auto-switches to Raw + Diff. This is always async (runs in a microtask or Web Worker).

- **`addRenderedComment(...)`**: Creates a `RenderedComment` with `crypto.randomUUID()`, inserts into `renderedComments`, recomputes `renderedCommentOrder` (sorted by element position in `astElements` then `createdAt`). Automatically regenerates the prompt via `buildRenderedPrompt()`.

- **`clearRenderedComments()`**: Resets `renderedComments` to `{}`, `renderedCommentOrder` to `[]`, `focusedRenderedCommentId` to `null`.

- **`generateRenderedPrompt()`**: Called automatically by rendered comment and preamble mutations. Calls the pure `buildRenderedPrompt()` function and stores the result in `generatedPrompt`.

- **`generateRenderedDiffPrompt()`**: Called automatically by rendered diff comment and preamble mutations. Calls the pure `buildRenderedDiffPrompt()` function and stores the result in `generatedPrompt`.

#### Integration with Existing Actions

- **`loadFile`**: Modified to also reset all rendered state. Sets `isMarkdownFile` based on the file extension (reuses the markdown extension list from `languageDetect.ts`). Resets `renderMode` to `'raw'`.

- **`clearSession`**: Extended to include rendered state in the reset.

- **`setViewMode`**: When switching between `'file'` and `'diff'` while in rendered mode, comments must be cleared (with confirmation) because element identifiers differ between file and diff modes.

### Data Flow for Rendered File View

```
User clicks "Rendered" toggle
  --> App shows confirmation if comments exist
    --> On confirm: clear current comments, store.setRenderMode('rendered')
      --> setRenderMode triggers parseMarkdownAst()
        --> Parse markdown to AST, assign element IDs, build source map
          --> Store astElements and elementSourceMap
            --> RenderedViewer renders using AST + sanitized HTML
```

### Data Flow for Rendered Diff View

```
User is in rendered mode and clicks "Diff" (or is in diff mode and clicks "Rendered")
  --> App shows confirmation if comments exist
    --> On confirm: clear comments, enter rendered + diff state
      --> store.computeAstDiff()
        --> Parse both HEAD and working copy into ASTs
          --> LCS-diff the AST block sequences
            --> Compute word-level diffs for modified blocks
              --> Store astDiffResult
                --> RenderedDiffViewer renders with diff annotations
```

---

## Library Selection

### Markdown Parsing: unified/remark Ecosystem

> Implements: `FR-mdr-render-commonmark`, `FR-mdr-render-styling`

**Selected**: `unified` + `remark-parse` + `remark-gfm` + `remark-rehype` + `rehype-sanitize` + `rehype-stringify`

**Dependencies to add** (in `engineering/apps/web/`):

| Package | Purpose | Size (gzipped) |
|---|---|---|
| `unified` | Pipeline runner | ~3 KB |
| `remark-parse` | Markdown to mdast parser (CommonMark) | ~15 KB |
| `remark-gfm` | GFM extension (tables, task lists, strikethrough, autolinks) | ~5 KB |
| `remark-rehype` | mdast to hast transformer | ~3 KB |
| `rehype-sanitize` | hast sanitization | ~2 KB |
| `rehype-stringify` | hast to HTML serializer | ~3 KB |
| **Total** | | **~31 KB** |

**Why not markdown-it**:
- markdown-it renders directly to HTML strings with no intermediate AST manipulation step. To assign element IDs, we would need to parse the output HTML back into a DOM tree, which is an unnecessary round-trip.
- markdown-it's token stream is harder to work with for AST diffing compared to mdast's clean tree structure.
- markdown-it is faster for pure rendering (~2x), but the difference is negligible for files under 10,000 lines, and we need AST access.

**Rendering pipeline**:

```
markdown source
  --> remark-parse (markdown -> mdast)
  --> remark-gfm (apply GFM extensions)
  --> [custom plugin: assign element IDs + build source map]
  --> remark-rehype (mdast -> hast)
  --> rehype-sanitize (strip dangerous HTML)
  --> [custom plugin: apply Shiki highlighting to code blocks]
  --> rehype-stringify (hast -> HTML string)
  --> innerHTML into RenderedViewer container
```

### HTML Sanitization: rehype-sanitize

> Implements: `NFR-mdr-xss-safety`, `AC-mdr-html-sanitized`

**Selected**: `rehype-sanitize` with a custom schema derived from GitHub's sanitization rules.

**Schema configuration**:

```typescript
import { defaultSchema } from 'rehype-sanitize';

const sanitizeSchema = {
  ...defaultSchema,
  tagNames: [
    ...(defaultSchema.tagNames ?? []),
    'details', 'summary', 'sup', 'sub', 'ins', 'del', 'mark', 'abbr',
  ],
  attributes: {
    ...defaultSchema.attributes,
    // Allow data-element-id for comment anchoring
    '*': [...(defaultSchema.attributes?.['*'] ?? []), 'data-element-id', 'tabindex', 'role', 'aria-label'],
    // Allow class on code blocks for syntax highlighting
    code: ['className'],
    pre: ['className'],
  },
};
```

**What is stripped**: `<script>` tags, event handler attributes (`onclick`, `onerror`, etc.), `javascript:` URLs, `data:` URLs (except images), `<iframe>`, `<object>`, `<embed>`, and any other active content vectors. This is enforced at the AST level before any HTML reaches the DOM.

**Why not DOMPurify**: DOMPurify operates on serialized HTML strings by parsing them into a DOM tree, sanitizing, and re-serializing. Since we already have the HTML AST (hast) from the remark-rehype pipeline, sanitizing at the hast level is more efficient and avoids a redundant parse/serialize cycle. rehype-sanitize also integrates as a pipeline plugin, keeping the architecture clean.

### AST Diffing: Custom LCS-Based Block Diff

> Implements: `FR-mdr-rendered-diff-display`, `NFR-mdr-rendered-diff-perf`

**Selected**: Custom implementation in `src/lib/astDiff.ts`.

**Algorithm**:

1. **Flatten both ASTs** to sequences of block-level elements. Each element is represented by an `AstBlockElement` with its `elementId`, `type`, `textContent`, and source line mapping.

2. **Compute a similarity key** for each block element. The key is a hash of `type + textContent`. Two blocks with the same key are considered "the same block" (possibly with minor modifications if the text differs slightly).

3. **Run LCS** on the two flattened sequences using the similarity keys to identify the longest common subsequence of unchanged blocks. Blocks not in the LCS are classified as added (in new only) or removed (in old only).

4. **Detect modifications**: For adjacent removed+added pairs (a removed block immediately followed by an added block of the same type), check if the text content similarity exceeds a threshold (e.g., > 30% of words match). If so, classify as "modified" rather than separate remove+add. This heuristic produces more readable diffs for blocks that were edited rather than replaced.

5. **Compute word-level diffs** for modified blocks using jsdiff's `diffWords()`. Each modified block gets a `WordDiffSegment[]` array.

6. **Check fallback threshold**: If more than 80% of the total blocks (max of old count, new count) are non-unchanged, set `exceedsFallbackThreshold: true`.

**Complexity**: The LCS step is O(n*m) where n and m are the block counts of the old and new documents. For a 5,000-line markdown file, the block count is typically 200-500 (one block per paragraph, heading, code block, etc.), making the LCS computation trivially fast (< 10ms). The word-level diffing step is O(w) per modified block where w is the word count.

**Why not tree edit distance**: Zhang-Shasha or APTED algorithms compute the theoretically optimal tree edit distance, but markdown documents are shallow (depth 1-3). A flat LCS on the block sequence captures the vast majority of real-world changes (paragraph added, paragraph removed, paragraph content modified) without the complexity of a full tree edit algorithm. Tree edit distance also has O(n^2) time complexity, which is unnecessary.

**Why not an existing library**: No npm package provides markdown-specific AST diffing with the exact granularity we need (block-level matching + word-level inline diffs + change-type classification + fallback threshold). General tree diff libraries exist but would require significant adaptation. The custom implementation is straightforward (~200 lines) and purpose-built.

### Word-Level Diffing: jsdiff `diffWords`

> Used within modified blocks in the rendered diff view.

`diffWords(oldText, newText)` from the `diff` package (already a project dependency) produces an array of `{ value: string; added?: boolean; removed?: boolean }` objects that map directly to our `WordDiffSegment` type. No additional dependency.

---

## Comment Anchoring Strategy

> Implements: `FR-mdr-element-id`, `FR-mdr-rendered-comment-create`, `FR-mdr-rendered-comment-prompt`

### Element Identifier Format

Each block-level element in the rendered markdown is assigned a stable identifier based on its position in the AST. The format encodes the element's type and its positional index among all block-level elements:

| Element Type | Identifier Format | Example |
|---|---|---|
| Heading | `heading-{index}` | `heading-0`, `heading-4` |
| Paragraph | `paragraph-{index}` | `paragraph-1`, `paragraph-3` |
| List item | `list-{listIndex}-item-{itemIndex}` | `list-2-item-0`, `list-2-item-3` |
| Fenced code block | `code-block-{index}` | `code-block-5` |
| Table | `table-{index}` | `table-1` |
| Block quote | `blockquote-{index}` | `blockquote-0` |
| Thematic break (horizontal rule) | `thematic-break-{index}` | `thematic-break-2` | Note: Uses the mdast node type name `thematicBreak`. In product/design specs, this is referred to as "horizontal rule". |
| Image (standalone) | `image-{index}` | `image-0` |

The `{index}` is the zero-based position of the element among all elements of the same type in the document. For example, if a document has three headings and two paragraphs, the identifiers would be: `heading-0`, `paragraph-0`, `heading-1`, `paragraph-1`, `heading-2`.

For list items, the identifier encodes both the parent list's index and the item's position within the list: `list-{n}-item-{m}` where `n` is the list's zero-based index among all lists and `m` is the item's zero-based position within that list.

**Determinism**: The same markdown source always produces the same identifiers because they are based on positional index in the AST, which is deterministic for a given input.

**Stability caveat**: Identifiers are positional, so inserting a paragraph before `paragraph-3` would shift it to `paragraph-4`. This is acceptable because identifiers are only used within a single session and are recomputed when the file changes.

### AST-to-Source-Line Mapping

The remark parser attaches position information to each AST node (line and column offsets in the source). During the element identification pass, we extract each block element's source line range:

```typescript
// During AST traversal
const elementSourceMap: ElementSourceMapping[] = [];

function assignElementId(node: MdastNode, elementId: string): void {
  if (node.position) {
    elementSourceMap.push({
      elementId,
      startLine: node.position.start.line,  // 1-indexed
      endLine: node.position.end.line,       // 1-indexed
    });
  }
}
```

This mapping is used by `buildRenderedPrompt()` to convert element-anchored comments back to raw source line references for the generated prompt.

### Element Identifiers in Rendered Diff Mode

In the rendered diff view, element identifiers are prefixed with the change type:

| Change Type | Identifier Format | Example |
|---|---|---|
| Added | `added:{elementId}` | `added:heading-3` |
| Removed | `removed:{elementId}` | `removed:paragraph-5` |
| Modified | `modified:{elementId}` | `modified:list-1-item-2` |
| Unchanged | `unchanged:{elementId}` | `unchanged:paragraph-0` |

Removed elements use the identifier from the old (HEAD) AST. Added, modified, and unchanged elements use the identifier from the new (working copy) AST.

### Separate Comment Store

Rendered-mode comments are stored in `renderedComments` (for rendered + file) and `renderedDiffComments` (for rendered + diff). These are completely separate from:
- `comments` (file-mode, line-number-anchored)
- `diffComments` (diff-mode, DiffLineId-anchored)

This follows the established pattern from the diff view specification: each anchoring model has its own comment store. Switching between modes clears comments (with confirmation) because the anchoring models are incompatible.

---

## Rendered Diff Algorithm

> Implements: `FR-mdr-rendered-diff-display`, `NFR-mdr-rendered-diff-perf`, `AC-mdr-rendered-diff-additions`, `AC-mdr-rendered-diff-removals`, `AC-mdr-rendered-diff-modifications`, `AC-mdr-diff-fallback`

The rendered diff algorithm is implemented as a pure function in `src/lib/astDiff.ts`.

### Pipeline

```
baselineContent + workingCopyContent
  --> Parse both into mdast via remark-parse + remark-gfm
  --> Flatten both ASTs into AstBlockElement[] sequences
  --> LCS-diff the two block sequences
  --> Classify each block: added, removed, modified, or unchanged
  --> For modified blocks, compute word-level diff via diffWords()
  --> Check fallback threshold (> 80% blocks changed)
  --> Return AstDiffResult
```

### Step 1: Flatten AST to Block Sequence

Walk the mdast tree and extract all block-level nodes into a flat sequence. Nested structures (e.g., list items within a list, paragraphs within a blockquote) are flattened with appropriate identifiers:

```typescript
function flattenAst(tree: MdastRoot): AstBlockElement[] {
  const elements: AstBlockElement[] = [];
  const counters: Record<string, number> = {};

  function getNextId(type: string, parentPrefix?: string): string {
    const key = parentPrefix ? `${parentPrefix}-${type}` : type;
    counters[key] = (counters[key] ?? -1) + 1;
    return parentPrefix
      ? `${parentPrefix}-${type}-${counters[key]}`
      : `${type}-${counters[key]}`;
  }

  function walk(node: MdastNode, parentPrefix?: string): void {
    if (isBlockElement(node)) {
      const elementId = getNextId(typeNameFor(node), parentPrefix);
      elements.push({
        elementId,
        type: typeNameFor(node),
        headingDepth: node.type === 'heading' ? node.depth : undefined,
        textContent: extractTextContent(node),
        startLine: node.position?.start.line ?? 0,
        endLine: node.position?.end.line ?? 0,
        rawSource: extractRawSource(sourceLines, node.position),
      });

      // Recurse into children for nested structures (lists, blockquotes)
      if (node.type === 'list') {
        for (const child of node.children) {
          walk(child, elementId);
        }
      }
    }
  }

  for (const child of tree.children) {
    walk(child);
  }

  return elements;
}
```

### Step 2: LCS Diff

Compute the Longest Common Subsequence of the old and new block sequences, using a similarity function to determine whether two blocks are "the same":

```typescript
function computeBlockDiff(
  oldBlocks: AstBlockElement[],
  newBlocks: AstBlockElement[],
): AstDiffEntry[] {
  // Similarity: same type + high text overlap
  function areSimilar(a: AstBlockElement, b: AstBlockElement): boolean {
    if (a.type !== b.type) return false;
    if (a.type === 'heading' && b.type === 'heading' && a.headingDepth !== b.headingDepth) return false;
    return a.textContent === b.textContent || computeWordOverlap(a.textContent, b.textContent) > 0.3;
  }

  // Standard LCS DP table
  const lcs = computeLCS(oldBlocks, newBlocks, areSimilar);

  // Walk the LCS result and classify each block
  const entries: AstDiffEntry[] = [];
  // ... classification logic (described in the Algorithm section above)

  return entries;
}
```

### Step 3: Classify and Compute Word Diffs

For each block not in the LCS:
- If it is in the old sequence only -> `removed`
- If it is in the new sequence only -> `added`
- If a removed block and an adjacent added block are of the same type and have > 30% word overlap -> `modified` (paired together, with word-level diff computed)

For modified blocks:

```typescript
import { diffWords } from 'diff';

function computeWordDiff(oldText: string, newText: string): WordDiffSegment[] {
  const changes = diffWords(oldText, newText);
  return changes.map((change) => ({
    type: change.added ? 'added' : change.removed ? 'removed' : 'unchanged',
    text: change.value,
  }));
}
```

### Step 4: Fallback Threshold

```typescript
const totalBlocks = Math.max(oldBlocks.length, newBlocks.length);
const unchangedCount = entries.filter(e => e.type === 'unchanged').length;
const changedRatio = 1 - (unchangedCount / totalBlocks);
const exceedsFallbackThreshold = changedRatio > 0.8;
```

When `exceedsFallbackThreshold` is true, the `RenderedDiffViewer` shows the fallback banner recommending the raw diff view. The rendered diff is still shown below the banner (the banner is dismissible).

### Fallback to Raw Diff

If computation exceeds the 5-second hard timeout (`NFR-mdr-rendered-diff-perf`):
1. Cancel the computation (via `AbortController` if using a Web Worker, or via a timeout wrapper).
2. Auto-switch `renderMode` to `'raw'` (keeping `viewMode` as `'diff'`).
3. Show an info toast: "File too large for rendered diff. Showing raw diff instead."

---

## Performance Strategy

> Implements: `NFR-mdr-render-perf`, `NFR-mdr-render-scroll-perf`, `NFR-mdr-rendered-diff-perf`, `AC-mdr-large-file-renders`

### Rendering Performance Budget

| File Size | Target: Parse + Render | Strategy |
|---|---|---|
| < 1,000 lines | < 50ms | Main thread, synchronous |
| 1,000 - 5,000 lines | < 200ms | Main thread, synchronous |
| 5,000 - 10,000 lines | < 500ms | Main thread with `content-visibility: auto`; Web Worker if > 200ms observed |
| > 10,000 lines | Best effort | Web Worker for parsing; `content-visibility: auto` for scroll perf |

The rendering pipeline (parse, transform, sanitize, stringify) is a single-pass operation. Shiki highlighting of fenced code blocks within the rendered output is the most expensive step per block. For large files with many code blocks, this highlighting can be deferred and applied progressively (render the code block as plain monospace text first, apply Shiki tokens in a microtask).

### Web Worker for Large File Parsing

For files over 5,000 lines where main-thread rendering would block UI for > 100ms, the parsing pipeline moves to a Web Worker:

```typescript
// src/workers/markdownWorker.ts
import { unified } from 'unified';
import remarkParse from 'remark-parse';
import remarkGfm from 'remark-gfm';
// ... pipeline setup

self.onmessage = (event) => {
  const { source, type } = event.data;

  if (type === 'parse') {
    const ast = unified().use(remarkParse).use(remarkGfm).parse(source);
    const elements = flattenAst(ast, source);
    self.postMessage({ type: 'parsed', elements });
  }

  if (type === 'diff') {
    const { oldSource, newSource } = event.data;
    const result = computeAstDiff(oldSource, newSource);
    self.postMessage({ type: 'diffResult', result });
  }
};
```

The worker handles both parsing (for rendered file view) and AST diffing (for rendered diff view). The store actions `parseMarkdownAst()` and `computeAstDiff()` dispatch to the worker for large files and receive results asynchronously.

### CSS `content-visibility` for Scroll Performance

For rendered documents with > ~100 top-level block elements (roughly corresponding to > 5,000 source lines), each block element wrapper receives:

```css
.rendered-block {
  content-visibility: auto;
  contain-intrinsic-size: auto 100px; /* estimated height per block */
}
```

This allows the browser to skip layout and painting for off-screen elements, significantly improving scroll performance for large documents. The `contain-intrinsic-size` provides an estimated height so the scrollbar behaves correctly.

### Lazy Syntax Highlighting of Fenced Code Blocks

Fenced code blocks within the rendered output are highlighted using the existing Shiki integration. For large files with many code blocks:

1. On initial render, code blocks show plain monospace text (no highlighting).
2. In a microtask or `requestIdleCallback`, iterate through code blocks and apply Shiki highlighting.
3. Update the DOM incrementally (each code block is highlighted independently).

This ensures the rendered view appears within the 200ms/500ms budget even if syntax highlighting takes longer. The visual effect is similar to the progressive highlighting used in the raw view.

### AST Diff Performance

| File Size | Expected Block Count | LCS Time | Word Diff Time | Total |
|---|---|---|---|---|
| < 1,000 lines | ~50 blocks | < 5ms | < 10ms | < 20ms |
| 1,000 - 5,000 lines | 50-300 blocks | < 50ms | < 100ms | < 200ms |
| 5,000 - 10,000 lines | 300-600 blocks | < 200ms | < 500ms | < 1s |

The LCS algorithm's complexity is O(n*m) where n and m are block counts. With typical markdown documents having 5-20 blocks per 100 source lines, even 10,000-line files produce manageable block counts.

---

## Security

> Implements: `NFR-mdr-xss-safety`, `AC-mdr-html-sanitized`

### XSS Prevention

The markdown rendered view introduces the first use of `innerHTML` in the application. The existing raw view uses React text nodes exclusively (`textContent`, no `dangerouslySetInnerHTML`). The rendered view must display HTML, which creates an XSS attack surface.

**Sanitization pipeline**:

```
Markdown source (untrusted)
  --> remark-parse (produces mdast -- safe, it's an AST)
  --> remark-rehype (converts mdast to hast -- safe, it's an AST)
  --> rehype-sanitize (strips dangerous nodes/attributes from hast)
  --> rehype-stringify (serializes safe hast to HTML string)
  --> dangerouslySetInnerHTML (safe because input is sanitized)
```

The key insight is that sanitization happens at the AST level (step 3), before serialization to HTML (step 4). This is more robust than serializing to HTML and then trying to clean it, because the AST representation makes it impossible for malformed HTML to bypass the sanitizer.

**What rehype-sanitize strips**:
- `<script>` elements
- Event handler attributes (`onclick`, `onerror`, `onload`, etc.)
- `javascript:` and `vbscript:` URLs in `href` and `src` attributes
- `data:` URLs (except whitelisted `data:image/*` for inline images)
- `<iframe>`, `<object>`, `<embed>`, `<form>`, `<input>` elements
- `<style>` elements (to prevent CSS-based attacks)
- Any attribute not in the explicit whitelist

**What is preserved**:
- Safe structural HTML: `<details>`, `<summary>`, `<sup>`, `<sub>`, `<ins>`, `<del>`, `<mark>`, `<abbr>`
- `<img>` with `src`, `alt`, `title` (URLs validated)
- `<a>` with `href` (URLs validated), plus `target="_blank"` and `rel="noopener noreferrer"` added automatically
- Standard formatting: `<strong>`, `<em>`, `<code>`, `<pre>`, `<blockquote>`, `<table>`, `<ul>`, `<ol>`, `<li>`, etc.
- Custom attributes needed by the application: `data-element-id`, `tabindex`, `role`, `aria-label`

**Testing**: Sanitization edge cases are covered by unit tests (see Testing Strategy). Test cases include: script injection, event handler injection, javascript: URLs, data: URLs, nested script tags, SVG-based XSS vectors, and CSS injection.

---

## Prompt Generation

### `buildRenderedPrompt` Function

> Implements: `FR-mdr-rendered-comment-prompt`, `AC-mdr-comment-prompt-format`

A new pure function in `src/lib/promptBuilder.ts`, alongside the existing `buildPrompt` and `buildDiffPrompt`:

```typescript
// Implements: FR-mdr-rendered-comment-prompt, AC-mdr-comment-prompt-format

export function buildRenderedPrompt(
  file: FileInfo,
  comments: RenderedComment[],
  preamble: string,
  elementSourceMap: ElementSourceMapping[],
): string {
  const sections: string[] = [];

  // Instructions section (only if preamble is non-empty after trimming)
  const trimmedPreamble = preamble.trim();
  if (trimmedPreamble) {
    sections.push(`## Instructions\n\n${trimmedPreamble}`);
  }

  // File heading with "-- Rendered View" suffix
  sections.push(`## File: ${file.name} (${file.language}) -- Rendered View`);

  // Full raw markdown source with line numbers
  const numberedLines = file.lines.map(
    (line, i) => `${String(i + 1).padStart(4)} | ${line}`
  );
  sections.push('```markdown\n' + numberedLines.join('\n') + '\n```');

  // Requested Changes section
  const sorted = [...comments].sort((a, b) => {
    const aMap = elementSourceMap.find(m => m.elementId === a.elementId);
    const bMap = elementSourceMap.find(m => m.elementId === b.elementId);
    const aLine = aMap?.startLine ?? 0;
    const bLine = bMap?.startLine ?? 0;
    if (aLine !== bLine) return aLine - bLine;
    return a.createdAt.localeCompare(b.createdAt);
  });

  if (sorted.length > 0) {
    const entries = sorted.map((comment) => {
      const mapping = elementSourceMap.find(m => m.elementId === comment.elementId);
      const lineRange = mapping
        ? `lines ${mapping.startLine}-${mapping.endLine}`
        : 'unknown lines';
      const sourceSnippet = mapping
        ? file.lines.slice(mapping.startLine - 1, mapping.endLine).join('\n')
        : '(source not available)';
      const typeLabel = capitalizeFirst(comment.elementType);

      return [
        `- **${typeLabel} (${lineRange})**:`,
        '  ```markdown',
        `  ${sourceSnippet}`,
        '  ```',
        `  Comment: "${comment.text}"`,
      ].join('\n');
    });

    sections.push('## Requested Changes\n\n' + entries.join('\n\n'));
  }

  return sections.join('\n\n');
}
```

### `buildRenderedDiffPrompt` Function

> Implements: `FR-mdr-rendered-diff-prompt`, `AC-mdr-rendered-diff-prompt`

```typescript
// Implements: FR-mdr-rendered-diff-prompt, AC-mdr-rendered-diff-prompt

export function buildRenderedDiffPrompt(
  file: FileInfo,
  comments: RenderedDiffComment[],
  preamble: string,
  astDiffResult: AstDiffResult,
  oldLines: string[],
  newLines: string[],
): string {
  const sections: string[] = [];

  // Instructions section
  const trimmedPreamble = preamble.trim();
  if (trimmedPreamble) {
    sections.push(`## Instructions\n\n${trimmedPreamble}`);
  }

  // File heading
  sections.push(`## File: ${file.name} (${file.language}) -- Rendered Diff View`);

  // Preamble about change notation
  sections.push(
    'The following shows changes between the git HEAD version and the current working copy,\n' +
    'annotated at the document element level.'
  );

  // Changed Elements section
  const sorted = [...comments].sort((a, b) => {
    // Sort by position in astDiffResult entries
    const aIndex = findEntryIndex(astDiffResult.entries, a.elementId, a.changeType);
    const bIndex = findEntryIndex(astDiffResult.entries, b.elementId, b.changeType);
    if (aIndex !== bIndex) return aIndex - bIndex;
    return a.createdAt.localeCompare(b.createdAt);
  });

  if (sorted.length > 0) {
    const entries = sorted.map((comment) => {
      const entry = findEntry(astDiffResult.entries, comment.elementId, comment.changeType);
      if (!entry) return `- **Unknown Element**: Comment: "${comment.text}"`;

      const typeLabel = capitalizeFirst(comment.elementType);
      const changeLabel = capitalizeFirst(comment.changeType);

      switch (entry.type) {
        case 'modified': {
          const oldLineRange = `old lines ${entry.oldElement.startLine}-${entry.oldElement.endLine}`;
          const newLineRange = `new lines ${entry.newElement.startLine}-${entry.newElement.endLine}`;
          return [
            `### ${changeLabel} ${typeLabel} (${oldLineRange} -> ${newLineRange}):`,
            'Old:',
            '```markdown',
            entry.oldElement.rawSource,
            '```',
            'New:',
            '```markdown',
            entry.newElement.rawSource,
            '```',
            `Comment: "${comment.text}"`,
          ].join('\n');
        }
        case 'added': {
          const lineRange = `new lines ${entry.element.startLine}-${entry.element.endLine}`;
          return [
            `### ${changeLabel} ${typeLabel} (${lineRange}):`,
            '```markdown',
            entry.element.rawSource,
            '```',
            `Comment: "${comment.text}"`,
          ].join('\n');
        }
        case 'removed': {
          const lineRange = `old lines ${entry.element.startLine}-${entry.element.endLine}`;
          return [
            `### ${changeLabel} ${typeLabel} (${lineRange}):`,
            '```markdown',
            entry.element.rawSource,
            '```',
            `Comment: "${comment.text}"`,
          ].join('\n');
        }
        case 'unchanged': {
          const lineRange = `lines ${entry.element.startLine}-${entry.element.endLine}`;
          return [
            `### ${changeLabel} ${typeLabel} (${lineRange}):`,
            '```markdown',
            entry.element.rawSource,
            '```',
            `Comment: "${comment.text}"`,
          ].join('\n');
        }
      }
    });

    sections.push('## Annotated Elements\n\n' + entries.join('\n\n'));
  }

  return sections.join('\n\n');
}
```

### Integration with Existing `buildPrompt` and `buildDiffPrompt`

The existing functions are unchanged. The store dispatches to the correct builder based on the combined `viewMode + renderMode` state:

| viewMode | renderMode | Builder Function |
|---|---|---|
| `file` | `raw` | `buildPrompt` (existing) |
| `diff` | `raw` | `buildDiffPrompt` (existing) |
| `file` | `rendered` | `buildRenderedPrompt` (new) |
| `diff` | `rendered` | `buildRenderedDiffPrompt` (new) |

---

## File Structure

New and modified files:

```
engineering/
  markdown-render.md                              NEW -- this spec
  apps/
    web/
      package.json                                MODIFIED -- add unified/remark/rehype dependencies
      src/
        App.tsx                                   MODIFIED -- conditional rendered/raw rendering, render mode switch dialogs
        types/
          index.ts                                MODIFIED -- add rendered-view-related types
        store/
          appStore.ts                             MODIFIED -- add rendered state and actions
        lib/
          markdownPipeline.ts                     NEW -- unified/remark rendering pipeline
          markdownDetect.ts                       NEW -- markdown file extension detection (extracted from languageDetect.ts)
          astDiff.ts                              NEW -- AST-level diff computation (LCS + word diff)
          elementId.ts                            NEW -- element identifier assignment and source mapping
          promptBuilder.ts                        MODIFIED -- add buildRenderedPrompt and buildRenderedDiffPrompt
        components/
          Toolbar.tsx                             MODIFIED -- add RenderToggle
          RenderToggle.tsx                        NEW -- segmented Raw/Rendered toggle
          RenderedViewer.tsx                      NEW -- rendered markdown display
          RenderedBlockElement.tsx                NEW -- individual block element wrapper
          ElementCommentAnchor.tsx                NEW -- hover comment affordance
          RenderedDiffViewer.tsx                  NEW -- rendered markdown diff display
          RenderedDiffBlock.tsx                   NEW -- diff block with change annotations
          RenderedDiffFallbackBanner.tsx          NEW -- fallback warning banner
          RenderedDiffLoadingState.tsx            NEW -- AST diff loading spinner
          CommentBubble.tsx                       MODIFIED -- extended label formatting for element-based labels
        workers/
          markdownWorker.ts                      NEW -- Web Worker for large file parsing and AST diffing
        styles/
          rendered-view.css                      NEW -- rendered markdown styling (typography, code blocks, tables, etc.)
          rendered-diff.css                      NEW -- rendered diff annotation styling (added/removed/modified)
        __tests__/
          unit/
            markdownPipeline.test.ts             NEW
            markdownDetect.test.ts               NEW
            astDiff.test.ts                      NEW
            elementId.test.ts                    NEW
            promptBuilder.test.ts                MODIFIED -- add buildRenderedPrompt and buildRenderedDiffPrompt tests
            appStore.test.ts                     MODIFIED -- add rendered state and action tests
          component/
            RenderToggle.test.tsx                NEW
            RenderedViewer.test.tsx               NEW
            ElementCommentAnchor.test.tsx         NEW
            RenderedDiffViewer.test.tsx           NEW
            RenderedDiffFallbackBanner.test.tsx   NEW
          e2e/
            rendered-view.spec.ts                NEW
            rendered-diff.spec.ts                NEW
```

---

## Testing Strategy

### Unit Tests (Vitest)

Pure logic functions tested in isolation:

| Module | Key Test Cases |
|---|---|
| `markdownDetect.ts` | Detects `.md`, `.mdx`, `.markdown`, `.mdown`, `.mkdn`, `.mkd` as markdown; returns false for `.ts`, `.py`, etc.; case-insensitive matching. Validates `FR-mdr-detect-markdown`. |
| `elementId.ts` | Generates correct IDs for headings, paragraphs, list items, code blocks, tables, blockquotes; handles nested lists (`list-0-item-0`, `list-0-item-1`); produces deterministic output; source line mapping matches AST positions. Validates `FR-mdr-element-id`. |
| `markdownPipeline.ts` | Renders CommonMark basics (headings, paragraphs, lists, links, bold, italic); renders GFM extensions (tables, task lists, strikethrough, autolinks); sanitizes `<script>` tags; sanitizes event handlers; preserves safe HTML (`<details>`, `<sup>`); handles empty input; handles input with only whitespace. Validates `FR-mdr-render-commonmark`, `NFR-mdr-xss-safety`, `AC-mdr-html-sanitized`. |
| `astDiff.ts` | Identical inputs produce no diff; fully new document has all-added entries; fully removed document has all-removed entries; single paragraph modified produces modified entry with word diff; modified block with < 30% word overlap classified as remove+add instead of modified; fallback threshold at > 80% changed blocks; handles empty documents; handles documents with only headings; word-level diff produces correct segments. Validates `FR-mdr-rendered-diff-display`, `AC-mdr-rendered-diff-additions`, `AC-mdr-rendered-diff-removals`, `AC-mdr-rendered-diff-modifications`, `AC-mdr-diff-fallback`. |
| `promptBuilder.ts` (additions) | `buildRenderedPrompt`: correct format with preamble; without preamble; single comment on heading; multiple comments in document order; raw source lines included (not HTML); element type labels correct. `buildRenderedDiffPrompt`: modified element shows old+new source; added element shows only new source; removed element shows only old source; change type labels correct; comments in document order. Validates `FR-mdr-rendered-comment-prompt`, `AC-mdr-comment-prompt-format`, `FR-mdr-rendered-diff-prompt`, `AC-mdr-rendered-diff-prompt`. |
| `appStore.ts` (additions) | `setRenderMode` sets mode; `parseMarkdownAst` populates astElements and elementSourceMap; `addRenderedComment` creates comment and regenerates prompt; `deleteRenderedComment` removes comment; `clearRenderedComments` resets rendered comment state; `computeAstDiff` populates astDiffResult; `loadFile` resets rendered state and detects markdown; `clearSession` resets all rendered state. |

### Component Tests (React Testing Library)

| Component | Key Test Cases |
|---|---|
| `RenderToggle` | Renders when `isVisible=true`; returns null when `isVisible=false`; "Raw" active by default; clicking "Rendered" fires onModeChange; keyboard navigation (ArrowLeft/ArrowRight, Enter); ARIA attributes correct. |
| `RenderedViewer` | Renders markdown as HTML (headings, paragraphs visible); comment affordance icon appears on hover; clicking comment icon fires onElementClick; comment bubbles render below elements; keyboard tab cycles through elements. |
| `ElementCommentAnchor` | Hidden by default; shows icon when isHovered=true; shows blue dot when hasComments=true; click fires onClick; ARIA attributes correct. |
| `RenderedDiffViewer` | Added blocks have green background and ADDED badge; removed blocks have strikethrough and REMOVED badge; modified blocks show word-level inline diffs; fallback banner appears when exceedsFallbackThreshold=true; "Switch to Raw Diff" link fires callback. |
| `RenderedDiffFallbackBanner` | Renders with correct text; dismiss button fires onDismiss; "Switch to Raw Diff" fires callback; ARIA role="alert". |

### E2E Tests (Playwright)

| Flow | Coverage |
|---|---|
| Load markdown file, toggle to rendered view, verify HTML rendering | `AC-mdr-toggle-appears`, `AC-mdr-render-basic`, `AC-mdr-render-gfm`, `AC-mdr-render-code-blocks` |
| Toggle hidden for non-markdown files | `AC-mdr-toggle-hidden-non-md` |
| Add comment on rendered element, verify prompt | `AC-mdr-comment-rendered-element`, `AC-mdr-comment-heading`, `AC-mdr-comment-prompt-format` |
| Switch between rendered and raw, verify confirmation dialog | `AC-mdr-switch-clears-comments`, `AC-mdr-switch-no-comments` |
| View rendered diff with additions, removals, modifications | `AC-mdr-rendered-diff-additions`, `AC-mdr-rendered-diff-removals`, `AC-mdr-rendered-diff-modifications` |
| Add comment on rendered diff element, verify prompt | `AC-mdr-rendered-diff-comment`, `AC-mdr-rendered-diff-prompt` |
| Large markdown file rendering performance | `AC-mdr-large-file-renders` |
| Keyboard comment in rendered view | `AC-mdr-keyboard-comment` |
| XSS sanitization (script tag in markdown) | `AC-mdr-html-sanitized` |
| Rendered diff fallback for heavily restructured file | `AC-mdr-diff-fallback` |
| Raw view unchanged for markdown files | `AC-mdr-raw-unchanged` |

---

## Implementation Plan

The work is divided into four phases. Each phase produces a testable increment. Phases are ordered by dependency.

### Phase 1: Markdown Pipeline and Detection (estimated 2-3 days)

**Goal**: The remark pipeline parses markdown, assigns element IDs, and renders sanitized HTML. Markdown files are detected.

1. **Add dependencies**: `pnpm add unified remark-parse remark-gfm remark-rehype rehype-sanitize rehype-stringify` in `engineering/apps/web/`.

2. **Implement `markdownDetect.ts`**: Extract the markdown extension list into a reusable utility. Write unit tests.

3. **Implement `elementId.ts`**: AST traversal that assigns stable element identifiers and builds the source-line mapping. Write unit tests.

4. **Implement `markdownPipeline.ts`**: The full remark pipeline including parsing, GFM, element ID assignment, sanitization, and serialization. Write unit tests for rendering and sanitization.

5. **Extend Zustand store**: Add `initialRenderedState` fields. Add `setRenderMode`, `parseMarkdownAst` actions. Modify `loadFile` to detect markdown and reset rendered state.

6. **Create `rendered-view.css`**: Styling for all rendered markdown elements per the design spec.

**Delivers**: The markdown pipeline works end-to-end. Markdown files are detected. No UI changes yet.

**Slug coverage**: `FR-mdr-detect-markdown`, `FR-mdr-render-commonmark`, `FR-mdr-render-styling`, `FR-mdr-element-id`, `NFR-mdr-xss-safety`, `NFR-mdr-client-only`.

### Phase 2: Rendered File View and Comments (estimated 3-4 days)

**Goal**: Users can view rendered markdown and add element-anchored comments.

1. **Build `RenderToggle`**: Implement the segmented control per the design spec. Wire into `Toolbar`.

2. **Build `RenderedViewer`**: Implement the rendered markdown display with the comment affordance column, block element wrappers, and hover interactions.

3. **Build `ElementCommentAnchor`**: Implement the comment affordance icon with hover/focus/click behavior.

4. **Build `RenderedBlockElement`**: Implement the block wrapper with data-element-id, hover highlight, and comment bubble positioning.

5. **Wire comment creation**: Integrate InlineCommentEditor for rendered-mode comments. Implement `addRenderedComment`, `updateRenderedComment`, `deleteRenderedComment` store actions.

6. **Implement `buildRenderedPrompt`**: Add the function to `promptBuilder.ts`. Wire auto-generation. Write unit tests.

7. **Modify `App.tsx`**: Conditional rendering for rendered view. Render mode switch confirmation dialogs.

**Delivers**: User can toggle to rendered view for markdown files, see formatted HTML, add comments on elements, and generate prompts with raw source references.

**Slug coverage**: `FR-mdr-render-toggle`, `FR-mdr-rendered-comment-create`, `FR-mdr-rendered-comment-prompt`, `FR-mdr-switch-comments`, `FR-mdr-raw-diff-unchanged`, `AC-mdr-toggle-appears`, `AC-mdr-toggle-hidden-non-md`, `AC-mdr-render-basic`, `AC-mdr-render-gfm`, `AC-mdr-render-code-blocks`, `AC-mdr-raw-unchanged`, `AC-mdr-comment-rendered-element`, `AC-mdr-comment-heading`, `AC-mdr-comment-prompt-format`, `AC-mdr-switch-clears-comments`, `AC-mdr-switch-no-comments`.

### Phase 3: Rendered Diff View (estimated 3-4 days)

**Goal**: Users can view rendered markdown diffs with change annotations and add comments.

1. **Implement `astDiff.ts`**: AST flattening, LCS diff, modification detection, word-level diffing, fallback threshold. Write comprehensive unit tests.

2. **Build `RenderedDiffViewer`**: Implement the rendered diff display with added/removed/modified/unchanged block annotations, word-level inline diffs, and the comment affordance.

3. **Build `RenderedDiffBlock`**: Implement individual diff block rendering with the appropriate visual treatment (green/red backgrounds, badges, strikethrough, inline word diff spans).

4. **Build `RenderedDiffFallbackBanner`** and **`RenderedDiffLoadingState`**.

5. **Create `rendered-diff.css`**: Styling for diff annotations (added/removed/modified block backgrounds, inline word diff highlights, badges).

6. **Implement `buildRenderedDiffPrompt`**: Add the function to `promptBuilder.ts`. Write unit tests.

7. **Wire store actions**: `computeAstDiff`, rendered diff comment CRUD, prompt generation. Handle the 5-second timeout with auto-fallback.

8. **Implement Web Worker**: Create `markdownWorker.ts` for large file parsing and AST diffing. Integrate with store actions.

**Delivers**: User can view rendered diffs with visual change annotations, add comments on diff elements, and generate prompts with old/new source references.

**Slug coverage**: `FR-mdr-rendered-diff-display`, `FR-mdr-rendered-diff-comment`, `FR-mdr-rendered-diff-prompt`, `NFR-mdr-rendered-diff-perf`, `AC-mdr-rendered-diff-additions`, `AC-mdr-rendered-diff-removals`, `AC-mdr-rendered-diff-modifications`, `AC-mdr-rendered-diff-comment`, `AC-mdr-rendered-diff-prompt`, `AC-mdr-diff-fallback`.

### Phase 4: Performance, Accessibility, and Polish (estimated 2-3 days)

**Goal**: Full keyboard accessibility, performance optimization, and comprehensive test coverage.

1. **Keyboard navigation**: Implement Tab cycling through rendered elements, Enter/c to comment, focus management per design spec.

2. **ARIA attributes**: Add all ARIA attributes per the design spec's accessibility section.

3. **Performance optimization**: Profile rendering for 5,000 and 10,000-line files. Apply `content-visibility: auto`. Implement progressive code block highlighting. Ensure performance budgets are met.

4. **Focus management**: Focus moves to first element on rendered view entry, returns to element after comment submission, moves to fallback banner when shown.

5. **E2E tests**: Full flow tests for all acceptance criteria.

6. **Component tests**: Test all new components.

7. **Cross-browser testing**: Verify rendering in Chrome, Firefox, and WebKit.

**Delivers**: Fully accessible, performant rendered view feature meeting all FR, NFR, and AC requirements.

**Slug coverage**: `NFR-mdr-render-perf`, `NFR-mdr-render-scroll-perf`, `NFR-mdr-accessibility`, `AC-mdr-large-file-renders`, `AC-mdr-keyboard-comment`, `AC-mdr-html-sanitized`.

---

## Requirement Traceability

### Functional Requirements

| Slug | Engineering Coverage |
|---|---|
| `FR-mdr-detect-markdown` | `markdownDetect.ts` utility; store `loadFile` sets `isMarkdownFile`; `RenderToggle` `isVisible` prop; `Toolbar` conditional rendering |
| `FR-mdr-render-toggle` | `RenderToggle` component; `Toolbar` integration; store `renderMode` state and `setRenderMode` action; `App.tsx` conditional rendering and confirmation dialogs |
| `FR-mdr-render-commonmark` | `markdownPipeline.ts` (remark-parse + remark-gfm pipeline); `RenderedViewer` component; `rendered-view.css` |
| `FR-mdr-render-styling` | `rendered-view.css` (typography, colors, spacing for all rendered elements); `RenderedViewer` layout (80ch max-width, comment affordance column) |
| `FR-mdr-element-id` | `elementId.ts` (AST traversal, identifier assignment, source mapping); `RenderedViewer` `data-element-id` attributes; `RenderedBlockElement` wrapper |
| `FR-mdr-rendered-comment-create` | `ElementCommentAnchor` component; `RenderedViewer` hover/click handlers; store `addRenderedComment` action; reused `InlineCommentEditor`; `RenderedComment` type |
| `FR-mdr-rendered-comment-prompt` | `buildRenderedPrompt` function in `promptBuilder.ts`; `elementSourceMap` for AST-to-line mapping; store `generateRenderedPrompt` action |
| `FR-mdr-switch-comments` | `App.tsx` render-mode-switch confirmation dialog; store `clearRenderedComments` and `clearRenderedDiffComments` actions; `ConfirmationDialog` reuse |
| `FR-mdr-raw-diff-unchanged` | No changes to `DiffViewer` or raw diff behavior; conditional rendering in `App.tsx` routes raw+diff to existing `DiffViewer` |
| `FR-mdr-rendered-diff-display` | `astDiff.ts` (LCS block diff + word-level diff); `RenderedDiffViewer` component; `RenderedDiffBlock` component; `rendered-diff.css`; store `computeAstDiff` action |
| `FR-mdr-rendered-diff-comment` | `RenderedDiffViewer` comment affordance; store `addRenderedDiffComment` action; `RenderedDiffComment` type with change-type qualifier |
| `FR-mdr-rendered-diff-prompt` | `buildRenderedDiffPrompt` function in `promptBuilder.ts`; store `generateRenderedDiffPrompt` action |

### Non-Functional Requirements

| Slug | Engineering Coverage |
|---|---|
| `NFR-mdr-render-perf` | `markdownPipeline.ts` single-pass rendering; `markdownWorker.ts` Web Worker for files > 5,000 lines; progressive code block highlighting |
| `NFR-mdr-render-scroll-perf` | `content-visibility: auto` CSS on block elements for files > 5,000 lines; no virtualization (heterogeneous elements) |
| `NFR-mdr-rendered-diff-perf` | `astDiff.ts` LCS algorithm O(n*m) on block counts; `markdownWorker.ts` async diff computation; 5-second hard timeout with auto-fallback to raw diff |
| `NFR-mdr-xss-safety` | `rehype-sanitize` in the remark pipeline; schema-based whitelist; AST-level sanitization before HTML serialization; unit tests for XSS vectors |
| `NFR-mdr-client-only` | All rendering, parsing, diffing, and sanitization happen in-browser; no server calls for markdown processing; Web Worker is still in-browser |
| `NFR-mdr-accessibility` | `RenderToggle` ARIA (`role="tablist"`, `role="tab"`, `aria-selected`); `RenderedViewer` keyboard navigation (Tab, Enter/c); `RenderedBlockElement` `role="article"` with `aria-label`; `ElementCommentAnchor` `role="button"`; `RenderedDiffViewer` diff-aware `aria-label`; inline diff uses `<ins>`/`<del>` elements; focus management |

### Acceptance Criteria

| Slug | Engineering Coverage |
|---|---|
| `AC-mdr-toggle-appears` | `RenderToggle` rendered in `Toolbar` when `isMarkdownFile === true`; defaults to "Raw" active |
| `AC-mdr-toggle-hidden-non-md` | `RenderToggle` returns null when `isVisible === false`; `isMarkdownFile` set by `loadFile` |
| `AC-mdr-render-basic` | `markdownPipeline.ts` CommonMark support; `rendered-view.css` heading, paragraph, bold, italic, link, list styling |
| `AC-mdr-render-gfm` | `remark-gfm` plugin; `rendered-view.css` table, task list, strikethrough styling |
| `AC-mdr-render-code-blocks` | `markdownPipeline.ts` Shiki integration for fenced code blocks; same dark theme as raw view (background `#1E293B`, text `#E2E8F0`) |
| `AC-mdr-raw-unchanged` | No changes to `CodeViewer`; conditional rendering routes raw+file to existing component |
| `AC-mdr-comment-rendered-element` | `ElementCommentAnchor` hover/click; `InlineCommentEditor` opens below element; `CommentBubble` renders below element |
| `AC-mdr-comment-heading` | Headings are commentable block elements; element label shows "Heading"; prompt references raw heading source line |
| `AC-mdr-comment-prompt-format` | `buildRenderedPrompt` includes raw markdown source (not HTML); element type + line range + source snippet + comment text |
| `AC-mdr-switch-clears-comments` | `App.tsx` `ConfirmationDialog` on render mode switch when comments exist; on confirm: clear comments, switch mode |
| `AC-mdr-switch-no-comments` | No dialog when comment count is 0; immediate mode switch |
| `AC-mdr-rendered-diff-additions` | `RenderedDiffBlock` added variant: green background `#F0FDF4`, left border `#22C55E`, "ADDED" badge |
| `AC-mdr-rendered-diff-removals` | `RenderedDiffBlock` removed variant: red background `#FEF2F2`, strikethrough, `#6B7280` text, "REMOVED" badge |
| `AC-mdr-rendered-diff-modifications` | `RenderedDiffBlock` modified variant: word-level inline diffs with `<ins>` (green `#BBF7D0`) and `<del>` (red `#FECACA`, strikethrough) |
| `AC-mdr-rendered-diff-comment` | `RenderedDiffViewer` comment affordance on all diff blocks; `RenderedDiffComment` with change-type qualifier |
| `AC-mdr-rendered-diff-prompt` | `buildRenderedDiffPrompt` with old/new source for modified, new-only for added, old-only for removed |
| `AC-mdr-html-sanitized` | `rehype-sanitize` strips `<script>`, event handlers, `javascript:` URLs; unit tests validate |
| `AC-mdr-large-file-renders` | `markdownWorker.ts` Web Worker for > 5,000 lines; `content-visibility: auto`; performance profiling in E2E tests |
| `AC-mdr-keyboard-comment` | Tab navigation through rendered elements; Enter/c opens editor; focus management; ARIA attributes |
| `AC-mdr-diff-fallback` | `astDiff.ts` fallback threshold (> 80%); `RenderedDiffFallbackBanner` with "Switch to Raw Diff" link; 5-second timeout auto-fallback |
