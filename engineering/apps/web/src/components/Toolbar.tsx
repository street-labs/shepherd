// Implements: FR-crp-comment-count, FR-crp-comment-navigation,
// FR-crp-prompt-copy, FR-crp-clear-session, AC-crp-generate-prompt-no-comments,
// FR-diff-mode-toggle, FR-diff-refresh

import { useAppStore } from '@/store/appStore';
import { ViewModeToggle } from './ViewModeToggle';
import { useEffect } from 'react';

interface ToolbarProps {
  onClearRequest: () => void;
  onModeChange: (mode: 'file' | 'diff') => void;
  onRefreshRequest: () => void;
}

export function Toolbar({ onClearRequest, onModeChange, onRefreshRequest }: ToolbarProps) {
  const file = useAppStore((s) => s.file);
  const viewMode = useAppStore((s) => s.viewMode);
  const fileSource = useAppStore((s) => s.fileSource);
  const isBaselineLoading = useAppStore((s) => s.isBaselineLoading);

  // Mode-aware comment count
  const fileCommentCount = useAppStore((s) => Object.keys(s.comments).length);
  const diffCommentCount = useAppStore((s) => Object.keys(s.diffComments).length);
  const commentCount = viewMode === 'diff' ? diffCommentCount : fileCommentCount;

  const generatedPrompt = useAppStore((s) => s.generatedPrompt);

  // Mode-aware focused comment
  const focusedCommentId = useAppStore((s) => s.focusedCommentId);
  const focusedDiffCommentId = useAppStore((s) => s.focusedDiffCommentId);
  const activeFocused = viewMode === 'diff' ? focusedDiffCommentId : focusedCommentId;

  // Mode-aware comment order
  const commentOrder = useAppStore((s) => s.commentOrder);
  const diffCommentOrder = useAppStore((s) => s.diffCommentOrder);
  const activeOrder = viewMode === 'diff' ? diffCommentOrder : commentOrder;

  const navigateComment = useAppStore((s) => s.navigateComment);
  const navigateDiffComment = useAppStore((s) => s.navigateDiffComment);
  const copyPrompt = useAppStore((s) => s.copyPrompt);

  const hasFile = file !== null;
  const hasComments = commentCount > 0;
  const hasPrompt = generatedPrompt !== null;
  const isDiffEnabled = fileSource === 'server';

  const currentIndex = activeFocused
    ? activeOrder.indexOf(activeFocused) + 1
    : 0;

  const handleNavigate = (direction: 'next' | 'prev') => {
    if (viewMode === 'diff') {
      navigateDiffComment(direction);
    } else {
      navigateComment(direction);
    }
  };

  // Keyboard shortcuts
  useEffect(() => {
    const handler = (e: KeyboardEvent) => {
      const metaOrCtrl = e.metaKey || e.ctrlKey;

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
        handleNavigate('next');
        return;
      }

      // [ : prev comment
      if (e.key === '[' && !metaOrCtrl && !e.shiftKey) {
        e.preventDefault();
        handleNavigate('prev');
        return;
      }
    };

    document.addEventListener('keydown', handler);
    return () => document.removeEventListener('keydown', handler);
  }, [hasComments, hasPrompt, copyPrompt, handleNavigate]);

  return (
    <header
      className="flex items-center gap-3 px-4 h-12 border-b border-border-default bg-surface-toolbar flex-shrink-0"
      role="toolbar"
      aria-label="Main toolbar"
    >
      <h1 className="text-sm font-semibold">Code Review Prompt</h1>

      {hasFile && (
        <>
          <ViewModeToggle
            activeMode={viewMode}
            isDiffEnabled={isDiffEnabled}
            onModeChange={onModeChange}
          />

          {/* Refresh button (diff mode only) */}
          {viewMode === 'diff' && (
            <button
              onClick={onRefreshRequest}
              disabled={isBaselineLoading}
              className="p-1.5 rounded border border-border-default hover:bg-surface-secondary disabled:opacity-40 disabled:cursor-not-allowed"
              aria-label="Refresh diff"
              title="Refresh diff"
            >
              <svg
                className={`w-3.5 h-3.5 ${isBaselineLoading ? 'animate-spin' : ''}`}
                viewBox="0 0 16 16"
                fill="none"
                stroke="currentColor"
                strokeWidth="1.5"
              >
                <path d="M14 8A6 6 0 1 1 8 2" strokeLinecap="round" />
                <path d="M8 0l3 2-3 2" strokeLinecap="round" strokeLinejoin="round" />
              </svg>
            </button>
          )}

          <div className="mr-auto" />

          {/* Comment navigation */}
          <div className="flex items-center gap-1">
            <button
              onClick={() => handleNavigate('prev')}
              disabled={!hasComments}
              className="px-2 py-1 text-xs rounded border border-border-default hover:bg-surface-secondary disabled:opacity-40 disabled:cursor-not-allowed"
              aria-label="Previous comment"
              title="Previous comment ([)"
            >
              &#x2039;
            </button>
            <span className="text-xs text-text-secondary min-w-[3ch] text-center tabular-nums">
              {hasComments ? `${currentIndex}/${commentCount}` : '0'}
            </span>
            <button
              onClick={() => handleNavigate('next')}
              disabled={!hasComments}
              className="px-2 py-1 text-xs rounded border border-border-default hover:bg-surface-secondary disabled:opacity-40 disabled:cursor-not-allowed"
              aria-label="Next comment"
              title="Next comment (])"
            >
              &#x203a;
            </button>
          </div>

          <div className="w-px h-5 bg-border-default" role="separator" />

          {/* Actions */}
          <button
            onClick={() => void copyPrompt()}
            disabled={!hasPrompt}
            className="px-3 py-1 text-xs font-medium rounded border border-border-default hover:bg-surface-secondary disabled:opacity-40 disabled:cursor-not-allowed"
            title="Copy prompt (&#x2318;&#x21E7;C)"
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
