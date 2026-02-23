import { describe, it, expect } from 'vitest';
import { buildPrompt, buildMultiFilePrompt, buildDiffPrompt, formatDiffCommentLabel, buildRenderedPrompt, buildRenderedDiffPrompt } from './promptBuilder';
import type { Comment, FileInfo, DiffLine, DiffComment, DiffLineId, CollapsedSection, RenderedComment, RenderedDiffComment, ElementSourceMapping, AstDiffResult, ElementId } from '@/types';

function makeFile(overrides: Partial<FileInfo> = {}): FileInfo {
  return {
    id: 'file-1',
    name: 'app.ts',
    language: 'typescript',
    content: 'line1\nline2\nline3\nline4\nline5',
    lines: ['line1', 'line2', 'line3', 'line4', 'line5'],
    ...overrides,
  };
}

function makeComment(overrides: Partial<Comment> = {}): Comment {
  return {
    id: 'c1',
    fileId: 'file-1',
    startLine: 1,
    endLine: 1,
    text: 'Fix this',
    createdAt: '2026-01-01T00:00:00.000Z',
    ...overrides,
  };
}

function makeDiffLineId(type: 'added' | 'removed' | 'context', oldLine: number | null, newLine: number | null): DiffLineId {
  return { lineType: type, oldLine, newLine };
}

function makeDiffComment(overrides: Partial<DiffComment> = {}): DiffComment {
  return {
    id: 'dc1',
    startLineId: makeDiffLineId('added', null, 5),
    endLineId: makeDiffLineId('added', null, 5),
    startIndex: 4,
    endIndex: 4,
    text: 'Diff comment',
    createdAt: '2026-01-01T00:00:00.000Z',
    ...overrides,
  };
}

function makeDiffLines(): DiffLine[] {
  return [
    { index: 0, type: 'context', oldLineNumber: 1, newLineNumber: 1, content: 'unchanged' },
    { index: 1, type: 'context', oldLineNumber: 2, newLineNumber: 2, content: 'also unchanged' },
    { index: 2, type: 'removed', oldLineNumber: 3, newLineNumber: null, content: 'old line' },
    { index: 3, type: 'added', oldLineNumber: null, newLineNumber: 3, content: 'new line' },
    { index: 4, type: 'added', oldLineNumber: null, newLineNumber: 4, content: 'another new' },
    { index: 5, type: 'context', oldLineNumber: 4, newLineNumber: 5, content: 'trailing' },
    { index: 6, type: 'context', oldLineNumber: 5, newLineNumber: 6, content: 'end' },
  ];
}

// ─── buildPrompt ──────────────────────────────────────────────────

describe('buildPrompt', () => {
  it('includes Instructions section when preamble is non-empty', () => {
    const result = buildPrompt(makeFile(), [makeComment()], 'Be concise');
    expect(result).toContain('## Instructions');
    expect(result).toContain('Be concise');
  });

  it('omits Instructions section when preamble is empty', () => {
    const result = buildPrompt(makeFile(), [makeComment()], '');
    expect(result).not.toContain('## Instructions');
  });

  it('omits Instructions section when preamble is whitespace', () => {
    const result = buildPrompt(makeFile(), [makeComment()], '   \n  ');
    expect(result).not.toContain('## Instructions');
  });

  it('includes File section with name and language', () => {
    const result = buildPrompt(makeFile({ name: 'main.py', language: 'python' }), [makeComment()], '');
    expect(result).toContain('## File: main.py (python)');
  });

  it('includes Review Feedback section', () => {
    const result = buildPrompt(makeFile(), [makeComment()], '');
    expect(result).toContain('## Review Feedback');
  });

  it('includes code snippet for each comment', () => {
    const result = buildPrompt(makeFile(), [makeComment({ startLine: 2, endLine: 2, text: 'Check this' })], '');
    expect(result).toContain('line2');
    expect(result).toContain('Check this');
  });

  it('sorts comments by startLine then createdAt', () => {
    const comments = [
      makeComment({ id: 'c1', startLine: 3, text: 'Third', createdAt: '2026-01-01T00:00:00Z' }),
      makeComment({ id: 'c2', startLine: 1, text: 'First', createdAt: '2026-01-01T00:00:00Z' }),
      makeComment({ id: 'c3', startLine: 1, text: 'Second', createdAt: '2026-01-02T00:00:00Z' }),
    ];
    const result = buildPrompt(makeFile(), comments, '');
    const firstIdx = result.indexOf('First');
    const secondIdx = result.indexOf('Second');
    const thirdIdx = result.indexOf('Third');
    expect(firstIdx).toBeLessThan(secondIdx);
    expect(secondIdx).toBeLessThan(thirdIdx);
  });

  it('handles single-line comments (startLine === endLine)', () => {
    const result = buildPrompt(makeFile(), [makeComment({ startLine: 2, endLine: 2 })], '');
    expect(result).toContain('line2');
    expect(result).not.toContain('line3');
  });

  it('handles multi-line range comments', () => {
    const result = buildPrompt(makeFile(), [makeComment({ startLine: 2, endLine: 4 })], '');
    expect(result).toContain('line2');
    expect(result).toContain('line3');
    expect(result).toContain('line4');
  });

  it('preserves special characters in comment text', () => {
    const result = buildPrompt(makeFile(), [makeComment({ text: 'Use `const` & <T> type' })], '');
    expect(result).toContain('Use `const` & <T> type');
  });

  it('handles "Untitled" file name', () => {
    const result = buildPrompt(makeFile({ name: 'Untitled' }), [makeComment()], '');
    expect(result).toContain('## File: Untitled');
  });
});

// ─── buildDiffPrompt ──────────────────────────────────────────────

describe('buildDiffPrompt', () => {
  const emptyCollapsed: CollapsedSection[] = [];
  const emptyExpanded = new Set<number>();

  it('includes "-- Diff View" in file heading', () => {
    const result = buildDiffPrompt(makeFile(), makeDiffLines(), [makeDiffComment()], '', emptyCollapsed, emptyExpanded);
    expect(result).toContain('-- Diff View');
  });

  it('prefixes added lines with +', () => {
    const comment = makeDiffComment({ startIndex: 3, endIndex: 3 });
    const result = buildDiffPrompt(makeFile(), makeDiffLines(), [comment], '', emptyCollapsed, emptyExpanded);
    expect(result).toContain('+ new line');
  });

  it('prefixes removed lines with -', () => {
    const comment = makeDiffComment({ startIndex: 2, endIndex: 2 });
    const result = buildDiffPrompt(makeFile(), makeDiffLines(), [comment], '', emptyCollapsed, emptyExpanded);
    expect(result).toContain('- old line');
  });

  it('prefixes context lines with space', () => {
    const comment = makeDiffComment({ startIndex: 0, endIndex: 0 });
    const result = buildDiffPrompt(makeFile(), makeDiffLines(), [comment], '', emptyCollapsed, emptyExpanded);
    expect(result).toMatch(/ {2} unchanged/);
  });

  it('includes surrounding context lines around each comment', () => {
    const comment = makeDiffComment({ startIndex: 3, endIndex: 3 });
    const result = buildDiffPrompt(makeFile(), makeDiffLines(), [comment], '', emptyCollapsed, emptyExpanded);
    // Context lines 2 before: index 1 and 2
    expect(result).toContain('also unchanged');
    expect(result).toContain('old line');
    // Context lines 2 after: index 4 and 5
    expect(result).toContain('another new');
    expect(result).toContain('trailing');
  });

  it('sorts comments by startIndex', () => {
    const comments = [
      makeDiffComment({ id: 'dc2', startIndex: 4, endIndex: 4, text: 'Later' }),
      makeDiffComment({ id: 'dc1', startIndex: 1, endIndex: 1, text: 'Earlier' }),
    ];
    const result = buildDiffPrompt(makeFile(), makeDiffLines(), comments, '', emptyCollapsed, emptyExpanded);
    const earlierIdx = result.indexOf('Earlier');
    const laterIdx = result.indexOf('Later');
    expect(earlierIdx).toBeLessThan(laterIdx);
  });

  it('includes Instructions when preamble is non-empty', () => {
    const result = buildDiffPrompt(makeFile(), makeDiffLines(), [makeDiffComment()], 'Review carefully', emptyCollapsed, emptyExpanded);
    expect(result).toContain('## Instructions');
    expect(result).toContain('Review carefully');
  });

  it('omits Instructions when preamble is empty', () => {
    const result = buildDiffPrompt(makeFile(), makeDiffLines(), [makeDiffComment()], '', emptyCollapsed, emptyExpanded);
    expect(result).not.toContain('## Instructions');
  });
});

// ─── formatDiffCommentLabel ───────────────────────────────────────

describe('formatDiffCommentLabel', () => {
  it('labels a single added line as "Line +N"', () => {
    const comment = makeDiffComment({
      startLineId: makeDiffLineId('added', null, 5),
      endLineId: makeDiffLineId('added', null, 5),
      startIndex: 4,
      endIndex: 4,
    });
    expect(formatDiffCommentLabel(comment)).toBe('Line +5');
  });

  it('labels a single removed line as "Line -N"', () => {
    const comment = makeDiffComment({
      startLineId: makeDiffLineId('removed', 3, null),
      endLineId: makeDiffLineId('removed', 3, null),
      startIndex: 2,
      endIndex: 2,
    });
    expect(formatDiffCommentLabel(comment)).toBe('Line -3');
  });

  it('labels a single context line as "Line N"', () => {
    const comment = makeDiffComment({
      startLineId: makeDiffLineId('context', 1, 1),
      endLineId: makeDiffLineId('context', 1, 1),
      startIndex: 0,
      endIndex: 0,
    });
    expect(formatDiffCommentLabel(comment)).toBe('Line 1');
  });

  it('labels a range of lines as "Lines X to Y"', () => {
    const comment = makeDiffComment({
      startLineId: makeDiffLineId('context', 1, 1),
      endLineId: makeDiffLineId('added', null, 4),
      startIndex: 0,
      endIndex: 4,
    });
    expect(formatDiffCommentLabel(comment)).toBe('Lines 1 to +4');
  });
});

// ─── buildRenderedPrompt ─────────────────────────────────────────

describe('buildRenderedPrompt', () => {
  function makeRenderedComment(overrides: Partial<RenderedComment> = {}): RenderedComment {
    return {
      id: 'rc1',
      elementId: 'heading-0' as ElementId,
      elementType: 'heading',
      contentPreview: 'API Reference',
      text: 'Update this heading',
      createdAt: '2026-01-01T00:00:00.000Z',
      ...overrides,
    };
  }

  const sourceMap: ElementSourceMapping[] = [
    { elementId: 'heading-0' as ElementId, startLine: 1, endLine: 1, rawSource: '## API Reference' },
    { elementId: 'paragraph-0' as ElementId, startLine: 3, endLine: 3, rawSource: 'Some text.' },
  ];

  it('includes "-- Rendered View" in heading', () => {
    const result = buildRenderedPrompt(makeFile(), [makeRenderedComment()], '', sourceMap);
    expect(result).toContain('-- Rendered View');
  });

  it('includes element type and line range', () => {
    const result = buildRenderedPrompt(makeFile(), [makeRenderedComment()], '', sourceMap);
    expect(result).toContain('Heading (lines 1-1)');
  });

  it('includes raw markdown source', () => {
    const result = buildRenderedPrompt(makeFile(), [makeRenderedComment()], '', sourceMap);
    expect(result).toContain('## API Reference');
  });

  it('includes comment text', () => {
    const result = buildRenderedPrompt(makeFile(), [makeRenderedComment()], '', sourceMap);
    expect(result).toContain('Update this heading');
  });

  it('includes instructions when preamble is non-empty', () => {
    const result = buildRenderedPrompt(makeFile(), [makeRenderedComment()], 'Be thorough', sourceMap);
    expect(result).toContain('## Instructions');
    expect(result).toContain('Be thorough');
  });

  it('omits instructions when preamble is empty', () => {
    const result = buildRenderedPrompt(makeFile(), [makeRenderedComment()], '', sourceMap);
    expect(result).not.toContain('## Instructions');
  });
});

// ─── buildRenderedDiffPrompt ─────────────────────────────────────

describe('buildRenderedDiffPrompt', () => {
  function makeRenderedDiffComment(overrides: Partial<RenderedDiffComment> = {}): RenderedDiffComment {
    return {
      id: 'rdc1',
      elementId: 'heading-0' as ElementId,
      elementType: 'heading',
      diffStatus: 'modified',
      contentPreview: 'API Reference',
      text: 'Check this change',
      createdAt: '2026-01-01T00:00:00.000Z',
      ...overrides,
    };
  }

  const sourceMap: ElementSourceMapping[] = [
    { elementId: 'heading-0' as ElementId, startLine: 1, endLine: 1, rawSource: '## API Reference' },
  ];

  const diffResult: AstDiffResult = {
    entries: [
      {
        elementId: 'heading-0' as ElementId,
        status: 'modified',
        type: 'heading',
        oldElement: { elementId: 'heading-0' as ElementId, type: 'heading', textContent: 'Old Title', startLine: 1, endLine: 1 },
        newElement: { elementId: 'heading-0' as ElementId, type: 'heading', textContent: 'New Title', startLine: 1, endLine: 1 },
      },
    ],
    exceedsFallbackThreshold: false,
  };

  it('includes "-- Rendered Diff View" in heading', () => {
    const result = buildRenderedDiffPrompt(makeFile(), [makeRenderedDiffComment()], '', diffResult, sourceMap);
    expect(result).toContain('-- Rendered Diff View');
  });

  it('includes "Annotated Elements" section', () => {
    const result = buildRenderedDiffPrompt(makeFile(), [makeRenderedDiffComment()], '', diffResult, sourceMap);
    expect(result).toContain('Annotated Elements');
  });

  it('shows old and new for modified elements', () => {
    const result = buildRenderedDiffPrompt(makeFile(), [makeRenderedDiffComment()], '', diffResult, sourceMap);
    expect(result).toContain('Old:');
    expect(result).toContain('New:');
    expect(result).toContain('Old Title');
    expect(result).toContain('New Title');
  });

  it('includes MODIFIED status label', () => {
    const result = buildRenderedDiffPrompt(makeFile(), [makeRenderedDiffComment()], '', diffResult, sourceMap);
    expect(result).toContain('[MODIFIED]');
  });
});

// ─── buildMultiFilePrompt ───────────────────────────────────────

describe('buildMultiFilePrompt', () => {
  const file1 = makeFile({ id: 'f1', name: 'app.ts', language: 'typescript' });
  const file2 = makeFile({
    id: 'f2',
    name: 'utils.py',
    language: 'python',
    content: 'def foo():\n  pass',
    lines: ['def foo():', '  pass'],
  });

  it('returns null when no comments exist', () => {
    const result = buildMultiFilePrompt(
      { f1: file1, f2: file2 },
      ['f1', 'f2'],
      {},
      '',
    );
    expect(result).toBeNull();
  });

  it('uses single-file format when only one file has comments', () => {
    const comments: Record<string, Comment> = {
      c1: makeComment({ id: 'c1', fileId: 'f1', text: 'Fix this' }),
    };
    const result = buildMultiFilePrompt(
      { f1: file1, f2: file2 },
      ['f1', 'f2'],
      comments,
      '',
    );
    expect(result).not.toBeNull();
    expect(result).toContain('## File: app.ts');
    expect(result).not.toContain('### File:');
  });

  it('uses multi-file format when multiple files have comments', () => {
    const comments: Record<string, Comment> = {
      c1: makeComment({ id: 'c1', fileId: 'f1', text: 'Fix TS' }),
      c2: makeComment({ id: 'c2', fileId: 'f2', startLine: 1, endLine: 1, text: 'Fix Python' }),
    };
    const result = buildMultiFilePrompt(
      { f1: file1, f2: file2 },
      ['f1', 'f2'],
      comments,
      '',
    );
    expect(result).not.toBeNull();
    expect(result).toContain('### File: app.ts (typescript)');
    expect(result).toContain('### File: utils.py (python)');
    expect(result).toContain('Fix TS');
    expect(result).toContain('Fix Python');
  });

  it('omits files with no comments', () => {
    const comments: Record<string, Comment> = {
      c1: makeComment({ id: 'c1', fileId: 'f2', startLine: 1, endLine: 1, text: 'Only Python' }),
    };
    const result = buildMultiFilePrompt(
      { f1: file1, f2: file2 },
      ['f1', 'f2'],
      comments,
      '',
    );
    expect(result).not.toBeNull();
    expect(result).not.toContain('app.ts');
    expect(result).toContain('utils.py');
  });

  it('respects fileOrder for section ordering', () => {
    const comments: Record<string, Comment> = {
      c1: makeComment({ id: 'c1', fileId: 'f1', text: 'TS comment' }),
      c2: makeComment({ id: 'c2', fileId: 'f2', startLine: 1, endLine: 1, text: 'PY comment' }),
    };

    // f2 before f1
    const result = buildMultiFilePrompt(
      { f1: file1, f2: file2 },
      ['f2', 'f1'],
      comments,
      '',
    );
    expect(result).not.toBeNull();
    const pyIdx = result!.indexOf('utils.py');
    const tsIdx = result!.indexOf('app.ts');
    expect(pyIdx).toBeLessThan(tsIdx);
  });

  it('includes preamble as Instructions section', () => {
    const comments: Record<string, Comment> = {
      c1: makeComment({ id: 'c1', fileId: 'f1', text: 'Fix' }),
      c2: makeComment({ id: 'c2', fileId: 'f2', startLine: 1, endLine: 1, text: 'Fix' }),
    };
    const result = buildMultiFilePrompt(
      { f1: file1, f2: file2 },
      ['f1', 'f2'],
      comments,
      'Review carefully',
    );
    expect(result).toContain('## Instructions');
    expect(result).toContain('Review carefully');
  });
});
