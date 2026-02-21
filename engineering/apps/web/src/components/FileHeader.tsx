// Implements: FR-crp-filename-display

import { useAppStore } from '@/store/appStore';
import { useState } from 'react';

export function FileHeader() {
  const file = useAppStore((s) => s.file);
  const updateFileName = useAppStore((s) => s.updateFileName);
  const [isEditing, setIsEditing] = useState(false);
  const [editValue, setEditValue] = useState('');

  if (!file) return null;

  const isUntitled = file.name === 'Untitled';

  const handleStartEdit = () => {
    if (!isUntitled) return;
    setEditValue(file.name);
    setIsEditing(true);
  };

  const handleSave = () => {
    const trimmed = editValue.trim();
    if (trimmed) {
      updateFileName(trimmed);
    }
    setIsEditing(false);
  };

  const handleKeyDown = (e: React.KeyboardEvent) => {
    if (e.key === 'Enter') handleSave();
    if (e.key === 'Escape') setIsEditing(false);
  };

  return (
    <div className="flex items-center gap-2 px-4 h-10 border-b border-border-default bg-surface-secondary flex-shrink-0">
      {isEditing ? (
        <input
          value={editValue}
          onChange={(e) => setEditValue(e.target.value)}
          onBlur={handleSave}
          onKeyDown={handleKeyDown}
          className="text-sm font-mono px-1 py-0.5 border border-primary-500 rounded outline-none"
          autoFocus
        />
      ) : (
        <span
          className={`text-sm font-mono ${isUntitled ? 'cursor-pointer hover:underline text-text-secondary italic' : 'text-text-primary'}`}
          onClick={handleStartEdit}
          title={isUntitled ? 'Click to rename' : undefined}
        >
          {file.name}
        </span>
      )}
      <span className="text-xs px-1.5 py-0.5 rounded bg-surface-primary border border-border-default text-text-secondary">
        {file.language}
      </span>
    </div>
  );
}
