import { describe, it, expect } from 'vitest';
import { detectLanguage } from './languageDetect';

describe('detectLanguage', () => {
  it('detects .ts as typescript', () => {
    expect(detectLanguage('app.ts')).toBe('typescript');
  });

  it('detects .tsx as typescript', () => {
    expect(detectLanguage('Component.tsx')).toBe('typescript');
  });

  it('detects .py as python', () => {
    expect(detectLanguage('script.py')).toBe('python');
  });

  it('detects .go as go', () => {
    expect(detectLanguage('main.go')).toBe('go');
  });

  it('detects .rs as rust', () => {
    expect(detectLanguage('lib.rs')).toBe('rust');
  });

  it('detects .md as markdown', () => {
    expect(detectLanguage('README.md')).toBe('markdown');
  });

  it('returns plaintext for unknown extension .xyz', () => {
    expect(detectLanguage('file.xyz')).toBe('plaintext');
  });

  it('returns plaintext for files with no extension', () => {
    expect(detectLanguage('Makefile')).toBe('plaintext');
  });

  it('handles case insensitive extensions (.TS)', () => {
    expect(detectLanguage('file.TS')).toBe('typescript');
  });

  it('uses the last extension for multi-dot filenames (file.test.ts)', () => {
    expect(detectLanguage('file.test.ts')).toBe('typescript');
  });

  it('handles dotfiles like .gitignore (no recognized extension)', () => {
    expect(detectLanguage('.gitignore')).toBe('plaintext');
  });
});
