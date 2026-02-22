// Implements: FR-diff-collapse, FR-diff-expand,
// AC-diff-collapse-default, AC-diff-expand-section

interface CollapsedSectionSeparatorProps {
  lineCount: number;
  onExpand: () => void;
}

export function CollapsedSectionSeparator({ lineCount, onExpand }: CollapsedSectionSeparatorProps) {
  return (
    <div
      className="flex items-center justify-center h-[36px] bg-diff-separator-bg border-y border-dashed border-diff-separator-border text-xs text-text-secondary cursor-pointer hover:bg-surface-secondary transition-colors select-none group"
      role="button"
      tabIndex={0}
      aria-label={`Expand ${lineCount} unchanged lines`}
      onClick={onExpand}
      onKeyDown={(e) => {
        if (e.key === 'Enter' || e.key === ' ') {
          e.preventDefault();
          onExpand();
        }
      }}
    >
      <span>... {lineCount} unchanged lines ...</span>
      <span className="ml-2 text-primary-500 opacity-0 group-hover:opacity-100 transition-opacity">
        Expand
      </span>
    </div>
  );
}
