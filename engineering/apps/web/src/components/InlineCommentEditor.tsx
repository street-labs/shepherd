// Implements: FR-crp-line-comment-create, FR-crp-line-comment-edit,
// AC-crp-add-comment-single-line, AC-crp-add-comment-line-range, AC-crp-edit-comment

import { useAppStore } from '@/store/appStore';
import { useState, useEffect, useRef } from 'react';

export function InlineCommentEditor() {
  const editorState = useAppStore((s) => s.editorState);
  const comments = useAppStore((s) => s.comments);
  const addComment = useAppStore((s) => s.addComment);
  const updateComment = useAppStore((s) => s.updateComment);
  const closeEditor = useAppStore((s) => s.closeEditor);

  const existingComment =
    editorState?.mode === 'edit' ? comments[editorState.commentId] : null;

  const [text, setText] = useState(existingComment?.text ?? '');
  const textareaRef = useRef<HTMLTextAreaElement>(null);

  useEffect(() => {
    setText(existingComment?.text ?? '');
  }, [existingComment]);

  useEffect(() => {
    // Auto-focus on mount
    textareaRef.current?.focus();
  }, []);

  if (!editorState) return null;

  const lineLabel =
    editorState.mode === 'create'
      ? editorState.anchorLine === editorState.endLine
        ? `Line ${editorState.anchorLine}`
        : `Lines ${editorState.anchorLine}-${editorState.endLine}`
      : existingComment
        ? existingComment.startLine === existingComment.endLine
          ? `Line ${existingComment.startLine}`
          : `Lines ${existingComment.startLine}-${existingComment.endLine}`
        : '';

  const handleSubmit = () => {
    if (!text.trim()) return;
    if (editorState.mode === 'create') {
      addComment(editorState.anchorLine, editorState.endLine, text.trim());
    } else {
      updateComment(editorState.commentId, text.trim());
    }
  };

  const handleKeyDown = (e: React.KeyboardEvent<HTMLTextAreaElement>) => {
    if ((e.metaKey || e.ctrlKey) && e.key === 'Enter') {
      e.preventDefault();
      handleSubmit();
    }
    if (e.key === 'Escape') {
      e.preventDefault();
      closeEditor();
    }
  };

  return (
    <div className="ml-8 mr-4 my-1 p-2 rounded border border-primary-500 bg-white shadow-sm">
      <div className="text-xs text-text-secondary font-medium mb-1">{lineLabel}</div>
      <textarea
        ref={textareaRef}
        value={text}
        onChange={(e) => setText(e.target.value)}
        onKeyDown={handleKeyDown}
        placeholder="Add your comment..."
        className="w-full min-h-[60px] p-2 text-sm border border-border-default rounded resize-y focus:outline-none focus:ring-1 focus:ring-primary-500"
        aria-label={`Comment for ${lineLabel}`}
      />
      <div className="flex items-center justify-between mt-1">
        <span className="text-xs text-text-tertiary">⌘+Enter to submit, Escape to cancel</span>
        <div className="flex gap-1">
          <button
            onClick={closeEditor}
            className="px-2 py-1 text-xs rounded border border-border-default hover:bg-surface-secondary"
          >
            Cancel
          </button>
          <button
            onClick={handleSubmit}
            disabled={!text.trim()}
            className="px-2 py-1 text-xs font-medium rounded bg-primary-500 text-text-on-primary hover:bg-primary-600 disabled:opacity-40 disabled:cursor-not-allowed"
          >
            {editorState.mode === 'create' ? 'Add' : 'Save'}
          </button>
        </div>
      </div>
    </div>
  );
}
