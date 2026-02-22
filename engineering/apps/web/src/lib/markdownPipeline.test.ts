import { describe, it, expect } from 'vitest';
import { renderMarkdown, parseMarkdownToAst } from './markdownPipeline';

describe('parseMarkdownToAst', () => {
  it('returns an mdast Root node', () => {
    const ast = parseMarkdownToAst('# Hello');
    expect(ast.type).toBe('root');
    expect(ast.children.length).toBeGreaterThan(0);
  });

  it('parses GFM tables', () => {
    const ast = parseMarkdownToAst('| A | B |\n|---|---|\n| 1 | 2 |');
    const table = ast.children.find((c) => c.type === 'table');
    expect(table).toBeDefined();
  });

  it('parses GFM strikethrough', () => {
    const ast = parseMarkdownToAst('~~deleted~~');
    expect(ast.children.length).toBeGreaterThan(0);
  });
});

describe('renderMarkdown', () => {
  it('returns HTML string', () => {
    const { html } = renderMarkdown('# Hello World');
    expect(html).toContain('<h1');
    expect(html).toContain('Hello World');
    expect(html).toContain('</h1>');
  });

  it('returns elements array', () => {
    const { elements } = renderMarkdown('# Title\n\nParagraph text.');
    expect(elements.length).toBeGreaterThanOrEqual(2);
    expect(elements[0]!.elementId).toBe('heading-0');
  });

  it('returns sourceMap', () => {
    const { sourceMap } = renderMarkdown('# Title');
    expect(sourceMap.length).toBeGreaterThan(0);
    expect(sourceMap[0]!.rawSource).toBe('# Title');
  });

  it('renders GFM tables as HTML tables', () => {
    const { html } = renderMarkdown('| A | B |\n|---|---|\n| 1 | 2 |');
    expect(html).toContain('<table');
    expect(html).toContain('<td');
  });

  it('renders fenced code blocks', () => {
    const { html } = renderMarkdown('```js\nconsole.log("hi");\n```');
    expect(html).toContain('<pre');
    expect(html).toContain('<code');
  });

  it('renders blockquotes', () => {
    const { html } = renderMarkdown('> Quote text');
    expect(html).toContain('<blockquote');
  });

  it('renders lists', () => {
    const { html } = renderMarkdown('- Item 1\n- Item 2');
    expect(html).toContain('<ul');
    expect(html).toContain('<li');
  });

  it('renders links', () => {
    const { html } = renderMarkdown('[Click](https://example.com)');
    expect(html).toContain('<a');
    expect(html).toContain('https://example.com');
  });

  it('renders images', () => {
    const { html } = renderMarkdown('![Alt](https://example.com/img.png)');
    expect(html).toContain('<img');
    expect(html).toContain('alt="Alt"');
  });

  it('injects data-element-id attributes', () => {
    const { html } = renderMarkdown('# Title\n\nSome text.');
    expect(html).toContain('data-element-id="heading-0"');
  });

  // ─── XSS prevention tests ───────────────────────────────────

  it('strips script tags', () => {
    const { html } = renderMarkdown('Hello <script>alert("xss")</script> world');
    expect(html).not.toContain('<script');
    // The text content of the script tag may remain as safe text — that's fine.
    // What matters is the <script> element itself is removed.
  });

  it('strips event handler attributes', () => {
    const { html } = renderMarkdown('<div onload="alert(1)">text</div>');
    expect(html).not.toContain('onload');
    expect(html).not.toContain('alert');
  });

  it('strips javascript: URLs from links', () => {
    const { html } = renderMarkdown('[click](javascript:alert(1))');
    expect(html).not.toContain('javascript:');
  });

  it('strips SVG-based XSS payloads', () => {
    const { html } = renderMarkdown('<svg onload="alert(1)"><circle r="10"/></svg>');
    expect(html).not.toContain('<svg');
    expect(html).not.toContain('onload');
  });

  it('strips iframe tags', () => {
    const { html } = renderMarkdown('<iframe src="https://evil.com"></iframe>');
    expect(html).not.toContain('<iframe');
  });

  it('strips img onerror XSS', () => {
    const { html } = renderMarkdown('<img src="x" onerror="alert(1)">');
    expect(html).not.toContain('onerror');
  });

  it('strips data: URLs from images', () => {
    const { html } = renderMarkdown('![x](data:text/html,<script>alert(1)</script>)');
    expect(html).not.toContain('data:text/html');
  });
});
