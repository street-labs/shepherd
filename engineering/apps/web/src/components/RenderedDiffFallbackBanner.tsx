// Implements: FR-mr-rendered-diff-fallback

import { useState } from 'react';

interface RenderedDiffFallbackBannerProps {
  onSwitchToRawDiff: () => void;
}

export function RenderedDiffFallbackBanner({ onSwitchToRawDiff }: RenderedDiffFallbackBannerProps) {
  const [dismissed, setDismissed] = useState(false);

  if (dismissed) return null;

  return (
    <div className="mx-4 my-2 px-4 py-3 rounded border border-amber-300 bg-amber-50 flex items-center justify-between">
      <div className="flex items-center gap-2 text-sm text-amber-800">
        <svg width="16" height="16" viewBox="0 0 16 16" fill="currentColor">
          <path d="M8 1a7 7 0 100 14A7 7 0 008 1zm0 10.5a.75.75 0 110-1.5.75.75 0 010 1.5zM8.75 4.5v4a.75.75 0 01-1.5 0v-4a.75.75 0 011.5 0z" />
        </svg>
        <span>
          Most of this file has changed. The rendered diff may not be useful.{' '}
          <button onClick={onSwitchToRawDiff} className="underline font-medium hover:text-amber-900">
            Switch to Raw Diff
          </button>
        </span>
      </div>
      <button
        onClick={() => setDismissed(true)}
        className="text-amber-600 hover:text-amber-800 p-1"
        aria-label="Dismiss"
      >
        <svg width="12" height="12" viewBox="0 0 12 12" fill="none" stroke="currentColor" strokeWidth="1.5">
          <path d="M2 2l8 8M10 2l-8 8" strokeLinecap="round" />
        </svg>
      </button>
    </div>
  );
}
