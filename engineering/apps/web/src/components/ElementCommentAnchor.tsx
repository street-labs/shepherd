
interface ElementCommentAnchorProps {
  elementId: string;
  elementType: string;
  contentPreview: string;
  hasComments: boolean;
  isHovered: boolean;
  isFocused: boolean;
  onClick: () => void;
}

// Implements: FR-mdr-rendered-comment-create
export function ElementCommentAnchor({
  elementType,
  contentPreview,
  hasComments,
  isHovered,
  isFocused,
  onClick,
}: ElementCommentAnchorProps) {
  const showIcon = isHovered || isFocused || hasComments;
  const preview = contentPreview.slice(0, 40);

  return (
    <div className="w-8 flex-shrink-0 flex items-start justify-center pt-1 relative">
      {hasComments && (
        <div
          className="absolute top-1 left-1/2 -translate-x-1/2 w-2 h-2 rounded-full"
          style={{ backgroundColor: 'var(--color-gutter-indicator)' }}
        />
      )}
      {showIcon && (
        <button
          role="button"
          aria-label={`Add comment on ${elementType}: ${preview}`}
          onClick={onClick}
          className="w-4 h-4 flex items-center justify-center rounded hover:bg-surface-secondary text-text-tertiary hover:text-primary-500 transition-colors mt-1"
          tabIndex={0}
        >
          <svg width="16" height="16" viewBox="0 0 16 16" fill="none" stroke="currentColor" strokeWidth="1.5">
            <path d="M2 2h12v9H5l-3 3V2z" strokeLinecap="round" strokeLinejoin="round" />
          </svg>
        </button>
      )}
    </div>
  );
}
