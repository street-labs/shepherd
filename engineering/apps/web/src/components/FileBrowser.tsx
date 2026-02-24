// Implements: FR-crp-file-reviewed-toggle, FR-crp-file-reviewed-visual,
// FR-crp-file-reviewed-grouping, FR-crp-file-reviewed-progress,
// FR-mf-tab-bar, FR-mf-tab-switch, FR-mf-tab-close

import { useAppStore } from '@/store/appStore';
import { ConfirmationDialog } from './ConfirmationDialog';
import { useState, useCallback, useMemo, useRef, useEffect } from 'react';

export function FileBrowser() {
  const files = useAppStore((s) => s.files);
  const fileOrder = useAppStore((s) => s.fileOrder);
  const activeFileId = useAppStore((s) => s.activeFileId);
  const comments = useAppStore((s) => s.comments);
  const reviewedFiles = useAppStore((s) => s.reviewedFiles);
  const setActiveFile = useAppStore((s) => s.setActiveFile);
  const removeFile = useAppStore((s) => s.removeFile);
  const openAddFileModal = useAppStore((s) => s.openAddFileModal);
  const toggleFileReviewed = useAppStore((s) => s.toggleFileReviewed);

  const [confirmRemoveId, setConfirmRemoveId] = useState<string | null>(null);
  const listRef = useRef<HTMLDivElement>(null);

  const getCommentCount = useCallback(
    (fileId: string) => {
      return Object.values(comments).filter((c) => c.fileId === fileId).length;
    },
    [comments],
  );

  // Split files into reviewed / to-review groups
  const { toReview, reviewed } = useMemo(() => {
    const toReview: string[] = [];
    const reviewed: string[] = [];
    for (const id of fileOrder) {
      if (reviewedFiles.has(id)) {
        reviewed.push(id);
      } else {
        toReview.push(id);
      }
    }
    return { toReview, reviewed };
  }, [fileOrder, reviewedFiles]);

  const reviewedCount = reviewed.length;
  const totalCount = fileOrder.length;
  const allReviewed = totalCount > 0 && reviewedCount === totalCount;

  // Flat ordered list for keyboard navigation
  const flatList = useMemo(() => [...toReview, ...reviewed], [toReview, reviewed]);

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
      const currentIndex = flatList.indexOf(activeFileId);

      switch (e.key) {
        case 'ArrowUp': {
          e.preventDefault();
          const prev = currentIndex > 0 ? flatList[currentIndex - 1] : flatList[flatList.length - 1];
          if (prev) setActiveFile(prev);
          break;
        }
        case 'ArrowDown': {
          e.preventDefault();
          const next = currentIndex < flatList.length - 1 ? flatList[currentIndex + 1] : flatList[0];
          if (next) setActiveFile(next);
          break;
        }
        case 'r': {
          e.preventDefault();
          toggleFileReviewed(activeFileId);
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
    [activeFileId, flatList, setActiveFile, removeFile, getCommentCount, toggleFileReviewed],
  );

  // Scroll active file into view
  useEffect(() => {
    if (!activeFileId || !listRef.current) return;
    const el = listRef.current.querySelector(`[data-file-id="${activeFileId}"]`);
    if (el) {
      el.scrollIntoView({ block: 'nearest' });
    }
  }, [activeFileId]);

  const renderFileRow = (fileId: string) => {
    const file = files[fileId];
    if (!file) return null;
    const isActive = fileId === activeFileId;
    const isReviewed = reviewedFiles.has(fileId);
    const count = getCommentCount(fileId);

    return (
      <div
        key={fileId}
        role="option"
        aria-selected={isActive}
        data-file-id={fileId}
        onClick={() => setActiveFile(fileId)}
        className={`group flex items-center gap-1.5 px-2 h-9 cursor-pointer text-sm font-mono flex-shrink-0 ${
          isActive
            ? 'border-l-[3px] border-l-primary-500 bg-surface-primary font-semibold text-text-primary'
            : isReviewed
            ? 'border-l-[3px] border-l-transparent text-text-tertiary hover:bg-surface-primary/50'
            : 'border-l-[3px] border-l-transparent text-text-secondary hover:bg-surface-primary/50'
        }`}
      >
        {/* Reviewed checkmark */}
        {isReviewed && (
          <span className="text-success-600 text-xs flex-shrink-0" aria-label="Reviewed">
            &#x2713;
          </span>
        )}

        {/* File name */}
        <span className="truncate flex-1 min-w-0">{file.name}</span>

        {/* Comment count badge */}
        {count > 0 && (
          <span className="text-[10px] leading-none px-1.5 py-0.5 rounded-full bg-primary-500 text-white tabular-nums flex-shrink-0">
            {count}
          </span>
        )}

        {/* Review toggle */}
        <button
          onClick={(e) => {
            e.stopPropagation();
            toggleFileReviewed(fileId);
          }}
          className={`w-4 h-4 flex items-center justify-center rounded text-xs flex-shrink-0 ${
            isReviewed
              ? 'text-success-600 opacity-100'
              : 'text-text-tertiary opacity-0 group-hover:opacity-100 hover:text-success-600'
          }`}
          aria-label={isReviewed ? `Unmark ${file.name} as reviewed` : `Mark ${file.name} as reviewed`}
          title={isReviewed ? 'Unmark reviewed' : 'Mark reviewed'}
        >
          {isReviewed ? '\u2713' : '\u25CB'}
        </button>

        {/* Close button */}
        <button
          onClick={(e) => handleClose(e, fileId)}
          className={`w-4 h-4 flex items-center justify-center rounded text-text-tertiary hover:text-text-primary hover:bg-surface-secondary flex-shrink-0 ${
            isActive ? 'opacity-100' : 'opacity-0 group-hover:opacity-100'
          }`}
          aria-label={`Close ${file.name}`}
        >
          &times;
        </button>
      </div>
    );
  };

  const hasGroups = reviewed.length > 0 && toReview.length > 0;

  return (
    <>
      <div
        className="w-60 flex flex-col border-r border-border-default bg-surface-secondary flex-shrink-0 h-full"
        role="listbox"
        aria-label="File browser"
        onKeyDown={handleKeyDown}
        tabIndex={0}
      >
        {/* Header */}
        <div className="flex items-center gap-2 px-3 h-10 border-b border-border-default flex-shrink-0">
          <span className="text-[10px] font-semibold tracking-wider text-text-tertiary uppercase">Files</span>
          <span className={`text-[10px] tabular-nums ${allReviewed ? 'text-success-600 font-medium' : 'text-text-tertiary'}`}>
            {reviewedCount}/{totalCount} reviewed
          </span>
          <button
            onClick={openAddFileModal}
            className="ml-auto w-5 h-5 flex items-center justify-center rounded text-text-tertiary hover:text-text-primary hover:bg-surface-primary/50"
            aria-label="Add file"
            title="Add file"
          >
            +
          </button>
        </div>

        {/* File list */}
        <div className="flex-1 overflow-y-auto min-h-0" ref={listRef}>
          {hasGroups && (
            <div className="px-3 pt-2 pb-1">
              <span className="text-[9px] font-semibold tracking-wider text-text-tertiary uppercase">
                To Review
              </span>
            </div>
          )}
          {toReview.map(renderFileRow)}

          {hasGroups && (
            <div className="px-3 pt-3 pb-1">
              <span className="text-[9px] font-semibold tracking-wider text-text-tertiary uppercase">
                Reviewed
              </span>
            </div>
          )}
          {reviewed.map(renderFileRow)}
        </div>
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
