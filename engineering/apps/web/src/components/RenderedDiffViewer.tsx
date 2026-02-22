// Implements: FR-mr-rendered-diff, FR-mr-rendered-diff-comment

import { useAppStore } from '@/store/appStore';
import { RenderedDiffBlock } from './RenderedDiffBlock';
import { RenderedDiffFallbackBanner } from './RenderedDiffFallbackBanner';
import { RenderedDiffLoadingState } from './RenderedDiffLoadingState';
import { CommentBubble } from './CommentBubble';
import { InlineCommentEditor } from './InlineCommentEditor';
import { useEffect } from 'react';
import type { RenderedDiffComment } from '@/types';

export function RenderedDiffViewer() {
  const astDiffResult = useAppStore((s) => s.astDiffResult);
  const isAstDiffComputing = useAppStore((s) => s.isAstDiffComputing);
  const renderedDiffComments = useAppStore((s) => s.renderedDiffComments);
  const renderedDiffCommentOrder = useAppStore((s) => s.renderedDiffCommentOrder);
  const focusedRenderedDiffCommentId = useAppStore((s) => s.focusedRenderedDiffCommentId);
  const renderedDiffEditorState = useAppStore((s) => s.renderedDiffEditorState);
  const openRenderedDiffEditor = useAppStore((s) => s.openRenderedDiffEditor);
  const setRenderMode = useAppStore((s) => s.setRenderMode);

  // Build comment lookup: elementId -> comments
  const commentsByElement = new Map<string, RenderedDiffComment[]>();
  for (const id of renderedDiffCommentOrder) {
    const comment = renderedDiffComments[id];
    if (!comment) continue;
    const existing = commentsByElement.get(comment.elementId) ?? [];
    existing.push(comment);
    commentsByElement.set(comment.elementId, existing);
  }

  // Scroll to focused comment
  useEffect(() => {
    if (focusedRenderedDiffCommentId) {
      const el = document.getElementById(`comment-${focusedRenderedDiffCommentId}`);
      el?.scrollIntoView({ behavior: 'smooth', block: 'center' });
    }
  }, [focusedRenderedDiffCommentId]);

  if (isAstDiffComputing) {
    return <RenderedDiffLoadingState />;
  }

  if (!astDiffResult) {
    return (
      <div className="flex-1 flex items-center justify-center text-text-secondary text-sm">
        No rendered diff data available.
      </div>
    );
  }

  return (
    <div className="h-full overflow-y-auto" style={{ contentVisibility: 'auto' }}>
      {astDiffResult.exceedsFallbackThreshold && (
        <RenderedDiffFallbackBanner onSwitchToRawDiff={() => setRenderMode('raw')} />
      )}

      <div className="py-4">
        {astDiffResult.entries.map((entry) => {
          const comments = commentsByElement.get(entry.elementId) ?? [];
          const hasComments = comments.length > 0;
          const isEditorOpen = renderedDiffEditorState?.mode === 'create' && renderedDiffEditorState.elementId === entry.elementId;
          const isEditingComment = renderedDiffEditorState?.mode === 'edit' && comments.some((c) => c.id === renderedDiffEditorState.commentId);

          return (
            <RenderedDiffBlock
              key={entry.elementId}
              entry={entry}
              hasComments={hasComments}
              isFocused={comments.some((c) => c.id === focusedRenderedDiffCommentId)}
              onCommentClick={() => openRenderedDiffEditor({ mode: 'create', elementId: entry.elementId })}
            >
              {comments.map((comment) => (
                <CommentBubble
                  key={comment.id}
                  comment={comment}
                  isFocused={comment.id === focusedRenderedDiffCommentId}
                  label={`${capitalize(entry.type)} [${entry.status}]`}
                  isRenderedDiffMode
                />
              ))}

              {(isEditorOpen || isEditingComment) && (
                <InlineCommentEditor isRenderedDiffMode />
              )}
            </RenderedDiffBlock>
          );
        })}
      </div>
    </div>
  );
}

function capitalize(s: string): string {
  return s.charAt(0).toUpperCase() + s.slice(1);
}
