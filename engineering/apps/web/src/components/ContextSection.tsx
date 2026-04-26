// Implements: FR-crp-review-context-display

interface ContextSectionProps {
  variant: 'neutral' | 'review';
  content: string;
}

export function ContextSection({ variant, content }: ContextSectionProps) {
  if (!content.trim()) return null;

  const isNeutral = variant === 'neutral';

  return (
    <div
      className="border-l-3 px-3 py-2 rounded-r text-sm"
      style={{
        borderColor: isNeutral
          ? 'var(--color-context-neutral-border)'
          : 'var(--color-context-review-border)',
        backgroundColor: isNeutral
          ? 'var(--color-context-neutral-bg)'
          : 'var(--color-context-review-bg)',
      }}
    >
      <span
        className="text-xs font-semibold uppercase tracking-wide block mb-1"
        style={{ color: 'var(--color-context-section-label)' }}
      >
        {isNeutral ? 'What Changed' : 'Agent Review'}
      </span>
      <p className="whitespace-pre-wrap text-text-primary leading-relaxed m-0">
        {content}
      </p>
    </div>
  );
}
