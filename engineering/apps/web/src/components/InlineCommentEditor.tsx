// Implements: FR-crp-line-comment-create, FR-crp-line-comment-edit,
// AC-crp-add-comment-single-line, AC-crp-add-comment-line-range, AC-crp-edit-comment,
// FR-diff-comment-create, FR-mdr-rendered-comment-create

import { useAppStore } from '@/store/appStore';
import { useState, useEffect, useRef } from 'react';
import type { ElementId } from '@/types';

interface InlineCommentEditorProps {
  isDiffMode?: boolean;
  isRenderedMode?: boolean;
  isRenderedDiffMode?: boolean;
}

export function InlineCommentEditor({ isDiffMode, isRenderedMode, isRenderedDiffMode }: InlineCommentEditorProps) {
  const editorState = useAppStore((s) => s.editorState);
  const diffEditorState = useAppStore((s) => s.diffEditorState);
  const renderedEditorState = useAppStore((s) => s.renderedEditorState);
  const renderedDiffEditorState = useAppStore((s) => s.renderedDiffEditorState);
  const comments = useAppStore((s) => s.comments);
  const diffComments = useAppStore((s) => s.diffComments);
  const renderedComments = useAppStore((s) => s.renderedComments);
  const renderedDiffComments = useAppStore((s) => s.renderedDiffComments);
  const astElements = useAppStore((s) => s.astElements);
  const addComment = useAppStore((s) => s.addComment);
  const updateComment = useAppStore((s) => s.updateComment);
  const closeEditor = useAppStore((s) => s.closeEditor);
  const addDiffComment = useAppStore((s) => s.addDiffComment);
  const updateDiffComment = useAppStore((s) => s.updateDiffComment);
  const closeDiffEditor = useAppStore((s) => s.closeDiffEditor);
  const addRenderedComment = useAppStore((s) => s.addRenderedComment);
  const updateRenderedComment = useAppStore((s) => s.updateRenderedComment);
  const closeRenderedEditor = useAppStore((s) => s.closeRenderedEditor);
  const addRenderedDiffComment = useAppStore((s) => s.addRenderedDiffComment);
  const updateRenderedDiffComment = useAppStore((s) => s.updateRenderedDiffComment);
  const closeRenderedDiffEditor = useAppStore((s) => s.closeRenderedDiffEditor);
  const astDiffResult = useAppStore((s) => s.astDiffResult);

  const activeState = isRenderedDiffMode ? renderedDiffEditorState
    : isRenderedMode ? renderedEditorState
    : isDiffMode ? diffEditorState
    : editorState;

  const existingComment = isRenderedDiffMode
    ? (activeState?.mode === 'edit' ? renderedDiffComments[activeState.commentId] : null)
    : isRenderedMode
    ? (activeState?.mode === 'edit' ? renderedComments[activeState.commentId] : null)
    : isDiffMode
    ? (activeState?.mode === 'edit' ? diffComments[activeState.commentId] : null)
    : (activeState?.mode === 'edit' ? comments[activeState.commentId] : null);

  const [text, setText] = useState(existingComment?.text ?? '');
  const textareaRef = useRef<HTMLTextAreaElement>(null);

  useEffect(() => {
    setText(existingComment?.text ?? '');
  }, [existingComment]);

  useEffect(() => {
    textareaRef.current?.focus();
  }, []);

  if (!activeState) return null;

  let lineLabel = '';
  if (isRenderedMode || isRenderedDiffMode) {
    if (activeState.mode === 'create') {
      const s = activeState as { elementId: ElementId };
      const element = astElements.find((e) => e.elementId === s.elementId);
      lineLabel = element ? `${capitalize(element.type)}: ${element.textContent.slice(0, 40)}` : 'Element';
    } else if (existingComment && 'elementType' in existingComment) {
      lineLabel = `${capitalize(existingComment.elementType)}: ${existingComment.contentPreview.slice(0, 40)}`;
    }
  } else if (!isDiffMode && activeState) {
    if (activeState.mode === 'create') {
      const s = activeState as { anchorLine: number; endLine: number };
      lineLabel = s.anchorLine === s.endLine
        ? `Line ${s.anchorLine}`
        : `Lines ${s.anchorLine}-${s.endLine}`;
    } else if (existingComment && 'startLine' in existingComment) {
      lineLabel = existingComment.startLine === existingComment.endLine
        ? `Line ${existingComment.startLine}`
        : `Lines ${existingComment.startLine}-${existingComment.endLine}`;
    }
  } else if (isDiffMode && activeState) {
    if (activeState.mode === 'create') {
      const s = activeState as { startIndex: number; endIndex: number };
      lineLabel = s.startIndex === s.endIndex
        ? `Diff line ${s.startIndex + 1}`
        : `Diff lines ${s.startIndex + 1}-${s.endIndex + 1}`;
    } else if (existingComment && 'startIndex' in existingComment) {
      lineLabel = existingComment.startIndex === existingComment.endIndex
        ? `Diff line ${existingComment.startIndex + 1}`
        : `Diff lines ${existingComment.startIndex + 1}-${existingComment.endIndex + 1}`;
    }
  }

  const handleSubmit = () => {
    if (!text.trim()) return;
    if (isRenderedDiffMode) {
      if (activeState.mode === 'create') {
        const s = activeState as { elementId: ElementId };
        const element = astElements.find((e) => e.elementId === s.elementId);
        const diffEntry = astDiffResult?.entries.find((e) => e.elementId === s.elementId);
        addRenderedDiffComment(
          s.elementId,
          element?.type ?? 'unknown',
          diffEntry?.status ?? 'unchanged',
          element?.textContent.slice(0, 80) ?? '',
          text.trim(),
        );
      } else {
        updateRenderedDiffComment(activeState.commentId, text.trim());
      }
    } else if (isRenderedMode) {
      if (activeState.mode === 'create') {
        const s = activeState as { elementId: ElementId };
        const element = astElements.find((e) => e.elementId === s.elementId);
        addRenderedComment(
          s.elementId,
          element?.type ?? 'unknown',
          element?.textContent.slice(0, 80) ?? '',
          text.trim(),
        );
      } else {
        updateRenderedComment(activeState.commentId, text.trim());
      }
    } else if (isDiffMode) {
      if (activeState.mode === 'create') {
        const s = activeState as { startIndex: number; endIndex: number };
        addDiffComment(s.startIndex, s.endIndex, text.trim());
      } else {
        updateDiffComment(activeState.commentId, text.trim());
      }
    } else {
      if (activeState.mode === 'create') {
        const s = activeState as { anchorLine: number; endLine: number };
        addComment(s.anchorLine, s.endLine, text.trim());
      } else {
        updateComment(activeState.commentId, text.trim());
      }
    }
  };

  const handleClose = () => {
    if (isRenderedDiffMode) {
      closeRenderedDiffEditor();
    } else if (isRenderedMode) {
      closeRenderedEditor();
    } else if (isDiffMode) {
      closeDiffEditor();
    } else {
      closeEditor();
    }
  };

  const handleKeyDown = (e: React.KeyboardEvent<HTMLTextAreaElement>) => {
    if ((e.metaKey || e.ctrlKey) && e.key === 'Enter') {
      e.preventDefault();
      handleSubmit();
    }
    if (e.key === 'Escape') {
      e.preventDefault();
      handleClose();
    }
  };

  return (
    <div className="ml-8 mr-4 my-1 p-2 rounded border border-primary-500 bg-surface-primary shadow-sm">
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
        <span className="text-xs text-text-tertiary">&#x2318;+Enter to submit, Escape to cancel</span>
        <div className="flex gap-1">
          <button
            onClick={handleClose}
            className="px-2 py-1 text-xs rounded border border-border-default hover:bg-surface-secondary"
          >
            Cancel
          </button>
          <button
            onClick={handleSubmit}
            disabled={!text.trim()}
            className="px-2 py-1 text-xs font-medium rounded bg-primary-500 text-text-on-primary hover:bg-primary-600 disabled:opacity-40 disabled:cursor-not-allowed"
          >
            {activeState.mode === 'create' ? 'Add' : 'Save'}
          </button>
        </div>
      </div>
    </div>
  );
}

function capitalize(s: string): string {
  return s.charAt(0).toUpperCase() + s.slice(1);
}
