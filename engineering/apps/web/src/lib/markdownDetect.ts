
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
// Implements: FR-mdr-detect-markdown
export function isMarkdownFile(fileName: string): boolean {
  const lastDot = fileName.lastIndexOf('.');
  if (lastDot === -1) return false;
  const ext = fileName.slice(lastDot).toLowerCase();
  return MARKDOWN_EXTENSIONS.has(ext);
}
