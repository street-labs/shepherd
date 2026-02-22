// Implements: FR-dm-persistence, FR-dm-realtime-tracking, FR-dm-manual-toggle,
// NFR-dm-smooth-transition

import { create } from 'zustand';
import type { ThemePreference, ResolvedTheme } from '@/types';

const STORAGE_KEY = 'shepherd-theme';

interface ThemeState {
  themePreference: ThemePreference;
  resolvedTheme: ResolvedTheme;
  setThemePreference: (pref: ThemePreference) => void;
}

function getSystemTheme(): ResolvedTheme {
  return window.matchMedia('(prefers-color-scheme: dark)').matches ? 'dark' : 'light';
}

function resolveTheme(pref: ThemePreference): ResolvedTheme {
  if (pref === 'light' || pref === 'dark') return pref;
  return getSystemTheme();
}

function readStoredPreference(): ThemePreference {
  try {
    const stored = localStorage.getItem(STORAGE_KEY);
    if (stored === 'light' || stored === 'dark' || stored === 'system') return stored;
  } catch { /* localStorage unavailable */ }
  return 'system';
}

function applyThemeToDOM(resolved: ResolvedTheme, animate: boolean): void {
  const html = document.documentElement;
  if (animate) {
    html.setAttribute('data-theme-transition', '');
  }
  html.setAttribute('data-theme', resolved);
  if (animate) {
    setTimeout(() => html.removeAttribute('data-theme-transition'), 200);
  }
}

export const useThemeStore = create<ThemeState>((set, get) => {
  const initialPref = readStoredPreference();
  const initialResolved = resolveTheme(initialPref);

  // Listen for OS preference changes
  const mediaQuery = window.matchMedia('(prefers-color-scheme: dark)');
  mediaQuery.addEventListener('change', () => {
    const { themePreference } = get();
    if (themePreference === 'system') {
      const newResolved = getSystemTheme();
      applyThemeToDOM(newResolved, true);
      set({ resolvedTheme: newResolved });
    }
  });

  return {
    themePreference: initialPref,
    resolvedTheme: initialResolved,
    setThemePreference: (pref: ThemePreference) => {
      const resolved = resolveTheme(pref);
      try { localStorage.setItem(STORAGE_KEY, pref); } catch { /* ignore */ }
      applyThemeToDOM(resolved, true);
      set({ themePreference: pref, resolvedTheme: resolved });
    },
  };
});
