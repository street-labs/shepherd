// Implements: FR-crp-prompt-preamble, FR-crp-prompt-preamble

import { useAppStore } from '@/store/appStore';
import { useState } from 'react';

export function PreambleInput() {
  const preamble = useAppStore((s) => s.preamble);
  const setPreamble = useAppStore((s) => s.setPreamble);
  const [isExpanded, setIsExpanded] = useState(false);

  return (
    <div className="p-4 border-b border-border-default">
      <button
        onClick={() => setIsExpanded(!isExpanded)}
        className="flex items-center gap-1 text-xs font-medium text-text-secondary hover:text-text-primary w-full"
      >
        <span className={`transition-transform ${isExpanded ? 'rotate-90' : ''}`}>▸</span>
        <span>Overall Comment</span>
        {preamble.trim() && !isExpanded && (
          <span className="text-text-tertiary ml-1 truncate">— {preamble.trim().slice(0, 50)}</span>
        )}
      </button>
      {isExpanded && (
        <textarea
          value={preamble}
          onChange={(e) => setPreamble(e.target.value)}
          placeholder="Add an overall comment for all files in this review..."
          className="w-full mt-2 min-h-[80px] p-2 text-sm border border-border-default rounded resize-y focus:outline-none focus:ring-1 focus:ring-primary-500"
          aria-label="Overall comment"
        />
      )}
    </div>
  );
}
