// Implements: FR-crp-file-load, FR-crp-line-comment-create, FR-crp-line-comment-edit,
// FR-crp-line-comment-delete, FR-crp-comment-navigation, FR-crp-prompt-generate,
// FR-crp-prompt-copy, FR-crp-clear-session, NFR-crp-no-data-persistence,
// FR-diff-mode-toggle, FR-diff-baseline-fetch, FR-diff-compute, FR-diff-expand,
// FR-diff-comment-create, FR-diff-refresh

import { create } from 'zustand';
import type {
  AppState,
  Comment,
  EditorState,
  DiffComment,
  DiffEditorState,
  DiffState,
  FileSource,
} from '@/types';
import { buildPrompt, buildDiffPrompt } from '@/lib/promptBuilder';
import { copyToClipboard } from '@/lib/clipboard';
import { computeFileDiff } from '@/lib/diffCompute';

const LARGE_FILE_THRESHOLD = 10_000;

const initialDiffState: DiffState = {
  viewMode: 'file',
  fileSource: null,
  filePath: null,
  baselineContent: null,
  diffLines: null,
  collapsedSections: null,
  expandedSections: new Set<number>(),
  isBaselineLoading: false,
  baselineError: null,
  isDiffEmpty: false,
  diffComments: {},
  diffCommentOrder: [],
  focusedDiffCommentId: null,
  diffSelectedRange: null,
  diffEditorState: null,
};

const initialState: AppState & DiffState = {
  file: null,
  comments: {},
  commentOrder: [],
  preamble: '',
  generatedPrompt: null,
  isPromptStale: false,
  focusedCommentId: null,
  selectedRange: null,
  editorState: null,
  largeFileWarningDismissed: false,
  showLargeFileWarning: false,
  ...initialDiffState,
};

function computeCommentOrder(comments: Record<string, Comment>): string[] {
  return Object.values(comments)
    .sort((a, b) => {
      if (a.startLine !== b.startLine) return a.startLine - b.startLine;
      return a.createdAt.localeCompare(b.createdAt);
    })
    .map((c) => c.id);
}

function computeDiffCommentOrder(comments: Record<string, DiffComment>): string[] {
  return Object.values(comments)
    .sort((a, b) => {
      if (a.startIndex !== b.startIndex) return a.startIndex - b.startIndex;
      return a.createdAt.localeCompare(b.createdAt);
    })
    .map((c) => c.id);
}

interface AppActions {
  // File actions
  loadFile: (content: string, fileName: string, language: string) => void;
  updateFileName: (name: string) => void;

  // Comment actions
  addComment: (startLine: number, endLine: number, text: string) => void;
  updateComment: (commentId: string, text: string) => void;
  deleteComment: (commentId: string) => void;

  // Editor actions
  openEditor: (state: EditorState) => void;
  closeEditor: () => void;

  // Navigation
  navigateComment: (direction: 'next' | 'prev') => void;
  setFocusedComment: (commentId: string | null) => void;

  // Line selection
  setSelectedRange: (range: { start: number; end: number } | null) => void;

  // Preamble
  setPreamble: (text: string) => void;

  // Prompt
  generatePrompt: () => void;
  copyPrompt: () => Promise<boolean>;

  // Session
  clearSession: () => void;

  // Large file warning
  dismissLargeFileWarning: () => void;

  // Toast
  toast: { message: string; type: 'success' | 'error' } | null;
  showToast: (message: string, type: 'success' | 'error') => void;
  dismissToast: () => void;

  // Diff: View mode
  setViewMode: (mode: 'file' | 'diff') => void;
  setFileSource: (source: FileSource) => void;
  setFilePath: (filePath: string) => void;

  // Diff: Baseline
  fetchBaseline: () => Promise<void>;

  // Diff: Computation
  computeDiff: () => void;

  // Diff: Expand/collapse
  expandSection: (sectionIndex: number) => void;

  // Diff: Comments
  addDiffComment: (startIndex: number, endIndex: number, text: string) => void;
  updateDiffComment: (commentId: string, text: string) => void;
  deleteDiffComment: (commentId: string) => void;
  clearDiffComments: () => void;

  // Diff: Navigation
  navigateDiffComment: (direction: 'next' | 'prev') => void;
  setFocusedDiffComment: (commentId: string | null) => void;

  // Diff: Selection
  setDiffSelectedRange: (range: { startIndex: number; endIndex: number } | null) => void;

  // Diff: Editor
  openDiffEditor: (state: DiffEditorState) => void;
  closeDiffEditor: () => void;

  // Diff: Prompt
  generateDiffPrompt: () => void;

  // Diff: Refresh
  refreshDiff: () => Promise<void>;
}

export type AppStore = AppState & DiffState & AppActions;

export const useAppStore = create<AppStore>((set, get) => ({
  ...initialState,
  toast: null,

  loadFile: (content, fileName, language) => {
    const lines = content.split('\n');
    set({
      ...initialState,
      file: { name: fileName, language, content, lines },
      showLargeFileWarning: lines.length > LARGE_FILE_THRESHOLD,
    });
  },

  updateFileName: (name) => {
    const { file } = get();
    if (!file) return;
    set({ file: { ...file, name } });
  },

  addComment: (startLine, endLine, text) => {
    const comment: Comment = {
      id: crypto.randomUUID(),
      startLine,
      endLine,
      text,
      createdAt: new Date().toISOString(),
    };
    const comments = { ...get().comments, [comment.id]: comment };
    set({
      comments,
      commentOrder: computeCommentOrder(comments),
      isPromptStale: get().generatedPrompt !== null,
      editorState: null,
      selectedRange: null,
    });
  },

  updateComment: (commentId, text) => {
    const existing = get().comments[commentId];
    if (!existing) return;
    const comments = {
      ...get().comments,
      [commentId]: { ...existing, text },
    };
    set({
      comments,
      isPromptStale: get().generatedPrompt !== null,
      editorState: null,
    });
  },

  deleteComment: (commentId) => {
    const { [commentId]: _, ...rest } = get().comments;
    const focusedCommentId =
      get().focusedCommentId === commentId ? null : get().focusedCommentId;
    set({
      comments: rest,
      commentOrder: computeCommentOrder(rest),
      isPromptStale: get().generatedPrompt !== null,
      focusedCommentId,
    });
  },

  openEditor: (editorState) => {
    set({ editorState, selectedRange: null });
  },

  closeEditor: () => {
    set({ editorState: null, selectedRange: null });
  },

  navigateComment: (direction) => {
    const { commentOrder, focusedCommentId } = get();
    if (commentOrder.length === 0) return;

    let index: number;
    if (focusedCommentId === null) {
      index = direction === 'next' ? 0 : commentOrder.length - 1;
    } else {
      const current = commentOrder.indexOf(focusedCommentId);
      if (direction === 'next') {
        index = (current + 1) % commentOrder.length;
      } else {
        index = (current - 1 + commentOrder.length) % commentOrder.length;
      }
    }

    set({ focusedCommentId: commentOrder[index] ?? null });
  },

  setFocusedComment: (commentId) => {
    set({ focusedCommentId: commentId });
  },

  setSelectedRange: (range) => {
    set({ selectedRange: range });
  },

  setPreamble: (text) => {
    set({
      preamble: text,
      isPromptStale: get().generatedPrompt !== null,
    });
  },

  generatePrompt: () => {
    const { file, comments, commentOrder, preamble } = get();
    if (!file) return;
    const orderedComments = commentOrder
      .map((id) => comments[id])
      .filter((c): c is Comment => c !== undefined);
    const prompt = buildPrompt(file, orderedComments, preamble);
    set({ generatedPrompt: prompt, isPromptStale: false });
  },

  copyPrompt: async () => {
    const { generatedPrompt } = get();
    if (!generatedPrompt) return false;
    const success = await copyToClipboard(generatedPrompt);
    if (success) {
      get().showToast('Copied to clipboard', 'success');
    } else {
      get().showToast('Failed to copy. Try selecting the text manually.', 'error');
    }
    return success;
  },

  clearSession: () => {
    set({ ...initialState, toast: null });
  },

  dismissLargeFileWarning: () => {
    set({ largeFileWarningDismissed: true });
  },

  showToast: (message, type) => {
    set({ toast: { message, type } });
  },

  dismissToast: () => {
    set({ toast: null });
  },

  // --- Diff actions ---

  setViewMode: (mode) => {
    set({ viewMode: mode });
    if (mode === 'diff' && get().baselineContent === null) {
      void get().fetchBaseline();
    }
  },

  setFileSource: (source) => {
    set({ fileSource: source });
  },

  setFilePath: (filePath) => {
    set({ filePath });
  },

  fetchBaseline: async () => {
    const { filePath } = get();
    if (!filePath) return;

    set({ isBaselineLoading: true, baselineError: null });

    try {
      const res = await fetch(`/api/file/head?path=${encodeURIComponent(filePath)}`);

      if (res.status === 404) {
        // Untracked file — treat as all-new
        set({ baselineContent: '', isBaselineLoading: false });
        get().computeDiff();
        return;
      }

      if (!res.ok) {
        const body = await res.json().catch(() => ({ error: 'Unknown error' }));
        throw new Error(body.error || `HTTP ${res.status}`);
      }

      const content = await res.text();
      set({ baselineContent: content, isBaselineLoading: false });
      get().computeDiff();
    } catch (err) {
      set({
        isBaselineLoading: false,
        baselineError: (err as Error).message || 'Failed to fetch baseline',
      });
    }
  },

  computeDiff: () => {
    const { baselineContent, file } = get();
    if (baselineContent === null || !file) return;

    const result = computeFileDiff(baselineContent, file.content);

    set({
      diffLines: result.diffLines,
      collapsedSections: result.collapsedSections,
      isDiffEmpty: result.isEmpty,
      expandedSections: new Set<number>(),
    });
  },

  expandSection: (sectionIndex) => {
    const { expandedSections } = get();
    const next = new Set(expandedSections);
    next.add(sectionIndex);
    set({ expandedSections: next });
  },

  addDiffComment: (startIndex, endIndex, text) => {
    const { diffLines } = get();
    if (!diffLines) return;

    const startLine = diffLines[startIndex];
    const endLine = diffLines[endIndex];
    if (!startLine || !endLine) return;

    const comment: DiffComment = {
      id: crypto.randomUUID(),
      startLineId: {
        lineType: startLine.type,
        oldLine: startLine.oldLineNumber,
        newLine: startLine.newLineNumber,
      },
      endLineId: {
        lineType: endLine.type,
        oldLine: endLine.oldLineNumber,
        newLine: endLine.newLineNumber,
      },
      startIndex,
      endIndex,
      text,
      createdAt: new Date().toISOString(),
    };

    const diffComments = { ...get().diffComments, [comment.id]: comment };
    set({
      diffComments,
      diffCommentOrder: computeDiffCommentOrder(diffComments),
      isPromptStale: get().generatedPrompt !== null,
      diffEditorState: null,
      diffSelectedRange: null,
    });
  },

  updateDiffComment: (commentId, text) => {
    const existing = get().diffComments[commentId];
    if (!existing) return;
    const diffComments = {
      ...get().diffComments,
      [commentId]: { ...existing, text },
    };
    set({
      diffComments,
      isPromptStale: get().generatedPrompt !== null,
      diffEditorState: null,
    });
  },

  deleteDiffComment: (commentId) => {
    const { [commentId]: _, ...rest } = get().diffComments;
    const focusedDiffCommentId =
      get().focusedDiffCommentId === commentId ? null : get().focusedDiffCommentId;
    set({
      diffComments: rest,
      diffCommentOrder: computeDiffCommentOrder(rest),
      isPromptStale: get().generatedPrompt !== null,
      focusedDiffCommentId,
    });
  },

  clearDiffComments: () => {
    set({
      diffComments: {},
      diffCommentOrder: [],
      focusedDiffCommentId: null,
    });
  },

  navigateDiffComment: (direction) => {
    const { diffCommentOrder, focusedDiffCommentId } = get();
    if (diffCommentOrder.length === 0) return;

    let index: number;
    if (focusedDiffCommentId === null) {
      index = direction === 'next' ? 0 : diffCommentOrder.length - 1;
    } else {
      const current = diffCommentOrder.indexOf(focusedDiffCommentId);
      if (direction === 'next') {
        index = (current + 1) % diffCommentOrder.length;
      } else {
        index = (current - 1 + diffCommentOrder.length) % diffCommentOrder.length;
      }
    }

    set({ focusedDiffCommentId: diffCommentOrder[index] ?? null });
  },

  setFocusedDiffComment: (commentId) => {
    set({ focusedDiffCommentId: commentId });
  },

  setDiffSelectedRange: (range) => {
    set({ diffSelectedRange: range });
  },

  openDiffEditor: (state) => {
    set({ diffEditorState: state, diffSelectedRange: null });
  },

  closeDiffEditor: () => {
    set({ diffEditorState: null, diffSelectedRange: null });
  },

  generateDiffPrompt: () => {
    const { file, diffLines, diffComments, diffCommentOrder, preamble, collapsedSections, expandedSections } = get();
    if (!file || !diffLines) return;

    const orderedComments = diffCommentOrder
      .map((id) => diffComments[id])
      .filter((c): c is DiffComment => c !== undefined);

    const prompt = buildDiffPrompt(
      file,
      diffLines,
      orderedComments,
      preamble,
      collapsedSections ?? [],
      expandedSections,
    );
    set({ generatedPrompt: prompt, isPromptStale: false });
  },

  refreshDiff: async () => {
    const { filePath } = get();
    if (!filePath) return;

    // Re-fetch working copy
    try {
      const res = await fetch(`/api/file?path=${encodeURIComponent(filePath)}`);
      if (res.ok) {
        const content = await res.text();
        const fileName = res.headers.get('X-File-Name') || filePath.split('/').pop() || 'Untitled';
        const language = res.headers.get('X-File-Language') || 'plaintext';
        const lines = content.split('\n');
        set({ file: { name: fileName, language, content, lines } });
      }
    } catch {
      // If working copy re-fetch fails, proceed with existing content
    }

    // Reset baseline so fetchBaseline runs fresh
    set({
      baselineContent: null,
      diffComments: {},
      diffCommentOrder: [],
      focusedDiffCommentId: null,
      diffEditorState: null,
      diffSelectedRange: null,
    });

    await get().fetchBaseline();
  },
}));
