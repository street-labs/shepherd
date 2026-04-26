// Implements: FR-mdr-rendered-comment-create

import { useState } from 'react';
import { ElementCommentAnchor } from './ElementCommentAnchor';

interface RenderedBlockElementProps {
  elementId: string;
  elementType: string;
  textContent: string;
  html: string;
  hasComments: boolean;
  isFocused: boolean;
  onCommentClick: () => void;
  children?: React.ReactNode;
}

export function RenderedBlockElement({
  elementId,
  elementType,
  textContent,
  html,
  hasComments,
  isFocused,
  onCommentClick,
  children,
}: RenderedBlockElementProps) {
  const [isHovered, setIsHovered] = useState(false);

  return (
    <div
      className="rendered-block"
      data-element-id={elementId}
      onMouseEnter={() => setIsHovered(true)}
      onMouseLeave={() => setIsHovered(false)}
      tabIndex={0}
      role="region"
      aria-label={`${elementType}: ${textContent.slice(0, 60)}`}
    >
      <div className="flex">
        <ElementCommentAnchor
          elementId={elementId}
          elementType={elementType}
          contentPreview={textContent}
          hasComments={hasComments}
          isHovered={isHovered}
          isFocused={isFocused}
          onClick={onCommentClick}
        />
        <div
          className="flex-1 min-w-0 rendered-content"
          dangerouslySetInnerHTML={{ __html: html }}
        />
      </div>
      {children}
    </div>
  );
}
