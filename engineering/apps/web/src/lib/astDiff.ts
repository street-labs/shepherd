// Implements: FR-mr-rendered-diff, FR-mr-ast-diff

import { diffWords } from 'diff';
import { parseMarkdownToAst } from './markdownPipeline';
import { assignElementIds } from './elementId';
import type { AstBlockElement, AstDiffResult, AstDiffEntry, WordDiffSegment } from '@/types';

const FALLBACK_THRESHOLD = 0.8; // >80% blocks changed → suggest raw diff
const MODIFIED_OVERLAP_THRESHOLD = 0.3; // >30% word overlap → "modified" not "removed+added"

/**
 * Flatten an AST into block elements with assigned IDs.
 */
function flattenAst(source: string): AstBlockElement[] {
  const ast = parseMarkdownToAst(source);
  const lines = source.split('\n');
  const { elements } = assignElementIds(ast, lines);
  // Filter out listItems — they're part of their parent list
  return elements.filter((e) => e.type !== 'listItem');
}

/**
 * Compute word overlap ratio between two strings.
 * Returns value between 0 (no overlap) and 1 (identical).
 */
function computeWordOverlap(a: string, b: string): number {
  const wordsA = new Set(a.toLowerCase().split(/\s+/).filter(Boolean));
  const wordsB = new Set(b.toLowerCase().split(/\s+/).filter(Boolean));
  if (wordsA.size === 0 && wordsB.size === 0) return 1;
  if (wordsA.size === 0 || wordsB.size === 0) return 0;

  let overlap = 0;
  for (const word of wordsA) {
    if (wordsB.has(word)) overlap++;
  }
  return overlap / Math.max(wordsA.size, wordsB.size);
}

/**
 * Compute word-level diff segments between two text strings.
 */
function computeWordDiff(oldText: string, newText: string): WordDiffSegment[] {
  const changes = diffWords(oldText, newText);
  return changes.map((change) => ({
    value: change.value,
    added: change.added || undefined,
    removed: change.removed || undefined,
  }));
}

/**
 * Compute an AST-level diff between old and new markdown sources.
 *
 * Algorithm:
 * 1. Parse both sources into flat lists of block elements.
 * 2. Use LCS-style alignment by element type + text similarity.
 * 3. Classify each entry as added, removed, modified, or unchanged.
 * 4. For modified blocks, compute word-level diffs.
 */
export function computeAstDiff(oldSource: string, newSource: string): AstDiffResult {
  const oldElements = flattenAst(oldSource);
  const newElements = flattenAst(newSource);

  const entries: AstDiffEntry[] = [];

  // Simple diff: walk both lists with LCS-style matching
  let oldIdx = 0;
  let newIdx = 0;

  // Build a simple greedy alignment
  const matched = new Set<number>(); // indices in newElements that have been matched

  while (oldIdx < oldElements.length) {
    const oldEl = oldElements[oldIdx]!;

    // Try to find a matching element in remaining new elements
    let bestMatch = -1;
    let bestOverlap = 0;

    for (let j = newIdx; j < newElements.length; j++) {
      if (matched.has(j)) continue;
      const newEl = newElements[j]!;

      // Same type required for matching
      if (oldEl.type !== newEl.type) continue;

      const overlap = computeWordOverlap(oldEl.textContent, newEl.textContent);
      if (overlap > bestOverlap) {
        bestOverlap = overlap;
        bestMatch = j;
      }
    }

    if (bestMatch >= 0 && bestOverlap >= MODIFIED_OVERLAP_THRESHOLD) {
      // Emit any unmatched new elements before the match as "added"
      for (let j = newIdx; j < bestMatch; j++) {
        if (!matched.has(j)) {
          const newEl = newElements[j]!;
          entries.push({
            elementId: newEl.elementId,
            status: 'added',
            type: newEl.type,
            newElement: newEl,
          });
          matched.add(j);
        }
      }

      const newEl = newElements[bestMatch]!;
      matched.add(bestMatch);

      if (oldEl.textContent === newEl.textContent) {
        // Unchanged
        entries.push({
          elementId: newEl.elementId,
          status: 'unchanged',
          type: newEl.type,
          oldElement: oldEl,
          newElement: newEl,
        });
      } else {
        // Modified
        entries.push({
          elementId: newEl.elementId,
          status: 'modified',
          type: newEl.type,
          oldElement: oldEl,
          newElement: newEl,
          wordDiff: computeWordDiff(oldEl.textContent, newEl.textContent),
        });
      }

      newIdx = bestMatch + 1;
    } else {
      // No match — this old element was removed
      entries.push({
        elementId: oldEl.elementId,
        status: 'removed',
        type: oldEl.type,
        oldElement: oldEl,
      });
    }

    oldIdx++;
  }

  // Any remaining unmatched new elements are "added"
  for (let j = 0; j < newElements.length; j++) {
    if (!matched.has(j)) {
      const newEl = newElements[j]!;
      entries.push({
        elementId: newEl.elementId,
        status: 'added',
        type: newEl.type,
        newElement: newEl,
      });
    }
  }

  // Determine if fallback threshold is exceeded
  const changedCount = entries.filter((e) => e.status !== 'unchanged').length;
  const totalCount = entries.length;
  const exceedsFallbackThreshold = totalCount > 0 && changedCount / totalCount > FALLBACK_THRESHOLD;

  return { entries, exceedsFallbackThreshold };
}
