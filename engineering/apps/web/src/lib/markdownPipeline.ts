// Implements: FR-mr-render-pipeline, FR-mr-sanitize, NFR-mr-xss-prevent

import { unified } from 'unified';
import remarkParse from 'remark-parse';
import remarkGfm from 'remark-gfm';
import remarkRehype from 'remark-rehype';
import rehypeSanitize, { defaultSchema } from 'rehype-sanitize';
import rehypeStringify from 'rehype-stringify';
import type { Root } from 'mdast';
import type { Root as HastRoot, Element as HastElement } from 'hast';
import type { AstBlockElement, ElementSourceMapping } from '@/types';
import { assignElementIds } from './elementId';

// Custom sanitization schema: extends default to allow safe attributes for rendered view
const customSchema = {
  ...defaultSchema,
  tagNames: [
    ...(defaultSchema.tagNames ?? []),
    'mark',
    'abbr',
    'details',
    'summary',
    'sup',
    'sub',
    'ins',
    'del',
  ],
  attributes: {
    ...defaultSchema.attributes,
    '*': [
      ...(defaultSchema.attributes?.['*'] ?? []),
      'dataElementId',
      'role',
      'ariaLabel',
      'className',
    ],
  },
};

/**
 * Parse markdown source into an mdast AST.
 */
export function parseMarkdownToAst(source: string): Root {
  return unified().use(remarkParse).use(remarkGfm).parse(source) as Root;
}

/**
 * A rehype plugin that injects `data-element-id` attributes onto top-level block elements.
 * Must run after remark-rehype (which preserves position info) and before rehype-sanitize.
 */
function rehypeInjectElementIds(elements: AstBlockElement[]) {
  // Build a map from startLine to elementId
  const lineToElementId = new Map<number, string>();
  for (const el of elements) {
    lineToElementId.set(el.startLine, el.elementId);
  }

  return () => (tree: HastRoot) => {
    for (const node of tree.children) {
      if (node.type === 'element') {
        const el = node as HastElement;
        if (el.position?.start.line) {
          const elementId = lineToElementId.get(el.position.start.line);
          if (elementId) {
            el.properties = el.properties ?? {};
            el.properties['dataElementId'] = elementId;
          }
        }
      }
    }
  };
}

export interface RenderMarkdownResult {
  html: string;
  elements: AstBlockElement[];
  sourceMap: ElementSourceMapping[];
}

/**
 * Full markdown rendering pipeline:
 * remark-parse -> remark-gfm -> remark-rehype -> [inject element IDs] -> rehype-sanitize -> rehype-stringify
 *
 * Returns sanitized HTML with data-element-id attributes, plus the AST element list and source map.
 */
export function renderMarkdown(source: string): RenderMarkdownResult {
  const sourceLines = source.split('\n');
  const mdast = parseMarkdownToAst(source);

  // Assign element IDs on the mdast
  const { elements, sourceMap } = assignElementIds(mdast, sourceLines);

  // Build HTML with element IDs injected after remark-rehype (so positions are preserved)
  // then sanitize (our custom schema allows data-element-id)
  const html = unified()
    .use(remarkParse)
    .use(remarkGfm)
    .use(remarkRehype)
    .use(rehypeInjectElementIds(elements))
    .use(rehypeSanitize, customSchema)
    .use(rehypeStringify)
    .processSync(source)
    .toString();

  return { html, elements, sourceMap };
}
