// Implements: FR-crp-file-load, FR-crp-file-display, NFR-crp-responsive-layout,
// FR-sc-auto-load-file, AC-sc-session-clear-on-new-file,
// FR-diff-mode-toggle, AC-diff-switch-clears-comments

import { useAppStore } from '@/store/appStore';
import { Toolbar } from '@/components/Toolbar';
import { FileDropZone } from '@/components/FileDropZone';
import { FileHeader } from '@/components/FileHeader';
import { CodeViewer } from '@/components/CodeViewer';
import { DiffViewer } from '@/components/DiffViewer';
import { DiffLoadingState } from '@/components/DiffLoadingState';
import { DiffErrorState } from '@/components/DiffErrorState';
import { DiffEmptyState } from '@/components/DiffEmptyState';
import { PreambleInput } from '@/components/PreambleInput';
import { PromptPreview } from '@/components/PromptPreview';
import { ConfirmationDialog } from '@/components/ConfirmationDialog';
import { ToastNotification } from '@/components/ToastNotification';
import { useFileFromUrl } from '@/hooks/useFileFromUrl';
import { useState, useEffect, useCallback } from 'react';

function useWindowWidth() {
  const [width, setWidth] = useState(window.innerWidth);
  useEffect(() => {
    const handleResize = () => setWidth(window.innerWidth);
    window.addEventListener('resize', handleResize);
    return () => window.removeEventListener('resize', handleResize);
  }, []);
  return width;
}

type DialogType = 'clear' | 'mode-switch' | 'refresh' | null;

export function App() {
  const file = useAppStore((s) => s.file);
  const fileCommentCount = useAppStore((s) => Object.keys(s.comments).length);
  const diffCommentCount = useAppStore((s) => Object.keys(s.diffComments).length);
  const viewMode = useAppStore((s) => s.viewMode);
  const isBaselineLoading = useAppStore((s) => s.isBaselineLoading);
  const baselineError = useAppStore((s) => s.baselineError);
  const isDiffEmpty = useAppStore((s) => s.isDiffEmpty);
  const diffLines = useAppStore((s) => s.diffLines);
  const clearSession = useAppStore((s) => s.clearSession);
  const setViewMode = useAppStore((s) => s.setViewMode);
  const clearDiffComments = useAppStore((s) => s.clearDiffComments);
  const fetchBaseline = useAppStore((s) => s.fetchBaseline);
  const refreshDiff = useAppStore((s) => s.refreshDiff);

  const [activeDialog, setActiveDialog] = useState<DialogType>(null);
  const [pendingMode, setPendingMode] = useState<'file' | 'diff' | null>(null);

  const windowWidth = useWindowWidth();
  const isTooNarrow = windowWidth < 1024;
  const urlFile = useFileFromUrl();

  const handleClearRequest = () => {
    const commentCount = viewMode === 'diff' ? diffCommentCount : fileCommentCount;
    if (commentCount === 0 && (viewMode === 'file' ? diffCommentCount === 0 : fileCommentCount === 0)) {
      clearSession();
    } else {
      setActiveDialog('clear');
    }
  };

  const handleClearConfirm = () => {
    clearSession();
    setActiveDialog(null);
  };

  const handleModeChange = useCallback((mode: 'file' | 'diff') => {
    if (mode === viewMode) return;

    // Check if current mode has comments
    const currentModeCommentCount = viewMode === 'diff' ? diffCommentCount : fileCommentCount;
    if (currentModeCommentCount > 0) {
      setPendingMode(mode);
      setActiveDialog('mode-switch');
    } else {
      // Switch directly
      if (viewMode === 'diff') {
        clearDiffComments();
      }
      setViewMode(mode);
    }
  }, [viewMode, fileCommentCount, diffCommentCount, setViewMode, clearDiffComments]);

  const handleModeSwitchConfirm = () => {
    if (!pendingMode) return;

    // Clear comments for the mode we're leaving
    if (viewMode === 'file') {
      // Leaving file mode: clear file comments
      const state = useAppStore.getState();
      const emptyComments = {};
      useAppStore.setState({
        comments: emptyComments,
        commentOrder: [],
        focusedCommentId: null,
      });
      void state; // satisfy unused reference
    } else {
      // Leaving diff mode: clear diff comments
      clearDiffComments();
    }

    setViewMode(pendingMode);
    setActiveDialog(null);
    setPendingMode(null);
  };

  const handleRefreshRequest = () => {
    if (diffCommentCount > 0) {
      setActiveDialog('refresh');
    } else {
      void refreshDiff();
    }
  };

  const handleRefreshConfirm = () => {
    setActiveDialog(null);
    void refreshDiff();
  };

  const handleSwitchToFile = () => {
    setViewMode('file');
  };

  if (isTooNarrow) {
    return (
      <div className="flex flex-col h-screen">
        <Toolbar
          onClearRequest={handleClearRequest}
          onModeChange={handleModeChange}
          onRefreshRequest={handleRefreshRequest}
        />
        <div className="flex-1 flex items-center justify-center p-8">
          <div className="text-center max-w-sm">
            <p className="text-lg font-medium text-text-primary">Window too narrow</p>
            <p className="text-sm text-text-secondary mt-2">
              The Code Review Prompt Generator requires a window width of at least 1024px.
              Please resize your browser window or use a larger screen.
            </p>
          </div>
        </div>
      </div>
    );
  }

  // Determine what to render in the code viewer panel
  const renderCodePanel = () => {
    if (viewMode === 'file') {
      return <CodeViewer />;
    }

    // Diff mode
    if (isBaselineLoading) {
      return <DiffLoadingState />;
    }
    if (baselineError) {
      return <DiffErrorState errorMessage={baselineError} onRetry={() => void fetchBaseline()} />;
    }
    if (isDiffEmpty) {
      return <DiffEmptyState onSwitchToFile={handleSwitchToFile} />;
    }
    if (diffLines) {
      return <DiffViewer />;
    }

    // Fallback: no diff data yet but not loading/error
    return <CodeViewer />;
  };

  return (
    <div className="flex flex-col h-screen">
      <Toolbar
        onClearRequest={handleClearRequest}
        onModeChange={handleModeChange}
        onRefreshRequest={handleRefreshRequest}
      />

      <main className="flex-1 min-h-0">
        {urlFile.loading ? (
          <div className="flex-1 flex items-center justify-center">
            <p className="text-sm text-text-secondary">Loading file...</p>
          </div>
        ) : urlFile.error ? (
          <div className="flex-1 flex items-center justify-center p-8">
            <div className="text-center max-w-md">
              <p className="text-sm font-medium text-destructive-600">Failed to load file</p>
              <p className="text-xs text-text-secondary mt-1">{urlFile.error}</p>
            </div>
          </div>
        ) : !file ? (
          <FileDropZone />
        ) : (
          <div className="flex h-full">
            {/* Left column: code viewer */}
            <div className="flex-1 flex flex-col min-w-0 border-r border-border-default">
              <FileHeader />
              <div className="flex-1 min-h-0">
                {renderCodePanel()}
              </div>
            </div>

            {/* Right column: sidebar */}
            <div className={`flex-shrink-0 flex flex-col bg-surface-sidebar overflow-y-auto ${
              windowWidth < 1280 ? 'w-72' : 'w-96'
            }`}>
              <PreambleInput />
              <PromptPreview />
            </div>
          </div>
        )}
      </main>

      {/* Clear session dialog */}
      {activeDialog === 'clear' && (
        <ConfirmationDialog
          title="Clear session?"
          message="This will remove the loaded file, all comments, and the generated prompt. This action cannot be undone."
          confirmLabel="Clear"
          onConfirm={handleClearConfirm}
          onCancel={() => setActiveDialog(null)}
        />
      )}

      {/* Mode switch dialog */}
      {activeDialog === 'mode-switch' && (
        <ConfirmationDialog
          title="Switch view mode?"
          message={`Switching to ${pendingMode === 'diff' ? 'Diff' : 'File'} view will clear your ${viewMode === 'diff' ? 'diff' : 'file'}-mode comments. This action cannot be undone.`}
          confirmLabel="Switch"
          onConfirm={handleModeSwitchConfirm}
          onCancel={() => { setActiveDialog(null); setPendingMode(null); }}
        />
      )}

      {/* Refresh dialog */}
      {activeDialog === 'refresh' && (
        <ConfirmationDialog
          title="Refresh diff?"
          message="Refreshing will re-read both files from disk and recompute the diff. Your diff-mode comments will be cleared. This action cannot be undone."
          confirmLabel="Refresh"
          onConfirm={handleRefreshConfirm}
          onCancel={() => setActiveDialog(null)}
        />
      )}

      <ToastNotification />
    </div>
  );
}
