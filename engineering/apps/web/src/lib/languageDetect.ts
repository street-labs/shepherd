// Implements: FR-crp-syntax-highlight

const EXTENSION_MAP: Record<string, string> = {
  '.js': 'javascript',
  '.jsx': 'javascript',
  '.mjs': 'javascript',
  '.cjs': 'javascript',
  '.ts': 'typescript',
  '.tsx': 'typescript',
  '.mts': 'typescript',
  '.cts': 'typescript',
  '.py': 'python',
  '.pyw': 'python',
  '.go': 'go',
  '.rs': 'rust',
  '.java': 'java',
  '.c': 'c',
  '.h': 'c',
  '.cpp': 'cpp',
  '.cc': 'cpp',
  '.cxx': 'cpp',
  '.hpp': 'cpp',
  '.hxx': 'cpp',
  '.html': 'html',
  '.htm': 'html',
  '.css': 'css',
  '.json': 'json',
  '.yaml': 'yaml',
  '.yml': 'yaml',
  '.md': 'markdown',
  '.mdx': 'markdown',
};

/**
 * Detects the programming language from a file name by matching its extension.
 * Returns the Shiki language identifier, or "plaintext" if unrecognized.
 */
export function detectLanguage(fileName: string): string {
  const lastDot = fileName.lastIndexOf('.');
  if (lastDot === -1) return 'plaintext';
  const ext = fileName.slice(lastDot).toLowerCase();
  return EXTENSION_MAP[ext] ?? 'plaintext';
}
