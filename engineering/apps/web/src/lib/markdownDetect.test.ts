import { describe, it, expect } from 'vitest';
import { isMarkdownFile } from './markdownDetect';

describe('isMarkdownFile', () => {
  it('returns true for .md', () => {
    expect(isMarkdownFile('README.md')).toBe(true);
  });

  it('returns true for .mdx', () => {
    expect(isMarkdownFile('page.mdx')).toBe(true);
  });

  it('returns true for .markdown', () => {
    expect(isMarkdownFile('doc.markdown')).toBe(true);
  });

  it('returns true for .mdown', () => {
    expect(isMarkdownFile('notes.mdown')).toBe(true);
  });

  it('returns true for .mkdn', () => {
    expect(isMarkdownFile('file.mkdn')).toBe(true);
  });

  it('returns true for .mkd', () => {
    expect(isMarkdownFile('file.mkd')).toBe(true);
  });

  it('is case-insensitive (.MD)', () => {
    expect(isMarkdownFile('README.MD')).toBe(true);
  });

  it('is case-insensitive (.Markdown)', () => {
    expect(isMarkdownFile('doc.Markdown')).toBe(true);
  });

  it('returns false for .ts', () => {
    expect(isMarkdownFile('app.ts')).toBe(false);
  });

  it('returns false for .txt', () => {
    expect(isMarkdownFile('readme.txt')).toBe(false);
  });

  it('returns false for files with no extension', () => {
    expect(isMarkdownFile('Makefile')).toBe(false);
  });

  it('returns false for dotfiles', () => {
    expect(isMarkdownFile('.gitignore')).toBe(false);
  });

  it('uses last extension for multi-dot names', () => {
    expect(isMarkdownFile('file.test.md')).toBe(true);
    expect(isMarkdownFile('file.md.bak')).toBe(false);
  });
});
