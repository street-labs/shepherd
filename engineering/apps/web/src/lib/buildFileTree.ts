// Implements: FR-crp-multi-file-nav

import type { FileInfo, FileTreeNode } from '@/types';

/**
 * Find the longest common directory prefix among a list of absolute paths.
 * Returns the common prefix ending with '/'. If there's only one path,
 * returns its directory. If no common prefix, returns '/'.
 */
function findCommonPrefix(paths: string[]): string {
  if (paths.length === 0) return '';
  if (paths.length === 1) {
    const lastSlash = paths[0]!.lastIndexOf('/');
    return lastSlash >= 0 ? paths[0]!.slice(0, lastSlash + 1) : '';
  }

  // Split all paths by '/' and find common segments
  const split = paths.map((p) => p.split('/'));
  const minLen = Math.min(...split.map((s) => s.length));
  let commonCount = 0;
  for (let i = 0; i < minLen; i++) {
    const seg = split[0]![i];
    if (split.every((s) => s[i] === seg)) {
      commonCount = i + 1;
    } else {
      break;
    }
  }

  if (commonCount === 0) return '';
  // Join common segments and add trailing slash
  const prefix = split[0]!.slice(0, commonCount).join('/');
  return prefix + '/';
}

/**
 * Build a nested file tree from the app's file list and server file paths.
 *
 * For files with server paths, strips the common directory prefix to produce
 * relative paths and groups them into directory nodes. Files without server
 * paths (uploaded/pasted) appear at the root level.
 *
 * Sorting within each directory: directories first (alphabetical),
 * then files ordered by their position in fileOrder.
 */
export function buildFileTree(
  files: Record<string, FileInfo>,
  fileOrder: string[],
  reviewedFiles: Set<string>,
  serverFilePaths: Record<string, string>,
): FileTreeNode[] {
  if (fileOrder.length === 0) return [];

  // Collect all server paths to find common prefix
  const serverPaths: string[] = [];
  for (const id of fileOrder) {
    const sp = serverFilePaths[id];
    if (sp) serverPaths.push(sp);
  }

  const commonPrefix = findCommonPrefix(serverPaths);

  // Build a map of fileId → relative path segments
  // e.g. '/Users/foo/project/src/utils/helpers.ts' with prefix '/Users/foo/project/'
  // → ['src', 'utils', 'helpers.ts']
  type FileEntry = { fileId: string; segments: string[]; orderIndex: number };
  const entries: FileEntry[] = [];

  for (let i = 0; i < fileOrder.length; i++) {
    const id = fileOrder[i]!;
    const file = files[id];
    if (!file) continue;

    const serverPath = serverFilePaths[id];
    let segments: string[];
    if (serverPath && commonPrefix) {
      const relative = serverPath.startsWith(commonPrefix)
        ? serverPath.slice(commonPrefix.length)
        : serverPath;
      segments = relative.split('/').filter((s) => s.length > 0);
    } else {
      // No server path — use bare filename at root
      segments = [file.name];
    }

    entries.push({ fileId: id, segments, orderIndex: i });
  }

  // Recursively group entries into tree nodes
  function buildLevel(items: FileEntry[], depth: number, pathPrefix: string): FileTreeNode[] {
    // Separate files at this level from those in subdirectories
    const filesAtThisLevel: FileEntry[] = [];
    const byDir = new Map<string, FileEntry[]>();

    for (const item of items) {
      if (item.segments.length === depth + 1) {
        // This is a file at the current level
        filesAtThisLevel.push(item);
      } else {
        // Goes into a subdirectory
        const dirName = item.segments[depth]!;
        let group = byDir.get(dirName);
        if (!group) {
          group = [];
          byDir.set(dirName, group);
        }
        group.push(item);
      }
    }

    const result: FileTreeNode[] = [];

    // Add directory nodes (sorted alphabetically)
    const sortedDirs = [...byDir.keys()].sort((a, b) => a.localeCompare(b));
    for (const dirName of sortedDirs) {
      const dirItems = byDir.get(dirName)!;
      const dirPath = pathPrefix ? `${pathPrefix}/${dirName}` : dirName;
      const children = buildLevel(dirItems, depth + 1, dirPath);
      result.push({ type: 'directory', name: dirName, path: dirPath, children });
    }

    // Add file nodes (unreviewed first by load order, then reviewed by load order)
    const unreviewed = filesAtThisLevel.filter((f) => !reviewedFiles.has(f.fileId));
    const reviewed = filesAtThisLevel.filter((f) => reviewedFiles.has(f.fileId));
    // Both sublists are already in load order (fileOrder index)
    for (const entry of [...unreviewed, ...reviewed]) {
      const fileName = entry.segments[entry.segments.length - 1]!;
      result.push({ type: 'file', fileId: entry.fileId, name: fileName });
    }

    return result;
  }

  return buildLevel(entries, 0, '');
}
