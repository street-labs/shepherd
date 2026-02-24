// Implements: FR-crp-file-reviewed-toggle, FR-crp-file-reviewed-visual,
// FR-crp-file-reviewed-progress, FR-crp-file-tree-display,
// FR-mf-tab-bar, FR-mf-tab-switch, FR-mf-tab-close

import { useAppStore } from '@/store/appStore';
import { ConfirmationDialog } from './ConfirmationDialog';
import { buildFileTree } from '@/lib/buildFileTree';
import { useState, useCallback, useMemo, useRef, useEffect } from 'react';
import type { FileTreeNode } from '@/types';

/** Flat node used for keyboard navigation over the visible tree. */
type FlatNode =
  | { type: 'directory'; path: string; depth: number }
  | { type: 'file'; fileId: string; depth: number };

/** Recursively count all file descendants of a tree node. */
function countFiles(node: FileTreeNode): number {
  if (node.type === 'file') return 1;
  return node.children.reduce((sum, child) => sum + countFiles(child), 0);
}

/** Collect all file IDs under a directory node. */
function collectFileIds(node: FileTreeNode): string[] {
  if (node.type === 'file') return [node.fileId];
  return node.children.flatMap(collectFileIds);
}

export function FileBrowser() {
  const files = useAppStore((s) => s.files);
  const fileOrder = useAppStore((s) => s.fileOrder);
  const activeFileId = useAppStore((s) => s.activeFileId);
  const comments = useAppStore((s) => s.comments);
  const reviewedFiles = useAppStore((s) => s.reviewedFiles);
  const serverFilePaths = useAppStore((s) => s.serverFilePaths);
  const collapsedDirs = useAppStore((s) => s.collapsedDirs);
  const setActiveFile = useAppStore((s) => s.setActiveFile);
  const removeFile = useAppStore((s) => s.removeFile);
  const openAddFileModal = useAppStore((s) => s.openAddFileModal);
  const toggleFileReviewed = useAppStore((s) => s.toggleFileReviewed);
  const toggleDirCollapsed = useAppStore((s) => s.toggleDirCollapsed);

  const [confirmRemoveId, setConfirmRemoveId] = useState<string | null>(null);
  const listRef = useRef<HTMLDivElement>(null);

  const getCommentCount = useCallback(
    (fileId: string) => {
      return Object.values(comments).filter((c) => c.fileId === fileId).length;
    },
    [comments],
  );

  // Build the nested tree
  const tree = useMemo(
    () => buildFileTree(files, fileOrder, reviewedFiles, serverFilePaths),
    [files, fileOrder, reviewedFiles, serverFilePaths],
  );

  // Flatten tree respecting collapsed state for keyboard navigation
  const flatList = useMemo(() => {
    const result: FlatNode[] = [];
    function walk(nodes: FileTreeNode[], depth: number) {
      for (const node of nodes) {
        if (node.type === 'directory') {
          result.push({ type: 'directory', path: node.path, depth });
          if (!collapsedDirs.has(node.path)) {
            walk(node.children, depth + 1);
          }
        } else {
          result.push({ type: 'file', fileId: node.fileId, depth });
        }
      }
    }
    walk(tree, 0);
    return result;
  }, [tree, collapsedDirs]);

  // Find the parent directory path for a given flat index
  const findParentDirPath = useCallback(
    (index: number): string | null => {
      const node = flatList[index];
      if (!node) return null;
      const targetDepth = node.depth - 1;
      if (targetDepth < 0) return null;
      // Walk backwards to find the nearest directory at targetDepth
      for (let i = index - 1; i >= 0; i--) {
        const n = flatList[i]!;
        if (n.type === 'directory' && n.depth === targetDepth) return n.path;
      }
      return null;
    },
    [flatList],
  );

  const reviewedCount = useMemo(
    () => fileOrder.filter((id) => reviewedFiles.has(id)).length,
    [fileOrder, reviewedFiles],
  );
  const totalCount = fileOrder.length;
  const allReviewed = totalCount > 0 && reviewedCount === totalCount;

  // Current flat index for keyboard nav
  const currentFlatIndex = useMemo(() => {
    if (!activeFileId) return -1;
    return flatList.findIndex((n) => n.type === 'file' && n.fileId === activeFileId);
  }, [flatList, activeFileId]);

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
      const idx = currentFlatIndex;

      switch (e.key) {
        case 'ArrowUp': {
          e.preventDefault();
          // Move to previous visible node
          const prev = idx > 0 ? idx - 1 : flatList.length - 1;
          const node = flatList[prev];
          if (node?.type === 'file') setActiveFile(node.fileId);
          else if (node?.type === 'directory') {
            // Focus on directory — we don't "activate" dirs, just expand if collapsed
            // For now, skip to prev file
            for (let i = prev - 1; i >= 0; i--) {
              const n = flatList[i];
              if (n?.type === 'file') { setActiveFile(n.fileId); return; }
            }
            // Wrap around
            for (let i = flatList.length - 1; i > prev; i--) {
              const n = flatList[i];
              if (n?.type === 'file') { setActiveFile(n.fileId); return; }
            }
          }
          break;
        }
        case 'ArrowDown': {
          e.preventDefault();
          const next = idx < flatList.length - 1 ? idx + 1 : 0;
          const node = flatList[next];
          if (node?.type === 'file') setActiveFile(node.fileId);
          else if (node?.type === 'directory') {
            // Skip to next file
            for (let i = next + 1; i < flatList.length; i++) {
              const n = flatList[i];
              if (n?.type === 'file') { setActiveFile(n.fileId); return; }
            }
            // Wrap around
            for (let i = 0; i < next; i++) {
              const n = flatList[i];
              if (n?.type === 'file') { setActiveFile(n.fileId); return; }
            }
          }
          break;
        }
        case 'ArrowRight': {
          e.preventDefault();
          // If current file is inside a collapsed dir, expand it
          // Otherwise no-op for files. For dirs, expand.
          if (idx >= 0) {
            const parentPath = findParentDirPath(idx);
            if (parentPath && collapsedDirs.has(parentPath)) {
              toggleDirCollapsed(parentPath);
            }
          }
          break;
        }
        case 'ArrowLeft': {
          e.preventDefault();
          // Collapse the parent directory of the current file
          if (idx >= 0) {
            const parentPath = findParentDirPath(idx);
            if (parentPath && !collapsedDirs.has(parentPath)) {
              toggleDirCollapsed(parentPath);
            }
          }
          break;
        }
        case 'r': {
          e.preventDefault();
          if (activeFileId) toggleFileReviewed(activeFileId);
          break;
        }
        case 'Delete':
        case 'Backspace': {
          e.preventDefault();
          if (!activeFileId) break;
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
    [currentFlatIndex, flatList, activeFileId, collapsedDirs, setActiveFile, removeFile, getCommentCount, toggleFileReviewed, toggleDirCollapsed, findParentDirPath],
  );

  // Scroll active file into view
  useEffect(() => {
    if (!activeFileId || !listRef.current) return;
    const el = listRef.current.querySelector(`[data-file-id="${activeFileId}"]`);
    if (el) {
      el.scrollIntoView({ block: 'nearest' });
    }
  }, [activeFileId]);

  const renderFileNode = (node: FileTreeNode & { type: 'file' }, depth: number) => {
    const file = files[node.fileId];
    if (!file) return null;
    const isActive = node.fileId === activeFileId;
    const isReviewed = reviewedFiles.has(node.fileId);
    const count = getCommentCount(node.fileId);

    return (
      <div
        key={node.fileId}
        role="treeitem"
        aria-selected={isActive}
        data-file-id={node.fileId}
        onClick={() => setActiveFile(node.fileId)}
        style={{ paddingLeft: `${12 + depth * 16}px` }}
        className={`group flex items-center gap-1.5 pr-2 h-8 cursor-pointer text-sm font-mono flex-shrink-0 ${
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
        <span className="truncate flex-1 min-w-0">{node.name}</span>

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
            toggleFileReviewed(node.fileId);
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
          onClick={(e) => handleClose(e, node.fileId)}
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

  const renderDirNode = (node: FileTreeNode & { type: 'directory' }, depth: number) => {
    const isCollapsed = collapsedDirs.has(node.path);
    const fileIds = collectFileIds(node);
    const allDescendantsReviewed = fileIds.length > 0 && fileIds.every((id) => reviewedFiles.has(id));
    const fileCount = countFiles(node);

    return (
      <div key={`dir-${node.path}`} role="treeitem" aria-expanded={!isCollapsed}>
        <div
          onClick={() => toggleDirCollapsed(node.path)}
          style={{ paddingLeft: `${12 + depth * 16}px` }}
          className={`group flex items-center gap-1.5 pr-2 h-7 cursor-pointer text-sm font-mono flex-shrink-0 border-l-[3px] border-l-transparent hover:bg-surface-primary/50 ${
            allDescendantsReviewed ? 'text-text-tertiary' : 'text-text-secondary'
          }`}
        >
          {/* Chevron */}
          <span className="text-[10px] flex-shrink-0 w-3 text-center text-text-tertiary">
            {isCollapsed ? '\u25B8' : '\u25BE'}
          </span>

          {/* All-reviewed checkmark */}
          {allDescendantsReviewed && (
            <span className="text-success-600 text-xs flex-shrink-0" aria-label="All files reviewed">
              &#x2713;
            </span>
          )}

          {/* Directory name */}
          <span className="truncate flex-1 min-w-0">
            {node.name}<span className="text-text-tertiary">/</span>
          </span>

          {/* Collapsed file count */}
          {isCollapsed && (
            <span className="text-[10px] text-text-tertiary tabular-nums flex-shrink-0">
              ({fileCount} {fileCount === 1 ? 'file' : 'files'})
            </span>
          )}
        </div>

        {/* Children */}
        {!isCollapsed && (
          <div role="group">
            {node.children.map((child) => renderTreeNode(child, depth + 1))}
          </div>
        )}
      </div>
    );
  };

  const renderTreeNode = (node: FileTreeNode, depth: number): React.ReactNode => {
    if (node.type === 'file') return renderFileNode(node as FileTreeNode & { type: 'file' }, depth);
    return renderDirNode(node as FileTreeNode & { type: 'directory' }, depth);
  };

  return (
    <>
      <div
        className="w-60 flex flex-col border-r border-border-default bg-surface-secondary flex-shrink-0 h-full"
        role="tree"
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

        {/* File tree */}
        <div className="flex-1 overflow-y-auto min-h-0" ref={listRef}>
          {tree.map((node) => renderTreeNode(node, 0))}
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
