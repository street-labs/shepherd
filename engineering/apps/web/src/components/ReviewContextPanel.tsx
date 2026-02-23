// Implements: FR-rc-collapsible-panel, FR-rc-per-file-context

import { useAppStore } from '@/store/appStore';
import { ContextSection } from '@/components/ContextSection';

/**
 * Per-file review context panel. Positioned between the file tab bar and code viewer.
 * Only shows context for the currently active file — overall changeset context
 * lives in ReviewContextSidebar (near the preamble).
 */
export function ReviewContextPanel() {
  const reviewContext = useAppStore((s) => s.reviewContext);
  const isCollapsed = useAppStore((s) => s.isReviewContextCollapsed);
  const toggleCollapsed = useAppStore((s) => s.toggleReviewContextCollapsed);
  const activeFileId = useAppStore((s) => s.activeFileId);
  const serverFilePaths = useAppStore((s) => s.serverFilePaths);

  if (!reviewContext) return null;

  // Look up per-file context using the server file path
  const currentFilePath = activeFileId ? serverFilePaths[activeFileId] : null;
  const fileContext = currentFilePath ? reviewContext.files[currentFilePath] : null;

  const hasFileContext = fileContext && (fileContext.neutral.trim() || fileContext.review.trim());

  if (!hasFileContext) return null;

  return (
    <div
      className="flex-shrink-0 border-b"
      style={{
        borderColor: 'var(--color-border)',
        backgroundColor: 'var(--color-context-panel-bg)',
      }}
    >
      {/* Header bar */}
      <button
        onClick={toggleCollapsed}
        className="w-full flex items-center gap-2 px-3 py-1.5 text-xs font-medium cursor-pointer select-none hover:opacity-80"
        style={{
          backgroundColor: 'var(--color-context-header-bg)',
          color: 'var(--color-text-secondary)',
        }}
      >
        <span
          className="transition-transform duration-150"
          style={{
            color: 'var(--color-context-chevron)',
            display: 'inline-block',
            transform: isCollapsed ? 'rotate(0deg)' : 'rotate(90deg)',
          }}
        >
          &#9656;
        </span>
        File Context
      </button>

      {/* Collapsible content */}
      {!isCollapsed && (
        <div className="max-h-[40vh] overflow-y-auto px-3 py-2 space-y-2">
          <ContextSection variant="neutral" content={fileContext!.neutral} />
          <ContextSection variant="review" content={fileContext!.review} />
        </div>
      )}
    </div>
  );
}
