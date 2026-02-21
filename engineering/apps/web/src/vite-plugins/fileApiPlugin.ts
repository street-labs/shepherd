// Implements: FR-sc-file-api, FR-sc-file-validation, FR-sc-auto-load-file

import type { Plugin } from 'vite';
import fs from 'fs';
import path from 'path';

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

export function fileApiPlugin(): Plugin {
  return {
    name: 'shepherd-file-api',
    configureServer(server) {
      server.middlewares.use((req, res, next) => {
        if (!req.url?.startsWith('/api/file')) return next();

        const url = new URL(req.url, `http://${req.headers.host}`);
        const filePath = url.searchParams.get('path');

        // Set JSON content type for error responses
        const jsonError = (status: number, error: string) => {
          res.writeHead(status, { 'Content-Type': 'application/json' });
          res.end(JSON.stringify({ error }));
        };

        if (!filePath) {
          return jsonError(400, 'Missing required query parameter: path');
        }

        // Resolve to absolute path
        const resolved = path.resolve(filePath);

        // Check existence
        let stat: fs.Stats;
        try {
          stat = fs.statSync(resolved);
        } catch (err: unknown) {
          if ((err as NodeJS.ErrnoException).code === 'ENOENT') {
            return jsonError(404, `File not found: ${resolved}`);
          }
          if ((err as NodeJS.ErrnoException).code === 'EACCES') {
            return jsonError(403, `Permission denied: ${resolved}`);
          }
          return jsonError(500, `Error reading file: ${resolved}`);
        }

        // Reject directories
        if (stat.isDirectory()) {
          return jsonError(404, `Path is a directory, not a file: ${resolved}`);
        }

        // Read file
        let buffer: Buffer;
        try {
          buffer = fs.readFileSync(resolved);
        } catch (err: unknown) {
          if ((err as NodeJS.ErrnoException).code === 'EACCES') {
            return jsonError(403, `Permission denied: ${resolved}`);
          }
          return jsonError(500, `Error reading file: ${resolved}`);
        }

        // Binary detection
        if (isBinaryBuffer(buffer)) {
          return jsonError(415, `Binary file not supported: ${resolved}`);
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
      });
    },
  };
}
