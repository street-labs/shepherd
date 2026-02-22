// Implements: FR-crp-prompt-preview, FR-crp-prompt-format,
// AC-crp-generate-prompt-structure, AC-crp-preview-matches-copy

import { useAppStore } from '@/store/appStore';

export function PromptPreview() {
  const generatedPrompt = useAppStore((s) => s.generatedPrompt);
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
          Add comments to the code to generate your AI prompt.
        </div>
      ) : (
        <div className="flex-1 min-h-0 flex flex-col">
          <pre className="flex-1 overflow-auto p-3 rounded bg-code-block-bg text-code-block-text text-xs leading-relaxed whitespace-pre-wrap break-words">
            {generatedPrompt}
          </pre>
        </div>
      )}
    </div>
  );
}
