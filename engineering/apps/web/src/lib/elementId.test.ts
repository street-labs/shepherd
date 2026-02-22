import { describe, it, expect } from 'vitest';
import { unified } from 'unified';
import remarkParse from 'remark-parse';
import remarkGfm from 'remark-gfm';
import type { Root } from 'mdast';
import { assignElementIds } from './elementId';

function parse(source: string): Root {
  return unified().use(remarkParse).use(remarkGfm).parse(source) as Root;
}

describe('assignElementIds', () => {
  it('assigns heading-N IDs to headings', () => {
    const source = '# Title\n\n## Subtitle';
    const tree = parse(source);
    const lines = source.split('\n');
    const { elements } = assignElementIds(tree, lines);

    const headings = elements.filter((e) => e.type === 'heading');
    expect(headings.length).toBe(2);
    expect(headings[0]!.elementId).toBe('heading-0');
    expect(headings[1]!.elementId).toBe('heading-1');
  });

  it('assigns paragraph-N IDs to paragraphs', () => {
    const source = 'First paragraph.\n\nSecond paragraph.';
    const tree = parse(source);
    const lines = source.split('\n');
    const { elements } = assignElementIds(tree, lines);

    const paragraphs = elements.filter((e) => e.type === 'paragraph');
    expect(paragraphs.length).toBe(2);
    expect(paragraphs[0]!.elementId).toBe('paragraph-0');
    expect(paragraphs[1]!.elementId).toBe('paragraph-1');
  });

  it('assigns code-block-N IDs to fenced code blocks', () => {
    const source = '```js\nconsole.log("hi");\n```';
    const tree = parse(source);
    const lines = source.split('\n');
    const { elements } = assignElementIds(tree, lines);

    const codeBlocks = elements.filter((e) => e.type === 'code');
    expect(codeBlocks.length).toBe(1);
    expect(codeBlocks[0]!.elementId).toBe('code-block-0');
  });

  it('assigns list-N IDs to lists and list-N-item-M IDs to items', () => {
    const source = '- Item A\n- Item B\n- Item C';
    const tree = parse(source);
    const lines = source.split('\n');
    const { elements } = assignElementIds(tree, lines);

    const lists = elements.filter((e) => e.type === 'list');
    expect(lists.length).toBe(1);
    expect(lists[0]!.elementId).toBe('list-0');

    const items = elements.filter((e) => e.type === 'listItem');
    expect(items.length).toBe(3);
    expect(items[0]!.elementId).toBe('list-0-item-0');
    expect(items[1]!.elementId).toBe('list-0-item-1');
    expect(items[2]!.elementId).toBe('list-0-item-2');
  });

  it('assigns table-N IDs to tables', () => {
    const source = '| A | B |\n|---|---|\n| 1 | 2 |';
    const tree = parse(source);
    const lines = source.split('\n');
    const { elements } = assignElementIds(tree, lines);

    const tables = elements.filter((e) => e.type === 'table');
    expect(tables.length).toBe(1);
    expect(tables[0]!.elementId).toBe('table-0');
  });

  it('assigns blockquote-N IDs', () => {
    const source = '> This is a quote';
    const tree = parse(source);
    const lines = source.split('\n');
    const { elements } = assignElementIds(tree, lines);

    const quotes = elements.filter((e) => e.type === 'blockquote');
    expect(quotes.length).toBe(1);
    expect(quotes[0]!.elementId).toBe('blockquote-0');
  });

  it('assigns thematic-break-N IDs', () => {
    const source = 'Above\n\n---\n\nBelow';
    const tree = parse(source);
    const lines = source.split('\n');
    const { elements } = assignElementIds(tree, lines);

    const breaks = elements.filter((e) => e.type === 'thematicBreak');
    expect(breaks.length).toBe(1);
    expect(breaks[0]!.elementId).toBe('thematic-break-0');
  });

  it('extracts textContent recursively', () => {
    const source = '# Hello **world**';
    const tree = parse(source);
    const lines = source.split('\n');
    const { elements } = assignElementIds(tree, lines);

    expect(elements[0]!.textContent).toBe('Hello world');
  });

  it('extracts rawSource from source lines', () => {
    const source = '# Title\n\nSome text here.';
    const tree = parse(source);
    const lines = source.split('\n');
    const { sourceMap } = assignElementIds(tree, lines);

    expect(sourceMap[0]!.rawSource).toBe('# Title');
  });

  it('sets startLine and endLine correctly', () => {
    const source = '# Title\n\nParagraph text.';
    const tree = parse(source);
    const lines = source.split('\n');
    const { elements } = assignElementIds(tree, lines);

    expect(elements[0]!.startLine).toBe(1);
    expect(elements[0]!.endLine).toBe(1);
    expect(elements[1]!.startLine).toBe(3);
    expect(elements[1]!.endLine).toBe(3);
  });

  it('sets depth for headings', () => {
    const source = '# H1\n\n### H3';
    const tree = parse(source);
    const lines = source.split('\n');
    const { elements } = assignElementIds(tree, lines);

    expect(elements[0]!.depth).toBe(1);
    expect(elements[1]!.depth).toBe(3);
  });
});
