
import { useAppStore } from '@/store/appStore';

export function ReviewStatusBar() {
  // Implements: FR-crp-file-reviewed-toggle, FR-crp-file-reviewed-visual
  const activeFileId = useAppStore((s) => s.activeFileId);
  const reviewedFiles = useAppStore((s) => s.reviewedFiles);
  const toggleFileReviewed = useAppStore((s) => s.toggleFileReviewed);
  const fileOrder = useAppStore((s) => s.fileOrder);

  // Only show in multi-file mode
  if (!activeFileId || fileOrder.length < 2) return null;

  const isReviewed = reviewedFiles.has(activeFileId);

  return (
    <div
      className={`flex items-center gap-2 px-3 h-9 border-b border-border-default flex-shrink-0 ${
        isReviewed ? 'bg-diff-added-bg' : 'bg-surface-secondary'
      }`}
    >
      <label className="flex items-center gap-2 cursor-pointer select-none text-xs">
        <input
          type="checkbox"
          checked={isReviewed}
          onChange={() => toggleFileReviewed(activeFileId)}
          className="accent-success-600 w-3.5 h-3.5"
        />
        <span className={isReviewed ? 'text-success-600 font-medium' : 'text-text-secondary'}>
          {isReviewed ? 'Reviewed' : 'Mark as reviewed'}
        </span>
      </label>

      <span className="text-[10px] text-text-tertiary ml-auto" aria-hidden="true">
        {'\u2318\u21E7R'}
      </span>
    </div>
  );
}
