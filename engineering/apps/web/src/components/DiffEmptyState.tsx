// Implements: FR-diff-empty-state, AC-diff-no-changes

interface DiffEmptyStateProps {
  onSwitchToFile: () => void;
}

export function DiffEmptyState({ onSwitchToFile }: DiffEmptyStateProps) {
  return (
    <div className="flex flex-col items-center justify-center h-full gap-3 text-center p-8">
      <div className="text-3xl text-text-tertiary">=</div>
      <p className="text-sm font-medium text-text-primary">No changes detected</p>
      <p className="text-xs text-text-secondary">
        The working copy matches the git HEAD version.
      </p>
      <button
        onClick={onSwitchToFile}
        className="mt-2 px-4 py-2 text-xs font-medium rounded bg-primary-500 text-text-on-primary hover:bg-primary-600"
        autoFocus
      >
        Switch to File view
      </button>
    </div>
  );
}
