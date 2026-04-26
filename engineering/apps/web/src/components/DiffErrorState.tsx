
interface DiffErrorStateProps {
  errorMessage: string;
  onRetry: () => void;
}

// Implements: FR-diff-baseline-fetch
export function DiffErrorState({ errorMessage, onRetry }: DiffErrorStateProps) {
  return (
    <div className="flex flex-col items-center justify-center h-full gap-3 text-center p-8">
      <p className="text-sm font-medium text-destructive-600">Failed to load baseline</p>
      <p className="text-xs text-text-secondary max-w-md">{errorMessage}</p>
      <button
        onClick={onRetry}
        className="mt-1 text-xs text-primary-600 hover:underline"
      >
        Retry
      </button>
    </div>
  );
}
