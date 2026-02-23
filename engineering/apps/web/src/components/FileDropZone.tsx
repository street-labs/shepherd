// Implements: FR-crp-file-load, AC-crp-load-paste, AC-crp-load-upload, AC-crp-load-drag-drop,
// AC-crp-binary-file-rejected, AC-crp-empty-state, FR-mf-add-file

import { useAppStore } from '@/store/appStore';
import { isBinary } from '@/lib/binaryDetect';
import { detectLanguage } from '@/lib/languageDetect';
import { useState, useRef, useCallback, useEffect } from 'react';
import { createPortal } from 'react-dom';

type DropZoneVariant = 'default' | 'drag-hover' | 'paste-mode' | 'loading' | 'error';

interface FileDropZoneProps {
  /** 'full' = empty-state page (uses loadFile). 'modal' = add-file dialog (uses addFile). */
  variant?: 'full' | 'modal';
  onClose?: () => void;
}

export function FileDropZone({ variant: displayVariant = 'full', onClose }: FileDropZoneProps) {
  const loadFile = useAppStore((s) => s.loadFile);
  const addFile = useAppStore((s) => s.addFile);
  const setFileSource = useAppStore((s) => s.setFileSource);
  const showToast = useAppStore((s) => s.showToast);
  const [dropVariant, setDropVariant] = useState<DropZoneVariant>('default');
  const [errorMessage, setErrorMessage] = useState('');
  const [pasteText, setPasteText] = useState('');
  const fileInputRef = useRef<HTMLInputElement>(null);
  const dragCounterRef = useRef(0);

  const isModal = displayVariant === 'modal';

  const handleFileLoaded = useCallback(
    (content: string, fileName: string, language: string) => {
      if (isModal) {
        addFile(content, fileName, language);
      } else {
        loadFile(content, fileName, language);
        setFileSource('local');
      }
    },
    [isModal, loadFile, addFile, setFileSource],
  );

  const processFile = useCallback(
    async (file: File) => {
      setDropVariant('loading');
      try {
        const buffer = await file.arrayBuffer();
        if (isBinary(buffer)) {
          setErrorMessage('This appears to be a binary file. Only text files are supported.');
          setDropVariant('error');
          return;
        }
        const content = new TextDecoder('utf-8').decode(buffer);
        const language = detectLanguage(file.name);
        handleFileLoaded(content, file.name, language);
      } catch {
        setErrorMessage('Failed to read file. Please try again.');
        setDropVariant('error');
      }
    },
    [handleFileLoaded],
  );

  const processMultipleFiles = useCallback(
    async (fileList: FileList) => {
      if (fileList.length === 0) return;

      // Single file: use normal flow
      if (fileList.length === 1) {
        await processFile(fileList[0]!);
        return;
      }

      // Multiple files
      setDropVariant('loading');
      let loaded = 0;
      let skipped = 0;

      for (let i = 0; i < fileList.length; i++) {
        const file = fileList[i]!;
        try {
          const buffer = await file.arrayBuffer();
          if (isBinary(buffer)) {
            skipped++;
            continue;
          }
          const content = new TextDecoder('utf-8').decode(buffer);
          const language = detectLanguage(file.name);
          if (i === 0 && !isModal) {
            // First file in full mode uses loadFile
            loadFile(content, file.name, language);
            setFileSource('local');
          } else {
            addFile(content, file.name, language);
          }
          loaded++;
        } catch {
          skipped++;
        }
      }

      if (loaded > 0) {
        const msg = skipped > 0
          ? `Loaded ${loaded} file${loaded > 1 ? 's' : ''} (${skipped} skipped)`
          : `Loaded ${loaded} file${loaded > 1 ? 's' : ''}`;
        showToast(msg, 'success');
        onClose?.();
      } else {
        setErrorMessage('No valid text files found.');
        setDropVariant('error');
      }
    },
    [processFile, isModal, loadFile, addFile, setFileSource, showToast, onClose],
  );

  const handleDragEnter = (e: React.DragEvent) => {
    e.preventDefault();
    e.stopPropagation();
    dragCounterRef.current++;
    if (dragCounterRef.current === 1) {
      setDropVariant('drag-hover');
    }
  };

  const handleDragLeave = (e: React.DragEvent) => {
    e.preventDefault();
    e.stopPropagation();
    dragCounterRef.current--;
    if (dragCounterRef.current === 0) {
      setDropVariant('default');
    }
  };

  const handleDragOver = (e: React.DragEvent) => {
    e.preventDefault();
    e.stopPropagation();
  };

  const handleDrop = (e: React.DragEvent) => {
    e.preventDefault();
    e.stopPropagation();
    dragCounterRef.current = 0;
    setDropVariant('default');

    const files = e.dataTransfer.files;
    if (files.length > 0) {
      void processMultipleFiles(files);
    }
  };

  const handleFileSelect = (e: React.ChangeEvent<HTMLInputElement>) => {
    const files = e.target.files;
    if (files && files.length > 0) {
      void processMultipleFiles(files);
    }
  };

  const handlePasteSubmit = () => {
    if (!pasteText.trim()) return;
    handleFileLoaded(pasteText, 'Untitled', 'plaintext');
    onClose?.();
  };

  const handlePasteKeyDown = (e: React.KeyboardEvent<HTMLTextAreaElement>) => {
    if ((e.metaKey || e.ctrlKey) && e.key === 'Enter') {
      handlePasteSubmit();
    }
  };

  // Escape key to close modal
  useEffect(() => {
    if (!isModal) return;
    const handler = (e: KeyboardEvent) => {
      if (e.key === 'Escape') {
        e.preventDefault();
        onClose?.();
      }
    };
    document.addEventListener('keydown', handler);
    return () => document.removeEventListener('keydown', handler);
  }, [isModal, onClose]);

  const dropContent = (
    <div
      className={`flex flex-col items-center justify-center ${isModal ? 'p-6' : 'h-full p-8'} transition-colors ${
        dropVariant === 'drag-hover' ? 'bg-selection-bg' : ''
      }`}
      onDragEnter={handleDragEnter}
      onDragLeave={handleDragLeave}
      onDragOver={handleDragOver}
      onDrop={handleDrop}
    >
      {dropVariant === 'paste-mode' ? (
        <div className="w-full max-w-2xl">
          <textarea
            value={pasteText}
            onChange={(e) => setPasteText(e.target.value)}
            onKeyDown={handlePasteKeyDown}
            placeholder="Paste your code here..."
            className="w-full h-64 p-4 font-mono text-sm border border-border-default rounded-lg resize-none focus:outline-none focus:ring-2 focus:ring-primary-500 focus:border-transparent"
            autoFocus
          />
          <div className="flex gap-2 mt-3 justify-end">
            <button
              onClick={() => {
                setDropVariant('default');
                setPasteText('');
              }}
              className="px-4 py-2 text-sm rounded border border-border-default hover:bg-surface-secondary"
            >
              Cancel
            </button>
            <button
              onClick={handlePasteSubmit}
              disabled={!pasteText.trim()}
              className="px-4 py-2 text-sm font-medium rounded bg-primary-500 text-text-on-primary hover:bg-primary-600 disabled:opacity-40 disabled:cursor-not-allowed"
            >
              {isModal ? 'Add Code' : 'Load Code'}
            </button>
          </div>
          <p className="text-xs text-text-tertiary mt-2 text-right">Cmd+Enter to submit</p>
        </div>
      ) : (
        <div
          className={`flex flex-col items-center gap-4 ${isModal ? 'p-8' : 'p-12'} border-2 border-dashed rounded-xl max-w-lg w-full transition-colors ${
            dropVariant === 'drag-hover'
              ? 'border-primary-500 bg-selection-bg/50'
              : dropVariant === 'error'
                ? 'border-destructive-500 bg-destructive-500/10'
                : 'border-border-strong'
          }`}
        >
          {dropVariant === 'loading' ? (
            <div className="text-sm text-text-secondary">Loading file...</div>
          ) : dropVariant === 'error' ? (
            <>
              <div className="text-sm text-destructive-600 text-center">{errorMessage}</div>
              <button
                onClick={() => setDropVariant('default')}
                className="px-4 py-2 text-sm rounded border border-border-default hover:bg-surface-secondary"
              >
                Try again
              </button>
            </>
          ) : (
            <>
              <div className="text-4xl text-text-tertiary">📄</div>
              <div className="text-center">
                <p className="text-sm font-medium text-text-primary">
                  {dropVariant === 'drag-hover'
                    ? isModal ? 'Drop file(s) here' : 'Drop file here'
                    : isModal ? 'Drop file(s) here to add' : 'Drop a file here to get started'}
                </p>
                <p className="text-xs text-text-secondary mt-1">or use one of the options below</p>
              </div>
              <div className="flex gap-2 mt-2">
                <button
                  onClick={() => fileInputRef.current?.click()}
                  className="px-4 py-2 text-sm font-medium rounded bg-primary-500 text-text-on-primary hover:bg-primary-600"
                >
                  {isModal ? 'Choose file(s)' : 'Upload file'}
                </button>
                <button
                  onClick={() => setDropVariant('paste-mode')}
                  className="px-4 py-2 text-sm rounded border border-border-default hover:bg-surface-secondary"
                >
                  Paste code
                </button>
              </div>
              <input
                ref={fileInputRef}
                type="file"
                multiple={isModal}
                onChange={handleFileSelect}
                className="hidden"
                aria-label={isModal ? 'Choose files to add' : 'Upload file'}
              />
            </>
          )}
        </div>
      )}
    </div>
  );

  if (!isModal) return dropContent;

  // Modal variant: render in a portal
  return createPortal(
    <div
      className="fixed inset-0 z-50 flex items-center justify-center"
      role="dialog"
      aria-modal="true"
      aria-label="Add file"
    >
      <div
        className="absolute inset-0"
        style={{ backgroundColor: 'var(--color-dialog-backdrop)' }}
        onClick={onClose}
      />
      <div className="relative bg-surface-primary rounded-lg shadow-lg max-w-xl w-full mx-4">
        <div className="flex items-center justify-between px-4 py-3 border-b border-border-default">
          <h2 className="text-sm font-semibold text-text-primary">Add File</h2>
          <button
            onClick={onClose}
            className="text-text-tertiary hover:text-text-primary"
            aria-label="Close"
          >
            &times;
          </button>
        </div>
        {dropContent}
      </div>
    </div>,
    document.body,
  );
}
