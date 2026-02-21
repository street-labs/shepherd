// Implements: FR-crp-file-load, AC-crp-load-paste, AC-crp-load-upload, AC-crp-load-drag-drop,
// AC-crp-binary-file-rejected, AC-crp-empty-state

import { useAppStore } from '@/store/appStore';
import { isBinary } from '@/lib/binaryDetect';
import { detectLanguage } from '@/lib/languageDetect';
import { useState, useRef, useCallback } from 'react';

type DropZoneVariant = 'default' | 'drag-hover' | 'paste-mode' | 'loading' | 'error';

export function FileDropZone() {
  const loadFile = useAppStore((s) => s.loadFile);
  const [variant, setVariant] = useState<DropZoneVariant>('default');
  const [errorMessage, setErrorMessage] = useState('');
  const [pasteText, setPasteText] = useState('');
  const fileInputRef = useRef<HTMLInputElement>(null);
  const dragCounterRef = useRef(0);

  const processFile = useCallback(
    async (file: File) => {
      setVariant('loading');
      try {
        const buffer = await file.arrayBuffer();
        if (isBinary(buffer)) {
          setErrorMessage('This appears to be a binary file. Only text files are supported.');
          setVariant('error');
          return;
        }
        const content = new TextDecoder('utf-8').decode(buffer);
        const language = detectLanguage(file.name);
        loadFile(content, file.name, language);
      } catch {
        setErrorMessage('Failed to read file. Please try again.');
        setVariant('error');
      }
    },
    [loadFile],
  );

  const handleDragEnter = (e: React.DragEvent) => {
    e.preventDefault();
    e.stopPropagation();
    dragCounterRef.current++;
    if (dragCounterRef.current === 1) {
      setVariant('drag-hover');
    }
  };

  const handleDragLeave = (e: React.DragEvent) => {
    e.preventDefault();
    e.stopPropagation();
    dragCounterRef.current--;
    if (dragCounterRef.current === 0) {
      setVariant('default');
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
    setVariant('default');

    const files = e.dataTransfer.files;
    if (files.length > 0) {
      void processFile(files[0]!);
    }
  };

  const handleFileSelect = (e: React.ChangeEvent<HTMLInputElement>) => {
    const file = e.target.files?.[0];
    if (file) {
      void processFile(file);
    }
  };

  const handlePasteSubmit = () => {
    if (!pasteText.trim()) return;
    loadFile(pasteText, 'Untitled', 'plaintext');
  };

  const handleKeyDown = (e: React.KeyboardEvent<HTMLTextAreaElement>) => {
    if ((e.metaKey || e.ctrlKey) && e.key === 'Enter') {
      handlePasteSubmit();
    }
  };

  if (variant === 'paste-mode') {
    return (
      <div className="flex flex-col items-center justify-center h-full p-8">
        <div className="w-full max-w-2xl">
          <textarea
            value={pasteText}
            onChange={(e) => setPasteText(e.target.value)}
            onKeyDown={handleKeyDown}
            placeholder="Paste your code here..."
            className="w-full h-64 p-4 font-mono text-sm border border-border-default rounded-lg resize-none focus:outline-none focus:ring-2 focus:ring-primary-500 focus:border-transparent"
            autoFocus
          />
          <div className="flex gap-2 mt-3 justify-end">
            <button
              onClick={() => {
                setVariant('default');
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
              Load Code
            </button>
          </div>
          <p className="text-xs text-text-tertiary mt-2 text-right">⌘+Enter to submit</p>
        </div>
      </div>
    );
  }

  return (
    <div
      className={`flex flex-col items-center justify-center h-full p-8 transition-colors ${
        variant === 'drag-hover'
          ? 'bg-blue-50'
          : ''
      }`}
      onDragEnter={handleDragEnter}
      onDragLeave={handleDragLeave}
      onDragOver={handleDragOver}
      onDrop={handleDrop}
    >
      <div
        className={`flex flex-col items-center gap-4 p-12 border-2 border-dashed rounded-xl max-w-lg w-full transition-colors ${
          variant === 'drag-hover'
            ? 'border-primary-500 bg-blue-50/50'
            : variant === 'error'
              ? 'border-destructive-500 bg-red-50/50'
              : 'border-border-strong'
        }`}
      >
        {variant === 'loading' ? (
          <div className="text-sm text-text-secondary">Loading file...</div>
        ) : variant === 'error' ? (
          <>
            <div className="text-sm text-destructive-600 text-center">{errorMessage}</div>
            <button
              onClick={() => setVariant('default')}
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
                {variant === 'drag-hover'
                  ? 'Drop file here'
                  : 'Drop a file here to get started'}
              </p>
              <p className="text-xs text-text-secondary mt-1">or use one of the options below</p>
            </div>
            <div className="flex gap-2 mt-2">
              <button
                onClick={() => fileInputRef.current?.click()}
                className="px-4 py-2 text-sm font-medium rounded bg-primary-500 text-text-on-primary hover:bg-primary-600"
              >
                Upload file
              </button>
              <button
                onClick={() => setVariant('paste-mode')}
                className="px-4 py-2 text-sm rounded border border-border-default hover:bg-surface-secondary"
              >
                Paste code
              </button>
            </div>
            <input
              ref={fileInputRef}
              type="file"
              onChange={handleFileSelect}
              className="hidden"
              aria-label="Upload file"
            />
          </>
        )}
      </div>
    </div>
  );
}
