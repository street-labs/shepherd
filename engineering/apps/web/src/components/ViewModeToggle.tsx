// Implements: FR-diff-mode-toggle, FR-diff-mode-availability,
// AC-diff-toggle-to-diff, AC-diff-toggle-to-file, AC-diff-paste-upload-disabled

interface ViewModeToggleProps {
  activeMode: 'file' | 'diff';
  isDiffEnabled: boolean;
  onModeChange: (mode: 'file' | 'diff') => void;
}

export function ViewModeToggle({ activeMode, isDiffEnabled, onModeChange }: ViewModeToggleProps) {
  const handleKeyDown = (e: React.KeyboardEvent, mode: 'file' | 'diff') => {
    if (e.key === 'ArrowLeft' || e.key === 'ArrowRight') {
      e.preventDefault();
      const target = mode === 'file' ? 'diff' : 'file';
      if (target === 'diff' && !isDiffEnabled) return;
      onModeChange(target);
    }
  };

  return (
    <div
      className="flex rounded border border-border-default overflow-hidden"
      role="tablist"
      aria-label="View mode"
    >
      <button
        role="tab"
        aria-selected={activeMode === 'file'}
        className={`px-3 py-1 text-xs font-medium transition-colors ${
          activeMode === 'file'
            ? 'bg-primary-500 text-text-on-primary'
            : 'bg-surface-primary text-text-primary hover:bg-surface-secondary'
        }`}
        onClick={() => onModeChange('file')}
        onKeyDown={(e) => handleKeyDown(e, 'file')}
      >
        File
      </button>
      <button
        role="tab"
        aria-selected={activeMode === 'diff'}
        aria-disabled={!isDiffEnabled}
        className={`px-3 py-1 text-xs font-medium transition-colors ${
          activeMode === 'diff'
            ? 'bg-primary-500 text-text-on-primary'
            : isDiffEnabled
              ? 'bg-surface-primary text-text-primary hover:bg-surface-secondary'
              : 'bg-surface-primary text-text-tertiary opacity-40 cursor-not-allowed'
        }`}
        onClick={() => isDiffEnabled && onModeChange('diff')}
        onKeyDown={(e) => handleKeyDown(e, 'diff')}
        title={!isDiffEnabled ? 'Diff view requires a file loaded via the /shepherd command' : undefined}
      >
        Diff
      </button>
    </div>
  );
}
