// Implements: FR-crp-line-comment-edit, FR-crp-line-comment-delete, FR-crp-comment-indicator,
// FR-mr-rendered-comment

import { useAppStore } from '@/store/appStore';
import type { Comment, DiffComment, RenderedComment, RenderedDiffComment } from '@/types';

interface CommentBubbleProps {
  comment: Comment | DiffComment | RenderedComment | RenderedDiffComment;
  isFocused: boolean;
  /** Optional label override. If provided, used instead of computing from line numbers. */
  label?: string;
  /** Whether this bubble is rendered in diff mode. Affects which store actions are called. */
  isDiffMode?: boolean;
  /** Whether this bubble is in rendered mode. */
  isRenderedMode?: boolean;
  /** Whether this bubble is in rendered diff mode. */
  isRenderedDiffMode?: boolean;
}

export function CommentBubble({ comment, isFocused, label, isDiffMode, isRenderedMode, isRenderedDiffMode }: CommentBubbleProps) {
  const openEditor = useAppStore((s) => s.openEditor);
  const deleteComment = useAppStore((s) => s.deleteComment);
  const openDiffEditor = useAppStore((s) => s.openDiffEditor);
  const deleteDiffComment = useAppStore((s) => s.deleteDiffComment);
  const openRenderedEditor = useAppStore((s) => s.openRenderedEditor);
  const deleteRenderedComment = useAppStore((s) => s.deleteRenderedComment);
  const openRenderedDiffEditor = useAppStore((s) => s.openRenderedDiffEditor);
  const deleteRenderedDiffComment = useAppStore((s) => s.deleteRenderedDiffComment);

  const lineLabel = label ?? (
    'startLine' in comment
      ? comment.startLine === comment.endLine
        ? `Line ${comment.startLine}`
        : `Lines ${comment.startLine}-${comment.endLine}`
      : ''
  );

  const handleEdit = () => {
    if (isRenderedDiffMode) {
      openRenderedDiffEditor({ mode: 'edit', commentId: comment.id });
    } else if (isRenderedMode) {
      openRenderedEditor({ mode: 'edit', commentId: comment.id });
    } else if (isDiffMode) {
      openDiffEditor({ mode: 'edit', commentId: comment.id });
    } else {
      openEditor({ mode: 'edit', commentId: comment.id });
    }
  };

  const handleDelete = () => {
    if (isRenderedDiffMode) {
      deleteRenderedDiffComment(comment.id);
    } else if (isRenderedMode) {
      deleteRenderedComment(comment.id);
    } else if (isDiffMode) {
      deleteDiffComment(comment.id);
    } else {
      deleteComment(comment.id);
    }
  };

  return (
    <div
      id={`comment-${comment.id}`}
      className={`group ml-8 mr-4 my-1 p-2 rounded border text-sm ${
        isFocused
          ? 'border-primary-500 bg-selection-bg ring-2 ring-primary-500/20'
          : 'border-comment-border bg-comment-bg'
      }`}
    >
      <div className="flex items-start justify-between gap-2">
        <div className="flex-1 min-w-0">
          <span className="text-xs text-text-secondary font-medium">{lineLabel}</span>
          <p className="text-text-primary mt-0.5 whitespace-pre-wrap break-words">{comment.text}</p>
        </div>
        <div className="flex gap-1 opacity-0 group-hover:opacity-100 transition-opacity flex-shrink-0">
          <button
            onClick={handleEdit}
            className="px-1.5 py-0.5 text-xs rounded hover:bg-surface-primary/50 text-text-secondary"
            aria-label={`Edit comment on ${lineLabel}`}
          >
            Edit
          </button>
          <button
            onClick={handleDelete}
            className="px-1.5 py-0.5 text-xs rounded hover:bg-destructive-500/10 text-destructive-600"
            aria-label={`Delete comment on ${lineLabel}`}
          >
            Delete
          </button>
        </div>
      </div>
    </div>
  );
}
