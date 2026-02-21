// Implements: FR-crp-prompt-generate, FR-crp-prompt-format, AC-crp-generate-prompt-structure

import type { Comment, FileInfo } from '@/types';

/**
 * Builds a structured prompt string from the loaded file, comments, and optional preamble.
 *
 * The prompt includes the file path and each comment with the actual code it references
 * (not line numbers, since those change as the file is edited).
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
