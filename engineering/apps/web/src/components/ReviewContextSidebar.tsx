// Implements: FR-rc-overall-context

import { useAppStore } from '@/store/appStore';
import { ContextSection } from '@/components/ContextSection';

/**
 * Overall changeset context displayed in the sidebar above the preamble.
 * Shows the agent's overall summary (neutral + review) for the entire changeset.
 * Per-file context lives in ReviewContextPanel (in the code viewer area).
 */
export function ReviewContextSidebar() {
  const reviewContext = useAppStore((s) => s.reviewContext);

  if (!reviewContext) return null;

  const hasOverall = reviewContext.overall.neutral.trim() || reviewContext.overall.review.trim();

  if (!hasOverall) return null;

  return (
    <div
      className="border-b px-4 py-3 space-y-2"
      style={{
        borderColor: 'var(--color-border)',
        backgroundColor: 'var(--color-context-panel-bg)',
      }}
    >
      <h4
        className="text-[10px] font-bold uppercase tracking-widest"
        style={{ color: 'var(--color-context-section-label)' }}
      >
        Changeset Overview
      </h4>
      <ContextSection variant="neutral" content={reviewContext.overall.neutral} />
      <ContextSection variant="review" content={reviewContext.overall.review} />
    </div>
  );
}
