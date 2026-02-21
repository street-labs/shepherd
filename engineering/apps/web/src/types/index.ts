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
