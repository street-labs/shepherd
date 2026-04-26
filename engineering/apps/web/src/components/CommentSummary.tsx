// Implements: FR-crp-comment-summary

import { useAppStore } from '@/store/appStore';

/**
 * All-comments summary view for the sidebar.
 * Shows every comment across all files, grouped by file in fileOrder.
 * Clicking a comment navigates to that file and focuses the comment.
 */
export function CommentSummary() {
  const files = useAppStore((s) => s.files);
  const fileOrder = useAppStore((s) => s.fileOrder);
  const comments = useAppStore((s) => s.comments);
  const diffComments = useAppStore((s) => s.diffComments);
  const viewMode = useAppStore((s) => s.viewMode);
  const activeFileId = useAppStore((s) => s.activeFileId);
  const setActiveFile = useAppStore((s) => s.setActiveFile);
  const setFocusedComment = useAppStore((s) => s.setFocusedComment);
  const setFocusedDiffComment = useAppStore((s) => s.setFocusedDiffComment);

  // Build grouped comment list based on current view mode
  const groups: { fileId: string; fileName: string; items: CommentItem[] }[] = [];

  if (viewMode === 'diff') {
    // Diff-mode comments
    const byFile = new Map<string, typeof diffComments[string][]>();
    for (const comment of Object.values(diffComments)) {
      const existing = byFile.get(comment.fileId) ?? [];
      existing.push(comment);
      byFile.set(comment.fileId, existing);
    }

    for (const fileId of fileOrder) {
      const fileComments = byFile.get(fileId);
      if (!fileComments || fileComments.length === 0) continue;
      const fileName = files[fileId]?.name ?? 'Unknown';
      const sorted = [...fileComments].sort((a, b) => {
        if (a.startIndex !== b.startIndex) return a.startIndex - b.startIndex;
        return a.createdAt.localeCompare(b.createdAt);
      });
      groups.push({
        fileId,
        fileName,
        items: sorted.map((c) => ({
          id: c.id,
          lineRef: formatDiffLineRef(c.startLineId, c.endLineId),
          text: c.text,
          isDiff: true,
        })),
      });
    }
  } else {
    // File-mode comments
    const byFile = new Map<string, typeof comments[string][]>();
    for (const comment of Object.values(comments)) {
      const existing = byFile.get(comment.fileId) ?? [];
      existing.push(comment);
      byFile.set(comment.fileId, existing);
    }

    for (const fileId of fileOrder) {
      const fileComments = byFile.get(fileId);
      if (!fileComments || fileComments.length === 0) continue;
      const fileName = files[fileId]?.name ?? 'Unknown';
      const sorted = [...fileComments].sort((a, b) => {
        if (a.startLine !== b.startLine) return a.startLine - b.startLine;
        return a.createdAt.localeCompare(b.createdAt);
      });
      groups.push({
        fileId,
        fileName,
        items: sorted.map((c) => ({
          id: c.id,
          lineRef: c.startLine === c.endLine
            ? `Line ${c.startLine}`
            : `Lines ${c.startLine}–${c.endLine}`,
          text: c.text,
          isDiff: false,
        })),
      });
    }
  }

  const totalCount = groups.reduce((sum, g) => sum + g.items.length, 0);

  if (totalCount === 0) {
    return (
      <div className="flex-1 flex items-center justify-center p-6">
        <p className="text-xs text-text-tertiary text-center">
          No comments yet — add comments to files to see them here.
        </p>
      </div>
    );
  }

  const handleClick = (fileId: string, commentId: string, isDiff: boolean) => {
    if (fileId !== activeFileId) {
      setActiveFile(fileId);
    }
    // Use setTimeout to ensure the file switch state update settles before focusing
    setTimeout(() => {
      if (isDiff) {
        setFocusedDiffComment(commentId);
      } else {
        setFocusedComment(commentId);
      }
    }, 0);
  };

  return (
    <div className="flex-1 overflow-y-auto">
      {groups.map((group) => (
        <div key={group.fileId} className="border-b border-border-default">
          {/* File header */}
          <div className="px-4 py-2 flex items-center justify-between bg-surface-secondary">
            <span className="text-xs font-medium text-text-primary truncate">
              {group.fileName}
            </span>
            <span className="text-[10px] text-text-tertiary ml-2 flex-shrink-0">
              {group.items.length}
            </span>
          </div>

          {/* Comments */}
          {group.items.map((item) => (
            <button
              key={item.id}
              onClick={() => handleClick(group.fileId, item.id, item.isDiff)}
              className="w-full text-left px-4 py-2 hover:bg-selection-bg/50 cursor-pointer border-t border-border-default"
            >
              <span className="text-[10px] font-mono text-text-tertiary">
                {item.lineRef}
              </span>
              <p className="text-xs text-text-secondary mt-0.5 line-clamp-2">
                {item.text}
              </p>
            </button>
          ))}
        </div>
      ))}
    </div>
  );
}

interface CommentItem {
  id: string;
  lineRef: string;
  text: string;
  isDiff: boolean;
}

function formatDiffLineRef(
  startLineId: { lineType: string; oldLine: number | null; newLine: number | null },
  endLineId: { lineType: string; oldLine: number | null; newLine: number | null },
): string {
  const startNum = startLineId.newLine ?? startLineId.oldLine ?? 0;
  const endNum = endLineId.newLine ?? endLineId.oldLine ?? 0;
  if (startNum === endNum) {
    return `Line ${startNum}`;
  }
  return `Lines ${startNum}–${endNum}`;
}
