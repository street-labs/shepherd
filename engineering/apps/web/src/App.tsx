// Implements: FR-crp-file-load, FR-crp-file-display, NFR-crp-responsive-layout,
// FR-sc-auto-load-file, AC-sc-session-clear-on-new-file,
// FR-diff-mode-toggle, AC-diff-switch-clears-comments

import { useAppStore } from '@/store/appStore';
import { Toolbar } from '@/components/Toolbar';
import { FileDropZone } from '@/components/FileDropZone';
import { FileHeader } from '@/components/FileHeader';
import { FileTabBar } from '@/components/FileTabBar';
import { CodeViewer } from '@/components/CodeViewer';
import { DiffViewer } from '@/components/DiffViewer';
import { DiffLoadingState } from '@/components/DiffLoadingState';
import { DiffErrorState } from '@/components/DiffErrorState';
import { DiffEmptyState } from '@/components/DiffEmptyState';
import { RenderedViewer } from '@/components/RenderedViewer';
import { RenderedDiffViewer } from '@/components/RenderedDiffViewer';
import { ReviewContextPanel } from '@/components/ReviewContextPanel';
import { ReviewContextSidebar } from '@/components/ReviewContextSidebar';
import { PreambleInput } from '@/components/PreambleInput';
import { PromptPreview } from '@/components/PromptPreview';
import { ConfirmationDialog } from '@/components/ConfirmationDialog';
import { ToastNotification } from '@/components/ToastNotification';
import { useFileFromUrl } from '@/hooks/useFileFromUrl';
import { isBinary } from '@/lib/binaryDetect';
import { detectLanguage } from '@/lib/languageDetect';
import { useState, useEffect, useCallback, useRef } from 'react';
import type { RenderMode } from '@/types';

function useWindowWidth() {
  const [width, setWidth] = useState(window.innerWidth);
  useEffect(() => {
    const handleResize = () => setWidth(window.innerWidth);
    window.addEventListener('resize', handleResize);
    return () => window.removeEventListener('resize', handleResize);
  }, []);
  return width;
}

type DialogType = 'clear' | 'mode-switch' | 'refresh' | 'render-mode-switch' | null;

export function App() {
  const file = useAppStore((s) => s.file);
  const fileOrder = useAppStore((s) => s.fileOrder);
  const isAddFileModalOpen = useAppStore((s) => s.isAddFileModalOpen);
  const closeAddFileModal = useAppStore((s) => s.closeAddFileModal);
  const addFile = useAppStore((s) => s.addFile);
  const showToast = useAppStore((s) => s.showToast);
  const fileCommentCount = useAppStore((s) => Object.keys(s.comments).length);
  const diffCommentCount = useAppStore((s) => Object.keys(s.diffComments).length);
  const viewMode = useAppStore((s) => s.viewMode);
  const isBaselineLoading = useAppStore((s) => s.isBaselineLoading);
  const baselineError = useAppStore((s) => s.baselineError);
  const isDiffEmpty = useAppStore((s) => s.isDiffEmpty);
  const diffLines = useAppStore((s) => s.diffLines);
  const renderMode = useAppStore((s) => s.renderMode);
  const isMarkdown = useAppStore((s) => s.isMarkdownFile);
  const renderedCommentCount = useAppStore((s) => Object.keys(s.renderedComments).length);
  const renderedDiffCommentCount = useAppStore((s) => Object.keys(s.renderedDiffComments).length);
  const clearSession = useAppStore((s) => s.clearSession);
  const setViewMode = useAppStore((s) => s.setViewMode);
  const setRenderMode = useAppStore((s) => s.setRenderMode);
  const clearDiffComments = useAppStore((s) => s.clearDiffComments);
  const clearRenderedComments = useAppStore((s) => s.clearRenderedComments);
  const clearRenderedDiffComments = useAppStore((s) => s.clearRenderedDiffComments);
  const fetchBaseline = useAppStore((s) => s.fetchBaseline);
  const refreshDiff = useAppStore((s) => s.refreshDiff);
  const computeRenderedDiff = useAppStore((s) => s.computeRenderedDiff);
  const isAstDiffComputing = useAppStore((s) => s.isAstDiffComputing);
  const astDiffResult = useAppStore((s) => s.astDiffResult);

  const [activeDialog, setActiveDialog] = useState<DialogType>(null);
  const [pendingMode, setPendingMode] = useState<'file' | 'diff' | null>(null);
  const [pendingRenderMode, setPendingRenderMode] = useState<RenderMode | null>(null);

  // Compute AST diff when entering rendered+diff mode
  useEffect(() => {
    if (renderMode === 'rendered' && viewMode === 'diff' && diffLines && !astDiffResult && !isAstDiffComputing) {
      computeRenderedDiff();
    }
  }, [renderMode, viewMode, diffLines, astDiffResult, isAstDiffComputing, computeRenderedDiff]);

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

  const handleRenderModeChange = useCallback((mode: RenderMode) => {
    if (mode === renderMode) return;

    // Check if current render mode has comments
    const currentRenderedCommentCount = renderMode === 'rendered'
      ? (viewMode === 'diff' ? renderedDiffCommentCount : renderedCommentCount)
      : 0; // Raw mode comments are separate, don't need clearing when switching render mode
    const currentRawCommentCount = renderMode === 'raw'
      ? (viewMode === 'diff' ? diffCommentCount : fileCommentCount)
      : 0;

    const currentCommentCount = currentRenderedCommentCount + currentRawCommentCount;
    if (currentCommentCount > 0) {
      setPendingRenderMode(mode);
      setActiveDialog('render-mode-switch');
    } else {
      setRenderMode(mode);
    }
  }, [renderMode, viewMode, renderedCommentCount, renderedDiffCommentCount, diffCommentCount, fileCommentCount, setRenderMode]);

  const handleRenderModeSwitchConfirm = () => {
    if (!pendingRenderMode) return;

    // Clear comments for the render mode we're leaving
    if (renderMode === 'rendered') {
      if (viewMode === 'diff') {
        clearRenderedDiffComments();
      } else {
        clearRenderedComments();
      }
    } else {
      // Leaving raw mode
      if (viewMode === 'diff') {
        clearDiffComments();
      } else {
        useAppStore.setState({
          comments: {},
          commentOrder: [],
          focusedCommentId: null,
          generatedPrompt: null,
        });
      }
    }

    setRenderMode(pendingRenderMode);
    setActiveDialog(null);
    setPendingRenderMode(null);
  };

  const handleSwitchToFile = () => {
    setViewMode('file');
  };

  // Global drop handler: when files are loaded, dropping on the main area adds files
  const globalDragCounter = useRef(0);
  const [showGlobalDrop, setShowGlobalDrop] = useState(false);

  const handleGlobalDragEnter = useCallback((e: React.DragEvent) => {
    if (!file) return;
    e.preventDefault();
    globalDragCounter.current++;
    if (globalDragCounter.current === 1) {
      setShowGlobalDrop(true);
    }
  }, [file]);

  const handleGlobalDragLeave = useCallback((e: React.DragEvent) => {
    e.preventDefault();
    globalDragCounter.current--;
    if (globalDragCounter.current === 0) {
      setShowGlobalDrop(false);
    }
  }, []);

  const handleGlobalDragOver = useCallback((e: React.DragEvent) => {
    if (!file) return;
    e.preventDefault();
  }, [file]);

  const handleGlobalDrop = useCallback(async (e: React.DragEvent) => {
    e.preventDefault();
    globalDragCounter.current = 0;
    setShowGlobalDrop(false);
    if (!file) return;

    const droppedFiles = e.dataTransfer.files;
    let loaded = 0;
    let skipped = 0;

    for (let i = 0; i < droppedFiles.length; i++) {
      const f = droppedFiles[i]!;
      try {
        const buffer = await f.arrayBuffer();
        if (isBinary(buffer)) { skipped++; continue; }
        const content = new TextDecoder('utf-8').decode(buffer);
        const language = detectLanguage(f.name);
        addFile(content, f.name, language);
        loaded++;
      } catch {
        skipped++;
      }
    }

    if (loaded > 0) {
      const msg = skipped > 0
        ? `Added ${loaded} file${loaded > 1 ? 's' : ''} (${skipped} skipped)`
        : `Added ${loaded} file${loaded > 1 ? 's' : ''}`;
      showToast(msg, 'success');
    }
  }, [file, addFile, showToast]);

  if (isTooNarrow) {
    return (
      <div className="flex flex-col h-screen">
        <Toolbar
          onClearRequest={handleClearRequest}
          onModeChange={handleModeChange}
          onRefreshRequest={handleRefreshRequest}
          onRenderModeChange={isMarkdown ? handleRenderModeChange : undefined}
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
    // Rendered file mode
    if (renderMode === 'rendered' && viewMode === 'file') {
      return <RenderedViewer />;
    }

    // Raw file mode
    if (viewMode === 'file') {
      return <CodeViewer />;
    }

    // Diff mode (rendered or raw)
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
      if (renderMode === 'rendered') {
        return <RenderedDiffViewer />;
      }
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
        onRenderModeChange={isMarkdown ? handleRenderModeChange : undefined}
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
          <div
            className="flex h-full relative"
            onDragEnter={handleGlobalDragEnter}
            onDragLeave={handleGlobalDragLeave}
            onDragOver={handleGlobalDragOver}
            onDrop={(e) => void handleGlobalDrop(e)}
          >
            {/* Left column: code viewer */}
            <div className="flex-1 flex flex-col min-w-0 border-r border-border-default">
              {fileOrder.length >= 2 ? <FileTabBar /> : <FileHeader />}
              <ReviewContextPanel />
              <div className="flex-1 min-h-0">
                {renderCodePanel()}
              </div>
            </div>

            {/* Right column: sidebar */}
            <div className={`flex-shrink-0 flex flex-col bg-surface-sidebar overflow-y-auto ${
              windowWidth < 1280 ? 'w-72' : 'w-96'
            }`}>
              <ReviewContextSidebar />
              <PreambleInput />
              <PromptPreview />
            </div>

            {/* Global drop overlay */}
            {showGlobalDrop && (
              <div className="absolute inset-0 z-40 flex items-center justify-center bg-selection-bg/80 border-2 border-dashed border-primary-500 rounded pointer-events-none">
                <p className="text-sm font-medium text-primary-600">Drop to add file(s)</p>
              </div>
            )}
          </div>
        )}
      </main>

      {/* Add file modal */}
      {isAddFileModalOpen && (
        <FileDropZone variant="modal" onClose={closeAddFileModal} />
      )}

      {/* Clear session dialog */}
      {activeDialog === 'clear' && (
        <ConfirmationDialog
          title="Clear session?"
          message={fileOrder.length > 1
            ? `This will remove all ${fileOrder.length} files, all comments, and the generated prompt. This action cannot be undone.`
            : 'This will remove the loaded file, all comments, and the generated prompt. This action cannot be undone.'}
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

      {/* Render mode switch dialog */}
      {activeDialog === 'render-mode-switch' && (
        <ConfirmationDialog
          title="Switch render mode?"
          message={`Switching to ${pendingRenderMode === 'rendered' ? 'Rendered' : 'Raw'} view will clear your current comments. This action cannot be undone.`}
          confirmLabel="Switch"
          onConfirm={handleRenderModeSwitchConfirm}
          onCancel={() => { setActiveDialog(null); setPendingRenderMode(null); }}
        />
      )}

      <ToastNotification />
    </div>
  );
}
