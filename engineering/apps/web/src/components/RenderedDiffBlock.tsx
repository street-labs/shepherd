// Implements: FR-mr-rendered-diff

import { useState } from 'react';
import { ElementCommentAnchor } from './ElementCommentAnchor';
import type { AstDiffEntry, WordDiffSegment } from '@/types';

interface RenderedDiffBlockProps {
  entry: AstDiffEntry;
  hasComments: boolean;
  isFocused: boolean;
  onCommentClick: () => void;
  children?: React.ReactNode;
}

function renderWordDiff(segments: WordDiffSegment[]): React.ReactNode {
  return segments.map((seg, i) => {
    if (seg.added) {
      return <ins key={i} className="rendered-diff-word-added">{seg.value}</ins>;
    }
    if (seg.removed) {
      return <del key={i} className="rendered-diff-word-removed">{seg.value}</del>;
    }
    return <span key={i}>{seg.value}</span>;
  });
}

function statusBadge(status: AstDiffEntry['status']): React.ReactNode {
  const colors: Record<string, string> = {
    added: 'bg-badge-added-bg text-badge-added-text',
    removed: 'bg-badge-removed-bg text-badge-removed-text',
    modified: 'bg-badge-modified-bg text-badge-modified-text',
    unchanged: '',
  };

  if (status === 'unchanged') return null;

  return (
    <span className={`inline-block text-[10px] font-semibold uppercase px-1.5 py-0.5 rounded ${colors[status] ?? ''}`}>
      {status}
    </span>
  );
}

export function RenderedDiffBlock({ entry, hasComments, isFocused, onCommentClick, children }: RenderedDiffBlockProps) {
  const [isHovered, setIsHovered] = useState(false);

  const blockClass = {
    added: 'rendered-diff-block-added',
    removed: 'rendered-diff-block-removed',
    modified: 'rendered-diff-block-modified',
    unchanged: '',
  }[entry.status];

  const contentPreview = entry.newElement?.textContent ?? entry.oldElement?.textContent ?? '';

  return (
    <div
      className={`rendered-block ${blockClass}`}
      data-element-id={entry.elementId}
      data-diff-status={entry.status}
      onMouseEnter={() => setIsHovered(true)}
      onMouseLeave={() => setIsHovered(false)}
      tabIndex={0}
      role="region"
      aria-label={`${entry.type} (${entry.status}): ${contentPreview.slice(0, 60)}`}
    >
      <div className="flex">
        <ElementCommentAnchor
          elementId={entry.elementId}
          elementType={entry.type}
          contentPreview={contentPreview}
          hasComments={hasComments}
          isHovered={isHovered}
          isFocused={isFocused}
          onClick={onCommentClick}
        />
        <div className="flex-1 min-w-0 rendered-content">
          <div className="flex items-center gap-2 mb-1">
            {statusBadge(entry.status)}
          </div>
          {entry.status === 'modified' && entry.wordDiff ? (
            <div className="rendered-diff-modified-content">
              {renderWordDiff(entry.wordDiff)}
            </div>
          ) : entry.status === 'removed' ? (
            <div className="rendered-diff-removed-text">
              <del>{entry.oldElement?.textContent ?? ''}</del>
            </div>
          ) : (
            <div>{entry.newElement?.textContent ?? entry.oldElement?.textContent ?? ''}</div>
          )}
        </div>
      </div>
      {children}
    </div>
  );
}
