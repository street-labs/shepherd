// Implements: FR-crp-active-file-path, AC-crp-active-file-path-visible,
// AC-crp-active-file-path-switches, AC-crp-active-file-path-single-file

import { useAppStore } from '@/store/appStore';

export function ActiveFilePath() {
  const activeFileId = useAppStore((s) => s.activeFileId);
  const fileOrder = useAppStore((s) => s.fileOrder);
  const files = useAppStore((s) => s.files);
  const serverFilePaths = useAppStore((s) => s.serverFilePaths);

  // Only render in multi-file mode (2+ files)
  if (fileOrder.length < 2 || !activeFileId) return null;

  const activeFile = files[activeFileId];
  if (!activeFile) return null;

  const filePath = serverFilePaths[activeFileId] || activeFile.name || 'Untitled';

  return (
    <div
      role="status"
      aria-live="polite"
      aria-label={`Active file: ${filePath}`}
      className="h-8 flex items-center px-3 border-b border-border-default bg-surface-secondary flex-shrink-0 min-w-0"
    >
      <span
        className="text-xs font-mono text-text-tertiary truncate"
        style={{ direction: 'rtl', textAlign: 'left' }}
        title={filePath}
      >
        {filePath}
      </span>
    </div>
  );
}
