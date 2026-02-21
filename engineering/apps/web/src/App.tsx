// Implements: FR-crp-file-load, FR-crp-file-display, NFR-crp-responsive-layout

import { useAppStore } from '@/store/appStore';
import { Toolbar } from '@/components/Toolbar';
import { FileDropZone } from '@/components/FileDropZone';
import { FileHeader } from '@/components/FileHeader';
import { CodeViewer } from '@/components/CodeViewer';
import { PreambleInput } from '@/components/PreambleInput';
import { PromptPreview } from '@/components/PromptPreview';
import { ConfirmationDialog } from '@/components/ConfirmationDialog';
import { ToastNotification } from '@/components/ToastNotification';
import { useState, useEffect } from 'react';

function useWindowWidth() {
  const [width, setWidth] = useState(window.innerWidth);
  useEffect(() => {
    const handleResize = () => setWidth(window.innerWidth);
    window.addEventListener('resize', handleResize);
    return () => window.removeEventListener('resize', handleResize);
  }, []);
  return width;
}

export function App() {
  const file = useAppStore((s) => s.file);
  const commentCount = useAppStore(
    (s) => Object.keys(s.comments).length,
  );
  const clearSession = useAppStore((s) => s.clearSession);
  const [showClearDialog, setShowClearDialog] = useState(false);
  const windowWidth = useWindowWidth();
  const isTooNarrow = windowWidth < 1024;

  const handleClearRequest = () => {
    // AC-crp-clear-no-confirm-empty: no confirmation if no comments
    if (commentCount === 0) {
      clearSession();
    } else {
      setShowClearDialog(true);
    }
  };

  const handleClearConfirm = () => {
    clearSession();
    setShowClearDialog(false);
  };

  if (isTooNarrow) {
    return (
      <div className="flex flex-col h-screen">
        <Toolbar onClearRequest={handleClearRequest} />
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

  return (
    <div className="flex flex-col h-screen">
      <Toolbar onClearRequest={handleClearRequest} />

      <main className="flex-1 min-h-0">
        {!file ? (
          <FileDropZone />
        ) : (
          <div className="flex h-full">
            {/* Left column: code viewer */}
            <div className="flex-1 flex flex-col min-w-0 border-r border-border-default">
              <FileHeader />
              <div className="flex-1 min-h-0">
                <CodeViewer />
              </div>
            </div>

            {/* Right column: sidebar — narrower between 1024-1279px */}
            <div className={`flex-shrink-0 flex flex-col bg-surface-sidebar overflow-y-auto ${
              windowWidth < 1280 ? 'w-72' : 'w-96'
            }`}>
              <PreambleInput />
              <PromptPreview />
            </div>
          </div>
        )}
      </main>

      {showClearDialog && (
        <ConfirmationDialog
          title="Clear session?"
          message="This will remove the loaded file, all comments, and the generated prompt. This action cannot be undone."
          confirmLabel="Clear"
          onConfirm={handleClearConfirm}
          onCancel={() => setShowClearDialog(false)}
        />
      )}

      <ToastNotification />
    </div>
  );
}
