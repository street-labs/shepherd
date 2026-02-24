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

    it('automatically generates the prompt', () => {
      loadTestFile(useAppStore.getState());
      expect(useAppStore.getState().generatedPrompt).toBeNull();
      useAppStore.getState().addComment(1, 1, 'review this');
      expect(useAppStore.getState().generatedPrompt).not.toBeNull();
      expect(useAppStore.getState().generatedPrompt).toContain('review this');
    });

    it('updates the prompt when a second comment is added', () => {
      loadTestFile(useAppStore.getState());
      useAppStore.getState().addComment(1, 1, 'first comment');
      const promptAfterFirst = useAppStore.getState().generatedPrompt;
      useAppStore.getState().addComment(2, 2, 'second comment');
      const promptAfterSecond = useAppStore.getState().generatedPrompt;
      expect(promptAfterSecond).not.toBe(promptAfterFirst);
      expect(promptAfterSecond).toContain('second comment');
      expect(promptAfterSecond).toContain('first comment');
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

    it('automatically regenerates the prompt with updated text', () => {
      loadTestFile(useAppStore.getState());
      useAppStore.getState().addComment(1, 1, 'original text');
      expect(useAppStore.getState().generatedPrompt).toContain('original text');
      const id = useAppStore.getState().commentOrder[0]!;
      useAppStore.getState().updateComment(id, 'updated text');
      expect(useAppStore.getState().generatedPrompt).toContain('updated text');
      expect(useAppStore.getState().generatedPrompt).not.toContain('original text');
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

    it('clears the prompt when the last comment is deleted', () => {
      loadTestFile(useAppStore.getState());
      useAppStore.getState().addComment(1, 1, 'only comment');
      expect(useAppStore.getState().generatedPrompt).not.toBeNull();
      const id = useAppStore.getState().commentOrder[0]!;
      useAppStore.getState().deleteComment(id);
      expect(useAppStore.getState().generatedPrompt).toBeNull();
    });

    it('updates the prompt when one of multiple comments is deleted', () => {
      loadTestFile(useAppStore.getState());
      useAppStore.getState().addComment(1, 1, 'keep this');
      useAppStore.getState().addComment(2, 2, 'delete this');
      const deleteId = useAppStore.getState().commentOrder[1]!;
      useAppStore.getState().deleteComment(deleteId);
      expect(useAppStore.getState().generatedPrompt).toContain('keep this');
      expect(useAppStore.getState().generatedPrompt).not.toContain('delete this');
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

  // ─── setPreamble ──────────────────────────────────────────

  describe('setPreamble', () => {
    it('regenerates the prompt when comments exist', () => {
      loadTestFile(useAppStore.getState());
      useAppStore.getState().addComment(1, 1, 'a');
      const promptBefore = useAppStore.getState().generatedPrompt;
      useAppStore.getState().setPreamble('new preamble');
      const promptAfter = useAppStore.getState().generatedPrompt;
      expect(promptAfter).not.toBe(promptBefore);
      expect(promptAfter).toContain('new preamble');
    });

    it('does not generate a prompt when no comments exist', () => {
      loadTestFile(useAppStore.getState());
      useAppStore.getState().setPreamble('text');
      expect(useAppStore.getState().generatedPrompt).toBeNull();
    });
  });

  // ─── clearSession ─────────────────────────────────────────

  describe('clearSession', () => {
    it('resets to initial state', () => {
      loadTestFile(useAppStore.getState());
      useAppStore.getState().addComment(1, 1, 'test');
      useAppStore.getState().setPreamble('preamble');
      useAppStore.getState().clearSession();
      const state = useAppStore.getState();
      expect(state.file).toBeNull();
      expect(state.commentOrder.length).toBe(0);
      expect(state.preamble).toBe('');
      expect(state.generatedPrompt).toBeNull();
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

  // ─── Slash command mode ────────────────────────────────────

  describe('isSlashCommandMode', () => {
    it('defaults to false', () => {
      expect(useAppStore.getState().isSlashCommandMode).toBe(false);
    });

    it('can be set to true', () => {
      useAppStore.getState().setSlashCommandMode(true);
      expect(useAppStore.getState().isSlashCommandMode).toBe(true);
    });

    it('resets on clearSession', () => {
      useAppStore.getState().setSlashCommandMode(true);
      useAppStore.getState().clearSession();
      expect(useAppStore.getState().isSlashCommandMode).toBe(false);
    });
  });

  // ─── doneState ──────────────────────────────────────────────

  describe('doneState', () => {
    it('defaults to idle', () => {
      expect(useAppStore.getState().doneState).toBe('idle');
    });

    it('resets to idle on addComment', () => {
      loadTestFile(useAppStore.getState());
      useAppStore.setState({ doneState: 'sent' });
      useAppStore.getState().addComment(1, 1, 'test');
      expect(useAppStore.getState().doneState).toBe('idle');
    });

    it('resets to idle on updateComment', () => {
      loadTestFile(useAppStore.getState());
      useAppStore.getState().addComment(1, 1, 'original');
      useAppStore.setState({ doneState: 'sent' });
      const id = useAppStore.getState().commentOrder[0]!;
      useAppStore.getState().updateComment(id, 'updated');
      expect(useAppStore.getState().doneState).toBe('idle');
    });

    it('resets to idle on deleteComment', () => {
      loadTestFile(useAppStore.getState());
      useAppStore.getState().addComment(1, 1, 'to delete');
      useAppStore.setState({ doneState: 'sent' });
      const id = useAppStore.getState().commentOrder[0]!;
      useAppStore.getState().deleteComment(id);
      expect(useAppStore.getState().doneState).toBe('idle');
    });

    it('resets to idle on setPreamble', () => {
      loadTestFile(useAppStore.getState());
      useAppStore.setState({ doneState: 'sent' });
      useAppStore.getState().setPreamble('new preamble');
      expect(useAppStore.getState().doneState).toBe('idle');
    });

    it('resets to idle on addDiffComment', () => {
      loadTestFile(useAppStore.getState());
      useAppStore.setState({
        doneState: 'sent',
        diffLines: [
          { index: 0, type: 'context', oldLineNumber: 1, newLineNumber: 1, content: 'ctx' },
          { index: 1, type: 'added', oldLineNumber: null, newLineNumber: 2, content: 'new' },
        ],
      });
      useAppStore.getState().addDiffComment(0, 0, 'diff note');
      expect(useAppStore.getState().doneState).toBe('idle');
    });

    it('resets to idle on updateDiffComment', () => {
      loadTestFile(useAppStore.getState());
      useAppStore.setState({
        diffLines: [
          { index: 0, type: 'context', oldLineNumber: 1, newLineNumber: 1, content: 'ctx' },
        ],
      });
      useAppStore.getState().addDiffComment(0, 0, 'original');
      useAppStore.setState({ doneState: 'sent' });
      const id = useAppStore.getState().diffCommentOrder[0]!;
      useAppStore.getState().updateDiffComment(id, 'updated');
      expect(useAppStore.getState().doneState).toBe('idle');
    });

    it('resets to idle on deleteDiffComment', () => {
      loadTestFile(useAppStore.getState());
      useAppStore.setState({
        diffLines: [
          { index: 0, type: 'context', oldLineNumber: 1, newLineNumber: 1, content: 'ctx' },
        ],
      });
      useAppStore.getState().addDiffComment(0, 0, 'to delete');
      useAppStore.setState({ doneState: 'sent' });
      const id = useAppStore.getState().diffCommentOrder[0]!;
      useAppStore.getState().deleteDiffComment(id);
      expect(useAppStore.getState().doneState).toBe('idle');
    });
  });

  // ─── sendPromptToAgent ──────────────────────────────────────

  describe('sendPromptToAgent', () => {
    it('sends empty string when generatedPrompt is null', async () => {
      expect(useAppStore.getState().generatedPrompt).toBeNull();
      globalThis.fetch = vi.fn().mockResolvedValue({ ok: true });
      const closeSpy = vi.fn();
      vi.stubGlobal('close', closeSpy);

      await useAppStore.getState().sendPromptToAgent();

      expect(globalThis.fetch).toHaveBeenCalledWith(
        '/api/prompt-output',
        expect.objectContaining({ body: '' }),
      );
      expect(useAppStore.getState().doneState).toBe('sent');
      vi.restoreAllMocks();
    });

    it('sets doneState to sending then sent on success', async () => {
      loadTestFile(useAppStore.getState());
      useAppStore.getState().addComment(1, 1, 'test');
      expect(useAppStore.getState().generatedPrompt).not.toBeNull();

      const states: string[] = [];
      const unsub = useAppStore.subscribe((s) => {
        if (!states.includes(s.doneState)) states.push(s.doneState);
      });

      globalThis.fetch = vi.fn().mockResolvedValue({ ok: true });
      // Mock window.close
      const closeSpy = vi.fn();
      vi.stubGlobal('close', closeSpy);

      await useAppStore.getState().sendPromptToAgent();

      expect(states).toContain('sending');
      expect(useAppStore.getState().doneState).toBe('sent');

      unsub();
      vi.restoreAllMocks();
    });

    it('reverts doneState to idle on failure', async () => {
      loadTestFile(useAppStore.getState());
      useAppStore.getState().addComment(1, 1, 'test');

      globalThis.fetch = vi.fn().mockResolvedValue({ ok: false, status: 500 });

      await useAppStore.getState().sendPromptToAgent();

      expect(useAppStore.getState().doneState).toBe('idle');
      expect(useAppStore.getState().toast).not.toBeNull();
      expect(useAppStore.getState().toast!.type).toBe('error');

      vi.restoreAllMocks();
    });
  });

  // ─── Rendered mode ─────────────────────────────────────────

  describe('rendered mode', () => {
    it('detects markdown files on loadFile', () => {
      useAppStore.getState().loadFile('# Hello', 'README.md', 'markdown');
      expect(useAppStore.getState().isMarkdownFile).toBe(true);
    });

    it('does not flag non-markdown files', () => {
      loadTestFile(useAppStore.getState());
      expect(useAppStore.getState().isMarkdownFile).toBe(false);
    });

    it('sets renderMode and parses AST on setRenderMode("rendered")', () => {
      useAppStore.getState().loadFile('# Title\n\nParagraph text.', 'doc.md', 'markdown');
      useAppStore.getState().setRenderMode('rendered');
      expect(useAppStore.getState().renderMode).toBe('rendered');
      expect(useAppStore.getState().astElements.length).toBeGreaterThan(0);
      expect(useAppStore.getState().renderedHtml).toContain('<h1');
    });

    it('adds rendered comments and auto-generates prompt', () => {
      useAppStore.getState().loadFile('# Title\n\nText.', 'doc.md', 'markdown');
      useAppStore.getState().setRenderMode('rendered');
      const elements = useAppStore.getState().astElements;
      const heading = elements.find((e) => e.type === 'heading');
      expect(heading).toBeDefined();

      useAppStore.getState().addRenderedComment(
        heading!.elementId,
        'heading',
        'Title',
        'Fix this heading',
      );

      expect(useAppStore.getState().renderedCommentOrder.length).toBe(1);
      expect(useAppStore.getState().generatedPrompt).not.toBeNull();
      expect(useAppStore.getState().generatedPrompt).toContain('Fix this heading');
      expect(useAppStore.getState().generatedPrompt).toContain('Rendered View');
    });

    it('deletes rendered comments and clears prompt when last deleted', () => {
      useAppStore.getState().loadFile('# Title', 'doc.md', 'markdown');
      useAppStore.getState().setRenderMode('rendered');
      const elements = useAppStore.getState().astElements;
      useAppStore.getState().addRenderedComment(
        elements[0]!.elementId,
        'heading',
        'Title',
        'Remove this',
      );

      const id = useAppStore.getState().renderedCommentOrder[0]!;
      useAppStore.getState().deleteRenderedComment(id);
      expect(useAppStore.getState().renderedCommentOrder.length).toBe(0);
      expect(useAppStore.getState().generatedPrompt).toBeNull();
    });

    it('navigates rendered comments', () => {
      useAppStore.getState().loadFile('# A\n\n# B', 'doc.md', 'markdown');
      useAppStore.getState().setRenderMode('rendered');
      const elements = useAppStore.getState().astElements;

      useAppStore.getState().addRenderedComment(elements[0]!.elementId, 'heading', 'A', 'First');
      useAppStore.getState().addRenderedComment(elements[1]!.elementId, 'heading', 'B', 'Second');

      useAppStore.getState().navigateRenderedComment('next');
      expect(useAppStore.getState().focusedRenderedCommentId).not.toBeNull();

      useAppStore.getState().navigateRenderedComment('next');
      const focused = useAppStore.getState().focusedRenderedCommentId;
      expect(focused).toBe(useAppStore.getState().renderedCommentOrder[1]);
    });

    it('resets rendered state on loadFile', () => {
      useAppStore.getState().loadFile('# A', 'doc.md', 'markdown');
      useAppStore.getState().setRenderMode('rendered');
      useAppStore.getState().addRenderedComment('heading-0' as any, 'heading', 'A', 'Test');

      useAppStore.getState().loadFile('new content', 'app.ts', 'typescript');
      expect(useAppStore.getState().isMarkdownFile).toBe(false);
      expect(useAppStore.getState().renderMode).toBe('raw');
      expect(useAppStore.getState().renderedCommentOrder.length).toBe(0);
      expect(useAppStore.getState().astElements.length).toBe(0);
    });
  });

  // ─── Rendered diff mode ─────────────────────────────────────

  describe('rendered diff mode', () => {
    it('computes AST diff', () => {
      useAppStore.getState().loadFile('# New Title\n\nNew text.', 'doc.md', 'markdown');
      useAppStore.setState({ baselineContent: '# Old Title\n\nOld text.' });
      useAppStore.getState().computeRenderedDiff();

      const result = useAppStore.getState().astDiffResult;
      expect(result).not.toBeNull();
      expect(result!.entries.length).toBeGreaterThan(0);
    });

    it('adds rendered diff comments', () => {
      useAppStore.getState().loadFile('# Title', 'doc.md', 'markdown');
      useAppStore.setState({ baselineContent: '# Old' });
      useAppStore.getState().computeRenderedDiff();
      useAppStore.getState().setRenderMode('rendered');

      const result = useAppStore.getState().astDiffResult;
      const entry = result!.entries[0]!;

      useAppStore.getState().addRenderedDiffComment(
        entry.elementId,
        entry.type,
        entry.status,
        'Title',
        'Check this diff',
      );

      expect(useAppStore.getState().renderedDiffCommentOrder.length).toBe(1);
      expect(useAppStore.getState().generatedPrompt).toContain('Check this diff');
    });
  });

  // ─── Multi-file: addFile ──────────────────────────────────────

  describe('addFile', () => {
    it('adds a second file and sets it as active', () => {
      loadTestFile(useAppStore.getState());
      const firstFileId = useAppStore.getState().activeFileId;
      expect(firstFileId).not.toBeNull();

      useAppStore.getState().addFile('new content', 'second.ts', 'typescript');
      const state = useAppStore.getState();

      expect(state.fileOrder.length).toBe(2);
      expect(state.activeFileId).not.toBe(firstFileId);
      expect(state.file?.name).toBe('second.ts');
      expect(state.files[state.activeFileId!]?.name).toBe('second.ts');
    });

    it('preserves existing comments when adding a file', () => {
      loadTestFile(useAppStore.getState());
      useAppStore.getState().addComment(1, 1, 'first file comment');
      expect(Object.keys(useAppStore.getState().comments).length).toBe(1);

      useAppStore.getState().addFile('new stuff', 'other.ts', 'typescript');
      // Comment still exists in global comments
      expect(Object.keys(useAppStore.getState().comments).length).toBe(1);
      // But commentOrder for the new active file is empty
      expect(useAppStore.getState().commentOrder.length).toBe(0);
    });

    it('closes the add-file modal', () => {
      loadTestFile(useAppStore.getState());
      useAppStore.getState().openAddFileModal();
      expect(useAppStore.getState().isAddFileModalOpen).toBe(true);

      useAppStore.getState().addFile('content', 'x.ts', 'typescript');
      expect(useAppStore.getState().isAddFileModalOpen).toBe(false);
    });
  });

  // ─── Multi-file: removeFile ───────────────────────────────────

  describe('removeFile', () => {
    it('removes a file and its comments', () => {
      loadTestFile(useAppStore.getState());
      const firstId = useAppStore.getState().activeFileId!;
      useAppStore.getState().addComment(1, 1, 'to be removed');

      useAppStore.getState().addFile('second', 'b.ts', 'typescript');
      const secondId = useAppStore.getState().activeFileId!;

      // Remove first file
      useAppStore.getState().removeFile(firstId);
      expect(useAppStore.getState().fileOrder.length).toBe(1);
      expect(useAppStore.getState().fileOrder[0]).toBe(secondId);
      // Comments from first file should be gone
      expect(Object.keys(useAppStore.getState().comments).length).toBe(0);
    });

    it('switches to adjacent file when active file is removed', () => {
      loadTestFile(useAppStore.getState());
      const firstId = useAppStore.getState().activeFileId!;
      useAppStore.getState().addFile('second', 'b.ts', 'typescript');
      const secondId = useAppStore.getState().activeFileId!;

      // Active is second. Remove second.
      useAppStore.getState().removeFile(secondId);
      expect(useAppStore.getState().activeFileId).toBe(firstId);
      expect(useAppStore.getState().file?.name).toBe('test.ts');
    });

    it('resets to initial state when last file is removed', () => {
      loadTestFile(useAppStore.getState());
      const fileId = useAppStore.getState().activeFileId!;
      useAppStore.getState().removeFile(fileId);
      expect(useAppStore.getState().file).toBeNull();
      expect(useAppStore.getState().fileOrder.length).toBe(0);
      expect(useAppStore.getState().activeFileId).toBeNull();
    });
  });

  // ─── Multi-file: setActiveFile ────────────────────────────────

  describe('setActiveFile', () => {
    it('switches active file and recomputes commentOrder', () => {
      loadTestFile(useAppStore.getState());
      const firstId = useAppStore.getState().activeFileId!;
      useAppStore.getState().addComment(1, 1, 'file1 comment');
      expect(useAppStore.getState().commentOrder.length).toBe(1);

      useAppStore.getState().addFile('second', 'b.ts', 'typescript');
      expect(useAppStore.getState().commentOrder.length).toBe(0);

      // Switch back to first file
      useAppStore.getState().setActiveFile(firstId);
      expect(useAppStore.getState().activeFileId).toBe(firstId);
      expect(useAppStore.getState().file?.name).toBe('test.ts');
      expect(useAppStore.getState().commentOrder.length).toBe(1);
    });

    it('clears editor and selection state', () => {
      loadTestFile(useAppStore.getState());
      const firstId = useAppStore.getState().activeFileId!;
      useAppStore.getState().openEditor({ mode: 'create', anchorLine: 1, endLine: 1 });
      useAppStore.getState().setSelectedRange({ start: 1, end: 3 });

      useAppStore.getState().addFile('second', 'b.ts', 'typescript');
      useAppStore.getState().setActiveFile(firstId);

      expect(useAppStore.getState().editorState).toBeNull();
      expect(useAppStore.getState().selectedRange).toBeNull();
      expect(useAppStore.getState().focusedCommentId).toBeNull();
    });

    it('resets viewMode and renderMode', () => {
      loadTestFile(useAppStore.getState());
      useAppStore.getState().addFile('second', 'b.ts', 'typescript');
      useAppStore.setState({ viewMode: 'diff', renderMode: 'rendered' });

      const firstId = useAppStore.getState().fileOrder[0]!;
      useAppStore.getState().setActiveFile(firstId);
      expect(useAppStore.getState().viewMode).toBe('file');
      expect(useAppStore.getState().renderMode).toBe('raw');
    });

    it('no-ops when setting the already active file', () => {
      loadTestFile(useAppStore.getState());
      const id = useAppStore.getState().activeFileId!;
      useAppStore.getState().openEditor({ mode: 'create', anchorLine: 1, endLine: 1 });

      useAppStore.getState().setActiveFile(id);
      // Editor should NOT be cleared since it's a no-op
      expect(useAppStore.getState().editorState).not.toBeNull();
    });
  });

  // ─── Multi-file: saveScrollPosition ───────────────────────────

  describe('saveScrollPosition', () => {
    it('saves and retrieves scroll positions', () => {
      loadTestFile(useAppStore.getState());
      const fileId = useAppStore.getState().activeFileId!;
      useAppStore.getState().saveScrollPosition(fileId, 250);
      expect(useAppStore.getState().scrollPositions[fileId]).toBe(250);
    });
  });

  // ─── Multi-file: clearSession ─────────────────────────────────

  describe('clearSession with multi-file', () => {
    it('resets all multi-file state', () => {
      loadTestFile(useAppStore.getState());
      useAppStore.getState().addFile('second', 'b.ts', 'typescript');
      useAppStore.getState().clearSession();

      const state = useAppStore.getState();
      expect(state.file).toBeNull();
      expect(state.fileOrder.length).toBe(0);
      expect(state.activeFileId).toBeNull();
      expect(Object.keys(state.files).length).toBe(0);
      expect(Object.keys(state.scrollPositions).length).toBe(0);
    });
  });

  // ─── toggleFileReviewed ──────────────────────────────────────

  describe('toggleFileReviewed', () => {
    it('marks a file as reviewed', () => {
      loadTestFile(useAppStore.getState());
      const fileId = useAppStore.getState().activeFileId!;
      useAppStore.getState().toggleFileReviewed(fileId);
      expect(useAppStore.getState().reviewedFiles.has(fileId)).toBe(true);
    });

    it('unmarks a reviewed file (toggle)', () => {
      loadTestFile(useAppStore.getState());
      const fileId = useAppStore.getState().activeFileId!;
      useAppStore.getState().toggleFileReviewed(fileId);
      expect(useAppStore.getState().reviewedFiles.has(fileId)).toBe(true);
      useAppStore.getState().toggleFileReviewed(fileId);
      expect(useAppStore.getState().reviewedFiles.has(fileId)).toBe(false);
    });

    it('removeFile cleans up reviewedFiles', () => {
      loadTestFile(useAppStore.getState());
      const firstId = useAppStore.getState().activeFileId!;
      useAppStore.getState().toggleFileReviewed(firstId);
      useAppStore.getState().addFile('second', 'b.ts', 'typescript');

      useAppStore.getState().removeFile(firstId);
      expect(useAppStore.getState().reviewedFiles.has(firstId)).toBe(false);
    });

    it('clearSession resets reviewedFiles', () => {
      loadTestFile(useAppStore.getState());
      const fileId = useAppStore.getState().activeFileId!;
      useAppStore.getState().toggleFileReviewed(fileId);
      useAppStore.getState().clearSession();
      expect(useAppStore.getState().reviewedFiles.size).toBe(0);
    });

    it('addFile does not auto-review', () => {
      loadTestFile(useAppStore.getState());
      useAppStore.getState().addFile('second', 'b.ts', 'typescript');
      const newId = useAppStore.getState().activeFileId!;
      expect(useAppStore.getState().reviewedFiles.has(newId)).toBe(false);
    });
  });

  // ─── toggleDirCollapsed ──────────────────────────────────────

  describe('toggleDirCollapsed', () => {
    it('adds a directory path to collapsedDirs', () => {
      useAppStore.getState().toggleDirCollapsed('src/components');
      expect(useAppStore.getState().collapsedDirs.has('src/components')).toBe(true);
    });

    it('removes a directory path when toggled again', () => {
      useAppStore.getState().toggleDirCollapsed('src/components');
      expect(useAppStore.getState().collapsedDirs.has('src/components')).toBe(true);
      useAppStore.getState().toggleDirCollapsed('src/components');
      expect(useAppStore.getState().collapsedDirs.has('src/components')).toBe(false);
    });

    it('handles multiple directories independently', () => {
      useAppStore.getState().toggleDirCollapsed('src');
      useAppStore.getState().toggleDirCollapsed('lib');
      expect(useAppStore.getState().collapsedDirs.has('src')).toBe(true);
      expect(useAppStore.getState().collapsedDirs.has('lib')).toBe(true);
      useAppStore.getState().toggleDirCollapsed('src');
      expect(useAppStore.getState().collapsedDirs.has('src')).toBe(false);
      expect(useAppStore.getState().collapsedDirs.has('lib')).toBe(true);
    });

    it('resets on clearSession', () => {
      useAppStore.getState().toggleDirCollapsed('src');
      useAppStore.getState().toggleDirCollapsed('lib');
      useAppStore.getState().clearSession();
      expect(useAppStore.getState().collapsedDirs.size).toBe(0);
    });
  });

  // ─── Multi-file: prompt generation ────────────────────────────

  describe('multi-file prompt generation', () => {
    it('generates multi-file prompt when comments span multiple files', () => {
      loadTestFile(useAppStore.getState());
      useAppStore.getState().addComment(1, 1, 'file1 comment');

      useAppStore.getState().addFile('line A\nline B', 'second.ts', 'typescript');
      useAppStore.getState().addComment(1, 1, 'file2 comment');

      const prompt = useAppStore.getState().generatedPrompt;
      expect(prompt).not.toBeNull();
      expect(prompt).toContain('file1 comment');
      expect(prompt).toContain('file2 comment');
      expect(prompt).toContain('test.ts');
      expect(prompt).toContain('second.ts');
    });

    it('generates single-file format when only one file has comments', () => {
      loadTestFile(useAppStore.getState());
      useAppStore.getState().addComment(1, 1, 'only comment');
      useAppStore.getState().addFile('no comments here', 'other.ts', 'typescript');

      const prompt = useAppStore.getState().generatedPrompt;
      expect(prompt).not.toBeNull();
      expect(prompt).toContain('## File: test.ts');
      expect(prompt).not.toContain('### File:');
    });
  });
});
