// Implements: FR-crp-prompt-generate, FR-crp-prompt-format, AC-crp-generate-prompt-structure,
// FR-diff-prompt-format, AC-diff-prompt-includes-diff

import type { Comment, FileInfo, DiffLine, DiffComment, DiffLineId, CollapsedSection, RenderedComment, RenderedDiffComment, ElementSourceMapping, AstDiffResult } from '@/types';

/**
 * Builds a structured prompt string from the loaded file, comments, and optional preamble.
 */
export function buildPrompt(
  file: FileInfo,
  comments: Comment[],
  preamble: string,
): string {
  const sections: string[] = [];

  // Instructions section (only if preamble is non-empty after trimming)
  const trimmedPreamble = preamble.trim();
  if (trimmedPreamble) {
    sections.push(`## Instructions\n\n${trimmedPreamble}`);
  }

  // File reference
  sections.push(`## File: ${file.name} (${file.language})`);

  // Feedback section — framed as user review feedback with code context
  sections.push(`## Review Feedback\n\nThe following are comments from a code review. Each item references the relevant code along with the reviewer's comment, which may be a suggested change, a question, or general feedback.`);

  const sorted = [...comments].sort((a, b) => {
    if (a.startLine !== b.startLine) return a.startLine - b.startLine;
    return a.createdAt.localeCompare(b.createdAt);
  });

  const changeEntries = sorted.map((c) => {
    const codeLines = file.lines.slice(c.startLine - 1, c.endLine);
    const codeSnippet = codeLines.join('\n');
    return `- **Referenced code:**\n  \`\`\`\n  ${codeSnippet.split('\n').join('\n  ')}\n  \`\`\`\n  **Comment:** ${c.text}`;
  });

  sections.push(changeEntries.join('\n\n'));

  return sections.join('\n\n');
}

/**
 * Builds a structured prompt from multiple files and their comments.
 * Groups comments by file, omits files with no comments, orders by fileOrder.
 * Falls back to single-file format when only one file has comments.
 */
export function buildMultiFilePrompt(
  files: Record<string, FileInfo>,
  fileOrder: string[],
  comments: Record<string, Comment>,
  preamble: string,
): string | null {
  // Group comments by fileId
  const commentsByFile = new Map<string, Comment[]>();
  for (const comment of Object.values(comments)) {
    const existing = commentsByFile.get(comment.fileId) ?? [];
    existing.push(comment);
    commentsByFile.set(comment.fileId, existing);
  }

  // Filter to files that have comments, in fileOrder order
  const filesWithComments = fileOrder.filter((fid) => commentsByFile.has(fid));
  if (filesWithComments.length === 0) return null;

  // Single file with comments — use the standard single-file format
  if (filesWithComments.length === 1) {
    const fid = filesWithComments[0]!;
    const file = files[fid];
    if (!file) return null;
    const fileComments = commentsByFile.get(fid)!;
    return buildPrompt(file, fileComments, preamble);
  }

  // Multi-file format
  const sections: string[] = [];

  const trimmedPreamble = preamble.trim();
  if (trimmedPreamble) {
    sections.push(`## Instructions\n\n${trimmedPreamble}`);
  }

  sections.push(`## Review Feedback\n\nThe following are comments from a code review across multiple files. Each file section includes the relevant code snippets along with the reviewer's comments.`);

  for (const fid of filesWithComments) {
    const file = files[fid];
    if (!file) continue;
    const fileComments = commentsByFile.get(fid)!;

    sections.push(`### File: ${file.name} (${file.language})`);

    const sorted = [...fileComments].sort((a, b) => {
      if (a.startLine !== b.startLine) return a.startLine - b.startLine;
      return a.createdAt.localeCompare(b.createdAt);
    });

    const changeEntries = sorted.map((c) => {
      const codeLines = file.lines.slice(c.startLine - 1, c.endLine);
      const codeSnippet = codeLines.join('\n');
      return `- **Referenced code:**\n  \`\`\`\n  ${codeSnippet.split('\n').join('\n  ')}\n  \`\`\`\n  **Comment:** ${c.text}`;
    });

    sections.push(changeEntries.join('\n\n'));
  }

  return sections.join('\n\n');
}

/**
 * Builds a structured prompt for diff-mode reviews.
 * Only includes the diff lines relevant to each comment (with a few lines of context),
 * not the entire diff.
 */
export function buildDiffPrompt(
  file: FileInfo,
  diffLines: DiffLine[],
  comments: DiffComment[],
  preamble: string,
  _collapsedSections: CollapsedSection[],
  _expandedSections: Set<number>,
): string {
  const sections: string[] = [];

  // Instructions section (only if preamble is non-empty)
  const trimmedPreamble = preamble.trim();
  if (trimmedPreamble) {
    sections.push(`## Instructions\n\n${trimmedPreamble}`);
  }

  // File reference
  sections.push(`## File: ${file.name} (${file.language}) -- Diff View`);

  // Feedback section
  sections.push(`## Review Feedback\n\nThe following are comments on changes between the git HEAD version and the current working copy. Each item shows the relevant diff context (lines prefixed with \`+\` are additions, \`-\` are removals, unmarked lines are unchanged) along with the reviewer's comment.`);

  const sorted = [...comments].sort((a, b) => {
    if (a.startIndex !== b.startIndex) return a.startIndex - b.startIndex;
    return a.createdAt.localeCompare(b.createdAt);
  });

  const CONTEXT_LINES = 2;

  const changeEntries = sorted.map((c) => {
    // Extract the commented lines plus a few lines of surrounding context
    const snippetStart = Math.max(0, c.startIndex - CONTEXT_LINES);
    const snippetEnd = Math.min(diffLines.length - 1, c.endIndex + CONTEXT_LINES);

    const snippetLines: string[] = [];
    for (let i = snippetStart; i <= snippetEnd; i++) {
      const line = diffLines[i]!;
      const prefix = line.type === 'added' ? '+' : line.type === 'removed' ? '-' : ' ';
      snippetLines.push(`  ${prefix} ${line.content}`);
    }
    const snippet = snippetLines.join('\n');

    const label = formatDiffCommentLabel(c);
    return `- **${label}:**\n  \`\`\`diff\n${snippet}\n  \`\`\`\n  **Comment:** ${c.text}`;
  });

  sections.push(changeEntries.join('\n\n'));

  return sections.join('\n\n');
}

export function formatDiffCommentLabel(comment: DiffComment): string {
  const startLabel = formatLineRef(comment.startLineId);
  if (comment.startIndex === comment.endIndex) {
    return `Line ${startLabel}`;
  }
  const endLabel = formatLineRef(comment.endLineId);
  return `Lines ${startLabel} to ${endLabel}`;
}

function formatLineRef(lineId: DiffLineId): string {
  if (lineId.lineType === 'added') return `+${lineId.newLine}`;
  if (lineId.lineType === 'removed') return `-${lineId.oldLine}`;
  return String(lineId.newLine); // Context lines use new line number
}

/**
 * Builds a prompt for rendered-mode reviews.
 * Includes raw markdown source (not HTML) for each commented element.
 */
export function buildRenderedPrompt(
  file: FileInfo,
  comments: RenderedComment[],
  preamble: string,
  sourceMap: ElementSourceMapping[],
): string {
  const sections: string[] = [];

  const trimmedPreamble = preamble.trim();
  if (trimmedPreamble) {
    sections.push(`## Instructions\n\n${trimmedPreamble}`);
  }

  sections.push(`## File: ${file.name} (${file.language}) -- Rendered View`);

  sections.push(`## Review Feedback\n\nThe following are comments on specific elements of a markdown file. Each item shows the element type, its source line range, and the raw markdown source along with the reviewer's comment.`);

  // Build a lookup from elementId to source mapping
  const sourceByElementId = new Map(sourceMap.map((m) => [m.elementId, m]));

  const sorted = [...comments].sort((a, b) => a.createdAt.localeCompare(b.createdAt));

  const changeEntries = sorted.map((c) => {
    const mapping = sourceByElementId.get(c.elementId);
    const lineRange = mapping ? `lines ${mapping.startLine}-${mapping.endLine}` : 'unknown lines';
    const rawSource = mapping?.rawSource ?? c.contentPreview;

    return `- **${capitalize(c.elementType)} (${lineRange})**:\n  \`\`\`markdown\n  ${rawSource.split('\n').join('\n  ')}\n  \`\`\`\n  **Comment:** ${c.text}`;
  });

  sections.push(changeEntries.join('\n\n'));

  return sections.join('\n\n');
}

/**
 * Builds a prompt for rendered-diff-mode reviews.
 * Shows old/new source for modified elements, new-only for added, old-only for removed.
 */
export function buildRenderedDiffPrompt(
  file: FileInfo,
  comments: RenderedDiffComment[],
  preamble: string,
  diffResult: AstDiffResult,
  sourceMap: ElementSourceMapping[],
): string {
  const sections: string[] = [];

  const trimmedPreamble = preamble.trim();
  if (trimmedPreamble) {
    sections.push(`## Instructions\n\n${trimmedPreamble}`);
  }

  sections.push(`## File: ${file.name} (${file.language}) -- Rendered Diff View`);

  sections.push(`## Annotated Elements\n\nThe following are comments on elements that changed between the git HEAD version and the current working copy. Each item shows the element type, its change status, and relevant source.`);

  // Build lookup from elementId to diff entry
  const diffByElementId = new Map(diffResult.entries.map((e) => [e.elementId, e]));
  const sourceByElementId = new Map(sourceMap.map((m) => [m.elementId, m]));

  const sorted = [...comments].sort((a, b) => a.createdAt.localeCompare(b.createdAt));

  const changeEntries = sorted.map((c) => {
    const entry = diffByElementId.get(c.elementId);
    const mapping = sourceByElementId.get(c.elementId);
    const status = c.diffStatus.toUpperCase();

    let sourceSection = '';
    if (entry?.status === 'modified') {
      const oldSrc = entry.oldElement?.textContent ?? '';
      const newSrc = entry.newElement?.textContent ?? '';
      sourceSection = `  Old:\n  \`\`\`markdown\n  ${oldSrc.split('\n').join('\n  ')}\n  \`\`\`\n  New:\n  \`\`\`markdown\n  ${newSrc.split('\n').join('\n  ')}\n  \`\`\``;
    } else if (entry?.status === 'added') {
      const src = mapping?.rawSource ?? entry.newElement?.textContent ?? '';
      sourceSection = `  \`\`\`markdown\n  ${src.split('\n').join('\n  ')}\n  \`\`\``;
    } else if (entry?.status === 'removed') {
      const src = entry.oldElement?.textContent ?? '';
      sourceSection = `  \`\`\`markdown\n  ${src.split('\n').join('\n  ')}\n  \`\`\``;
    } else {
      const src = mapping?.rawSource ?? '';
      sourceSection = `  \`\`\`markdown\n  ${src.split('\n').join('\n  ')}\n  \`\`\``;
    }

    return `- **${capitalize(c.elementType)} [${status}]**:\n${sourceSection}\n  **Comment:** ${c.text}`;
  });

  sections.push(changeEntries.join('\n\n'));

  return sections.join('\n\n');
}

function capitalize(s: string): string {
  return s.charAt(0).toUpperCase() + s.slice(1);
}

