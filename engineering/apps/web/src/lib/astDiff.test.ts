import { describe, it, expect } from 'vitest';
import { computeAstDiff } from './astDiff';

describe('computeAstDiff', () => {
  it('detects unchanged blocks', () => {
    const source = '# Title\n\nSome text.';
    const result = computeAstDiff(source, source);
    expect(result.entries.every((e) => e.status === 'unchanged')).toBe(true);
    expect(result.exceedsFallbackThreshold).toBe(false);
  });

  it('detects added blocks', () => {
    const oldSource = '# Title';
    const newSource = '# Title\n\nNew paragraph.';
    const result = computeAstDiff(oldSource, newSource);

    const added = result.entries.filter((e) => e.status === 'added');
    expect(added.length).toBe(1);
    expect(added[0]!.type).toBe('paragraph');
  });

  it('detects removed blocks', () => {
    const oldSource = '# Title\n\nOld paragraph.';
    const newSource = '# Title';
    const result = computeAstDiff(oldSource, newSource);

    const removed = result.entries.filter((e) => e.status === 'removed');
    expect(removed.length).toBe(1);
    expect(removed[0]!.type).toBe('paragraph');
  });

  it('detects modified blocks with word-level diff', () => {
    const oldSource = '# Title\n\nThis is old text content.';
    const newSource = '# Title\n\nThis is new text content.';
    const result = computeAstDiff(oldSource, newSource);

    const modified = result.entries.filter((e) => e.status === 'modified');
    expect(modified.length).toBe(1);
    expect(modified[0]!.wordDiff).toBeDefined();
    expect(modified[0]!.wordDiff!.length).toBeGreaterThan(0);
  });

  it('returns word diff segments with added/removed flags', () => {
    const oldSource = 'Hello world foo.';
    const newSource = 'Hello world bar.';
    const result = computeAstDiff(oldSource, newSource);

    const modified = result.entries.find((e) => e.status === 'modified');
    expect(modified).toBeDefined();

    const removed = modified!.wordDiff!.filter((s) => s.removed);
    const added = modified!.wordDiff!.filter((s) => s.added);
    expect(removed.length).toBeGreaterThan(0);
    expect(added.length).toBeGreaterThan(0);
  });

  it('sets exceedsFallbackThreshold when >80% blocks changed', () => {
    const oldSource = '# A\n\nPara 1.\n\nPara 2.\n\nPara 3.\n\nPara 4.\n\nPara 5.';
    const newSource = '# Z\n\nNew 1.\n\nNew 2.\n\nNew 3.\n\nNew 4.\n\nNew 5.';
    const result = computeAstDiff(oldSource, newSource);
    // All blocks have changed — should exceed threshold
    expect(result.exceedsFallbackThreshold).toBe(true);
  });

  it('does not exceed fallback threshold when most blocks unchanged', () => {
    const oldSource = '# Title\n\nPara 1.\n\nPara 2.\n\nPara 3.\n\nPara 4.\n\nPara 5.';
    const newSource = '# Title\n\nPara 1.\n\nPara 2.\n\nPara 3.\n\nPara 4.\n\nModified 5.';
    const result = computeAstDiff(oldSource, newSource);
    expect(result.exceedsFallbackThreshold).toBe(false);
  });

  it('handles empty old source (all blocks are added)', () => {
    const result = computeAstDiff('', '# New\n\nText.');
    const added = result.entries.filter((e) => e.status === 'added');
    expect(added.length).toBeGreaterThan(0);
  });

  it('handles empty new source (all blocks are removed)', () => {
    const result = computeAstDiff('# Old\n\nText.', '');
    const removed = result.entries.filter((e) => e.status === 'removed');
    expect(removed.length).toBeGreaterThan(0);
  });

  it('handles both sources empty', () => {
    const result = computeAstDiff('', '');
    expect(result.entries.length).toBe(0);
    expect(result.exceedsFallbackThreshold).toBe(false);
  });

  it('preserves element types in entries', () => {
    const source = '# Title\n\n```js\ncode\n```\n\n- item';
    const result = computeAstDiff(source, source);
    const types = result.entries.map((e) => e.type);
    expect(types).toContain('heading');
    expect(types).toContain('code');
    expect(types).toContain('list');
  });
});
