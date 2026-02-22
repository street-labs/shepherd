// Implements: FR-mr-markdown-detect

const MARKDOWN_EXTENSIONS = new Set([
  '.md',
  '.mdx',
  '.markdown',
  '.mdown',
  '.mkdn',
  '.mkd',
]);

/**
 * Checks whether a file name has a markdown extension (case-insensitive).
 */
export function isMarkdownFile(fileName: string): boolean {
  const lastDot = fileName.lastIndexOf('.');
  if (lastDot === -1) return false;
  const ext = fileName.slice(lastDot).toLowerCase();
  return MARKDOWN_EXTENSIONS.has(ext);
}
