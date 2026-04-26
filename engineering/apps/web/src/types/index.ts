// Implements: FR-crp-line-comment-create, FR-crp-line-comment-edit, FR-crp-line-range-comment

/** A single inline comment attached to one or more lines. */
export interface Comment {
  /** Unique identifier. Generated via crypto.randomUUID(). */
  id: string;
  /** The file this comment belongs to. Links to FileInfo.id. */
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

// Implements: FR-crp-file-load, FR-crp-file-display, FR-crp-syntax-highlight

/** Metadata about the loaded file. */
export interface FileInfo {
  /** Unique identifier. Generated via crypto.randomUUID(). */
  id: string;
  /** File name, or "Untitled" if pasted without a name. */
  name: string;
  /** Detected or inferred programming language identifier (e.g., "typescript", "python"). */
  language: string;
  /** The raw file content as a single string. */
  content: string;
  /** The content split into individual lines. Derived from content. */
  lines: string[];
}

/** State of the inline comment editor. */
export type EditorState =
  | { mode: 'create'; anchorLine: number; endLine: number }
  | { mode: 'edit'; commentId: string };

// Implements: FR-crp-review-context-receive
/** Structured review context written by the shepherd-review agent. */
export interface ReviewContext {
  overall: { neutral: string; review: string };
  files: Record<string, { neutral: string; review: string }>;
}

/** The full application state. */
export interface AppState {
  /** The currently active file, or null if no file is loaded. Alias for files[activeFileId]. */
  file: FileInfo | null;
  /** All loaded files, keyed by file ID. */
  files: Record<string, FileInfo>;
  /** Ordered array of file IDs representing tab order. */
  fileOrder: string[];
  /** The ID of the currently active file, or null. */
  activeFileId: string | null;
  /** Saved scroll positions per file ID. */
  scrollPositions: Record<string, number>;
  /** Whether the add-file modal is open. */
  isAddFileModalOpen: boolean;
  /** All comments, keyed by comment ID for O(1) lookup. */
  comments: Record<string, Comment>;
  /** Ordered array of comment IDs for the active file, sorted by startLine then createdAt. */
  commentOrder: string[];
  /** The user's preamble text. */
  preamble: string;
  /** The automatically generated prompt string, or null when no comments exist. Auto-computed after every comment or preamble change. */
  generatedPrompt: string | null;
  /** The ID of the currently focused comment (via navigation), or null. */
  focusedCommentId: string | null;
  /** The currently selected line range for range-commenting, or null. */
  selectedRange: { start: number; end: number } | null;
  /** Whether the inline comment editor is open, and if so, in what mode. */
  editorState: EditorState | null;
  /** Whether the large file warning banner has been dismissed. */
  largeFileWarningDismissed: boolean;
  /** Whether a large file warning should be shown. */
  showLargeFileWarning: boolean;
  /** Maps fileId → absolute file path for server-loaded files. Used to restore filePath on tab switch. */
  serverFilePaths: Record<string, string>;
  /** Review context data loaded from the agent, or null if unavailable. */
  reviewContext: ReviewContext | null;
  /** Whether the review context panel is collapsed. */
  isReviewContextCollapsed: boolean;
  /** Whether the review context sidebar (changeset overview) is collapsed. */
  isReviewContextSidebarCollapsed: boolean;
  /** Which tab is active in the sidebar content area. */
  sidebarTab: 'preview' | 'comments';
  /** Set of file IDs that the user has marked as reviewed. */
  reviewedFiles: Set<string>;
  /** Whether line wrapping is enabled in the code viewer. Default: true (wrapping ON). */
  lineWrapEnabled: boolean;
  /** Set of directory paths that are currently collapsed in the file tree. */
  collapsedDirs: Set<string>;
  /** Session ID from ?session= URL param. Null in standalone mode. */
  sessionId: string | null;
  /** Width of the FileBrowser sidebar in pixels. Default 240. Implements: FR-crp-panel-resize */
  fileBrowserWidth: number;
}

// Implements: FR-crp-multi-file-nav
/** A node in the file browser tree: either a directory or a file leaf. */
export type FileTreeNode =
  | { type: 'directory'; name: string; path: string; children: FileTreeNode[] }
  | { type: 'file'; fileId: string; name: string };

/** Display items for the virtualized code viewer. */
export type DisplayItem =
  | { type: 'code-line'; lineNumber: number; content: string }
  | { type: 'comment-bubble'; comment: Comment }
  | { type: 'editor'; anchorLine: number; endLine: number; mode: 'create' | 'edit'; commentId?: string };

// Implements: FR-dm-css-custom-properties
export type ThemePreference = 'light' | 'dark' | 'system';
export type ResolvedTheme = 'light' | 'dark';

/** Shiki token for syntax highlighting. */
export interface HighlightToken {
  content: string;
  color?: string;
  lightColor?: string;
  darkColor?: string;
}

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
  /** The file this comment belongs to. Links to FileInfo.id. */
  fileId: string;
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
  /** Pre-computed diff snippet with surrounding context lines. Stored at creation time so the prompt can be built without needing the live diffLines array. */
  contextSnippet: string;
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

/** State of the inline comment editor in diff mode. */
export type DiffEditorState =
  | { mode: 'create'; startIndex: number; endIndex: number }
  | { mode: 'edit'; commentId: string };

// Implements: FR-mdr-element-id, FR-mdr-render-toggle, FR-mdr-rendered-comment-create

/** Opaque element ID string (e.g., "heading-0", "paragraph-1", "list-2-item-0"). */
export type ElementId = string & { readonly __brand: unique symbol };

/** Maps an AST block element to its source line range. */
export interface ElementSourceMapping {
  elementId: ElementId;
  startLine: number;
  endLine: number;
  rawSource: string;
}

/** A block-level AST element with metadata for rendering and commenting. */
export interface AstBlockElement {
  elementId: ElementId;
  type: string;
  textContent: string;
  startLine: number;
  endLine: number;
  depth?: number; // heading depth (1-6)
}

/** A comment anchored to a rendered markdown element. */
export interface RenderedComment {
  id: string;
  elementId: ElementId;
  elementType: string;
  contentPreview: string;
  text: string;
  createdAt: string;
}

/** A comment anchored to a rendered diff element. */
export interface RenderedDiffComment {
  id: string;
  elementId: ElementId;
  elementType: string;
  diffStatus: 'added' | 'removed' | 'modified' | 'unchanged';
  contentPreview: string;
  text: string;
  createdAt: string;
}

/** A single entry in the AST diff result. */
export interface AstDiffEntry {
  elementId: ElementId;
  status: 'added' | 'removed' | 'modified' | 'unchanged';
  type: string;
  oldElement?: AstBlockElement;
  newElement?: AstBlockElement;
  oldHtml?: string;
  newHtml?: string;
  wordDiff?: WordDiffSegment[];
}

/** Word-level diff segment for modified blocks. */
export interface WordDiffSegment {
  value: string;
  added?: boolean;
  removed?: boolean;
}

/** The result of computing an AST-level diff between two markdown sources. */
export interface AstDiffResult {
  entries: AstDiffEntry[];
  exceedsFallbackThreshold: boolean;
}

/** Whether the code panel shows raw source or rendered markdown. */
export type RenderMode = 'raw' | 'rendered';

/** Editor state for rendered-mode comments. */
export type RenderedEditorState =
  | { mode: 'create'; elementId: ElementId }
  | { mode: 'edit'; commentId: string };

/** Editor state for rendered-diff-mode comments. */
export type RenderedDiffEditorState =
  | { mode: 'create'; elementId: ElementId }
  | { mode: 'edit'; commentId: string };

/** Diff-specific state fields added to AppState. */
export interface DiffState {
  /** Current view mode: 'file' for full-file view, 'diff' for unified diff view. */
  viewMode: 'file' | 'diff';
  /** How the file was loaded. 'server' = via /api/file (slash command). 'local' = paste/upload/drag-and-drop. */
  fileSource: FileSource | null;
  /** The server file path for re-fetching. */
  filePath: string | null;
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
  /** Whether the CRPG is in slash command mode (file loaded via ?file= URL param). */
  isSlashCommandMode: boolean;
  /** State of the Done button: idle, sending, or sent. */
  doneState: 'idle' | 'sending' | 'sent';
}

/** Rendered-view state fields added to AppState. */
export interface RenderedState {
  /** Current render mode: 'raw' shows source, 'rendered' shows formatted HTML. */
  renderMode: RenderMode;
  /** Whether the current file is a markdown file. */
  isMarkdownFile: boolean;
  /** Parsed AST block elements for the current file. */
  astElements: AstBlockElement[];
  /** Source mapping for AST elements. */
  elementSourceMap: ElementSourceMapping[];
  /** Rendered HTML for the current file. */
  renderedHtml: string;
  /** Rendered-mode comments, keyed by comment ID. */
  renderedComments: Record<string, RenderedComment>;
  /** Ordered array of rendered comment IDs. */
  renderedCommentOrder: string[];
  /** ID of the focused rendered comment. */
  focusedRenderedCommentId: string | null;
  /** Editor state for rendered-mode comments. */
  renderedEditorState: RenderedEditorState | null;
  /** Rendered-diff-mode comments, keyed by comment ID. */
  renderedDiffComments: Record<string, RenderedDiffComment>;
  /** Ordered array of rendered diff comment IDs. */
  renderedDiffCommentOrder: string[];
  /** ID of the focused rendered diff comment. */
  focusedRenderedDiffCommentId: string | null;
  /** Editor state for rendered-diff-mode comments. */
  renderedDiffEditorState: RenderedDiffEditorState | null;
  /** The computed AST diff result, or null. */
  astDiffResult: AstDiffResult | null;
  /** Whether the AST diff is currently being computed. */
  isAstDiffComputing: boolean;
}
