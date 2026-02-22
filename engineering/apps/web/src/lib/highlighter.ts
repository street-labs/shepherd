// Implements: FR-crp-syntax-highlight, AC-crp-syntax-highlight-detected,
// NFR-dm-syntax-highlight-both-themes

import type { HighlightToken } from '@/types';

let highlighterPromise: Promise<import('shiki').HighlighterGeneric<any, any>> | null = null;

async function getHighlighter() {
  if (!highlighterPromise) {
    const { createHighlighter } = await import('shiki');
    highlighterPromise = createHighlighter({
      themes: ['github-light', 'github-dark'],
      langs: ['plaintext'],
    });
  }
  return highlighterPromise;
}

/**
 * Highlights code content and returns an array of token arrays (one per line).
 * Loads the language grammar lazily if not already loaded.
 * Returns tokens with both light and dark colors for dual-theme support.
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

    // Use codeToTokensWithThemes for dual-theme token output
    const result = highlighter.codeToTokensWithThemes(content, {
      lang: language as import('shiki').BundledLanguage,
      themes: {
        light: 'github-light',
        dark: 'github-dark',
      },
    });

    return result.map((line) =>
      line.map((token) => ({
        content: token.content,
        color: token.variants['light']?.color,
        lightColor: token.variants['light']?.color,
        darkColor: token.variants['dark']?.color,
      })),
    );
  } catch {
    // Fallback: return plain text tokens
    return content.split('\n').map((line) => [{ content: line }]);
  }
}
