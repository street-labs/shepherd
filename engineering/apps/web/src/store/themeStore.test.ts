import { describe, it, expect, beforeEach, vi, afterEach } from 'vitest';

// Mock localStorage
const storage: Record<string, string> = {};
const localStorageMock = {
  getItem: vi.fn((key: string) => storage[key] ?? null),
  setItem: vi.fn((key: string, value: string) => { storage[key] = value; }),
  removeItem: vi.fn((key: string) => { delete storage[key]; }),
  clear: vi.fn(() => { for (const key in storage) delete storage[key]; }),
  get length() { return Object.keys(storage).length; },
  key: vi.fn((i: number) => Object.keys(storage)[i] ?? null),
};
vi.stubGlobal('localStorage', localStorageMock);

// Mock matchMedia
let darkModeEnabled = false;
const changeListeners: Array<(e: { matches: boolean }) => void> = [];
const matchMediaMock = vi.fn().mockImplementation((query: string) => ({
  matches: query === '(prefers-color-scheme: dark)' ? darkModeEnabled : false,
  media: query,
  addEventListener: vi.fn((_event: string, cb: (e: { matches: boolean }) => void) => {
    changeListeners.push(cb);
  }),
  removeEventListener: vi.fn(),
  dispatchEvent: vi.fn(),
}));
vi.stubGlobal('matchMedia', matchMediaMock);

// Mock document.documentElement.setAttribute
const setAttributeSpy = vi.spyOn(document.documentElement, 'setAttribute');
const removeAttributeSpy = vi.spyOn(document.documentElement, 'removeAttribute');

describe('themeStore', () => {
  beforeEach(() => {
    // Clear mocks and state
    vi.clearAllMocks();
    localStorageMock.clear();
    darkModeEnabled = false;
    changeListeners.length = 0;
    vi.useFakeTimers();

    // Clear module cache so each test gets a fresh store
    vi.resetModules();
  });

  afterEach(() => {
    vi.useRealTimers();
  });

  async function loadStore() {
    const mod = await import('./themeStore');
    return mod.useThemeStore;
  }

  it('defaults to system preference when no localStorage entry', async () => {
    darkModeEnabled = false;
    const useThemeStore = await loadStore();
    const state = useThemeStore.getState();
    expect(state.themePreference).toBe('system');
    expect(state.resolvedTheme).toBe('light');
  });

  it('defaults to dark when system prefers dark and no localStorage', async () => {
    darkModeEnabled = true;
    const useThemeStore = await loadStore();
    const state = useThemeStore.getState();
    expect(state.themePreference).toBe('system');
    expect(state.resolvedTheme).toBe('dark');
  });

  it('reads stored preference from localStorage', async () => {
    storage['shepherd-theme'] = 'dark';
    const useThemeStore = await loadStore();
    const state = useThemeStore.getState();
    expect(state.themePreference).toBe('dark');
    expect(state.resolvedTheme).toBe('dark');
  });

  it('treats invalid localStorage value as system', async () => {
    storage['shepherd-theme'] = 'invalid-value';
    const useThemeStore = await loadStore();
    const state = useThemeStore.getState();
    expect(state.themePreference).toBe('system');
  });

  it('setPreference updates store state, localStorage, and DOM', async () => {
    const useThemeStore = await loadStore();
    useThemeStore.getState().setThemePreference('dark');

    const state = useThemeStore.getState();
    expect(state.themePreference).toBe('dark');
    expect(state.resolvedTheme).toBe('dark');
    expect(localStorageMock.setItem).toHaveBeenCalledWith('shepherd-theme', 'dark');
    expect(setAttributeSpy).toHaveBeenCalledWith('data-theme', 'dark');
  });

  it('setPreference adds and removes transition attribute', async () => {
    const useThemeStore = await loadStore();
    useThemeStore.getState().setThemePreference('dark');

    expect(setAttributeSpy).toHaveBeenCalledWith('data-theme-transition', '');

    vi.advanceTimersByTime(200);

    expect(removeAttributeSpy).toHaveBeenCalledWith('data-theme-transition');
  });

  it('system mode responds to matchMedia change events', async () => {
    const useThemeStore = await loadStore();
    expect(useThemeStore.getState().themePreference).toBe('system');
    expect(useThemeStore.getState().resolvedTheme).toBe('light');

    // Simulate OS dark mode change
    darkModeEnabled = true;
    // The listener was registered with our mock
    for (const listener of changeListeners) {
      listener({ matches: true });
    }

    // In the actual store, the change handler calls getSystemTheme which
    // re-queries matchMedia. Since we changed darkModeEnabled, it should resolve dark.
    expect(useThemeStore.getState().resolvedTheme).toBe('dark');
  });

  it('manual mode ignores matchMedia change events', async () => {
    const useThemeStore = await loadStore();
    useThemeStore.getState().setThemePreference('light');

    // Simulate OS dark mode change
    darkModeEnabled = true;
    for (const listener of changeListeners) {
      listener({ matches: true });
    }

    // Should still be light because manual override
    expect(useThemeStore.getState().resolvedTheme).toBe('light');
  });

  it('switching to system re-enables OS tracking', async () => {
    const useThemeStore = await loadStore();
    useThemeStore.getState().setThemePreference('light');
    expect(useThemeStore.getState().resolvedTheme).toBe('light');

    // Switch back to system while OS is dark
    darkModeEnabled = true;
    useThemeStore.getState().setThemePreference('system');
    expect(useThemeStore.getState().resolvedTheme).toBe('dark');
  });
});
