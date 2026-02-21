// Implements: FR-crp-comment-count, FR-crp-comment-navigation, FR-crp-prompt-generate,
// FR-crp-prompt-copy, FR-crp-clear-session, AC-crp-generate-prompt-no-comments

import { useAppStore } from '@/store/appStore';
import { useEffect } from 'react';

interface ToolbarProps {
  onClearRequest: () => void;
}

export function Toolbar({ onClearRequest }: ToolbarProps) {
  const file = useAppStore((s) => s.file);
  const commentCount = useAppStore((s) => Object.keys(s.comments).length);
  const generatedPrompt = useAppStore((s) => s.generatedPrompt);
  const focusedCommentId = useAppStore((s) => s.focusedCommentId);
  const commentOrder = useAppStore((s) => s.commentOrder);
  const navigateComment = useAppStore((s) => s.navigateComment);
  const generatePrompt = useAppStore((s) => s.generatePrompt);
  const copyPrompt = useAppStore((s) => s.copyPrompt);

  const hasFile = file !== null;
  const hasComments = commentCount > 0;
  const hasPrompt = generatedPrompt !== null;

  const currentIndex = focusedCommentId
    ? commentOrder.indexOf(focusedCommentId) + 1
    : 0;

  // Keyboard shortcuts
  useEffect(() => {
    const handler = (e: KeyboardEvent) => {
      const metaOrCtrl = e.metaKey || e.ctrlKey;

      // Cmd+Shift+G: generate prompt
      if (metaOrCtrl && e.shiftKey && e.key === 'G') {
        e.preventDefault();
        if (hasComments) generatePrompt();
        return;
      }

      // Cmd+Shift+C: copy prompt
      if (metaOrCtrl && e.shiftKey && e.key === 'C') {
        e.preventDefault();
        if (hasPrompt) void copyPrompt();
        return;
      }

      // Don't trigger navigation shortcuts when typing in input/textarea
      const target = e.target as HTMLElement;
      if (target.tagName === 'INPUT' || target.tagName === 'TEXTAREA') return;

      // ] : next comment
      if (e.key === ']' && !metaOrCtrl && !e.shiftKey) {
        e.preventDefault();
        navigateComment('next');
        return;
      }

      // [ : prev comment
      if (e.key === '[' && !metaOrCtrl && !e.shiftKey) {
        e.preventDefault();
        navigateComment('prev');
        return;
      }
    };

    document.addEventListener('keydown', handler);
    return () => document.removeEventListener('keydown', handler);
  }, [hasComments, hasPrompt, generatePrompt, copyPrompt, navigateComment]);

  return (
    <header
      className="flex items-center gap-3 px-4 h-12 border-b border-border-default bg-surface-toolbar flex-shrink-0"
      role="toolbar"
      aria-label="Main toolbar"
    >
      <h1 className="text-sm font-semibold mr-auto">Code Review Prompt</h1>

      {hasFile && (
        <>
          {/* Comment navigation */}
          <div className="flex items-center gap-1">
            <button
              onClick={() => navigateComment('prev')}
              disabled={!hasComments}
              className="px-2 py-1 text-xs rounded border border-border-default hover:bg-surface-secondary disabled:opacity-40 disabled:cursor-not-allowed"
              aria-label="Previous comment"
              title="Previous comment ([)"
            >
              ‹
            </button>
            <span className="text-xs text-text-secondary min-w-[3ch] text-center tabular-nums">
              {hasComments ? `${currentIndex}/${commentCount}` : '0'}
            </span>
            <button
              onClick={() => navigateComment('next')}
              disabled={!hasComments}
              className="px-2 py-1 text-xs rounded border border-border-default hover:bg-surface-secondary disabled:opacity-40 disabled:cursor-not-allowed"
              aria-label="Next comment"
              title="Next comment (])"
            >
              ›
            </button>
          </div>

          <div className="w-px h-5 bg-border-default" role="separator" />

          {/* Actions */}
          <button
            onClick={generatePrompt}
            disabled={!hasComments}
            className="px-3 py-1 text-xs font-medium rounded bg-primary-500 text-text-on-primary hover:bg-primary-600 disabled:opacity-40 disabled:cursor-not-allowed"
            title="Generate prompt (⌘⇧G)"
          >
            {hasPrompt ? 'Regenerate' : 'Generate'}
          </button>

          <button
            onClick={() => void copyPrompt()}
            disabled={!hasPrompt}
            className="px-3 py-1 text-xs font-medium rounded border border-border-default hover:bg-surface-secondary disabled:opacity-40 disabled:cursor-not-allowed"
            title="Copy prompt (⌘⇧C)"
          >
            Copy
          </button>

          <button
            onClick={onClearRequest}
            className="px-3 py-1 text-xs font-medium rounded border border-border-default text-destructive-600 hover:bg-red-50 disabled:opacity-40 disabled:cursor-not-allowed"
          >
            Clear
          </button>
        </>
      )}
    </header>
  );
}
