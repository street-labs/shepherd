# Working Copy Diff View -- Technical Spec

> Based on requirements in `../product/diff-view.md`
> Based on design in `../design/diff-view.md`

## Technical Approach

The diff view is an alternative rendering mode for the existing CRPG code viewer panel. When active, it replaces the `CodeViewer` component with a new `DiffViewer` component that displays a unified diff between the file's git HEAD version (baseline) and its current working copy on disk.

The implementation adds three concerns to the existing architecture:

1. **Server-side baseline retrieval**: A new `GET /api/file/head` endpoint on the Vite plugin (`fileApiPlugin.ts`) runs `git show HEAD:<path>` to serve the git HEAD version of a file. The client fetches this and performs the diff entirely in-browser (`NFR-diff-client-compute`).

2. **Client-side diff computation**: The `diff` npm package (jsdiff) computes a structured patch between the baseline and working copy. The result is transformed into an array of diff lines with collapse/expand metadata.

3. **Diff-aware rendering and commenting**: A new `DiffViewer` component renders the diff with dual line numbers, type indicators, colored backgrounds, and collapsible unchanged sections. Comments in diff mode use a diff-specific anchoring model (`DiffLineId`) instead of absolute line numbers. A new `buildDiffPrompt` function generates prompts with unified diff notation.

### Key Technical Decisions

| Decision | Choice | Rationale |
|---|---|---|
| Diff library | `diff` (jsdiff) v7+ | The standard JavaScript diff library. `structuredPatch` produces unified-diff-style output with hunks, exactly matching our data model. Well-maintained (10M+ weekly npm downloads), zero dependencies, works in the browser. Rolling our own Myers diff implementation would be error-prone and offer no advantage -- jsdiff is battle-tested and produces minimal, human-readable diffs. |
| Baseline source | `git show HEAD:<path>` via server endpoint | The only reliable way to get the HEAD version of a file without reading the git object store directly in the browser. The server already has filesystem access via the Vite plugin. Running `git show` is a single subprocess call that returns the file content directly. |
| Diff computation location | Client-side (main thread for v1) | Consistent with `NFR-crp-client-only` and `NFR-diff-client-compute`. The server provides raw text; all computation happens in the browser. jsdiff processes 10K-line files in well under 500ms on modern hardware (`NFR-diff-compute-perf`). A Web Worker escape hatch is documented but deferred to post-v1. |
| Diff comment anchoring | `DiffLineId` (lineType + oldLine + newLine) | Absolute line numbers are ambiguous in a diff context (added line 5 and removed line 5 are different lines). A composite identifier encoding the line type and position is unambiguous and stable within a single diff computation. |
| Collapsed section rendering | Single virtual row per collapsed section | Each collapsed section is one row in the TanStack Virtual list with a fixed 36px height. Expanding replaces it with the hidden lines. The virtualizer's item count changes dynamically, which TanStack Virtual handles natively. |
| View mode state | Zustand store (`viewMode` field) | The view mode affects the toolbar, code viewer panel, comment model, and prompt generation. Centralizing it in the store ensures all components react consistently. |

---

## Data Model

### New Types

The following types are added to `src/types/index.ts`. They extend the existing type definitions without modifying them.

```typescript
// Implements: FR-diff-display, FR-diff-comment-create

/** Identifies a line's position and type within a diff. */
export interface DiffLineId {
  /** The type of change this line represents. */
  lineType: 'added' | 'removed' | 'context';
  /** Line number in the old (HEAD) version. Null for added lines. */
  oldLine: number | null;
  /** Line number in the new (working copy) version. Null for removed lines. */
  newLine: number | null;
}

/** A single line in the computed diff. */
export interface DiffLine {
  /** Unique index within the diffLines array (0-based). Used as the virtualizer key. */
  index: number;
  /** The line type: added, removed, or context (unchanged). */
  type: 'added' | 'removed' | 'context';
  /** Line number in the old (HEAD) version. Null for added lines. */
  oldLineNumber: number | null;
  /** Line number in the new (working copy) version. Null for removed lines. */
  newLineNumber: number | null;
  /** The text content of the line (without +/- prefix). */
  content: string;
}

/** A contiguous range of context lines that should be collapsed. */
export interface CollapsedSection {
  /** Index into the diffLines array where the collapsed range starts (inclusive). */
  startIndex: number;
  /** Index into the diffLines array where the collapsed range ends (inclusive). */
  endIndex: number;
  /** Number of lines hidden in this section. */
  lineCount: number;
}

/** A comment anchored to a diff line or range of diff lines. */
export interface DiffComment {
  /** Unique identifier. Generated via crypto.randomUUID(). */
  id: string;
  /** The diff line identifier for the start of the commented range. */
  startLineId: DiffLineId;
  /** The diff line identifier for the end of the commented range. Same as startLineId for single-line comments. */
  endLineId: DiffLineId;
  /** Index of the start line in the diffLines array. Used for ordering and rendering. */
  startIndex: number;
  /** Index of the end line in the diffLines array. */
  endIndex: number;
  /** The user's comment text. */
  text: string;
  /** ISO-8601 timestamp of creation. Used for stable ordering when positions are equal. */
  createdAt: string;
}

/** Display items for the virtualized diff viewer. */
export type DiffDisplayItem =
  | { type: 'diff-line'; line: DiffLine }
  | { type: 'collapsed-section'; section: CollapsedSection; sectionIndex: number }
  | { type: 'diff-comment-bubble'; comment: DiffComment }
  | { type: 'diff-editor'; startIndex: number; endIndex: number; mode: 'create' | 'edit'; commentId?: string };

/** How the file was loaded -- determines whether diff view is available. */
export type FileSource = 'server' | 'local';
```

### Modified Types

The `AppState` interface is extended with new fields. Existing fields are not changed.

```typescript
/** Additions to AppState (merged into the existing interface). */
export interface DiffState {
  /** Current view mode: 'file' for full-file view, 'diff' for unified diff view. */
  viewMode: 'file' | 'diff';
  /** How the file was loaded. 'server' = via /api/file (slash command). 'local' = paste/upload/drag-and-drop. */
  fileSource: FileSource | null;
  /** The git HEAD version of the file content, or null if not fetched. */
  baselineContent: string | null;
  /** The computed diff lines, or null if not computed. */
  diffLines: DiffLine[] | null;
  /** Collapsed sections derived from diffLines. */
  collapsedSections: CollapsedSection[] | null;
  /** Set of collapsed section indices that have been expanded by the user. */
  expandedSections: Set<number>;
  /** Whether the baseline is currently being fetched. */
  isBaselineLoading: boolean;
  /** Error message from baseline fetch, or null. */
  baselineError: string | null;
  /** Whether the diff is empty (working copy matches HEAD). */
  isDiffEmpty: boolean;
  /** All diff-mode comments, keyed by comment ID. Separate from file-mode comments. */
  diffComments: Record<string, DiffComment>;
  /** Ordered array of diff comment IDs sorted by startIndex then createdAt. */
  diffCommentOrder: string[];
  /** The ID of the currently focused diff comment (via navigation), or null. */
  focusedDiffCommentId: string | null;
  /** The currently selected range in diff view (indices into diffLines), or null. */
  diffSelectedRange: { startIndex: number; endIndex: number } | null;
  /** Editor state for diff-mode comment editing. */
  diffEditorState: DiffEditorState | null;
}

/** State of the inline comment editor in diff mode. */
export type DiffEditorState =
  | { mode: 'create'; startIndex: number; endIndex: number }
  | { mode: 'edit'; commentId: string };
```

### Derived Data

Computed from the store via selectors, not stored directly:

- **Visible diff lines**: The `diffLines` array filtered through `collapsedSections` and `expandedSections` to produce the display items array. Collapsed sections that have not been expanded are represented as single `collapsed-section` display items.
- **Diff comment count**: `Object.keys(state.diffComments).length`.
- **Active comment count**: `viewMode === 'diff' ? diffCommentCount : fileCommentCount`. Used by the toolbar to display the correct count regardless of mode.
- **Diff comments by line index**: A `Map<number, DiffComment[]>` mapping each diffLine index to the comments covering that line. Computed the same way as the file-mode `commentsByLine`.
- **Is diff available**: `fileSource === 'server'`. Determines whether the "Diff" segment in the view mode toggle is enabled.

---

## API / Interface Design

### New Endpoint: `GET /api/file/head`

> Implements: `FR-diff-baseline-fetch`, `NFR-diff-baseline-fetch-speed`

A new route in the `fileApiPlugin.ts` Vite plugin that serves the git HEAD version of a file.

**Request**: `GET /api/file/head?path=<url-encoded-absolute-path>`

**Response**:

| Status | Condition | Content-Type | Body | Headers |
|---|---|---|---|---|
| 200 | HEAD version read successfully | `text/plain; charset=utf-8` | Raw file content at HEAD | `X-File-Lines: <count>` |
| 400 | Missing `path` parameter | `application/json` | `{"error": "Missing required query parameter: path"}` | -- |
| 404 | File has no git history (untracked) | `application/json` | `{"error": "File has no git history: <path>"}` | -- |
| 404 | Git repository not found | `application/json` | `{"error": "Not a git repository: <path>"}` | -- |
| 415 | HEAD version is binary | `application/json` | `{"error": "Binary file at HEAD not supported: <path>"}` | -- |
| 500 | Git command failed | `application/json` | `{"error": "Failed to read HEAD version: <details>"}` | -- |

#### Implementation Details

The endpoint is added as a second route handler in the existing `fileApiPlugin.ts` middleware. The URL prefix check changes from `req.url?.startsWith('/api/file')` to a more specific routing:

```typescript
server.middlewares.use((req, res, next) => {
  const url = new URL(req.url!, `http://${req.headers.host}`);

  if (url.pathname === '/api/file/head') {
    // Handle HEAD version request
    return handleHeadRequest(req, res, url);
  }

  if (url.pathname === '/api/file') {
    // Handle working copy request (existing logic)
    return handleFileRequest(req, res, url);
  }

  return next();
});
```

**Important**: The `/api/file/head` route must be matched before `/api/file` because `/api/file/head` would also match a prefix check for `/api/file`. Using exact `pathname` matching eliminates this ambiguity.

#### `handleHeadRequest` Implementation

```typescript
import { execSync } from 'child_process';

function handleHeadRequest(req, res, url) {
  const filePath = url.searchParams.get('path');
  if (!filePath) {
    return jsonError(res, 400, 'Missing required query parameter: path');
  }

  const resolved = path.resolve(filePath);

  // 1. Find the git repository root for this file
  let gitRoot: string;
  try {
    gitRoot = execSync('git rev-parse --show-toplevel', {
      cwd: path.dirname(resolved),
      encoding: 'utf-8',
      timeout: 5000,
    }).trim();
  } catch {
    return jsonError(res, 404, `Not a git repository: ${resolved}`);
  }

  // 2. Compute the git-relative path
  const relativePath = path.relative(gitRoot, resolved);

  // 3. Run git show HEAD:<relative-path>
  let headContent: string;
  try {
    headContent = execSync(`git show HEAD:${relativePath}`, {
      cwd: gitRoot,
      encoding: 'buffer',  // Read as buffer for binary detection
      timeout: 5000,
      maxBuffer: 50 * 1024 * 1024,  // 50 MB max
    });
  } catch (err) {
    const message = (err as Error).message || '';
    // git show exits with code 128 when the path doesn't exist at HEAD
    if (message.includes('does not exist') || message.includes('fatal: path')) {
      return jsonError(res, 404, `File has no git history: ${resolved}`);
    }
    return jsonError(res, 500, `Failed to read HEAD version: ${message}`);
  }

  // 4. Binary detection on HEAD content
  if (isBinaryBuffer(headContent)) {
    return jsonError(res, 415, `Binary file at HEAD not supported: ${resolved}`);
  }

  // 5. Return the content
  const content = headContent.toString('utf-8');
  const lines = content.split('\n').length;

  res.writeHead(200, {
    'Content-Type': 'text/plain; charset=utf-8',
    'X-File-Lines': String(lines),
  });
  res.end(content);
}
```

**Key implementation notes**:

1. **Git-relative path resolution**: `git show HEAD:<path>` requires a path relative to the repository root, not an absolute path. The implementation first discovers the git root via `git rev-parse --show-toplevel`, then computes `path.relative(gitRoot, resolved)`.

2. **Buffer encoding for binary detection**: `execSync` is called with `encoding: 'buffer'` so we can run the same `isBinaryBuffer` check on the HEAD content before decoding it as UTF-8. This reuses the existing binary detection function.

3. **Timeout**: A 5-second timeout on both `git rev-parse` and `git show` prevents hanging if git is unresponsive. This is generous -- typical execution is <100ms.

4. **Error differentiation**: Git's error messages are parsed to distinguish between "file not tracked" (404) and other failures (500). The key indicator is whether the error message references a path that doesn't exist in the tree.

5. **Submodule / worktree**: For v1, submodules and secondary worktrees are not explicitly handled. `git rev-parse --show-toplevel` returns the top-level of the innermost repository (submodule or main), and `git show HEAD:<path>` works relative to that root. This means submodule files work correctly as long as the submodule has its own HEAD. Secondary worktrees should also work because `git show HEAD:` resolves relative to the worktree's HEAD. If edge cases arise, they will be addressed in a future iteration (per Open Question 7 in the product spec).

### Modified Endpoint: `GET /api/file`

The existing `/api/file` endpoint is not modified in its response format. However, the routing logic in the middleware is updated to use exact pathname matching (as shown above) instead of a prefix check. This is a non-breaking change -- the existing endpoint continues to work identically.

Additionally, when a file is loaded via `/api/file`, the web app needs to know that the file came from the server (so it can enable diff view). This is already implicit: if the file was loaded via `useFileFromUrl` (which fetches from `/api/file`), it was server-loaded. The `fileSource` store field is set to `'server'` in the `useFileFromUrl` hook's success path.

---

## Component Architecture

The component tree is extended with new components for diff view. The existing component tree is unchanged -- the diff components are parallel alternatives that render when `viewMode === 'diff'`.

```
App
 +-- Toolbar                          MODIFIED -- adds ViewModeToggle and RefreshButton
 |    +-- ViewModeToggle              NEW -- segmented File/Diff toggle
 |    +-- RefreshButton               NEW -- refresh diff button (visible only in diff mode)
 +-- MainContent
      +-- [if no file] FileDropZone   (unchanged)
      +-- [if file loaded]
           +-- CodeViewerPanel
           |    +-- FileHeader        (unchanged)
           |    +-- [if viewMode === 'file']
           |    |    +-- CodeViewer   (unchanged)
           |    +-- [if viewMode === 'diff' && isBaselineLoading]
           |    |    +-- DiffLoadingState     NEW
           |    +-- [if viewMode === 'diff' && baselineError]
           |    |    +-- DiffErrorState       NEW
           |    +-- [if viewMode === 'diff' && isDiffEmpty]
           |    |    +-- DiffEmptyState       NEW
           |    +-- [if viewMode === 'diff' && diffLines]
           |         +-- DiffViewer           NEW
           |              +-- DiffVirtualRow (repeated, virtualized)  NEW
           |              |    +-- DiffGutterCell        NEW
           |              |    +-- DiffOldLineNumber     NEW
           |              |    +-- DiffNewLineNumber     NEW
           |              |    +-- DiffTypeIndicator     NEW
           |              |    +-- DiffCodeContent       NEW
           |              +-- CollapsedSectionSeparator  NEW
           |              +-- CommentBubble (reused, with diff-aware labels)
           |              +-- InlineCommentEditor (reused)
           +-- SidebarPanel
                +-- PreambleInput     (unchanged)
                +-- PromptPreview     (unchanged)
 +-- ConfirmationDialog               MODIFIED -- new confirmation variants for mode switch and refresh
 +-- ToastNotification                (unchanged)
```

### Component Responsibilities

#### `ViewModeToggle` (new)

> Implements: `FR-diff-mode-toggle`, `FR-diff-mode-availability`, `AC-diff-toggle-to-diff`, `AC-diff-toggle-to-file`, `AC-diff-paste-upload-disabled`

A segmented control with "File" and "Diff" segments. Placed in the `Toolbar` after the title.

**Props**:
- `activeMode: 'file' | 'diff'` -- current view mode from store.
- `isDiffEnabled: boolean` -- whether the Diff segment is clickable (true when `fileSource === 'server'`).
- `onModeChange: (mode: 'file' | 'diff') => void` -- callback. The parent (`Toolbar` or `App`) handles confirmation dialogs before actually dispatching the store action.

**Behavior**:
- Renders two segments in a horizontal group with `role="tablist"`.
- Each segment is `role="tab"` with `aria-selected`.
- Disabled "Diff" segment shows a tooltip: "Diff view requires a file loaded via the /shepherd command".
- Arrow keys move focus between segments; Enter/Space activates.
- The component is purely presentational. Mode-switch side effects (confirmation dialogs, baseline fetching) are handled by the parent.

#### `RefreshButton` (new)

> Implements: `FR-diff-refresh`, `AC-diff-refresh-updates`

A 32x32 icon button with a circular arrow icon. Visible only when `viewMode === 'diff'`.

**Props**:
- `isLoading: boolean` -- when true, the icon spins and the button is disabled.
- `onRefresh: () => void` -- callback. The parent handles confirmation if comments exist.

#### `DiffViewer` (new)

> Implements: `FR-diff-display`, `FR-diff-collapse`, `FR-diff-expand`, `FR-diff-comment-create`, `FR-diff-comment-on-range`, `NFR-diff-render-perf`, `NFR-diff-accessibility`

The core diff display component. Parallel to `CodeViewer` but renders diff-specific rows. Uses TanStack Virtual for the same virtualization strategy (`NFR-diff-render-perf`).

**Key differences from `CodeViewer`**:
1. Wider gutter: 140px total (28px comment gutter + 44px old line number + 44px new line number + 20px type indicator + 4px spacer) vs 76px in file mode.
2. Each row has a background color based on line type (green for added, red for removed, white for context).
3. Collapsed sections are single 36px rows that expand on click.
4. Comments anchor to `DiffLineId` instead of absolute line numbers.
5. Range selections cannot span across collapsed section separators.

**Virtualizer setup**: The virtualizer operates on a `DiffDisplayItem[]` array that interleaves diff lines, collapsed sections, comment bubbles, and the editor. The item count changes dynamically when sections are expanded.

**Syntax highlighting**: Both added and removed lines are syntax-highlighted using the same Shiki integration as `CodeViewer`. The diff computation preserves the original line content (without `+`/`-` prefixes), so the same `highlightCode` function works unchanged. Highlighting is applied to the combined set of unique source lines from both the old and new versions.

#### `CollapsedSectionSeparator` (new)

> Implements: `FR-diff-collapse`, `FR-diff-expand`, `AC-diff-collapse-default`, `AC-diff-expand-section`

A single row representing a collapsed block of unchanged lines.

**Props**:
- `lineCount: number` -- number of hidden lines.
- `onExpand: () => void` -- callback to expand this section.

**Behavior**:
- Renders a 36px row with "... N unchanged lines ..." text and an "Expand" link.
- Entire row is clickable. Enter/Space when focused triggers expansion.
- `role="button"`, `aria-label="Expand N unchanged lines"`, `tabindex="0"`.
- Expansion animation: separator fades out (100ms), hidden lines expand in (150ms ease-out).

#### `DiffEmptyState` (new)

> Implements: `FR-diff-empty-state`, `AC-diff-no-changes`

Displayed when the diff computation finds zero changes.

**Props**:
- `onSwitchToFile: () => void` -- callback to switch back to file view.

Renders a centered message with an icon, title, description, and "Switch to File view" button.

#### `DiffLoadingState` (new)

> Implements: `FR-diff-baseline-fetch`

Displayed while the baseline is being fetched from the server. Centered spinner with "Loading baseline..." text.

#### `DiffErrorState` (new)

> Implements: `FR-diff-baseline-fetch`

Displayed when the baseline fetch fails (non-404 errors). Shows an error banner with a "Retry" link.

**Props**:
- `errorMessage: string` -- the error message to display.
- `onRetry: () => void` -- callback to retry the fetch.

#### `Toolbar` (modified)

The existing `Toolbar` component is extended to render the `ViewModeToggle` and `RefreshButton` when a file is loaded. The comment count display, navigation, and Generate/Copy/Clear buttons continue to work as before, but they now read from the active mode's comment set.

**Changes**:
- After the title, render `ViewModeToggle` when `hasFile === true`.
- After the toggle, render `RefreshButton` when `viewMode === 'diff'`.
- Comment count reads from `viewMode === 'diff' ? diffCommentCount : fileCommentCount`.
- Comment navigation dispatches `navigateComment` or `navigateDiffComment` based on `viewMode`.
- Generate button calls `generatePrompt` or `generateDiffPrompt` based on `viewMode`.

#### `App` (modified)

> Implements: `AC-diff-switch-clears-comments`

The `App` component is modified to:

1. Conditionally render `CodeViewer` or diff-related components based on `viewMode`.
2. Handle mode-switch confirmation dialogs: when the user clicks a toggle segment, check if comments exist in the current mode. If so, show a `ConfirmationDialog` with the mode-switch warning. On confirm, clear comments and switch mode. On cancel, do nothing.
3. Handle refresh confirmation dialogs similarly.
4. Set `fileSource` when loading a file. The `useFileFromUrl` hook sets `fileSource: 'server'` on successful API load. The `FileDropZone` sets `fileSource: 'local'` on paste/upload/drag-and-drop.

#### `CommentBubble` (reused with modification)

The existing `CommentBubble` component is reused in diff mode. The line label formatting is extended:

- File mode: "Line N" or "Lines N-M" (existing behavior).
- Diff mode: "Line +N" (added), "Line -N" (removed), "Line N" (context), or range variants like "Lines +4 to +7", "Lines -10 to +7".

The component receives a `label: string` prop computed by the parent (`DiffViewer` or `CodeViewer`). This is a non-breaking change -- the existing `CodeViewer` passes the label the same way it does today.

---

## State Management

### Zustand Store Additions

The store at `src/store/appStore.ts` is extended with new state and actions. Existing state and actions are unchanged.

#### New State Fields

Added to `initialState`:

```typescript
const initialDiffState = {
  viewMode: 'file' as const,
  fileSource: null as FileSource | null,
  baselineContent: null as string | null,
  diffLines: null as DiffLine[] | null,
  collapsedSections: null as CollapsedSection[] | null,
  expandedSections: new Set<number>(),
  isBaselineLoading: false,
  baselineError: null as string | null,
  isDiffEmpty: false,
  diffComments: {} as Record<string, DiffComment>,
  diffCommentOrder: [] as string[],
  focusedDiffCommentId: null as string | null,
  diffSelectedRange: null as { startIndex: number; endIndex: number } | null,
  diffEditorState: null as DiffEditorState | null,
};
```

When `loadFile` is called, these fields are reset to their initial values. When `clearSession` is called, all state (including diff state) is reset.

#### New Actions

```typescript
interface DiffActions {
  // View mode
  setViewMode: (mode: 'file' | 'diff') => void;
  setFileSource: (source: FileSource) => void;

  // Baseline
  fetchBaseline: () => Promise<void>;

  // Diff computation
  computeDiff: () => void;

  // Expand/collapse
  expandSection: (sectionIndex: number) => void;

  // Diff comments
  addDiffComment: (startIndex: number, endIndex: number, text: string) => void;
  updateDiffComment: (commentId: string, text: string) => void;
  deleteDiffComment: (commentId: string) => void;
  clearDiffComments: () => void;

  // Diff navigation
  navigateDiffComment: (direction: 'next' | 'prev') => void;
  setFocusedDiffComment: (commentId: string | null) => void;

  // Diff selection
  setDiffSelectedRange: (range: { startIndex: number; endIndex: number } | null) => void;

  // Diff editor
  openDiffEditor: (state: DiffEditorState) => void;
  closeDiffEditor: () => void;

  // Diff prompt
  generateDiffPrompt: () => void;

  // Refresh
  refreshDiff: () => Promise<void>;
}
```

#### Action Semantics

- **`setViewMode(mode)`**: Sets `viewMode`. Does NOT clear comments -- the caller is responsible for calling `clearDiffComments()` or clearing file-mode comments before switching, after showing a confirmation dialog if needed. When switching to `'diff'`, triggers `fetchBaseline()` if `baselineContent` is null.

- **`setFileSource(source)`**: Sets `fileSource`. Called by `useFileFromUrl` (sets `'server'`) or `FileDropZone` load handlers (sets `'local'`).

- **`fetchBaseline()`**: Sets `isBaselineLoading: true`, fetches `GET /api/file/head?path=<path>`, stores the result in `baselineContent`, then calls `computeDiff()`. On 404 (untracked file), sets `baselineContent` to `''` (empty string) and computes diff (all lines as additions). On other errors, sets `baselineError` with the error message. Always sets `isBaselineLoading: false` at the end.

- **`computeDiff()`**: Takes `baselineContent` and `file.content`, computes the diff using jsdiff's `structuredPatch`, transforms the result into `DiffLine[]`, computes `CollapsedSection[]`, and stores both. Sets `isDiffEmpty: true` if no changes found. Resets `expandedSections` to an empty set. See the Diff Algorithm section for details.

- **`expandSection(sectionIndex)`**: Adds `sectionIndex` to `expandedSections`. This triggers a recomputation of the display items array (collapsed sections that are in `expandedSections` are replaced with their constituent lines). Per `FR-diff-expand`, there is no mechanism to re-collapse.

- **`addDiffComment(startIndex, endIndex, text)`**: Creates a `DiffComment` with a UUID, computes the `DiffLineId` for start and end from `diffLines[startIndex]` and `diffLines[endIndex]`, inserts into `diffComments`, recomputes `diffCommentOrder`. Sets `isPromptStale: true` if a prompt exists. Closes the diff editor and clears the diff selection.

- **`clearDiffComments()`**: Resets `diffComments` to `{}`, `diffCommentOrder` to `[]`, `focusedDiffCommentId` to `null`.

- **`navigateDiffComment(direction)`**: Same wrapping logic as `navigateComment` but operates on `diffCommentOrder` and `focusedDiffCommentId`.

- **`generateDiffPrompt()`**: Calls the pure `buildDiffPrompt()` function (see Prompt Builder section) and stores the result in `generatedPrompt`. Sets `isPromptStale: false`.

- **`refreshDiff()`**: Re-fetches the working copy via `GET /api/file?path=<path>`, updates `file.content` and `file.lines`, re-fetches the baseline via `fetchBaseline()`, and recomputes the diff. Clears all diff comments (caller handles confirmation).

#### Integration with Existing Actions

- **`loadFile`**: Modified to also reset all diff state (`initialDiffState`). The `viewMode` resets to `'file'` on every new file load.

- **`generatePrompt`**: Unchanged. Only generates file-mode prompts. Diff-mode prompt generation uses the separate `generateDiffPrompt` action.

- **`clearSession`**: Already resets the entire store. Extended to include diff state in the reset.

### Data Flow for Diff Mode

```
User clicks "Diff" toggle
  --> App shows confirmation if file-mode comments exist
    --> On confirm: store.clearComments(), store.setViewMode('diff')
      --> setViewMode triggers fetchBaseline()
        --> Fetch GET /api/file/head?path=...
          --> On success: store baselineContent, call computeDiff()
            --> computeDiff produces diffLines and collapsedSections
              --> DiffViewer renders with virtualized diff lines
```

```
User clicks gutter in DiffViewer
  --> store.openDiffEditor({ mode: 'create', startIndex, endIndex })
    --> InlineCommentEditor renders below the target line
      --> User submits --> store.addDiffComment(startIndex, endIndex, text)
        --> DiffComment created, diffCommentOrder updated
          --> DiffViewer re-renders with comment bubble
```

```
User clicks "Generate" in diff mode
  --> store.generateDiffPrompt()
    --> buildDiffPrompt(file, diffLines, diffComments, preamble, collapsedSections, expandedSections)
      --> Returns prompt string with unified diff notation
        --> Stored in generatedPrompt, displayed in PromptPreview
```

---

## Diff Algorithm

> Implements: `FR-diff-compute`, `NFR-diff-compute-perf`, `NFR-diff-client-compute`

### Library: `diff` (jsdiff)

The `diff` npm package provides `structuredPatch(oldFileName, newFileName, oldContent, newContent, oldHeader, newHeader, options)` which returns a patch object with an array of hunks. Each hunk contains:

```typescript
interface Hunk {
  oldStart: number;  // Starting line in old file (1-indexed)
  oldLines: number;  // Number of lines from old file in this hunk
  newStart: number;  // Starting line in new file (1-indexed)
  newLines: number;  // Number of lines from new file in this hunk
  lines: string[];   // Lines with +/- / space prefix
}
```

### Diff Computation Pipeline

The diff computation is implemented as a pure function in `src/lib/diffCompute.ts`:

```typescript
// Implements: FR-diff-compute, NFR-diff-compute-perf

import { structuredPatch } from 'diff';

interface DiffResult {
  diffLines: DiffLine[];
  collapsedSections: CollapsedSection[];
  isEmpty: boolean;
}

const DEFAULT_CONTEXT_LINES = 3;

export function computeFileDiff(
  oldContent: string,
  newContent: string,
  contextLines: number = DEFAULT_CONTEXT_LINES,
): DiffResult {
  // Step 1: Compute the structured patch with full context
  // We request a large context so we get ALL lines, then handle collapsing ourselves
  const patch = structuredPatch(
    'old', 'new',
    oldContent, newContent,
    '', '',
    { context: Infinity },  // Get all context lines
  );

  // Step 2: Transform patch hunks into DiffLine[]
  const diffLines = transformHunksToDiffLines(patch.hunks);

  // Step 3: If no changes detected, return empty
  const hasChanges = diffLines.some(l => l.type !== 'context');
  if (!hasChanges) {
    return { diffLines: [], collapsedSections: [], isEmpty: true };
  }

  // Step 4: Compute collapsed sections
  const collapsedSections = computeCollapsedSections(diffLines, contextLines);

  return { diffLines, collapsedSections, isEmpty: false };
}
```

### Step 2: Transform Hunks to DiffLines

```typescript
function transformHunksToDiffLines(hunks: Hunk[]): DiffLine[] {
  const lines: DiffLine[] = [];
  let index = 0;

  for (const hunk of hunks) {
    let oldLine = hunk.oldStart;
    let newLine = hunk.newStart;

    for (const line of hunk.lines) {
      const prefix = line[0];
      const content = line.substring(1);

      if (prefix === '+') {
        lines.push({
          index,
          type: 'added',
          oldLineNumber: null,
          newLineNumber: newLine,
          content,
        });
        newLine++;
      } else if (prefix === '-') {
        lines.push({
          index,
          type: 'removed',
          oldLineNumber: oldLine,
          newLineNumber: null,
          content,
        });
        oldLine++;
      } else {
        // Context line (space prefix or no prefix)
        lines.push({
          index,
          type: 'context',
          oldLineNumber: oldLine,
          newLineNumber: newLine,
          content,
        });
        oldLine++;
        newLine++;
      }
      index++;
    }
  }

  return lines;
}
```

### Step 4: Compute Collapsed Sections

> Implements: `FR-diff-collapse`, `AC-diff-collapse-default`

The collapse algorithm identifies contiguous runs of context lines that should be hidden. The rules from the design spec:

1. Between two adjacent change hunks, if the gap of unchanged lines is greater than `2 * contextLines + 1` (default 7), the middle portion is collapsed.
2. If the gap is `2 * contextLines + 1` or fewer (default 7), all lines are shown without collapsing.
3. At the top of the file, context lines before the first change are collapsed (keeping `contextLines` trailing lines visible before the first change).
4. At the bottom of the file, context lines after the last change are collapsed (keeping `contextLines` leading lines visible after the last change).

```typescript
function computeCollapsedSections(
  diffLines: DiffLine[],
  contextLines: number,
): CollapsedSection[] {
  const sections: CollapsedSection[] = [];

  // Find all change indices (non-context lines)
  const changeIndices: number[] = [];
  for (let i = 0; i < diffLines.length; i++) {
    if (diffLines[i].type !== 'context') {
      changeIndices.push(i);
    }
  }

  if (changeIndices.length === 0) return [];

  const firstChange = changeIndices[0];
  const lastChange = changeIndices[changeIndices.length - 1];

  // Leading context (before first change)
  if (firstChange > contextLines) {
    sections.push({
      startIndex: 0,
      endIndex: firstChange - contextLines - 1,
      lineCount: firstChange - contextLines,
    });
  }

  // Gaps between change regions
  // A "change region" is a maximal contiguous block of non-context lines
  // (possibly with context lines interleaved, but bounded by context-only gaps)
  let i = 0;
  while (i < changeIndices.length) {
    // Find the end of this change region
    let regionEnd = changeIndices[i];
    let j = i + 1;
    while (j < changeIndices.length && changeIndices[j] - regionEnd <= 2 * contextLines + 1) {
      regionEnd = changeIndices[j];
      j++;
    }

    // Now look at the gap between this region and the next
    if (j < changeIndices.length) {
      const gapStart = regionEnd + 1;
      const gapEnd = changeIndices[j] - 1;
      const gapSize = gapEnd - gapStart + 1;

      if (gapSize > 2 * contextLines + 1) {
        // Collapse the middle of the gap
        const collapseStart = gapStart + contextLines;
        const collapseEnd = gapEnd - contextLines;
        sections.push({
          startIndex: collapseStart,
          endIndex: collapseEnd,
          lineCount: collapseEnd - collapseStart + 1,
        });
      }
    }

    i = j;
  }

  // Trailing context (after last change)
  const trailingStart = lastChange + contextLines + 1;
  if (trailingStart < diffLines.length) {
    sections.push({
      startIndex: trailingStart,
      endIndex: diffLines.length - 1,
      lineCount: diffLines.length - trailingStart,
    });
  }

  return sections;
}
```

### Building the Display Items Array

The `DiffViewer` computes its display items by walking `diffLines`, checking each line against the collapsed sections and expanded sections:

```typescript
function buildDiffDisplayItems(
  diffLines: DiffLine[],
  collapsedSections: CollapsedSection[],
  expandedSections: Set<number>,
  diffComments: Record<string, DiffComment>,
  diffCommentOrder: string[],
  diffEditorState: DiffEditorState | null,
): DiffDisplayItem[] {
  const items: DiffDisplayItem[] = [];

  // Build a set of line indices that are collapsed (and not expanded)
  const collapsedRanges: Map<number, { section: CollapsedSection; sectionIndex: number }> = new Map();
  for (let si = 0; si < collapsedSections.length; si++) {
    if (!expandedSections.has(si)) {
      collapsedRanges.set(collapsedSections[si].startIndex, {
        section: collapsedSections[si],
        sectionIndex: si,
      });
    }
  }

  // Map of endIndex -> comments that render after that line
  const commentsAfterIndex = new Map<number, DiffComment[]>();
  for (const id of diffCommentOrder) {
    const comment = diffComments[id];
    if (!comment) continue;
    const existing = commentsAfterIndex.get(comment.endIndex) ?? [];
    existing.push(comment);
    commentsAfterIndex.set(comment.endIndex, existing);
  }

  const editorAfterIndex = diffEditorState
    ? diffEditorState.mode === 'create'
      ? diffEditorState.endIndex
      : (diffComments[diffEditorState.commentId]?.endIndex ?? null)
    : null;

  let i = 0;
  while (i < diffLines.length) {
    // Check if this index starts a collapsed (non-expanded) section
    const collapsed = collapsedRanges.get(i);
    if (collapsed) {
      items.push({
        type: 'collapsed-section',
        section: collapsed.section,
        sectionIndex: collapsed.sectionIndex,
      });
      i = collapsed.section.endIndex + 1;
      continue;
    }

    // Regular diff line
    const line = diffLines[i];
    items.push({ type: 'diff-line', line });

    // Comments after this line
    const lineComments = commentsAfterIndex.get(i);
    if (lineComments) {
      for (const comment of lineComments) {
        items.push({ type: 'diff-comment-bubble', comment });
      }
    }

    // Editor after this line
    if (editorAfterIndex === i && diffEditorState) {
      items.push({
        type: 'diff-editor',
        startIndex: diffEditorState.mode === 'create'
          ? diffEditorState.startIndex
          : (diffComments[diffEditorState.commentId]?.startIndex ?? i),
        endIndex: i,
        mode: diffEditorState.mode,
        commentId: diffEditorState.mode === 'edit' ? diffEditorState.commentId : undefined,
      });
    }

    i++;
  }

  return items;
}
```

### Performance (`NFR-diff-compute-perf`)

**Target**: Under 500ms for files up to 10,000 lines. Under 2 seconds for 10,000-50,000 lines.

**Analysis**:
- jsdiff's `structuredPatch` uses a modified Myers algorithm. For two 10,000-line files with moderate differences (<20% changed), computation takes approximately 50-200ms on a modern desktop browser (Chrome/V8).
- The `transformHunksToDiffLines` step is O(total lines) -- a single pass.
- The `computeCollapsedSections` step is O(change count) -- typically much smaller than total lines.
- Total expected time for 10,000 lines: 100-300ms, well within the 500ms budget.

**Web Worker escape hatch**: For v1, the diff runs on the main thread. If profiling shows blocking for files approaching 50,000 lines, the `computeFileDiff` function can be moved to a Web Worker without changing its interface. The function is already pure (no DOM access, no store access) and accepts/returns serializable data, making it trivially transferable to a worker. The store action `computeDiff()` would change from a synchronous call to an async one that posts a message to the worker and awaits the result. No component changes would be needed because the store already exposes `diffLines` as state -- components are agnostic to how it was computed.

---

## Prompt Builder Changes

> Implements: `FR-diff-prompt-format`, `AC-diff-prompt-includes-diff`

### New Function: `buildDiffPrompt`

A new pure function in `src/lib/promptBuilder.ts`, alongside the existing `buildPrompt`:

```typescript
// Implements: FR-diff-prompt-format, AC-diff-prompt-includes-diff

export function buildDiffPrompt(
  file: FileInfo,
  diffLines: DiffLine[],
  comments: DiffComment[],
  preamble: string,
  collapsedSections: CollapsedSection[],
  expandedSections: Set<number>,
): string {
  const sections: string[] = [];

  // Instructions section (only if preamble is non-empty)
  const trimmedPreamble = preamble.trim();
  if (trimmedPreamble) {
    sections.push(`## Instructions\n\n${trimmedPreamble}`);
  }

  // File heading with "-- Diff View" suffix
  sections.push(`## File: ${file.name} (${file.language}) -- Diff View`);

  // Diff notation explanation (fixed, always included)
  sections.push(
    'The following shows changes between the git HEAD version and the current working copy.\n' +
    'Lines prefixed with `+` are additions. Lines prefixed with `-` are removals. Unmarked lines are unchanged context.'
  );

  // Build the diff code block
  const diffBlock = buildDiffBlock(diffLines, collapsedSections, expandedSections);
  sections.push('```diff\n' + diffBlock + '\n```');

  // Requested Changes section
  const sorted = [...comments].sort((a, b) => {
    if (a.startIndex !== b.startIndex) return a.startIndex - b.startIndex;
    return a.createdAt.localeCompare(b.createdAt);
  });

  if (sorted.length > 0) {
    const changeEntries = sorted.map((c) => {
      const label = formatDiffCommentLabel(c);
      const typeDesc = formatDiffCommentTypeDesc(c, diffLines);
      return `- **${label}** (${typeDesc}): ${c.text}`;
    });

    sections.push('## Requested Changes\n\n' + changeEntries.join('\n'));
  }

  return sections.join('\n\n');
}
```

### Diff Block Formatting

The diff block includes all visible lines (context + changes) and collapsed-section markers:

```typescript
function buildDiffBlock(
  diffLines: DiffLine[],
  collapsedSections: CollapsedSection[],
  expandedSections: Set<number>,
): string {
  const output: string[] = [];

  // Build collapsed index set (non-expanded sections)
  const collapsedStarts = new Map<number, CollapsedSection>();
  const collapsedIndices = new Set<number>();
  for (let si = 0; si < collapsedSections.length; si++) {
    const section = collapsedSections[si];
    if (!expandedSections.has(si)) {
      collapsedStarts.set(section.startIndex, section);
      for (let j = section.startIndex; j <= section.endIndex; j++) {
        collapsedIndices.add(j);
      }
    }
  }

  let i = 0;
  while (i < diffLines.length) {
    if (collapsedStarts.has(i)) {
      const section = collapsedStarts.get(i)!;
      output.push(`@@ ... ${section.lineCount} unchanged lines ... @@`);
      i = section.endIndex + 1;
      continue;
    }

    if (collapsedIndices.has(i)) {
      i++;
      continue;
    }

    const line = diffLines[i];
    const prefix = line.type === 'added' ? '+' : line.type === 'removed' ? '-' : ' ';
    const lineNum = line.type === 'removed'
      ? String(line.oldLineNumber).padStart(4)
      : String(line.newLineNumber).padStart(4);
    output.push(`${prefix}${lineNum} | ${line.content}`);
    i++;
  }

  return output.join('\n');
}
```

### Comment Label Formatting

```typescript
function formatDiffCommentLabel(comment: DiffComment): string {
  const startLabel = formatLineRef(comment.startLineId);
  if (comment.startIndex === comment.endIndex) {
    return `Line ${startLabel}`;
  }
  const endLabel = formatLineRef(comment.endLineId);
  return `Lines ${startLabel} to ${endLabel}`;
}

function formatLineRef(lineId: DiffLineId): string {
  if (lineId.lineType === 'added') return `+${lineId.newLine}`;
  if (lineId.lineType === 'removed') return `-${lineId.oldLine}`;
  return String(lineId.newLine);  // Context lines use new line number
}

function formatDiffCommentTypeDesc(
  comment: DiffComment,
  diffLines: DiffLine[],
): string {
  const types = new Set<string>();
  for (let i = comment.startIndex; i <= comment.endIndex; i++) {
    if (diffLines[i]) types.add(diffLines[i].type);
  }
  if (types.size > 1) return 'mixed';
  const only = [...types][0];
  return only;  // 'added', 'removed', or 'context'
}
```

### Existing `buildPrompt` -- No Changes

The existing `buildPrompt` function is unchanged. It continues to be called when `viewMode === 'file'`. The store's `generatePrompt` action calls `buildPrompt`; the new `generateDiffPrompt` action calls `buildDiffPrompt`.

---

## Error Handling

| Error Case | Detection | User Impact | Recovery |
|---|---|---|---|
| Baseline fetch: no git repo | 404 from `/api/file/head` with "Not a git repository" | `DiffErrorState` with message and "Retry" link | User retries or switches to file view |
| Baseline fetch: untracked file | 404 from `/api/file/head` with "no git history" | All lines shown as additions (green). No error. | Normal behavior per `AC-diff-no-git-history` |
| Baseline fetch: binary at HEAD | 415 from `/api/file/head` | `DiffErrorState` with message | User switches to file view |
| Baseline fetch: network error | `fetch` throws or returns non-JSON | `DiffErrorState` with generic message | User retries |
| Baseline fetch: server error | 500 from `/api/file/head` | `DiffErrorState` with server message | User retries |
| Diff computation: empty | `structuredPatch` returns no changes | `DiffEmptyState` with "No changes detected" | User switches to file view |
| Git command timeout | `execSync` times out (5s) | 500 error propagated to client | User retries; if persistent, check git status |
| `git show` output too large | `maxBuffer` exceeded (50 MB) | 500 error: "File too large" | User uses file view instead |

**Error state transitions**: When `baselineError` is set, the `DiffErrorState` component renders. The "Retry" link calls `fetchBaseline()` again, which clears `baselineError` on success. The user can always switch to file view via the toggle regardless of error state.

**Graceful degradation**: If the diff view is unavailable for any reason, the file view remains fully functional. The diff toggle shows its disabled state and the user can still review the full file and add comments.

---

## Performance Considerations

### Diff Computation (`NFR-diff-compute-perf`)

| File Size | Expected Time | Strategy |
|---|---|---|
| < 1,000 lines | < 20ms | Main thread, synchronous |
| 1,000 - 10,000 lines | 50-300ms | Main thread, synchronous |
| 10,000 - 50,000 lines | 300ms - 2s | Main thread for v1; Web Worker if >500ms observed |
| > 50,000 lines | > 2s | Web Worker (future) |

The `computeFileDiff` function is already pure and serializable, making it trivially movable to a Web Worker. The migration path:

1. Create `src/workers/diffWorker.ts` that imports `computeFileDiff`.
2. In the store's `computeDiff` action, post `{ oldContent, newContent, contextLines }` to the worker.
3. On message back, set `diffLines` and `collapsedSections` in the store.
4. Show a loading indicator while the worker computes.

No component changes needed -- the store API remains the same.

### Rendering (`NFR-diff-render-perf`)

The `DiffViewer` uses TanStack Virtual with the same configuration as `CodeViewer`:

- **Row height**: Code lines = 20px (fixed). Collapsed sections = 36px (fixed). Comment bubbles and editors = dynamic (measured via `ResizeObserver`).
- **Overscan**: 20 rows above and below viewport.
- **DOM node count**: ~90 nodes at any time for a 10,000-line diff visible at 50 lines/viewport.
- **Re-renders on expand**: When a collapsed section is expanded, the virtualizer's item count changes. TanStack Virtual handles this natively -- it recomputes positions from the changed items array.

### Baseline Fetch (`NFR-diff-baseline-fetch-speed`)

Target: under 500ms for files up to 10,000 lines.

`git show HEAD:<path>` reads from the git object store, which is typically memory-mapped. For a 10,000-line file (~500 KB), the subprocess overhead is the dominant cost (~50ms for process spawn + stdout pipe). Total expected time: 50-100ms, well within the 500ms budget.

### Syntax Highlighting

Both the old and new file versions need to be highlighted. However, the diff only displays a subset of lines from each version. The approach:

1. Highlight the full working copy content (already done by the existing `CodeViewer` logic).
2. Highlight the baseline content separately using the same `highlightCode` function.
3. In the `DiffViewer`, map each diff line to its corresponding token array: added lines use tokens from the new file's highlighting, removed lines use tokens from the old file's highlighting, context lines use tokens from the new file's highlighting (they are identical in both).

This requires two `highlightCode` calls, but each is independent and can run concurrently. The progressive highlighting strategy from the existing spec applies: render raw text first, apply tokens when ready.

### Memory

A 10,000-line file's diff adds:
- Baseline content: ~500 KB (same as working copy).
- DiffLine array: ~10,000 objects at ~100 bytes each = ~1 MB.
- Collapsed sections: negligible (typically <100 objects).
- Highlight tokens for baseline: ~1 MB (same as working copy tokens).
- Total additional memory for diff: ~2.5 MB. Combined with the existing ~3 MB for the working copy and its tokens, total is ~5.5 MB. Trivial for a browser tab.

---

## Security Considerations

### File API (`/api/file/head`)

The new endpoint has the same security posture as the existing `/api/file` endpoint:

1. **Localhost binding**: The Vite dev server binds to `127.0.0.1` by default. The endpoint is not accessible from other machines.

2. **Same-origin enforcement**: No CORS headers. Cross-origin requests are blocked by the browser.

3. **No directory listing**: The endpoint only accepts explicit file paths. `git show` returns a single file's content, not directory listings.

4. **No file writing**: Read-only. `git show` does not modify the repository.

5. **Binary detection**: The HEAD content is checked for binary data before returning, preventing accidental exposure of binary content.

6. **Command injection**: The `path` parameter is passed to `git show` via `execSync`. The path is resolved via `path.resolve()` and `path.relative()`, not interpolated into the command string. However, the current implementation does use string interpolation in the `git show HEAD:${relativePath}` call. To prevent command injection, the relative path must be validated:
   - Reject paths containing shell metacharacters (`` ` ``, `$`, `;`, `|`, `&`, `(`, `)`, etc.).
   - Alternatively, use `execFileSync('git', ['show', `HEAD:${relativePath}`])` instead of `execSync` to avoid shell interpretation entirely. **This is the recommended approach.**

   The implementation should use `execFileSync` for both `git rev-parse` and `git show`:

   ```typescript
   import { execFileSync } from 'child_process';

   // Instead of: execSync('git rev-parse --show-toplevel', ...)
   gitRoot = execFileSync('git', ['rev-parse', '--show-toplevel'], {
     cwd: path.dirname(resolved),
     encoding: 'utf-8',
     timeout: 5000,
   }).trim();

   // Instead of: execSync(`git show HEAD:${relativePath}`, ...)
   headContent = execFileSync('git', ['show', `HEAD:${relativePath}`], {
     cwd: gitRoot,
     timeout: 5000,
     maxBuffer: 50 * 1024 * 1024,
   });
   ```

   `execFileSync` does not spawn a shell, so shell metacharacters in the path are treated as literal characters.

7. **Path traversal**: The `relativePath` computed via `path.relative(gitRoot, resolved)` could theoretically contain `..` segments if the file is outside the git repository. However, `git show HEAD:../foo` would fail because git rejects paths that escape the tree root. This is a safe fallback -- git itself prevents traversal.

---

## Implementation Plan

The work is divided into four phases. Each phase produces a testable increment. Phases are ordered by dependency: the API must exist before the client can use it, the diff computation must work before the viewer can render, and the viewer must render before comments can be added.

### Phase 1: API Endpoint and Diff Computation (estimated 2-3 days)

**Goal**: The server can serve HEAD versions of files, and the client can compute diffs.

1. **Add `diff` dependency**: `pnpm add diff` in `engineering/apps/web/`. Also add `@types/diff` for TypeScript types.

2. **Extend `fileApiPlugin.ts`**: Add the `GET /api/file/head` route handler. Implement `handleHeadRequest` with git-relative path resolution, `execFileSync('git', ['show', ...])`, binary detection, and error handling. Update the routing to use exact pathname matching for both `/api/file` and `/api/file/head`.

3. **Add new types**: Add `DiffLineId`, `DiffLine`, `CollapsedSection`, `DiffComment`, `DiffDisplayItem`, `DiffEditorState`, `DiffState`, and `FileSource` to `src/types/index.ts`.

4. **Implement `diffCompute.ts`**: Create `src/lib/diffCompute.ts` with `computeFileDiff`, `transformHunksToDiffLines`, and `computeCollapsedSections`. Write unit tests covering: empty diff, all-added (untracked file), all-removed, mixed changes, collapse rules (gap > 7 shows separator, gap <= 7 shows all lines), leading/trailing context collapse.

5. **Extend Zustand store**: Add `initialDiffState` fields and all diff-related actions to `appStore.ts`. Write unit tests for `fetchBaseline` (mocked fetch), `computeDiff`, `expandSection`, `addDiffComment`, `clearDiffComments`, `setViewMode`.

6. **Set `fileSource`**: Modify `useFileFromUrl` to call `store.setFileSource('server')` on successful API load. Modify `FileDropZone` load handlers to call `store.setFileSource('local')`.

**Delivers**: The store can fetch a baseline, compute a diff, and manage diff state. No UI changes yet.

**Slug coverage**: `FR-diff-baseline-fetch`, `FR-diff-compute`, `NFR-diff-compute-perf`, `NFR-diff-client-compute`, `NFR-diff-baseline-fetch-speed`.

### Phase 2: Diff Viewer Rendering (estimated 3-4 days)

**Goal**: The user can toggle to diff view and see a rendered unified diff with collapsed sections.

1. **Build `ViewModeToggle`**: Implement the segmented control component per the design spec. Wire into `Toolbar`.

2. **Build `RefreshButton`**: Implement the refresh icon button. Wire into `Toolbar`, visible only in diff mode.

3. **Build `DiffViewer`**: Implement the virtualized diff viewer with dual line numbers, type indicators, colored backgrounds, and syntax highlighting. Use TanStack Virtual with the `DiffDisplayItem` array. Handle the expanded gutter layout (140px).

4. **Build `CollapsedSectionSeparator`**: Implement the collapsible section row with expand behavior and animation.

5. **Build `DiffEmptyState`**: Implement the empty diff message.

6. **Build `DiffLoadingState`** and **`DiffErrorState`**: Loading spinner and error banner.

7. **Modify `App.tsx`**: Conditionally render `CodeViewer` or diff-mode components based on `viewMode`. Handle mode-switch confirmation dialogs.

8. **Highlight baseline**: Extend the highlighting integration to also highlight `baselineContent`. Map diff lines to the correct token arrays.

**Delivers**: User can toggle between file and diff view. Diff renders with colors, line numbers, collapsible sections. Mode switch shows confirmation if comments exist.

**Slug coverage**: `FR-diff-mode-toggle`, `FR-diff-mode-availability`, `FR-diff-display`, `FR-diff-collapse`, `FR-diff-expand`, `FR-diff-empty-state`, `FR-diff-refresh`, `AC-diff-toggle-to-diff`, `AC-diff-toggle-to-file`, `AC-diff-collapse-default`, `AC-diff-expand-section`, `AC-diff-no-git-history`, `AC-diff-no-changes`, `AC-diff-paste-upload-disabled`, `AC-diff-line-numbers`, `AC-diff-syntax-highlight`, `AC-diff-switch-clears-comments`, `AC-diff-refresh-updates`, `NFR-diff-render-perf`.

### Phase 3: Diff Comments and Prompt Generation (estimated 3-4 days)

**Goal**: Users can add comments on diff lines and generate diff-aware prompts.

1. **Diff comment creation**: Wire the `DiffViewer` gutter click handler to `openDiffEditor`. Reuse `InlineCommentEditor` component (it already handles text input, submit, cancel). On submit, call `addDiffComment`.

2. **Diff comment display**: Render `CommentBubble` components in the diff view with diff-aware line labels. Extend `CommentBubble` to accept a `label` prop.

3. **Range selection in diff view**: Implement mouse drag and Shift+click selection in `DiffViewer`, respecting the constraint that ranges cannot span collapsed sections.

4. **Comment navigation in diff mode**: Wire toolbar prev/next buttons to `navigateDiffComment`. Implement `scrollToIndex` for focused diff comments.

5. **Implement `buildDiffPrompt`**: Add the function to `promptBuilder.ts`. Write unit tests covering: single comment on added line, comment on removed line, comment on context line, range comment, multiple comments, prompt with/without preamble, collapsed sections in diff block.

6. **Wire Generate button**: In diff mode, the Generate button calls `generateDiffPrompt` instead of `generatePrompt`. The `PromptPreview` and Copy button work unchanged (they read `generatedPrompt` from the store).

**Delivers**: Complete diff-mode workflow: toggle to diff, view changes, add comments, generate prompt, copy prompt.

**Slug coverage**: `FR-diff-comment-create`, `FR-diff-comment-on-range`, `FR-diff-prompt-format`, `AC-diff-comment-added-line`, `AC-diff-comment-removed-line`, `AC-diff-comment-context-line`, `AC-diff-prompt-includes-diff`, `AC-diff-comment-range`, `AC-diff-expand-then-comment`.

### Phase 4: Accessibility, Polish, and Testing (estimated 2-3 days)

**Goal**: Full keyboard accessibility, animations, and comprehensive test coverage.

1. **Keyboard navigation in `DiffViewer`**: Implement ArrowUp/Down line focus, Enter/`c` to open editor, Shift+Arrow for range selection, Enter/Space on collapsed sections to expand, Escape to clear selection.

2. **ARIA attributes**: Add `role="grid"`, `role="row"`, `role="rowheader"`, `role="gridcell"`, `role="button"`, `aria-label`, `aria-selected`, `aria-disabled` per the design spec's accessibility section.

3. **Focus management**: Focus moves to first visible diff line after switching to diff mode. Focus moves to first revealed line after expanding a section. Focus moves to "Switch to File view" button in empty diff state.

4. **Animations**: Collapsed section expand animation (fade out 100ms, height expand 150ms). Refresh button spin animation while loading. Toggle segment transition.

5. **E2E tests (Playwright)**: Full flows: toggle to diff, collapse/expand, add comment on added/removed/context line, range comment, generate prompt, refresh, mode switch confirmation, untracked file, empty diff.

6. **Component tests**: `ViewModeToggle`, `DiffViewer`, `CollapsedSectionSeparator`, `DiffEmptyState`.

7. **Unit tests**: `computeFileDiff` edge cases, `buildDiffPrompt` format validation, store action behavior.

**Delivers**: Fully accessible, polished diff view feature meeting all FR, NFR, and AC requirements.

**Slug coverage**: `NFR-diff-accessibility`, `AC-diff-expand-then-comment`.

---

## Project Structure

New and modified files:

```
engineering/
  diff-view.md                                  NEW -- this spec
  apps/
    web/
      package.json                              MODIFIED -- add 'diff' dependency
      src/
        App.tsx                                 MODIFIED -- conditional diff/file rendering, mode switch dialogs
        types/
          index.ts                              MODIFIED -- add diff-related types
        store/
          appStore.ts                           MODIFIED -- add diff state and actions
        lib/
          diffCompute.ts                        NEW -- diff computation (structuredPatch + collapse logic)
          promptBuilder.ts                      MODIFIED -- add buildDiffPrompt function
        components/
          Toolbar.tsx                           MODIFIED -- add ViewModeToggle and RefreshButton
          ViewModeToggle.tsx                    NEW -- segmented File/Diff control
          RefreshButton.tsx                     NEW -- diff refresh button
          DiffViewer.tsx                        NEW -- virtualized diff display
          CollapsedSectionSeparator.tsx         NEW -- collapsed section row
          DiffEmptyState.tsx                    NEW -- no-changes empty state
          DiffLoadingState.tsx                  NEW -- baseline loading spinner
          DiffErrorState.tsx                    NEW -- baseline fetch error
          CommentBubble.tsx                     MODIFIED -- accept label prop for diff-aware labels
        hooks/
          useFileFromUrl.ts                     MODIFIED -- set fileSource on successful load
        vite-plugins/
          fileApiPlugin.ts                      MODIFIED -- add /api/file/head route, refactor routing
        __tests__/
          unit/
            diffCompute.test.ts                 NEW
            promptBuilder.test.ts               MODIFIED -- add buildDiffPrompt tests
            appStore.test.ts                    MODIFIED -- add diff action tests
          component/
            ViewModeToggle.test.tsx              NEW
            DiffViewer.test.tsx                  NEW
            CollapsedSectionSeparator.test.tsx   NEW
            DiffEmptyState.test.tsx              NEW
          e2e/
            diff-view.spec.ts                   NEW
```

---

## Requirement Traceability

### Functional Requirements

| Slug | Engineering Coverage |
|---|---|
| `FR-diff-mode-toggle` | `ViewModeToggle` component; `Toolbar` integration; store `viewMode` state and `setViewMode` action; `App.tsx` conditional rendering |
| `FR-diff-mode-availability` | Store `fileSource` state; `ViewModeToggle` `isDiffEnabled` prop; `useFileFromUrl` sets `'server'`; `FileDropZone` sets `'local'` |
| `FR-diff-baseline-fetch` | `GET /api/file/head` endpoint in `fileApiPlugin.ts`; store `fetchBaseline` action; `DiffLoadingState` and `DiffErrorState` components |
| `FR-diff-compute` | `diffCompute.ts` module (`computeFileDiff`, `transformHunksToDiffLines`); `diff` npm package (`structuredPatch`); store `computeDiff` action |
| `FR-diff-display` | `DiffViewer` component; `DiffVirtualRow` with dual line numbers, type indicators, colored backgrounds; TanStack Virtual integration |
| `FR-diff-collapse` | `computeCollapsedSections` in `diffCompute.ts`; `CollapsedSectionSeparator` component; `DiffDisplayItem` collapsed-section type |
| `FR-diff-expand` | Store `expandSection` action and `expandedSections` state; `CollapsedSectionSeparator` click handler; `buildDiffDisplayItems` respects expanded set |
| `FR-diff-comment-create` | `DiffViewer` gutter click handler; store `addDiffComment` action; `DiffComment` type with `DiffLineId` anchoring; reused `InlineCommentEditor` |
| `FR-diff-comment-on-range` | `DiffViewer` range selection (mouse drag, Shift+click); store `diffSelectedRange` state; `addDiffComment` with startIndex/endIndex |
| `FR-diff-prompt-format` | `buildDiffPrompt` function in `promptBuilder.ts`; unified diff notation in code blocks; diff-aware comment labels |
| `FR-diff-empty-state` | `DiffEmptyState` component; store `isDiffEmpty` state; `computeDiff` sets flag when no changes |
| `FR-diff-refresh` | `RefreshButton` component; store `refreshDiff` action; `ConfirmationDialog` for refresh with comments |

### Non-Functional Requirements

| Slug | Engineering Coverage |
|---|---|
| `NFR-diff-compute-perf` | `diff` library performance characteristics; main-thread for v1; Web Worker escape hatch documented; pure function design enables migration |
| `NFR-diff-render-perf` | `DiffViewer` uses TanStack Virtual; fixed row heights for code lines and separators; 20-row overscan; ~90 DOM nodes at any time |
| `NFR-diff-client-compute` | Diff computed in browser via jsdiff `structuredPatch`; server provides raw text only via `/api/file` and `/api/file/head` |
| `NFR-diff-baseline-fetch-speed` | `git show HEAD:<path>` via `execFileSync`; 5s timeout; expected <100ms for typical files |
| `NFR-diff-accessibility` | Keyboard navigation in `DiffViewer`; ARIA attributes per design spec; focus management on mode switch, section expand, empty state |

### Acceptance Criteria

| Slug | Engineering Coverage |
|---|---|
| `AC-diff-toggle-to-diff` | `ViewModeToggle` click handler; store `setViewMode('diff')`; `fetchBaseline` triggered; `App.tsx` renders `DiffViewer` |
| `AC-diff-toggle-to-file` | `ViewModeToggle` click handler; store `setViewMode('file')`; `App.tsx` renders `CodeViewer`; `clearDiffComments` after confirmation |
| `AC-diff-collapse-default` | `computeCollapsedSections` with `contextLines=3`; gaps > 7 lines collapsed; `CollapsedSectionSeparator` rendered |
| `AC-diff-expand-section` | `CollapsedSectionSeparator` click/Enter/Space; store `expandSection`; separator replaced with hidden lines |
| `AC-diff-comment-added-line` | `DiffViewer` gutter click on added line; `addDiffComment` with `lineType: 'added'`; `CommentBubble` label "Line +N" |
| `AC-diff-comment-removed-line` | `DiffViewer` gutter click on removed line; `addDiffComment` with `lineType: 'removed'`; `CommentBubble` label "Line -N" |
| `AC-diff-comment-context-line` | `DiffViewer` gutter click on context line; `addDiffComment` with `lineType: 'context'`; `CommentBubble` label "Line N" |
| `AC-diff-prompt-includes-diff` | `buildDiffPrompt` produces `diff` code block with `+`/`-`/` ` prefixes; "Requested Changes" section with typed line labels |
| `AC-diff-no-git-history` | `/api/file/head` returns 404; `fetchBaseline` sets `baselineContent` to empty string; `computeDiff` shows all lines as additions |
| `AC-diff-no-changes` | `computeDiff` sets `isDiffEmpty: true`; `DiffEmptyState` renders with "No changes detected" message |
| `AC-diff-paste-upload-disabled` | `fileSource === 'local'`; `ViewModeToggle` renders "Diff" segment disabled with tooltip |
| `AC-diff-line-numbers` | `DiffViewer` renders OldLN and NewLN columns; added lines omit old number; removed lines omit new number; context lines show both |
| `AC-diff-syntax-highlight` | Shiki highlights both baseline and working copy; `DiffViewer` maps diff lines to correct token arrays |
| `AC-diff-refresh-updates` | `RefreshButton` click; confirmation if comments exist; `refreshDiff` re-fetches both versions and recomputes diff |
| `AC-diff-switch-clears-comments` | `App.tsx` shows `ConfirmationDialog` on mode switch when comments exist; on confirm: clear comments, switch mode; on cancel: no change |
| `AC-diff-comment-range` | `DiffViewer` range selection; `addDiffComment` with startIndex != endIndex; `CommentBubble` range label format |
| `AC-diff-expand-then-comment` | After `expandSection`, revealed lines are regular diff-line display items; gutter click works identically to other context lines |
