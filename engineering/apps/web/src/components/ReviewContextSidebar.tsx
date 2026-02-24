// Implements: FR-rc-overall-context, FR-sb-collapse-toggle

import { useAppStore } from '@/store/appStore';
import { ContextSection } from '@/components/ContextSection';

/**
 * Overall changeset context displayed in the sidebar above the preamble.
 * Shows the agent's overall summary (neutral + review) for the entire changeset.
 * Per-file context lives in ReviewContextPanel (in the code viewer area).
 */
export function ReviewContextSidebar() {
  const reviewContext = useAppStore((s) => s.reviewContext);
  const isCollapsed = useAppStore((s) => s.isReviewContextSidebarCollapsed);
  const toggleCollapsed = useAppStore((s) => s.toggleReviewContextSidebarCollapsed);

  if (!reviewContext) return null;

  const hasOverall = reviewContext.overall.neutral.trim() || reviewContext.overall.review.trim();

  if (!hasOverall) return null;

  return (
    <div
      className="border-b"
      style={{
        borderColor: 'var(--color-border)',
        backgroundColor: 'var(--color-context-panel-bg)',
      }}
    >
      {/* Header bar */}
      <button
        onClick={toggleCollapsed}
        className="w-full flex items-center gap-2 px-4 py-2 text-xs font-medium cursor-pointer select-none hover:opacity-80"
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
        <span
          className="text-[10px] font-bold uppercase tracking-widest"
          style={{ color: 'var(--color-context-section-label)' }}
        >
          Changeset Overview
        </span>
      </button>

      {/* Collapsible content */}
      {!isCollapsed && (
        <div className="px-4 py-3 space-y-2">
          <ContextSection variant="neutral" content={reviewContext.overall.neutral} />
          <ContextSection variant="review" content={reviewContext.overall.review} />
        </div>
      )}
    </div>
  );
}
