// Implements: FR-sc-auto-load-file, AC-sc-session-clear-on-new-file

import { useEffect, useState } from 'react';
import { useAppStore } from '@/store/appStore';
import { isMarkdownFile } from '@/lib/markdownDetect';

interface FileFromUrlState {
  loading: boolean;
  error: string | null;
}

/**
 * Reads all `?file=<path>` URL query parameters on mount and fetches
 * each file from the local file-serving API. The first file is loaded
 * via loadFile (clearing any existing session); subsequent files are
 * added as tabs via addFile. Each file's path is stored in the
 * serverFilePaths map so setActiveFile can restore it on tab switch.
 */
export function useFileFromUrl(): FileFromUrlState {
  const [state, setState] = useState<FileFromUrlState>({ loading: false, error: null });
  const loadFile = useAppStore((s) => s.loadFile);
  const addFile = useAppStore((s) => s.addFile);
  const setServerFilePath = useAppStore((s) => s.setServerFilePath);
  const setFileSource = useAppStore((s) => s.setFileSource);
  const setFilePath = useAppStore((s) => s.setFilePath);
  const setViewMode = useAppStore((s) => s.setViewMode);
  const setSlashCommandMode = useAppStore((s) => s.setSlashCommandMode);
  const setRenderMode = useAppStore((s) => s.setRenderMode);

  useEffect(() => {
    const params = new URLSearchParams(window.location.search);
    const filePaths = params.getAll('file');
    if (filePaths.length === 0) return;

    let cancelled = false;

    setState({ loading: true, error: null });

    (async () => {
      let loadedCount = 0;
      let lastFileName = '';
      let lastFilePath = '';

      // Phase 1: Load all files into tabs without side effects.
      // Avoid calling setViewMode/setRenderMode between addFile calls —
      // they trigger async work (fetchBaseline, parseMarkdownAst) that
      // races with subsequent addFile state updates.
      for (const filePath of filePaths) {
        if (cancelled) return;

        try {
          const res = await fetch(`/api/file?path=${encodeURIComponent(filePath)}`);
          if (!res.ok) {
            const body = await res.json().catch(() => ({ error: 'Unknown error' }));
            throw new Error(body.error || `HTTP ${res.status}`);
          }

          const content = await res.text();
          const fileName = res.headers.get('X-File-Name') || filePath.split('/').pop() || 'Untitled';
          const language = res.headers.get('X-File-Language') || 'plaintext';

          if (cancelled) return;

          if (loadedCount === 0) {
            loadFile(content, fileName, language);
          } else {
            addFile(content, fileName, language);
          }

          // Record the server path for this file so setActiveFile can
          // restore fileSource/filePath/viewMode on tab switch.
          const activeId = useAppStore.getState().activeFileId;
          if (activeId) {
            setServerFilePath(activeId, filePath);
          }

          lastFileName = fileName;
          lastFilePath = filePath;
          loadedCount++;
        } catch (err) {
          console.warn(`Failed to load file from URL: ${filePath}`, err);
        }
      }

      if (cancelled) return;

      if (loadedCount === 0) {
        setState({ loading: false, error: 'Failed to load any files from URL' });
        return;
      }

      // Phase 2: Activate the first file and set session state.
      // After loading, the last file is active. Switch to the first so
      // the reviewer starts at the top of the priority list. setActiveFile
      // restores fileSource/filePath/viewMode/renderMode from serverFilePaths.
      const { fileOrder, setActiveFile } = useAppStore.getState();
      if (fileOrder.length > 1) {
        setActiveFile(fileOrder[0]);
      } else {
        // Single file — setActiveFile won't fire (already active), set manually
        const firstPath = useAppStore.getState().serverFilePaths[fileOrder[0]] || lastFilePath;
        const firstName = useAppStore.getState().file?.name || lastFileName;
        setFileSource('server');
        setFilePath(firstPath);
        setViewMode('diff');
        if (isMarkdownFile(firstName)) {
          setRenderMode('rendered');
        }
      }
      setSlashCommandMode(true);

      setState({ loading: false, error: null });

      // Clean the URL without reloading — removes all 'file' params at once
      const url = new URL(window.location.href);
      url.searchParams.delete('file');
      window.history.replaceState({}, '', url.pathname);
    })();

    return () => {
      cancelled = true;
    };
  }, []); // eslint-disable-line react-hooks/exhaustive-deps

  return state;
}
