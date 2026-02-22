// Implements: FR-diff-compute, FR-diff-collapse, FR-diff-expand,
// NFR-diff-compute-perf, NFR-diff-client-compute

import { structuredPatch } from 'diff';
import type {
  DiffLine,
  CollapsedSection,
  DiffComment,
  DiffDisplayItem,
  DiffEditorState,
} from '@/types';

interface DiffResult {
  diffLines: DiffLine[];
  collapsedSections: CollapsedSection[];
  isEmpty: boolean;
}

const DEFAULT_CONTEXT_LINES = 3;

/**
 * Computes a unified diff between old and new content.
 * Returns an array of diff lines, collapsed section metadata, and whether the diff is empty.
 */
export function computeFileDiff(
  oldContent: string,
  newContent: string,
  contextLines: number = DEFAULT_CONTEXT_LINES,
): DiffResult {
  const patch = structuredPatch(
    'old', 'new',
    oldContent, newContent,
    '', '',
    { context: 999999 }, // Get all context lines
  );

  const diffLines = transformHunksToDiffLines(patch.hunks);

  const hasChanges = diffLines.some((l) => l.type !== 'context');
  if (!hasChanges) {
    return { diffLines: [], collapsedSections: [], isEmpty: true };
  }

  const collapsedSections = computeCollapsedSections(diffLines, contextLines);

  return { diffLines, collapsedSections, isEmpty: false };
}

interface Hunk {
  oldStart: number;
  newStart: number;
  lines: string[];
}

function transformHunksToDiffLines(hunks: Hunk[]): DiffLine[] {
  const lines: DiffLine[] = [];
  let index = 0;

  for (const hunk of hunks) {
    let oldLine = hunk.oldStart;
    let newLine = hunk.newStart;

    for (const line of hunk.lines) {
      const prefix = line[0];
      const content = line.substring(1);

      if (prefix === '+') {
        lines.push({
          index,
          type: 'added',
          oldLineNumber: null,
          newLineNumber: newLine,
          content,
        });
        newLine++;
      } else if (prefix === '-') {
        lines.push({
          index,
          type: 'removed',
          oldLineNumber: oldLine,
          newLineNumber: null,
          content,
        });
        oldLine++;
      } else {
        lines.push({
          index,
          type: 'context',
          oldLineNumber: oldLine,
          newLineNumber: newLine,
          content,
        });
        oldLine++;
        newLine++;
      }
      index++;
    }
  }

  return lines;
}

function computeCollapsedSections(
  diffLines: DiffLine[],
  contextLines: number,
): CollapsedSection[] {
  const sections: CollapsedSection[] = [];

  // Find all change indices (non-context lines)
  const changeIndices: number[] = [];
  for (let i = 0; i < diffLines.length; i++) {
    if (diffLines[i]!.type !== 'context') {
      changeIndices.push(i);
    }
  }

  if (changeIndices.length === 0) return [];

  const firstChange = changeIndices[0]!;
  const lastChange = changeIndices[changeIndices.length - 1]!;

  // Leading context (before first change)
  if (firstChange > contextLines) {
    sections.push({
      startIndex: 0,
      endIndex: firstChange - contextLines - 1,
      lineCount: firstChange - contextLines,
    });
  }

  // Gaps between change regions
  let i = 0;
  while (i < changeIndices.length) {
    let regionEnd = changeIndices[i]!;
    let j = i + 1;
    while (j < changeIndices.length && changeIndices[j]! - regionEnd <= 2 * contextLines + 1) {
      regionEnd = changeIndices[j]!;
      j++;
    }

    if (j < changeIndices.length) {
      const gapStart = regionEnd + 1;
      const gapEnd = changeIndices[j]! - 1;
      const gapSize = gapEnd - gapStart + 1;

      if (gapSize > 2 * contextLines + 1) {
        const collapseStart = gapStart + contextLines;
        const collapseEnd = gapEnd - contextLines;
        sections.push({
          startIndex: collapseStart,
          endIndex: collapseEnd,
          lineCount: collapseEnd - collapseStart + 1,
        });
      }
    }

    i = j;
  }

  // Trailing context (after last change)
  const trailingStart = lastChange + contextLines + 1;
  if (trailingStart < diffLines.length) {
    sections.push({
      startIndex: trailingStart,
      endIndex: diffLines.length - 1,
      lineCount: diffLines.length - trailingStart,
    });
  }

  return sections;
}

/**
 * Builds the display items array by interleaving diff lines, collapsed sections,
 * comment bubbles, and the editor.
 */
export function buildDiffDisplayItems(
  diffLines: DiffLine[],
  collapsedSections: CollapsedSection[],
  expandedSections: Set<number>,
  diffComments: Record<string, DiffComment>,
  diffCommentOrder: string[],
  diffEditorState: DiffEditorState | null,
): DiffDisplayItem[] {
  const items: DiffDisplayItem[] = [];

  // Build a map of collapsed section start indices (non-expanded only)
  const collapsedRanges = new Map<number, { section: CollapsedSection; sectionIndex: number }>();
  for (let si = 0; si < collapsedSections.length; si++) {
    if (!expandedSections.has(si)) {
      collapsedRanges.set(collapsedSections[si]!.startIndex, {
        section: collapsedSections[si]!,
        sectionIndex: si,
      });
    }
  }

  // Map of endIndex -> comments that render after that line
  const commentsAfterIndex = new Map<number, DiffComment[]>();
  for (const id of diffCommentOrder) {
    const comment = diffComments[id];
    if (!comment) continue;
    const existing = commentsAfterIndex.get(comment.endIndex) ?? [];
    existing.push(comment);
    commentsAfterIndex.set(comment.endIndex, existing);
  }

  const editorAfterIndex = diffEditorState
    ? diffEditorState.mode === 'create'
      ? diffEditorState.endIndex
      : (diffComments[diffEditorState.commentId]?.endIndex ?? null)
    : null;

  let i = 0;
  while (i < diffLines.length) {
    // Check if this index starts a collapsed (non-expanded) section
    const collapsed = collapsedRanges.get(i);
    if (collapsed) {
      items.push({
        type: 'collapsed-section',
        section: collapsed.section,
        sectionIndex: collapsed.sectionIndex,
      });
      i = collapsed.section.endIndex + 1;
      continue;
    }

    // Regular diff line
    const line = diffLines[i]!;
    items.push({ type: 'diff-line', line });

    // Comments after this line
    const lineComments = commentsAfterIndex.get(i);
    if (lineComments) {
      for (const comment of lineComments) {
        items.push({ type: 'diff-comment-bubble', comment });
      }
    }

    // Editor after this line
    if (editorAfterIndex === i && diffEditorState) {
      items.push({
        type: 'diff-editor',
        startIndex: diffEditorState.mode === 'create'
          ? diffEditorState.startIndex
          : (diffComments[diffEditorState.commentId]?.startIndex ?? i),
        endIndex: i,
        mode: diffEditorState.mode,
        commentId: diffEditorState.mode === 'edit' ? diffEditorState.commentId : undefined,
      });
    }

    i++;
  }

  return items;
}
