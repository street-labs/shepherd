// Implements: FR-crp-line-comment-edit, FR-crp-line-comment-delete, FR-crp-comment-indicator

import { useAppStore } from '@/store/appStore';
import type { Comment } from '@/types';

interface CommentBubbleProps {
  comment: Comment;
  isFocused: boolean;
}

export function CommentBubble({ comment, isFocused }: CommentBubbleProps) {
  const openEditor = useAppStore((s) => s.openEditor);
  const deleteComment = useAppStore((s) => s.deleteComment);

  const lineLabel =
    comment.startLine === comment.endLine
      ? `Line ${comment.startLine}`
      : `Lines ${comment.startLine}-${comment.endLine}`;

  return (
    <div
      id={`comment-${comment.id}`}
      className={`group ml-8 mr-4 my-1 p-2 rounded border text-sm ${
        isFocused
          ? 'border-primary-500 bg-blue-50 ring-2 ring-primary-500/20'
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
            onClick={() => openEditor({ mode: 'edit', commentId: comment.id })}
            className="px-1.5 py-0.5 text-xs rounded hover:bg-white/50 text-text-secondary"
            aria-label={`Edit comment on ${lineLabel}`}
          >
            Edit
          </button>
          <button
            onClick={() => deleteComment(comment.id)}
            className="px-1.5 py-0.5 text-xs rounded hover:bg-red-50 text-destructive-600"
            aria-label={`Delete comment on ${lineLabel}`}
          >
            Delete
          </button>
        </div>
      </div>
    </div>
  );
}
