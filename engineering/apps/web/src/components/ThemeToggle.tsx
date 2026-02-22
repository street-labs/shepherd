// Implements: FR-dm-manual-toggle, AC-dm-toggle-to-dark, AC-dm-toggle-to-light,
// AC-dm-toggle-to-system, AC-dm-keyboard-toggle

import { useThemeStore } from '@/store/themeStore';
import type { ThemePreference } from '@/types';
import { useRef, useCallback } from 'react';

const options: { value: ThemePreference; label: string; icon: React.ReactNode }[] = [
  {
    value: 'light',
    label: 'Light mode',
    icon: (
      <svg width="14" height="14" viewBox="0 0 16 16" fill="none" stroke="currentColor" strokeWidth="1.5">
        <circle cx="8" cy="8" r="3" />
        <path d="M8 1v2M8 13v2M1 8h2M13 8h2M3.05 3.05l1.41 1.41M11.54 11.54l1.41 1.41M3.05 12.95l1.41-1.41M11.54 4.46l1.41-1.41" strokeLinecap="round" />
      </svg>
    ),
  },
  {
    value: 'system',
    label: 'Match system setting',
    icon: (
      <svg width="14" height="14" viewBox="0 0 16 16" fill="none" stroke="currentColor" strokeWidth="1.5">
        <rect x="2" y="2" width="12" height="9" rx="1" />
        <path d="M5 14h6M8 11v3" strokeLinecap="round" />
      </svg>
    ),
  },
  {
    value: 'dark',
    label: 'Dark mode',
    icon: (
      <svg width="14" height="14" viewBox="0 0 16 16" fill="none" stroke="currentColor" strokeWidth="1.5">
        <path d="M13.5 8.5a5.5 5.5 0 0 1-7-7C3.5 2.5 1.5 5 1.5 8a6 6 0 0 0 6 6c3 0 5.5-2 6-5.5z" strokeLinecap="round" strokeLinejoin="round" />
      </svg>
    ),
  },
];

export function ThemeToggle() {
  const preference = useThemeStore((s) => s.themePreference);
  const setPreference = useThemeStore((s) => s.setThemePreference);
  const buttonsRef = useRef<(HTMLButtonElement | null)[]>([]);

  const currentIndex = options.findIndex((o) => o.value === preference);

  const handleKeyDown = useCallback(
    (e: React.KeyboardEvent) => {
      let newIndex: number | null = null;
      if (e.key === 'ArrowRight') {
        e.preventDefault();
        newIndex = (currentIndex + 1) % options.length;
      } else if (e.key === 'ArrowLeft') {
        e.preventDefault();
        newIndex = (currentIndex - 1 + options.length) % options.length;
      }
      if (newIndex !== null) {
        const opt = options[newIndex]!;
        setPreference(opt.value);
        buttonsRef.current[newIndex]?.focus();
      }
    },
    [currentIndex, setPreference],
  );

  return (
    <div
      className="flex rounded-md border border-border-default overflow-hidden"
      role="radiogroup"
      aria-label="Theme"
      onKeyDown={handleKeyDown}
    >
      {options.map((opt, i) => {
        const isActive = opt.value === preference;
        return (
          <button
            key={opt.value}
            ref={(el) => { buttonsRef.current[i] = el; }}
            role="radio"
            aria-checked={isActive}
            aria-label={opt.label}
            title={opt.label}
            tabIndex={isActive ? 0 : -1}
            onClick={() => setPreference(opt.value)}
            className={`flex items-center justify-center w-9 h-8 transition-colors ${
              isActive
                ? 'bg-primary-500 text-text-on-primary'
                : 'bg-surface-primary text-text-secondary hover:bg-surface-secondary'
            }`}
          >
            {opt.icon}
          </button>
        );
      })}
    </div>
  );
}
