// Implements: FR-mf-tab-bar, FR-mf-tab-switch, FR-mf-tab-close

import { useAppStore } from '@/store/appStore';
import { ConfirmationDialog } from './ConfirmationDialog';
import { useState, useCallback } from 'react';

export function FileTabBar() {
  const files = useAppStore((s) => s.files);
  const fileOrder = useAppStore((s) => s.fileOrder);
  const activeFileId = useAppStore((s) => s.activeFileId);
  const comments = useAppStore((s) => s.comments);
  const setActiveFile = useAppStore((s) => s.setActiveFile);
  const removeFile = useAppStore((s) => s.removeFile);
  const openAddFileModal = useAppStore((s) => s.openAddFileModal);

  const [confirmRemoveId, setConfirmRemoveId] = useState<string | null>(null);

  const getCommentCount = useCallback(
    (fileId: string) => {
      return Object.values(comments).filter((c) => c.fileId === fileId).length;
    },
    [comments],
  );

  const handleClose = useCallback(
    (e: React.MouseEvent, fileId: string) => {
      e.stopPropagation();
      const count = getCommentCount(fileId);
      if (count > 0) {
        setConfirmRemoveId(fileId);
      } else {
        removeFile(fileId);
      }
    },
    [getCommentCount, removeFile],
  );

  const handleConfirmRemove = () => {
    if (confirmRemoveId) {
      removeFile(confirmRemoveId);
      setConfirmRemoveId(null);
    }
  };

  const handleKeyDown = useCallback(
    (e: React.KeyboardEvent) => {
      if (!activeFileId) return;
      const currentIndex = fileOrder.indexOf(activeFileId);

      switch (e.key) {
        case 'ArrowLeft': {
          e.preventDefault();
          const prev = currentIndex > 0 ? fileOrder[currentIndex - 1] : fileOrder[fileOrder.length - 1];
          if (prev) setActiveFile(prev);
          break;
        }
        case 'ArrowRight': {
          e.preventDefault();
          const next = currentIndex < fileOrder.length - 1 ? fileOrder[currentIndex + 1] : fileOrder[0];
          if (next) setActiveFile(next);
          break;
        }
        case 'Delete':
        case 'Backspace': {
          e.preventDefault();
          const count = getCommentCount(activeFileId);
          if (count > 0) {
            setConfirmRemoveId(activeFileId);
          } else {
            removeFile(activeFileId);
          }
          break;
        }
      }
    },
    [activeFileId, fileOrder, setActiveFile, removeFile, getCommentCount],
  );

  return (
    <>
      <div
        className="flex items-center h-10 border-b border-border-default bg-surface-secondary flex-shrink-0 overflow-x-auto"
        role="tablist"
        aria-label="Open files"
        onKeyDown={handleKeyDown}
      >
        {fileOrder.map((fileId) => {
          const file = files[fileId];
          if (!file) return null;
          const isActive = fileId === activeFileId;
          const count = getCommentCount(fileId);

          return (
            <button
              key={fileId}
              role="tab"
              aria-selected={isActive}
              tabIndex={isActive ? 0 : -1}
              onClick={() => setActiveFile(fileId)}
              className={`group relative flex items-center gap-1.5 px-3 h-full text-sm font-mono border-r border-border-default whitespace-nowrap ${
                isActive
                  ? 'bg-surface-primary text-text-primary border-b-2 border-b-primary-500'
                  : 'text-text-secondary hover:bg-surface-primary/50'
              }`}
            >
              <span className="max-w-[120px] truncate">{file.name}</span>

              {count > 0 && (
                <span className="text-[10px] leading-none px-1 py-0.5 rounded-full bg-primary-500/15 text-primary-600 tabular-nums">
                  {count}
                </span>
              )}

              <span
                onClick={(e) => handleClose(e, fileId)}
                className={`ml-0.5 w-4 h-4 flex items-center justify-center rounded text-text-tertiary hover:text-text-primary hover:bg-surface-secondary ${
                  isActive ? 'opacity-100' : 'opacity-0 group-hover:opacity-100'
                }`}
                aria-label={`Close ${file.name}`}
                role="button"
              >
                &times;
              </span>
            </button>
          );
        })}

        <button
          onClick={openAddFileModal}
          className="flex items-center justify-center w-8 h-full text-text-tertiary hover:text-text-primary hover:bg-surface-primary/50"
          aria-label="Add file"
          title="Add file"
        >
          +
        </button>
      </div>

      {confirmRemoveId && (
        <ConfirmationDialog
          title="Remove file?"
          message={`"${files[confirmRemoveId]?.name ?? 'file'}" has comments that will be lost. This action cannot be undone.`}
          confirmLabel="Remove"
          onConfirm={handleConfirmRemove}
          onCancel={() => setConfirmRemoveId(null)}
        />
      )}
    </>
  );
}
