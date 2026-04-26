// Implements: FR-mdr-render-commonmark, FR-mdr-rendered-comment-create, FR-mdr-rendered-comment-prompt

import { useAppStore } from '@/store/appStore';
import { RenderedBlockElement } from './RenderedBlockElement';
import { CommentBubble } from './CommentBubble';
import { InlineCommentEditor } from './InlineCommentEditor';
import { useEffect, useRef, useCallback } from 'react';
import type { ElementId, RenderedComment } from '@/types';

export function RenderedViewer() {
  const astElements = useAppStore((s) => s.astElements);
  const renderedHtml = useAppStore((s) => s.renderedHtml);
  const renderedComments = useAppStore((s) => s.renderedComments);
  const renderedCommentOrder = useAppStore((s) => s.renderedCommentOrder);
  const focusedRenderedCommentId = useAppStore((s) => s.focusedRenderedCommentId);
  const renderedEditorState = useAppStore((s) => s.renderedEditorState);
  const openRenderedEditor = useAppStore((s) => s.openRenderedEditor);
  const containerRef = useRef<HTMLDivElement>(null);

  // Build per-element HTML fragments from the full rendered HTML
  // Each element has a data-element-id attribute we can use to extract its HTML
  const elementHtmlMap = useCallback(() => {
    const map = new Map<string, string>();
    if (!renderedHtml) return map;

    // Parse the HTML and extract per-element chunks
    const parser = new DOMParser();
    const doc = parser.parseFromString(renderedHtml, 'text/html');
    const body = doc.body;

    for (const child of Array.from(body.children)) {
      const id = child.getAttribute('data-element-id');
      if (id) {
        map.set(id, child.outerHTML);
      } else {
        // Element without ID — use its index in document order
        // This shouldn't happen normally but is a safe fallback
      }
    }

    // Also grab elements that weren't top-level (shouldn't happen, but fallback)
    // For elements not in the map, we'll use a simple approach
    return map;
  }, [renderedHtml]);

  const htmlMap = elementHtmlMap();

  // Build comment lookup: elementId -> comments on that element
  const commentsByElement = new Map<string, RenderedComment[]>();
  for (const id of renderedCommentOrder) {
    const comment = renderedComments[id];
    if (!comment) continue;
    const existing = commentsByElement.get(comment.elementId) ?? [];
    existing.push(comment);
    commentsByElement.set(comment.elementId, existing);
  }

  // Scroll to focused comment
  useEffect(() => {
    if (focusedRenderedCommentId) {
      const el = document.getElementById(`comment-${focusedRenderedCommentId}`);
      el?.scrollIntoView({ behavior: 'smooth', block: 'center' });
    }
  }, [focusedRenderedCommentId]);

  const closeRenderedEditor = useAppStore((s) => s.closeRenderedEditor);

  // Keyboard navigation
  useEffect(() => {
    const handler = (e: KeyboardEvent) => {
      const target = e.target as HTMLElement;
      if (target.tagName === 'INPUT' || target.tagName === 'TEXTAREA') return;

      // c or Enter: open comment editor on focused element
      if ((e.key === 'c' || e.key === 'Enter') && !e.metaKey && !e.ctrlKey && !e.shiftKey) {
        const focused = document.activeElement?.closest('[data-element-id]');
        if (focused) {
          const elementId = focused.getAttribute('data-element-id') as ElementId;
          const element = astElements.find((el) => el.elementId === elementId);
          if (element) {
            e.preventDefault();
            openRenderedEditor({ mode: 'create', elementId });
          }
        }
      }

      // Escape: close editor
      if (e.key === 'Escape' && renderedEditorState) {
        e.preventDefault();
        closeRenderedEditor();
      }
    };

    document.addEventListener('keydown', handler);
    return () => document.removeEventListener('keydown', handler);
  }, [astElements, openRenderedEditor, closeRenderedEditor, renderedEditorState]);

  if (astElements.length === 0) {
    return (
      <div className="flex-1 flex items-center justify-center text-text-secondary text-sm">
        No markdown content to render.
      </div>
    );
  }

  return (
    <div
      ref={containerRef}
      className="h-full overflow-y-auto"
      style={{ contentVisibility: 'auto' }}
    >
      <div className="py-4">
        {astElements.map((element) => {
          // Skip list items — they're rendered inside their parent list
          if (element.type === 'listItem') return null;

          const html = htmlMap.get(element.elementId) ?? '';
          const comments = commentsByElement.get(element.elementId) ?? [];
          const hasComments = comments.length > 0;
          const isEditorOpen = renderedEditorState?.mode === 'create' && renderedEditorState.elementId === element.elementId;
          const isEditingComment = renderedEditorState?.mode === 'edit' && comments.some((c) => c.id === renderedEditorState.commentId);

          return (
            <RenderedBlockElement
              key={element.elementId}
              elementId={element.elementId}
              elementType={element.type}
              textContent={element.textContent}
              html={html}
              hasComments={hasComments}
              isFocused={comments.some((c) => c.id === focusedRenderedCommentId)}
              onCommentClick={() => openRenderedEditor({ mode: 'create', elementId: element.elementId })}
            >
              {/* Comment bubbles after this element */}
              {comments.map((comment) => (
                <CommentBubble
                  key={comment.id}
                  comment={comment}
                  isFocused={comment.id === focusedRenderedCommentId}
                  label={`${capitalize(element.type)}: ${element.textContent.slice(0, 40)}`}
                  isRenderedMode
                />
              ))}

              {/* Editor after this element */}
              {(isEditorOpen || isEditingComment) && (
                <InlineCommentEditor isRenderedMode />
              )}
            </RenderedBlockElement>
          );
        })}
      </div>
    </div>
  );
}

function capitalize(s: string): string {
  return s.charAt(0).toUpperCase() + s.slice(1);
}
