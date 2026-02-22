import { describe, it, expect, beforeEach, vi } from 'vitest';
import { useAppStore } from './appStore';
import type { AppStore } from './appStore';

// Mock crypto.randomUUID for deterministic IDs
let uuidCounter = 0;
vi.stubGlobal('crypto', {
  randomUUID: () => `uuid-${++uuidCounter}`,
});

function loadTestFile(store: AppStore) {
  store.loadFile('line1\nline2\nline3\nline4\nline5', 'test.ts', 'typescript');
}

describe('appStore', () => {
  beforeEach(() => {
    uuidCounter = 0;
    useAppStore.setState(useAppStore.getInitialState());
  });

  // ─── loadFile ─────────────────────────────────────────────

  describe('loadFile', () => {
    it('sets file info with name, language, content, and lines', () => {
      useAppStore.getState().loadFile('a\nb\nc', 'app.ts', 'typescript');
      const file = useAppStore.getState().file;
      expect(file).not.toBeNull();
      expect(file!.name).toBe('app.ts');
      expect(file!.language).toBe('typescript');
      expect(file!.content).toBe('a\nb\nc');
      expect(file!.lines).toEqual(['a', 'b', 'c']);
    });

    it('resets comments and other state', () => {
      const store = useAppStore.getState();
      store.loadFile('line1', 'a.ts', 'typescript');
      store.addComment(1, 1, 'comment');
      store.loadFile('new content', 'b.ts', 'typescript');
      expect(useAppStore.getState().commentOrder.length).toBe(0);
      expect(Object.keys(useAppStore.getState().comments).length).toBe(0);
    });

    it('shows large file warning when lines exceed threshold', () => {
      const largeContent = Array.from({ length: 10_001 }, (_, i) => `line${i}`).join('\n');
      useAppStore.getState().loadFile(largeContent, 'big.ts', 'typescript');
      expect(useAppStore.getState().showLargeFileWarning).toBe(true);
    });

    it('does not show large file warning for small files', () => {
      useAppStore.getState().loadFile('small', 'small.ts', 'typescript');
      expect(useAppStore.getState().showLargeFileWarning).toBe(false);
    });
  });

  // ─── addComment ───────────────────────────────────────────

  describe('addComment', () => {
    it('creates a comment with the correct fields', () => {
      loadTestFile(useAppStore.getState());
      useAppStore.getState().addComment(1, 1, 'Hello');
      const comments = useAppStore.getState().comments;
      expect(Object.keys(comments).length).toBe(1);
      const comment = Object.values(comments)[0]!;
      expect(comment.startLine).toBe(1);
      expect(comment.endLine).toBe(1);
      expect(comment.text).toBe('Hello');
    });

    it('updates commentOrder', () => {
      loadTestFile(useAppStore.getState());
      useAppStore.getState().addComment(1, 1, 'First');
      expect(useAppStore.getState().commentOrder.length).toBe(1);
    });

    it('marks prompt as stale when prompt exists', () => {
      loadTestFile(useAppStore.getState());
      useAppStore.getState().addComment(1, 1, 'a');
      useAppStore.getState().generatePrompt();
      expect(useAppStore.getState().isPromptStale).toBe(false);
      useAppStore.getState().addComment(2, 2, 'b');
      expect(useAppStore.getState().isPromptStale).toBe(true);
    });

    it('closes the editor after adding', () => {
      loadTestFile(useAppStore.getState());
      useAppStore.getState().openEditor({ mode: 'create', anchorLine: 1, endLine: 1 });
      useAppStore.getState().addComment(1, 1, 'test');
      expect(useAppStore.getState().editorState).toBeNull();
    });
  });

  // ─── updateComment ────────────────────────────────────────

  describe('updateComment', () => {
    it('updates the comment text', () => {
      loadTestFile(useAppStore.getState());
      useAppStore.getState().addComment(1, 1, 'original');
      const id = useAppStore.getState().commentOrder[0]!;
      useAppStore.getState().updateComment(id, 'updated');
      expect(useAppStore.getState().comments[id]!.text).toBe('updated');
    });

    it('marks prompt as stale', () => {
      loadTestFile(useAppStore.getState());
      useAppStore.getState().addComment(1, 1, 'a');
      useAppStore.getState().generatePrompt();
      const id = useAppStore.getState().commentOrder[0]!;
      useAppStore.getState().updateComment(id, 'b');
      expect(useAppStore.getState().isPromptStale).toBe(true);
    });
  });

  // ─── deleteComment ────────────────────────────────────────

  describe('deleteComment', () => {
    it('removes the comment from record and order', () => {
      loadTestFile(useAppStore.getState());
      useAppStore.getState().addComment(1, 1, 'to delete');
      const id = useAppStore.getState().commentOrder[0]!;
      useAppStore.getState().deleteComment(id);
      expect(useAppStore.getState().comments[id]).toBeUndefined();
      expect(useAppStore.getState().commentOrder.length).toBe(0);
    });

    it('clears focusedCommentId if deleted comment was focused', () => {
      loadTestFile(useAppStore.getState());
      useAppStore.getState().addComment(1, 1, 'focus me');
      const id = useAppStore.getState().commentOrder[0]!;
      useAppStore.getState().setFocusedComment(id);
      expect(useAppStore.getState().focusedCommentId).toBe(id);
      useAppStore.getState().deleteComment(id);
      expect(useAppStore.getState().focusedCommentId).toBeNull();
    });
  });

  // ─── navigateComment ──────────────────────────────────────

  describe('navigateComment', () => {
    it('navigates to first comment when none focused and direction is next', () => {
      loadTestFile(useAppStore.getState());
      useAppStore.getState().addComment(1, 1, 'a');
      useAppStore.getState().addComment(3, 3, 'b');
      useAppStore.getState().navigateComment('next');
      expect(useAppStore.getState().focusedCommentId).toBe(useAppStore.getState().commentOrder[0]);
    });

    it('navigates to last comment when none focused and direction is prev', () => {
      loadTestFile(useAppStore.getState());
      useAppStore.getState().addComment(1, 1, 'a');
      useAppStore.getState().addComment(3, 3, 'b');
      useAppStore.getState().navigateComment('prev');
      const order = useAppStore.getState().commentOrder;
      expect(useAppStore.getState().focusedCommentId).toBe(order[order.length - 1]);
    });

    it('wraps around from last to first', () => {
      loadTestFile(useAppStore.getState());
      useAppStore.getState().addComment(1, 1, 'a');
      useAppStore.getState().addComment(3, 3, 'b');
      const order = useAppStore.getState().commentOrder;
      useAppStore.getState().setFocusedComment(order[order.length - 1]!);
      useAppStore.getState().navigateComment('next');
      expect(useAppStore.getState().focusedCommentId).toBe(order[0]);
    });

    it('does nothing when no comments exist', () => {
      loadTestFile(useAppStore.getState());
      useAppStore.getState().navigateComment('next');
      expect(useAppStore.getState().focusedCommentId).toBeNull();
    });
  });

  // ─── generatePrompt ───────────────────────────────────────

  describe('generatePrompt', () => {
    it('generates a prompt and sets isPromptStale to false', () => {
      loadTestFile(useAppStore.getState());
      useAppStore.getState().addComment(1, 1, 'review this');
      useAppStore.getState().generatePrompt();
      expect(useAppStore.getState().generatedPrompt).not.toBeNull();
      expect(useAppStore.getState().isPromptStale).toBe(false);
    });

    it('includes comment text in generated prompt', () => {
      loadTestFile(useAppStore.getState());
      useAppStore.getState().addComment(1, 1, 'specific comment text');
      useAppStore.getState().generatePrompt();
      expect(useAppStore.getState().generatedPrompt).toContain('specific comment text');
    });
  });

  // ─── clearSession ─────────────────────────────────────────

  describe('clearSession', () => {
    it('resets to initial state', () => {
      loadTestFile(useAppStore.getState());
      useAppStore.getState().addComment(1, 1, 'test');
      useAppStore.getState().setPreamble('preamble');
      useAppStore.getState().generatePrompt();
      useAppStore.getState().clearSession();
      const state = useAppStore.getState();
      expect(state.file).toBeNull();
      expect(state.commentOrder.length).toBe(0);
      expect(state.preamble).toBe('');
      expect(state.generatedPrompt).toBeNull();
    });
  });

  // ─── setPreamble ──────────────────────────────────────────

  describe('setPreamble', () => {
    it('marks stale when prompt exists', () => {
      loadTestFile(useAppStore.getState());
      useAppStore.getState().addComment(1, 1, 'a');
      useAppStore.getState().generatePrompt();
      expect(useAppStore.getState().isPromptStale).toBe(false);
      useAppStore.getState().setPreamble('new preamble');
      expect(useAppStore.getState().isPromptStale).toBe(true);
    });

    it('does not mark stale when no prompt exists', () => {
      loadTestFile(useAppStore.getState());
      useAppStore.getState().setPreamble('text');
      expect(useAppStore.getState().isPromptStale).toBe(false);
    });
  });

  // ─── Diff: setViewMode ────────────────────────────────────

  describe('setViewMode', () => {
    it('sets the view mode', () => {
      useAppStore.getState().setViewMode('diff');
      expect(useAppStore.getState().viewMode).toBe('diff');
    });
  });

  // ─── Diff: expandSection ──────────────────────────────────

  describe('expandSection', () => {
    it('adds section index to expandedSections', () => {
      useAppStore.getState().expandSection(2);
      expect(useAppStore.getState().expandedSections.has(2)).toBe(true);
    });

    it('preserves previously expanded sections', () => {
      useAppStore.getState().expandSection(1);
      useAppStore.getState().expandSection(3);
      expect(useAppStore.getState().expandedSections.has(1)).toBe(true);
      expect(useAppStore.getState().expandedSections.has(3)).toBe(true);
    });
  });

  // ─── Diff: addDiffComment ─────────────────────────────────

  describe('addDiffComment', () => {
    function setupDiffState() {
      loadTestFile(useAppStore.getState());
      useAppStore.setState({
        diffLines: [
          { index: 0, type: 'context', oldLineNumber: 1, newLineNumber: 1, content: 'ctx' },
          { index: 1, type: 'added', oldLineNumber: null, newLineNumber: 2, content: 'new' },
          { index: 2, type: 'removed', oldLineNumber: 2, newLineNumber: null, content: 'old' },
        ],
      });
    }

    it('creates a diff comment', () => {
      setupDiffState();
      useAppStore.getState().addDiffComment(1, 1, 'diff note');
      expect(useAppStore.getState().diffCommentOrder.length).toBe(1);
      const id = useAppStore.getState().diffCommentOrder[0]!;
      expect(useAppStore.getState().diffComments[id]!.text).toBe('diff note');
    });

    it('does nothing when diffLines is null', () => {
      loadTestFile(useAppStore.getState());
      useAppStore.getState().addDiffComment(0, 0, 'should fail');
      expect(useAppStore.getState().diffCommentOrder.length).toBe(0);
    });
  });

  // ─── Diff: navigateDiffComment ────────────────────────────

  describe('navigateDiffComment', () => {
    it('does nothing when no diff comments exist', () => {
      useAppStore.getState().navigateDiffComment('next');
      expect(useAppStore.getState().focusedDiffCommentId).toBeNull();
    });
  });
});
