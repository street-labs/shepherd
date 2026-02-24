// Implements: FR-crp-file-display, FR-crp-syntax-highlight, FR-crp-comment-indicator,
// FR-crp-line-comment-create, FR-crp-line-range-comment, FR-crp-comment-navigation,
// NFR-crp-large-file-perf, NFR-crp-render-time, AC-crp-large-file-scroll,
// NFR-crp-accessibility-keyboard, AC-crp-keyboard-add-comment

import { useAppStore } from '@/store/appStore';
import { CommentBubble } from './CommentBubble';
import { InlineCommentEditor } from './InlineCommentEditor';
import { useRef, useMemo, useCallback, useEffect, useState } from 'react';
import { useVirtualizer } from '@tanstack/react-virtual';
import { highlightCode } from '@/lib/highlighter';
import type { Comment, DisplayItem, HighlightToken } from '@/types';

const CODE_LINE_HEIGHT = 20;
const COMMENT_BUBBLE_HEIGHT = 60;
const EDITOR_HEIGHT = 160;
const OVERSCAN = 20;

export function CodeViewer() {
  const file = useAppStore((s) => s.file);
  const activeFileId = useAppStore((s) => s.activeFileId);
  const scrollPositions = useAppStore((s) => s.scrollPositions);
  const saveScrollPosition = useAppStore((s) => s.saveScrollPosition);
  const comments = useAppStore((s) => s.comments);
  const commentOrder = useAppStore((s) => s.commentOrder);
  const editorState = useAppStore((s) => s.editorState);
  const selectedRange = useAppStore((s) => s.selectedRange);
  const focusedCommentId = useAppStore((s) => s.focusedCommentId);
  const showLargeFileWarning = useAppStore((s) => s.showLargeFileWarning);
  const largeFileWarningDismissed = useAppStore((s) => s.largeFileWarningDismissed);
  const dismissLargeFileWarning = useAppStore((s) => s.dismissLargeFileWarning);
  const openEditor = useAppStore((s) => s.openEditor);
  const setSelectedRange = useAppStore((s) => s.setSelectedRange);
  const lineWrapEnabled = useAppStore((s) => s.lineWrapEnabled);

  const containerRef = useRef<HTMLDivElement>(null);
  const isSelectingRef = useRef(false);
  const selectionStartRef = useRef<number | null>(null);

  // Keyboard navigation state
  const [focusedLine, setFocusedLine] = useState<number | null>(null);
  const [rangeAnchor, setRangeAnchor] = useState<number | null>(null);

  // Syntax highlighting state (progressive: tokens load async)
  const [highlightTokens, setHighlightTokens] = useState<HighlightToken[][] | null>(null);

  // Load syntax highlighting when file changes
  useEffect(() => {
    if (!file) {
      setHighlightTokens(null);
      return;
    }
    let cancelled = false;
    highlightCode(file.content, file.language).then((tokens) => {
      if (!cancelled) setHighlightTokens(tokens);
    });
    return () => { cancelled = true; };
  }, [file?.content, file?.language]);

  // Save scroll position when switching away, restore when switching to
  const prevFileIdRef = useRef(activeFileId);
  useEffect(() => {
    const container = containerRef.current;
    if (prevFileIdRef.current && prevFileIdRef.current !== activeFileId && container) {
      saveScrollPosition(prevFileIdRef.current, container.scrollTop);
    }
    prevFileIdRef.current = activeFileId;

    // Restore scroll position for the new file
    if (activeFileId && container) {
      const saved = scrollPositions[activeFileId];
      // Use requestAnimationFrame to let the DOM settle before scrolling
      requestAnimationFrame(() => {
        container.scrollTop = saved ?? 0;
      });
    }
  }, [activeFileId]); // intentionally minimal deps — save/restore on file switch only

  // Compute which lines have comments
  const commentsByLine = useMemo(() => {
    const map = new Map<number, Comment[]>();
    for (const id of commentOrder) {
      const comment = comments[id];
      if (!comment) continue;
      for (let line = comment.startLine; line <= comment.endLine; line++) {
        const existing = map.get(line) ?? [];
        existing.push(comment);
        map.set(line, existing);
      }
    }
    return map;
  }, [comments, commentOrder]);

  // Compute comments that should render after each line (render after endLine)
  const commentsAfterLine = useMemo(() => {
    const map = new Map<number, Comment[]>();
    for (const id of commentOrder) {
      const comment = comments[id];
      if (!comment) continue;
      const existing = map.get(comment.endLine) ?? [];
      existing.push(comment);
      map.set(comment.endLine, existing);
    }
    return map;
  }, [comments, commentOrder]);

  // Determine where to render the editor
  const editorAfterLine = editorState
    ? editorState.mode === 'create'
      ? editorState.endLine
      : (comments[editorState.commentId]?.endLine ?? null)
    : null;

  // Build display items array (interleaving code lines with comments/editor)
  const displayItems = useMemo((): DisplayItem[] => {
    if (!file) return [];
    const items: DisplayItem[] = [];
    for (let i = 0; i < file.lines.length; i++) {
      const lineNumber = i + 1;
      items.push({ type: 'code-line', lineNumber, content: file.lines[i]! });

      // Comments after this line
      const lineComments = commentsAfterLine.get(lineNumber);
      if (lineComments) {
        for (const comment of lineComments) {
          items.push({ type: 'comment-bubble', comment });
        }
      }

      // Editor after this line
      if (editorAfterLine === lineNumber && editorState) {
        items.push({
          type: 'editor',
          anchorLine: editorState.mode === 'create' ? editorState.anchorLine : (comments[editorState.commentId]?.startLine ?? lineNumber),
          endLine: lineNumber,
          mode: editorState.mode,
          commentId: editorState.mode === 'edit' ? editorState.commentId : undefined,
        });
      }
    }
    return items;
  }, [file, commentsAfterLine, editorAfterLine, editorState, comments]);

  const virtualizer = useVirtualizer({
    count: displayItems.length,
    getScrollElement: () => containerRef.current,
    estimateSize: (index) => {
      const item = displayItems[index];
      if (!item) return CODE_LINE_HEIGHT;
      switch (item.type) {
        case 'code-line': return CODE_LINE_HEIGHT;
        case 'comment-bubble': return COMMENT_BUBBLE_HEIGHT;
        case 'editor': return EDITOR_HEIGHT;
      }
    },
    overscan: OVERSCAN,
    measureElement: (el) => el.getBoundingClientRect().height,
  });

  // Scroll to focused comment
  useEffect(() => {
    if (!focusedCommentId) return;
    const index = displayItems.findIndex(
      (item) => item.type === 'comment-bubble' && item.comment.id === focusedCommentId,
    );
    if (index >= 0) {
      virtualizer.scrollToIndex(index, { align: 'center', behavior: 'smooth' });
    }
  }, [focusedCommentId, displayItems, virtualizer]);

  // Re-measure virtualizer when line wrap toggles
  useEffect(() => {
    virtualizer.measure();
  }, [lineWrapEnabled, virtualizer]);

  // Re-measure when container width changes (wrapped line heights depend on width)
  useEffect(() => {
    if (!lineWrapEnabled) return;
    const container = containerRef.current;
    if (!container) return;
    const observer = new ResizeObserver(() => {
      virtualizer.measure();
    });
    observer.observe(container);
    return () => observer.disconnect();
  }, [lineWrapEnabled, virtualizer]);

  // Keyboard navigation for code viewer
  const handleKeyDown = useCallback(
    (e: React.KeyboardEvent) => {
      // Don't capture keys when typing in inputs/textareas
      const target = e.target as HTMLElement;
      if (target.tagName === 'INPUT' || target.tagName === 'TEXTAREA') return;

      if (!file) return;
      const totalLines = file.lines.length;
      const current = focusedLine ?? 0;

      switch (e.key) {
        case 'ArrowDown': {
          e.preventDefault();
          const next = Math.min(current + 1, totalLines);
          setFocusedLine(next);
          if (e.shiftKey) {
            // Range selection
            const anchor = rangeAnchor ?? next;
            if (rangeAnchor === null) setRangeAnchor(current || 1);
            const start = Math.min(anchor, next);
            const end = Math.max(anchor, next);
            setSelectedRange({ start, end });
          } else {
            setRangeAnchor(null);
            setSelectedRange(null);
          }
          // Scroll focused line into view
          const lineIndex = displayItems.findIndex(
            (item) => item.type === 'code-line' && item.lineNumber === next,
          );
          if (lineIndex >= 0) {
            virtualizer.scrollToIndex(lineIndex, { align: 'auto' });
          }
          break;
        }
        case 'ArrowUp': {
          e.preventDefault();
          const prev = Math.max(current - 1, 1);
          setFocusedLine(prev);
          if (e.shiftKey) {
            const anchor = rangeAnchor ?? prev;
            if (rangeAnchor === null) setRangeAnchor(current || 1);
            const start = Math.min(anchor, prev);
            const end = Math.max(anchor, prev);
            setSelectedRange({ start, end });
          } else {
            setRangeAnchor(null);
            setSelectedRange(null);
          }
          const lineIndex = displayItems.findIndex(
            (item) => item.type === 'code-line' && item.lineNumber === prev,
          );
          if (lineIndex >= 0) {
            virtualizer.scrollToIndex(lineIndex, { align: 'auto' });
          }
          break;
        }
        case 'Enter':
        case 'c': {
          e.preventDefault();
          if (selectedRange && selectedRange.start !== selectedRange.end) {
            openEditor({ mode: 'create', anchorLine: selectedRange.start, endLine: selectedRange.end });
          } else if (focusedLine) {
            openEditor({ mode: 'create', anchorLine: focusedLine, endLine: focusedLine });
          }
          setRangeAnchor(null);
          break;
        }
        case 'Escape': {
          setFocusedLine(null);
          setRangeAnchor(null);
          setSelectedRange(null);
          break;
        }
      }
    },
    [file, focusedLine, rangeAnchor, displayItems, virtualizer, openEditor, setSelectedRange],
  );

  const handleGutterClick = useCallback(
    (lineNumber: number, e: React.MouseEvent) => {
      if (e.shiftKey && selectionStartRef.current !== null) {
        const start = Math.min(selectionStartRef.current, lineNumber);
        const end = Math.max(selectionStartRef.current, lineNumber);
        setSelectedRange({ start, end });
        openEditor({ mode: 'create', anchorLine: start, endLine: end });
        selectionStartRef.current = null;
      } else {
        selectionStartRef.current = lineNumber;
        openEditor({ mode: 'create', anchorLine: lineNumber, endLine: lineNumber });
      }
    },
    [openEditor, setSelectedRange],
  );

  const handleMouseDown = useCallback(
    (lineNumber: number) => {
      isSelectingRef.current = true;
      selectionStartRef.current = lineNumber;
      setSelectedRange({ start: lineNumber, end: lineNumber });
    },
    [setSelectedRange],
  );

  const handleMouseEnter = useCallback(
    (lineNumber: number) => {
      if (!isSelectingRef.current || selectionStartRef.current === null) return;
      const start = Math.min(selectionStartRef.current, lineNumber);
      const end = Math.max(selectionStartRef.current, lineNumber);
      setSelectedRange({ start, end });
    },
    [setSelectedRange],
  );

  const handleMouseUp = useCallback(() => {
    if (!isSelectingRef.current) return;
    isSelectingRef.current = false;
    const range = useAppStore.getState().selectedRange;
    if (range && range.start !== range.end) {
      openEditor({ mode: 'create', anchorLine: range.start, endLine: range.end });
    }
  }, [openEditor]);

  useEffect(() => {
    const handleGlobalMouseUp = () => {
      isSelectingRef.current = false;
    };
    document.addEventListener('mouseup', handleGlobalMouseUp);
    return () => document.removeEventListener('mouseup', handleGlobalMouseUp);
  }, []);

  if (!file) return null;

  const padWidth = Math.max(String(file.lines.length).toString().length, 1);

  return (
    <div
      ref={containerRef}
      className="h-full overflow-auto font-mono text-[13px] leading-[20px] focus:outline-none focus-visible:ring-2 focus-visible:ring-inset focus-visible:ring-primary-500"
      role="grid"
      aria-label="Code viewer"
      aria-rowcount={file.lines.length}
      tabIndex={0}
      onKeyDown={handleKeyDown}
      onMouseUp={handleMouseUp}
    >
      {showLargeFileWarning && !largeFileWarningDismissed && (
        <div className="sticky top-0 z-10 flex items-center gap-2 px-4 py-2 bg-warning-bg border-b border-warning-border text-warning-text text-xs">
          <span>This file has more than 10,000 lines. Performance may vary.</span>
          <button
            onClick={dismissLargeFileWarning}
            className="ml-auto text-warning-text hover:underline"
          >
            Dismiss
          </button>
        </div>
      )}

      <div
        style={{
          height: `${virtualizer.getTotalSize()}px`,
          width: '100%',
          position: 'relative',
        }}
      >
        {virtualizer.getVirtualItems().map((virtualItem) => {
          const item = displayItems[virtualItem.index];
          if (!item) return null;

          if (item.type === 'comment-bubble') {
            return (
              <div
                key={virtualItem.key}
                ref={virtualizer.measureElement}
                data-index={virtualItem.index}
                style={{
                  position: 'absolute',
                  top: 0,
                  left: 0,
                  width: '100%',
                  transform: `translateY(${virtualItem.start}px)`,
                }}
              >
                <CommentBubble
                  comment={item.comment}
                  isFocused={item.comment.id === focusedCommentId}
                />
              </div>
            );
          }

          if (item.type === 'editor') {
            return (
              <div
                key={virtualItem.key}
                ref={virtualizer.measureElement}
                data-index={virtualItem.index}
                style={{
                  position: 'absolute',
                  top: 0,
                  left: 0,
                  width: '100%',
                  transform: `translateY(${virtualItem.start}px)`,
                }}
              >
                <InlineCommentEditor />
              </div>
            );
          }

          // code-line
          const lineNumber = item.lineNumber;
          const hasComment = commentsByLine.has(lineNumber);
          const isInRange =
            selectedRange &&
            lineNumber >= selectedRange.start &&
            lineNumber <= selectedRange.end;
          const isFocusedLine = focusedLine === lineNumber;
          const tokens = highlightTokens?.[lineNumber - 1];

          return (
            <div
              key={virtualItem.key}
              ref={virtualizer.measureElement}
              data-index={virtualItem.index}
              className={`flex ${isInRange ? 'bg-selection-bg' : ''} ${isFocusedLine ? 'ring-1 ring-inset ring-primary-500/40 bg-selection-bg/50' : ''}`}
              role="row"
              aria-rowindex={lineNumber}
              style={{
                position: 'absolute',
                top: 0,
                left: 0,
                width: '100%',
                ...(lineWrapEnabled ? {} : { height: `${CODE_LINE_HEIGHT}px` }),
                transform: `translateY(${virtualItem.start}px)`,
              }}
            >
              {/* Gutter */}
              <div
                className={`w-8 flex-shrink-0 flex ${lineWrapEnabled ? 'items-start pt-0.5' : 'items-center'} justify-center cursor-pointer select-none hover:bg-surface-secondary`}
                onClick={(e) => handleGutterClick(lineNumber, e)}
                onMouseDown={(e) => {
                  e.preventDefault();
                  handleMouseDown(lineNumber);
                }}
                onMouseEnter={() => handleMouseEnter(lineNumber)}
                role="rowheader"
                aria-label={`Line ${lineNumber} gutter${hasComment ? ', has comment' : ''}`}
              >
                {hasComment && (
                  <div className="w-2 h-2 rounded-full bg-comment-gutter" />
                )}
              </div>

              {/* Line number */}
              <div
                className={`flex-shrink-0 text-right pr-3 text-text-tertiary select-none cursor-pointer hover:bg-surface-secondary${lineWrapEnabled ? ' leading-[20px]' : ''}`}
                style={{ width: `${(padWidth + 1) * 0.6 + 1}rem` }}
                onClick={(e) => handleGutterClick(lineNumber, e)}
                onMouseDown={(e) => {
                  e.preventDefault();
                  handleMouseDown(lineNumber);
                }}
                onMouseEnter={() => handleMouseEnter(lineNumber)}
              >
                {lineNumber}
              </div>

              {/* Code content */}
              <div className={`flex-1 px-2 ${lineWrapEnabled ? 'whitespace-pre-wrap break-words overflow-x-hidden' : 'whitespace-pre overflow-x-auto'}`} role="gridcell">
                {tokens ? (
                  tokens.map((token, j) => (
                    <span
                      key={j}
                      className="shiki-token"
                      style={{
                        '--sl': token.lightColor ?? token.color,
                        '--sd': token.darkColor ?? token.color,
                      } as React.CSSProperties}
                    >
                      {token.content}
                    </span>
                  ))
                ) : (
                  item.content || '\n'
                )}
              </div>
            </div>
          );
        })}
      </div>
    </div>
  );
}
