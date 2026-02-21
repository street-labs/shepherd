// Implements: FR-crp-syntax-highlight, AC-crp-syntax-highlight-detected

import type { HighlightToken } from '@/types';

let highlighterPromise: Promise<import('shiki').Highlighter> | null = null;

async function getHighlighter() {
  if (!highlighterPromise) {
    const { createHighlighter } = await import('shiki');
    highlighterPromise = createHighlighter({
      themes: ['github-light'],
      langs: ['plaintext'],
    });
  }
  return highlighterPromise;
}

/**
 * Highlights code content and returns an array of token arrays (one per line).
 * Loads the language grammar lazily if not already loaded.
 */
export async function highlightCode(
  content: string,
  language: string,
): Promise<HighlightToken[][]> {
  try {
    const highlighter = await getHighlighter();

    // Load language if not already loaded
    if (language !== 'plaintext') {
      const loaded = highlighter.getLoadedLanguages();
      if (!loaded.includes(language)) {
        await highlighter.loadLanguage(language as Parameters<typeof highlighter.loadLanguage>[0]);
      }
    }

    const result = highlighter.codeToTokens(content, {
      lang: language as import('shiki').BundledLanguage,
      theme: 'github-light',
    });

    return result.tokens.map((line) =>
      line.map((token) => ({
        content: token.content,
        color: token.color,
      })),
    );
  } catch {
    // Fallback: return plain text tokens
    return content.split('\n').map((line) => [{ content: line }]);
  }
}
