import { describe, it, expect } from 'vitest';
import { buildFileTree } from './buildFileTree';
import type { FileInfo, FileTreeNode } from '@/types';

function makeFile(id: string, name: string): FileInfo {
  return { id, name, language: 'typescript', content: '', lines: [] };
}

describe('buildFileTree', () => {
  it('returns empty array for empty fileOrder', () => {
    expect(buildFileTree({}, [], new Set(), {})).toEqual([]);
  });

  it('puts files at root when no server paths exist', () => {
    const files = {
      a: makeFile('a', 'App.tsx'),
      b: makeFile('b', 'index.ts'),
    };
    const result = buildFileTree(files, ['a', 'b'], new Set(), {});
    expect(result).toEqual([
      { type: 'file', fileId: 'a', name: 'App.tsx' },
      { type: 'file', fileId: 'b', name: 'index.ts' },
    ]);
  });

  it('groups files under shared directory when server paths exist', () => {
    const files = {
      a: makeFile('a', 'App.tsx'),
      b: makeFile('b', 'helpers.ts'),
    };
    const serverPaths = {
      a: '/project/src/App.tsx',
      b: '/project/src/utils/helpers.ts',
    };
    const result = buildFileTree(files, ['a', 'b'], new Set(), serverPaths);

    // Common prefix is '/project/src/' so:
    // - App.tsx at root
    // - utils/ directory containing helpers.ts
    expect(result.length).toBe(2);

    const dirNode = result.find((n) => n.type === 'directory');
    const fileNode = result.find((n) => n.type === 'file');
    expect(dirNode).toBeDefined();
    expect(fileNode).toBeDefined();

    expect(dirNode!.type).toBe('directory');
    if (dirNode!.type === 'directory') {
      expect(dirNode!.name).toBe('utils');
      expect(dirNode!.children.length).toBe(1);
      expect(dirNode!.children[0]!.type).toBe('file');
      if (dirNode!.children[0]!.type === 'file') {
        expect(dirNode!.children[0]!.name).toBe('helpers.ts');
      }
    }

    if (fileNode!.type === 'file') {
      expect(fileNode!.name).toBe('App.tsx');
    }
  });

  it('strips common prefix correctly', () => {
    const files = {
      a: makeFile('a', 'foo.ts'),
      b: makeFile('b', 'bar.ts'),
    };
    const serverPaths = {
      a: '/Users/dev/project/src/components/foo.ts',
      b: '/Users/dev/project/src/components/bar.ts',
    };
    const result = buildFileTree(files, ['a', 'b'], new Set(), serverPaths);

    // Common prefix is /Users/dev/project/src/components/
    // Both files are at root
    expect(result.length).toBe(2);
    expect(result.every((n) => n.type === 'file')).toBe(true);
  });

  it('sorts unreviewed files before reviewed within same directory', () => {
    const files = {
      a: makeFile('a', 'alpha.ts'),
      b: makeFile('b', 'beta.ts'),
      c: makeFile('c', 'gamma.ts'),
    };
    const reviewed = new Set(['a']); // alpha is reviewed

    const result = buildFileTree(files, ['a', 'b', 'c'], reviewed, {});
    // Should be: beta, gamma (unreviewed, load order), alpha (reviewed)
    const names = result.map((n) => (n.type === 'file' ? n.name : ''));
    expect(names).toEqual(['beta.ts', 'gamma.ts', 'alpha.ts']);
  });

  it('sorts directories first, then files', () => {
    const files = {
      a: makeFile('a', 'root.ts'),
      b: makeFile('b', 'nested.ts'),
    };
    const serverPaths = {
      a: '/project/src/root.ts',
      b: '/project/src/sub/nested.ts',
    };
    const result = buildFileTree(files, ['a', 'b'], new Set(), serverPaths);

    // sub/ directory should come before root.ts
    expect(result[0]!.type).toBe('directory');
    expect(result[1]!.type).toBe('file');
  });

  it('handles deeply nested paths', () => {
    const files = {
      a: makeFile('a', 'deep.ts'),
    };
    const serverPaths = {
      a: '/project/src/a/b/c/deep.ts',
    };
    // Common prefix for single file is its directory: /project/src/a/b/c/
    const result = buildFileTree(files, ['a'], new Set(), serverPaths);
    expect(result.length).toBe(1);
    expect(result[0]!.type).toBe('file');
    if (result[0]!.type === 'file') {
      expect(result[0]!.name).toBe('deep.ts');
    }
  });

  it('handles mixed server and local files', () => {
    const files = {
      a: makeFile('a', 'server.ts'),
      b: makeFile('b', 'local.ts'),
    };
    const serverPaths = {
      a: '/project/src/lib/server.ts',
    };
    const result = buildFileTree(files, ['a', 'b'], new Set(), serverPaths);

    // 'a' gets a relative path from its own dir: just 'server.ts'
    // 'b' has no server path: bare name 'local.ts'
    // When there's only one server path, common prefix is its directory
    // So 'a' → 'server.ts' at root, 'b' → 'local.ts' at root
    expect(result.length).toBe(2);
    const names = result.map((n) => (n.type === 'file' ? n.name : ''));
    expect(names).toContain('server.ts');
    expect(names).toContain('local.ts');
  });

  it('handles single file with server path at root', () => {
    const files = {
      a: makeFile('a', 'only.ts'),
    };
    const serverPaths = {
      a: '/project/src/only.ts',
    };
    const result = buildFileTree(files, ['a'], new Set(), serverPaths);
    expect(result.length).toBe(1);
    expect(result[0]!.type).toBe('file');
    if (result[0]!.type === 'file') {
      expect(result[0]!.fileId).toBe('a');
      expect(result[0]!.name).toBe('only.ts');
    }
  });

  it('puts pasted "Untitled" files at root', () => {
    const files = {
      a: makeFile('a', 'Untitled'),
      b: makeFile('b', 'real.ts'),
    };
    const serverPaths = {
      b: '/project/src/real.ts',
    };
    const result = buildFileTree(files, ['a', 'b'], new Set(), serverPaths);

    // 'a' (Untitled) has no server path → root
    // 'b' has server path, single so common prefix is dir → 'real.ts' at root
    const fileNames = result.filter((n) => n.type === 'file').map((n) => n.type === 'file' ? n.name : '');
    expect(fileNames).toContain('Untitled');
    expect(fileNames).toContain('real.ts');
  });

  it('preserves load order for files within the same directory', () => {
    const files = {
      a: makeFile('a', 'third.ts'),
      b: makeFile('b', 'first.ts'),
      c: makeFile('c', 'second.ts'),
    };
    // All at root, no server paths — should follow fileOrder
    const result = buildFileTree(files, ['a', 'b', 'c'], new Set(), {});
    const names = result.map((n) => (n.type === 'file' ? n.name : ''));
    expect(names).toEqual(['third.ts', 'first.ts', 'second.ts']);
  });

  it('creates correct directory paths for nested dirs', () => {
    const files = {
      a: makeFile('a', 'a.ts'),
      b: makeFile('b', 'b.ts'),
    };
    const serverPaths = {
      a: '/p/src/components/Button/a.ts',
      b: '/p/src/utils/b.ts',
    };
    const result = buildFileTree(files, ['a', 'b'], new Set(), serverPaths);

    // Common prefix: /p/src/
    // Tree: components/ → Button/ → a.ts, utils/ → b.ts
    expect(result.length).toBe(2);
    expect(result.every((n) => n.type === 'directory')).toBe(true);

    const compDir = result.find((n) => n.type === 'directory' && n.name === 'components') as
      FileTreeNode & { type: 'directory' } | undefined;
    expect(compDir).toBeDefined();
    expect(compDir!.path).toBe('components');
    expect(compDir!.children.length).toBe(1);
    expect(compDir!.children[0]!.type).toBe('directory');

    const buttonDir = compDir!.children[0] as FileTreeNode & { type: 'directory' };
    expect(buttonDir.name).toBe('Button');
    expect(buttonDir.path).toBe('components/Button');
    expect(buttonDir.children.length).toBe(1);
    expect(buttonDir.children[0]!.type).toBe('file');

    const utilsDir = result.find((n) => n.type === 'directory' && n.name === 'utils') as
      FileTreeNode & { type: 'directory' } | undefined;
    expect(utilsDir).toBeDefined();
    expect(utilsDir!.path).toBe('utils');
  });

  it('sorts directories alphabetically', () => {
    const files = {
      a: makeFile('a', 'a.ts'),
      b: makeFile('b', 'b.ts'),
      c: makeFile('c', 'c.ts'),
    };
    const serverPaths = {
      a: '/p/src/zebra/a.ts',
      b: '/p/src/alpha/b.ts',
      c: '/p/src/middle/c.ts',
    };
    const result = buildFileTree(files, ['a', 'b', 'c'], new Set(), serverPaths);

    const dirNames = result
      .filter((n) => n.type === 'directory')
      .map((n) => n.type === 'directory' ? n.name : '');
    expect(dirNames).toEqual(['alpha', 'middle', 'zebra']);
  });
});
