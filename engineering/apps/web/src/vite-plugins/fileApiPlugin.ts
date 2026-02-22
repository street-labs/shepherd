// Implements: FR-sc-file-api, FR-sc-file-validation, FR-sc-auto-load-file, FR-diff-baseline-fetch

import type { Plugin } from 'vite';
import type { ServerResponse, IncomingMessage } from 'http';
import fs from 'fs';
import path from 'path';
import { execFileSync } from 'child_process';

const BINARY_CHECK_BYTES = 8192;

function isBinaryBuffer(buffer: Buffer): boolean {
  const limit = Math.min(buffer.length, BINARY_CHECK_BYTES);
  for (let i = 0; i < limit; i++) {
    if (buffer[i] === 0x00) return true;
  }
  return false;
}

const EXTENSION_MAP: Record<string, string> = {
  '.js': 'javascript', '.jsx': 'javascript', '.mjs': 'javascript', '.cjs': 'javascript',
  '.ts': 'typescript', '.tsx': 'typescript', '.mts': 'typescript', '.cts': 'typescript',
  '.py': 'python', '.pyw': 'python',
  '.go': 'go', '.rs': 'rust', '.java': 'java',
  '.c': 'c', '.h': 'c',
  '.cpp': 'cpp', '.cc': 'cpp', '.cxx': 'cpp', '.hpp': 'cpp', '.hxx': 'cpp',
  '.html': 'html', '.htm': 'html',
  '.css': 'css', '.json': 'json',
  '.yaml': 'yaml', '.yml': 'yaml',
  '.md': 'markdown', '.mdx': 'markdown',
};

function detectLanguage(filePath: string): string {
  const ext = path.extname(filePath).toLowerCase();
  return EXTENSION_MAP[ext] ?? 'plaintext';
}

function jsonError(res: ServerResponse, status: number, error: string) {
  res.writeHead(status, { 'Content-Type': 'application/json' });
  res.end(JSON.stringify({ error }));
}

function handleFileRequest(_req: IncomingMessage, res: ServerResponse, url: URL) {
  const filePath = url.searchParams.get('path');

  if (!filePath) {
    return jsonError(res, 400, 'Missing required query parameter: path');
  }

  // Resolve to absolute path
  const resolved = path.resolve(filePath);

  // Check existence
  let stat: fs.Stats;
  try {
    stat = fs.statSync(resolved);
  } catch (err: unknown) {
    if ((err as NodeJS.ErrnoException).code === 'ENOENT') {
      return jsonError(res, 404, `File not found: ${resolved}`);
    }
    if ((err as NodeJS.ErrnoException).code === 'EACCES') {
      return jsonError(res, 403, `Permission denied: ${resolved}`);
    }
    return jsonError(res, 500, `Error reading file: ${resolved}`);
  }

  // Reject directories
  if (stat.isDirectory()) {
    return jsonError(res, 404, `Path is a directory, not a file: ${resolved}`);
  }

  // Read file
  let buffer: Buffer;
  try {
    buffer = fs.readFileSync(resolved);
  } catch (err: unknown) {
    if ((err as NodeJS.ErrnoException).code === 'EACCES') {
      return jsonError(res, 403, `Permission denied: ${resolved}`);
    }
    return jsonError(res, 500, `Error reading file: ${resolved}`);
  }

  // Binary detection
  if (isBinaryBuffer(buffer)) {
    return jsonError(res, 415, `Binary file not supported: ${resolved}`);
  }

  // Success
  const content = buffer.toString('utf-8');
  const lines = content.split('\n').length;
  const language = detectLanguage(resolved);
  const fileName = path.basename(resolved);

  res.writeHead(200, {
    'Content-Type': 'text/plain; charset=utf-8',
    'X-File-Name': fileName,
    'X-File-Lines': String(lines),
    'X-File-Language': language,
  });
  res.end(content);
}

function handleHeadRequest(_req: IncomingMessage, res: ServerResponse, url: URL) {
  const filePath = url.searchParams.get('path');

  if (!filePath) {
    return jsonError(res, 400, 'Missing required query parameter: path');
  }

  const resolved = path.resolve(filePath);

  // 1. Find the git repository root for this file
  let gitRoot: string;
  try {
    gitRoot = execFileSync('git', ['rev-parse', '--show-toplevel'], {
      cwd: path.dirname(resolved),
      encoding: 'utf-8',
      timeout: 5000,
    }).trim();
  } catch {
    return jsonError(res, 404, `Not a git repository: ${resolved}`);
  }

  // 2. Compute the git-relative path
  const relativePath = path.relative(gitRoot, resolved);

  // 3. Run git show HEAD:<relative-path>
  let headBuffer: Buffer;
  try {
    headBuffer = execFileSync('git', ['show', `HEAD:${relativePath}`], {
      cwd: gitRoot,
      timeout: 5000,
      maxBuffer: 50 * 1024 * 1024,
    });
  } catch (err) {
    const message = (err as Error).message || '';
    if (message.includes('does not exist') || message.includes('fatal: path')) {
      return jsonError(res, 404, `File has no git history: ${resolved}`);
    }
    return jsonError(res, 500, `Failed to read HEAD version: ${message}`);
  }

  // 4. Binary detection on HEAD content
  if (isBinaryBuffer(headBuffer)) {
    return jsonError(res, 415, `Binary file at HEAD not supported: ${resolved}`);
  }

  // 5. Return the content
  const content = headBuffer.toString('utf-8');
  const lines = content.split('\n').length;

  res.writeHead(200, {
    'Content-Type': 'text/plain; charset=utf-8',
    'X-File-Lines': String(lines),
  });
  res.end(content);
}

export function fileApiPlugin(): Plugin {
  return {
    name: 'shepherd-file-api',
    configureServer(server) {
      server.middlewares.use((req, res, next) => {
        if (!req.url?.startsWith('/api/file')) return next();

        const url = new URL(req.url, `http://${req.headers.host}`);

        // Match /api/file/head before /api/file (exact pathname matching)
        if (url.pathname === '/api/file/head') {
          return handleHeadRequest(req, res, url);
        }

        if (url.pathname === '/api/file') {
          return handleFileRequest(req, res, url);
        }

        return next();
      });
    },
  };
}
