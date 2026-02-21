// Implements: FR-crp-file-load, FR-crp-line-comment-create, FR-crp-line-comment-edit,
// FR-crp-line-comment-delete, FR-crp-comment-navigation, FR-crp-prompt-generate,
// FR-crp-prompt-copy, FR-crp-clear-session, NFR-crp-no-data-persistence

import { create } from 'zustand';
import type { AppState, Comment, EditorState } from '@/types';
import { buildPrompt } from '@/lib/promptBuilder';
import { copyToClipboard } from '@/lib/clipboard';

const LARGE_FILE_THRESHOLD = 10_000;

const initialState: AppState = {
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
};

function computeCommentOrder(comments: Record<string, Comment>): string[] {
  return Object.values(comments)
    .sort((a, b) => {
      if (a.startLine !== b.startLine) return a.startLine - b.startLine;
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
}

export type AppStore = AppState & AppActions;

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
}));
