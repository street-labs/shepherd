// Implements: FR-diff-display, FR-diff-collapse, FR-diff-expand, FR-diff-comment-create,
// FR-diff-comment-on-range, NFR-diff-render-perf, NFR-diff-accessibility,
// AC-diff-line-numbers, AC-diff-syntax-highlight

import { useAppStore } from '@/store/appStore';
import { CommentBubble } from './CommentBubble';
import { InlineCommentEditor } from './InlineCommentEditor';
import { CollapsedSectionSeparator } from './CollapsedSectionSeparator';
import { useRef, useMemo, useCallback, useEffect, useState } from 'react';
import { useVirtualizer } from '@tanstack/react-virtual';
import { highlightCode } from '@/lib/highlighter';
import { buildDiffDisplayItems } from '@/lib/diffCompute';
import { formatDiffCommentLabel } from '@/lib/promptBuilder';
import type { DiffDisplayItem, DiffLine, HighlightToken } from '@/types';

const CODE_LINE_HEIGHT = 20;
const COLLAPSED_SECTION_HEIGHT = 36;
const COMMENT_BUBBLE_HEIGHT = 60;
const EDITOR_HEIGHT = 160;
const OVERSCAN = 20;

export function DiffViewer() {
  const file = useAppStore((s) => s.file);
  const baselineContent = useAppStore((s) => s.baselineContent);
  const diffLines = useAppStore((s) => s.diffLines);
  const collapsedSections = useAppStore((s) => s.collapsedSections);
  const expandedSections = useAppStore((s) => s.expandedSections);
  const diffComments = useAppStore((s) => s.diffComments);
  const diffCommentOrder = useAppStore((s) => s.diffCommentOrder);
  const diffEditorState = useAppStore((s) => s.diffEditorState);
  const diffSelectedRange = useAppStore((s) => s.diffSelectedRange);
  const focusedDiffCommentId = useAppStore((s) => s.focusedDiffCommentId);
  const expandSection = useAppStore((s) => s.expandSection);
  const openDiffEditor = useAppStore((s) => s.openDiffEditor);
  const setDiffSelectedRange = useAppStore((s) => s.setDiffSelectedRange);
  const lineWrapEnabled = useAppStore((s) => s.lineWrapEnabled);

  const containerRef = useRef<HTMLDivElement>(null);
  const isSelectingRef = useRef(false);
  const selectionStartRef = useRef<number | null>(null);

  // Keyboard navigation state
  const [focusedIndex, setFocusedIndex] = useState<number | null>(null);
  const [rangeAnchor, setRangeAnchor] = useState<number | null>(null);

  // Syntax highlighting state
  const [newTokens, setNewTokens] = useState<HighlightToken[][] | null>(null);
  const [oldTokens, setOldTokens] = useState<HighlightToken[][] | null>(null);

  // Load syntax highlighting for both versions
  useEffect(() => {
    if (!file) { setNewTokens(null); return; }
    let cancelled = false;
    highlightCode(file.content, file.language).then((tokens) => {
      if (!cancelled) setNewTokens(tokens);
    });
    return () => { cancelled = true; };
  }, [file?.content, file?.language]);

  useEffect(() => {
    if (baselineContent === null || !file) { setOldTokens(null); return; }
    let cancelled = false;
    highlightCode(baselineContent, file.language).then((tokens) => {
      if (!cancelled) setOldTokens(tokens);
    });
    return () => { cancelled = true; };
  }, [baselineContent, file?.language]);

  // Compute which diff indices have comments
  const commentsByIndex = useMemo(() => {
    const map = new Map<number, boolean>();
    for (const id of diffCommentOrder) {
      const comment = diffComments[id];
      if (!comment) continue;
      for (let idx = comment.startIndex; idx <= comment.endIndex; idx++) {
        map.set(idx, true);
      }
    }
    return map;
  }, [diffComments, diffCommentOrder]);

  // Build display items
  const displayItems = useMemo((): DiffDisplayItem[] => {
    if (!diffLines || !collapsedSections) return [];
    return buildDiffDisplayItems(
      diffLines,
      collapsedSections,
      expandedSections,
      diffComments,
      diffCommentOrder,
      diffEditorState,
    );
  }, [diffLines, collapsedSections, expandedSections, diffComments, diffCommentOrder, diffEditorState]);

  const virtualizer = useVirtualizer({
    count: displayItems.length,
    getScrollElement: () => containerRef.current,
    estimateSize: (index) => {
      const item = displayItems[index];
      if (!item) return CODE_LINE_HEIGHT;
      switch (item.type) {
        case 'diff-line': return CODE_LINE_HEIGHT;
        case 'collapsed-section': return COLLAPSED_SECTION_HEIGHT;
        case 'diff-comment-bubble': return COMMENT_BUBBLE_HEIGHT;
        case 'diff-editor': return EDITOR_HEIGHT;
      }
    },
    overscan: OVERSCAN,
    measureElement: (el) => el.getBoundingClientRect().height,
  });

  // Scroll to focused comment
  useEffect(() => {
    if (!focusedDiffCommentId) return;
    const index = displayItems.findIndex(
      (item) => item.type === 'diff-comment-bubble' && item.comment.id === focusedDiffCommentId,
    );
    if (index >= 0) {
      virtualizer.scrollToIndex(index, { align: 'center', behavior: 'smooth' });
    }
  }, [focusedDiffCommentId, displayItems, virtualizer]);

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

  // Get tokens for a diff line
  const getTokensForLine = useCallback(
    (line: DiffLine): HighlightToken[] | undefined => {
      if (line.type === 'removed' && oldTokens && line.oldLineNumber !== null) {
        return oldTokens[line.oldLineNumber - 1];
      }
      if (newTokens && line.newLineNumber !== null) {
        return newTokens[line.newLineNumber - 1];
      }
      return undefined;
    },
    [oldTokens, newTokens],
  );

  // Keyboard navigation
  const handleKeyDown = useCallback(
    (e: React.KeyboardEvent) => {
      const target = e.target as HTMLElement;
      if (target.tagName === 'INPUT' || target.tagName === 'TEXTAREA') return;
      if (!diffLines) return;

      const totalIndices = diffLines.length;
      const current = focusedIndex ?? -1;

      switch (e.key) {
        case 'ArrowDown': {
          e.preventDefault();
          const next = Math.min(current + 1, totalIndices - 1);
          setFocusedIndex(next);
          if (e.shiftKey) {
            const anchor = rangeAnchor ?? next;
            if (rangeAnchor === null) setRangeAnchor(current >= 0 ? current : 0);
            const start = Math.min(anchor, next);
            const end = Math.max(anchor, next);
            setDiffSelectedRange({ startIndex: start, endIndex: end });
          } else {
            setRangeAnchor(null);
            setDiffSelectedRange(null);
          }
          const lineDisplayIdx = displayItems.findIndex(
            (item) => item.type === 'diff-line' && item.line.index === next,
          );
          if (lineDisplayIdx >= 0) virtualizer.scrollToIndex(lineDisplayIdx, { align: 'auto' });
          break;
        }
        case 'ArrowUp': {
          e.preventDefault();
          const prev = Math.max(current - 1, 0);
          setFocusedIndex(prev);
          if (e.shiftKey) {
            const anchor = rangeAnchor ?? prev;
            if (rangeAnchor === null) setRangeAnchor(current >= 0 ? current : 0);
            const start = Math.min(anchor, prev);
            const end = Math.max(anchor, prev);
            setDiffSelectedRange({ startIndex: start, endIndex: end });
          } else {
            setRangeAnchor(null);
            setDiffSelectedRange(null);
          }
          const lineDisplayIdx = displayItems.findIndex(
            (item) => item.type === 'diff-line' && item.line.index === prev,
          );
          if (lineDisplayIdx >= 0) virtualizer.scrollToIndex(lineDisplayIdx, { align: 'auto' });
          break;
        }
        case 'Enter':
        case 'c': {
          e.preventDefault();
          if (diffSelectedRange && diffSelectedRange.startIndex !== diffSelectedRange.endIndex) {
            openDiffEditor({ mode: 'create', startIndex: diffSelectedRange.startIndex, endIndex: diffSelectedRange.endIndex });
          } else if (focusedIndex !== null && focusedIndex >= 0) {
            openDiffEditor({ mode: 'create', startIndex: focusedIndex, endIndex: focusedIndex });
          }
          setRangeAnchor(null);
          break;
        }
        case 'Escape': {
          setFocusedIndex(null);
          setRangeAnchor(null);
          setDiffSelectedRange(null);
          break;
        }
      }
    },
    [diffLines, focusedIndex, rangeAnchor, displayItems, virtualizer, openDiffEditor, setDiffSelectedRange, diffSelectedRange],
  );

  const handleGutterClick = useCallback(
    (lineIndex: number, e: React.MouseEvent) => {
      if (e.shiftKey && selectionStartRef.current !== null) {
        const start = Math.min(selectionStartRef.current, lineIndex);
        const end = Math.max(selectionStartRef.current, lineIndex);
        setDiffSelectedRange({ startIndex: start, endIndex: end });
        openDiffEditor({ mode: 'create', startIndex: start, endIndex: end });
        selectionStartRef.current = null;
      } else {
        selectionStartRef.current = lineIndex;
        openDiffEditor({ mode: 'create', startIndex: lineIndex, endIndex: lineIndex });
      }
    },
    [openDiffEditor, setDiffSelectedRange],
  );

  const handleMouseDown = useCallback(
    (lineIndex: number) => {
      isSelectingRef.current = true;
      selectionStartRef.current = lineIndex;
      setDiffSelectedRange({ startIndex: lineIndex, endIndex: lineIndex });
    },
    [setDiffSelectedRange],
  );

  const handleMouseEnter = useCallback(
    (lineIndex: number) => {
      if (!isSelectingRef.current || selectionStartRef.current === null) return;
      const start = Math.min(selectionStartRef.current, lineIndex);
      const end = Math.max(selectionStartRef.current, lineIndex);
      setDiffSelectedRange({ startIndex: start, endIndex: end });
    },
    [setDiffSelectedRange],
  );

  const handleMouseUp = useCallback(() => {
    if (!isSelectingRef.current) return;
    isSelectingRef.current = false;
    const range = useAppStore.getState().diffSelectedRange;
    if (range && range.startIndex !== range.endIndex) {
      openDiffEditor({ mode: 'create', startIndex: range.startIndex, endIndex: range.endIndex });
    }
  }, [openDiffEditor]);

  useEffect(() => {
    const handleGlobalMouseUp = () => { isSelectingRef.current = false; };
    document.addEventListener('mouseup', handleGlobalMouseUp);
    return () => document.removeEventListener('mouseup', handleGlobalMouseUp);
  }, []);

  if (!file || !diffLines) return null;

  return (
    <div
      ref={containerRef}
      className="h-full overflow-auto font-mono text-[13px] leading-[20px] focus:outline-none focus-visible:ring-2 focus-visible:ring-inset focus-visible:ring-primary-500"
      role="grid"
      aria-label="Diff viewer"
      aria-rowcount={diffLines.length}
      tabIndex={0}
      onKeyDown={handleKeyDown}
      onMouseUp={handleMouseUp}
    >
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

          if (item.type === 'collapsed-section') {
            return (
              <div
                key={`collapsed-${item.sectionIndex}`}
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
                <CollapsedSectionSeparator
                  lineCount={item.section.lineCount}
                  onExpand={() => expandSection(item.sectionIndex)}
                />
              </div>
            );
          }

          if (item.type === 'diff-comment-bubble') {
            const label = formatDiffCommentLabel(item.comment);
            return (
              <div
                key={`comment-${item.comment.id}`}
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
                  isFocused={item.comment.id === focusedDiffCommentId}
                  label={label}
                  isDiffMode
                />
              </div>
            );
          }

          if (item.type === 'diff-editor') {
            return (
              <div
                key="diff-editor"
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
                <InlineCommentEditor isDiffMode />
              </div>
            );
          }

          // diff-line
          const line = item.line;
          const hasComment = commentsByIndex.has(line.index);
          const isInRange =
            diffSelectedRange &&
            line.index >= diffSelectedRange.startIndex &&
            line.index <= diffSelectedRange.endIndex;
          const isFocusedLine = focusedIndex === line.index;
          const tokens = getTokensForLine(line);

          const bgColor =
            line.type === 'added'
              ? 'bg-diff-added-bg'
              : line.type === 'removed'
                ? 'bg-diff-removed-bg'
                : '';

          const gutterBg =
            line.type === 'added'
              ? 'bg-diff-added-gutter'
              : line.type === 'removed'
                ? 'bg-diff-removed-gutter'
                : '';

          return (
            <div
              key={`line-${line.index}`}
              ref={virtualizer.measureElement}
              data-index={virtualItem.index}
              className={`flex ${bgColor} ${isInRange ? 'ring-1 ring-inset ring-primary-500/30 bg-selection-bg/60' : ''} ${isFocusedLine ? 'ring-1 ring-inset ring-primary-500/40' : ''}`}
              role="row"
              aria-rowindex={line.index + 1}
              style={{
                position: 'absolute',
                top: 0,
                left: 0,
                width: '100%',
                ...(lineWrapEnabled ? {} : { height: `${CODE_LINE_HEIGHT}px` }),
                transform: `translateY(${virtualItem.start}px)`,
              }}
            >
              {/* Comment gutter (28px) */}
              <div
                className={`w-7 flex-shrink-0 flex ${lineWrapEnabled ? 'items-start pt-0.5' : 'items-center'} justify-center cursor-pointer select-none hover:bg-selection-bg/50 ${gutterBg}`}
                onClick={(e) => handleGutterClick(line.index, e)}
                onMouseDown={(e) => { e.preventDefault(); handleMouseDown(line.index); }}
                onMouseEnter={() => handleMouseEnter(line.index)}
                role="rowheader"
                aria-label={`Diff line ${line.index + 1} gutter${hasComment ? ', has comment' : ''}`}
              >
                {hasComment && (
                  <div className="w-2 h-2 rounded-full bg-comment-gutter" />
                )}
              </div>

              {/* Old line number (44px) */}
              <div
                className={`w-11 flex-shrink-0 text-right pr-1 text-text-tertiary select-none text-[11px] cursor-pointer hover:bg-selection-bg/50 ${gutterBg}${lineWrapEnabled ? ' leading-[20px]' : ''}`}
                onClick={(e) => handleGutterClick(line.index, e)}
                onMouseDown={(e) => { e.preventDefault(); handleMouseDown(line.index); }}
                onMouseEnter={() => handleMouseEnter(line.index)}
              >
                {line.oldLineNumber ?? ''}
              </div>

              {/* New line number (44px) */}
              <div
                className={`w-11 flex-shrink-0 text-right pr-1 text-text-tertiary select-none text-[11px] cursor-pointer hover:bg-selection-bg/50 ${gutterBg}${lineWrapEnabled ? ' leading-[20px]' : ''}`}
                onClick={(e) => handleGutterClick(line.index, e)}
                onMouseDown={(e) => { e.preventDefault(); handleMouseDown(line.index); }}
                onMouseEnter={() => handleMouseEnter(line.index)}
              >
                {line.newLineNumber ?? ''}
              </div>

              {/* Type indicator (20px) */}
              <div
                className={`w-5 flex-shrink-0 text-center select-none font-bold text-[11px] cursor-pointer hover:bg-selection-bg/50 ${
                  line.type === 'added'
                    ? 'text-diff-added-indicator'
                    : line.type === 'removed'
                      ? 'text-diff-removed-indicator'
                      : 'text-transparent'
                }`}
                onClick={(e) => handleGutterClick(line.index, e)}
                onMouseDown={(e) => { e.preventDefault(); handleMouseDown(line.index); }}
                onMouseEnter={() => handleMouseEnter(line.index)}
              >
                {line.type === 'added' ? '+' : line.type === 'removed' ? '-' : ' '}
              </div>

              {/* Spacer (4px) */}
              <div className="w-1 flex-shrink-0" />

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
                  line.content || '\n'
                )}
              </div>
            </div>
          );
        })}
      </div>
    </div>
  );
}
