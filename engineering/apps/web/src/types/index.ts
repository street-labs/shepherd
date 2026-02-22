// Implements: FR-crp-line-comment-create, FR-crp-line-comment-edit, FR-crp-line-range-comment

/** A single inline comment attached to one or more lines. */
export interface Comment {
  /** Unique identifier. Generated via crypto.randomUUID(). */
  id: string;
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

/** The full application state. */
export interface AppState {
  /** The currently loaded file, or null if no file is loaded. */
  file: FileInfo | null;
  /** All comments, keyed by comment ID for O(1) lookup. */
  comments: Record<string, Comment>;
  /** Ordered array of comment IDs sorted by startLine then createdAt. */
  commentOrder: string[];
  /** The user's preamble text. */
  preamble: string;
  /** The most recently generated prompt string, or null. */
  generatedPrompt: string | null;
  /** Whether the generated prompt is stale (comments or preamble changed since generation). */
  isPromptStale: boolean;
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
}

/** Display items for the virtualized code viewer. */
export type DisplayItem =
  | { type: 'code-line'; lineNumber: number; content: string }
  | { type: 'comment-bubble'; comment: Comment }
  | { type: 'editor'; anchorLine: number; endLine: number; mode: 'create' | 'edit'; commentId?: string };

/** Shiki token for syntax highlighting. */
export interface HighlightToken {
  content: string;
  color?: string;
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

/** State of the inline comment editor in diff mode. */
export type DiffEditorState =
  | { mode: 'create'; startIndex: number; endIndex: number }
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
}
