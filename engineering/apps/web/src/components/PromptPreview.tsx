// Implements: FR-crp-prompt-preview, FR-crp-prompt-format,
// AC-crp-generate-prompt-structure, AC-crp-preview-matches-copy

import { useAppStore } from '@/store/appStore';

export function PromptPreview() {
  const generatedPrompt = useAppStore((s) => s.generatedPrompt);
  const isPromptStale = useAppStore((s) => s.isPromptStale);
  const generatePrompt = useAppStore((s) => s.generatePrompt);
  const copyPrompt = useAppStore((s) => s.copyPrompt);

  return (
    <div className="flex-1 flex flex-col p-4 min-h-0">
      <div className="flex items-center justify-between mb-2">
        <h2 className="text-xs font-medium text-text-secondary">Preview</h2>
        {generatedPrompt && (
          <button
            onClick={() => void copyPrompt()}
            className="text-xs text-primary-600 hover:text-primary-700"
          >
            Copy
          </button>
        )}
      </div>

      {!generatedPrompt ? (
        <div className="flex-1 flex items-center justify-center text-sm text-text-tertiary">
          Add comments and click Generate to preview the prompt.
        </div>
      ) : (
        <div className="flex-1 min-h-0 flex flex-col">
          {isPromptStale && (
            <div className="flex items-center gap-2 mb-2 px-2 py-1 rounded bg-warning-bg text-warning-text text-xs">
              <span>Prompt is outdated.</span>
              <button
                onClick={generatePrompt}
                className="underline hover:no-underline"
              >
                Regenerate
              </button>
            </div>
          )}
          <pre className="flex-1 overflow-auto p-3 rounded bg-gray-900 text-gray-100 text-xs leading-relaxed whitespace-pre-wrap break-words">
            {generatedPrompt}
          </pre>
        </div>
      )}
    </div>
  );
}
