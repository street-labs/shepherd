// Implements: FR-mdr-render-toggle

import type { RenderMode } from '@/types';

interface RenderToggleProps {
  activeMode: RenderMode;
  isVisible: boolean;
  onModeChange: (mode: RenderMode) => void;
}

export function RenderToggle({ activeMode, isVisible, onModeChange }: RenderToggleProps) {
  if (!isVisible) return null;

  const handleKeyDown = (e: React.KeyboardEvent, mode: RenderMode) => {
    if (e.key === 'ArrowLeft' || e.key === 'ArrowRight') {
      e.preventDefault();
      const target: RenderMode = mode === 'raw' ? 'rendered' : 'raw';
      onModeChange(target);
    }
  };

  return (
    <div
      className="flex rounded border border-border-default overflow-hidden"
      role="tablist"
      aria-label="Render mode"
    >
      <button
        role="tab"
        aria-selected={activeMode === 'raw'}
        className={`px-3 py-1 text-xs font-medium transition-colors ${
          activeMode === 'raw'
            ? 'bg-primary-500 text-text-on-primary'
            : 'bg-surface-primary text-text-primary hover:bg-surface-secondary'
        }`}
        onClick={() => onModeChange('raw')}
        onKeyDown={(e) => handleKeyDown(e, 'raw')}
      >
        Raw
      </button>
      <button
        role="tab"
        aria-selected={activeMode === 'rendered'}
        className={`px-3 py-1 text-xs font-medium transition-colors ${
          activeMode === 'rendered'
            ? 'bg-primary-500 text-text-on-primary'
            : 'bg-surface-primary text-text-primary hover:bg-surface-secondary'
        }`}
        onClick={() => onModeChange('rendered')}
        onKeyDown={(e) => handleKeyDown(e, 'rendered')}
      >
        Rendered
      </button>
    </div>
  );
}
