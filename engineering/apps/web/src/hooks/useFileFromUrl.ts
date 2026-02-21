// Implements: FR-sc-auto-load-file, AC-sc-session-clear-on-new-file

import { useEffect, useState } from 'react';
import { useAppStore } from '@/store/appStore';

interface FileFromUrlState {
  loading: boolean;
  error: string | null;
}

/**
 * Reads the `?file=<path>` URL query parameter on mount and fetches
 * the file from the local file-serving API. Loads it into the store,
 * clearing any existing session.
 */
export function useFileFromUrl(): FileFromUrlState {
  const [state, setState] = useState<FileFromUrlState>({ loading: false, error: null });
  const loadFile = useAppStore((s) => s.loadFile);

  useEffect(() => {
    const params = new URLSearchParams(window.location.search);
    const filePath = params.get('file');
    if (!filePath) return;

    setState({ loading: true, error: null });

    fetch(`/api/file?path=${encodeURIComponent(filePath)}`)
      .then(async (res) => {
        if (!res.ok) {
          const body = await res.json().catch(() => ({ error: 'Unknown error' }));
          throw new Error(body.error || `HTTP ${res.status}`);
        }

        const content = await res.text();
        const fileName = res.headers.get('X-File-Name') || filePath.split('/').pop() || 'Untitled';
        const language = res.headers.get('X-File-Language') || 'plaintext';

        loadFile(content, fileName, language);
        setState({ loading: false, error: null });

        // Clean the URL without reloading
        const url = new URL(window.location.href);
        url.searchParams.delete('file');
        window.history.replaceState({}, '', url.pathname);
      })
      .catch((err: Error) => {
        setState({ loading: false, error: err.message });
      });
  }, []); // eslint-disable-line react-hooks/exhaustive-deps

  return state;
}
