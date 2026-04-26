
import type { Root, RootContent } from 'mdast';
import type { AstBlockElement, ElementSourceMapping, ElementId } from '@/types';

/**
 * Recursively extract all text content from an mdast node.
 */
// Implements: FR-mdr-element-id
function extractTextContent(node: RootContent | Root): string {
  if ('value' in node && typeof node.value === 'string') {
    return node.value;
  }
  if ('children' in node && Array.isArray(node.children)) {
    return (node.children as RootContent[]).map(extractTextContent).join('');
  }
  return '';
}

// Map of mdast node types to our element type prefixes
const BLOCK_TYPE_MAP: Record<string, string> = {
  heading: 'heading',
  paragraph: 'paragraph',
  list: 'list',
  code: 'code-block',
  table: 'table',
  blockquote: 'blockquote',
  thematicBreak: 'thematic-break',
  image: 'image',
  html: 'html-block',
};

/**
 * Walks the mdast tree and assigns element IDs to block-level nodes.
 * Returns the list of block elements and their source mappings.
 */
export function assignElementIds(
  tree: Root,
  sourceLines: string[],
): { elements: AstBlockElement[]; sourceMap: ElementSourceMapping[] } {
  const elements: AstBlockElement[] = [];
  const sourceMap: ElementSourceMapping[] = [];
  const typeCounts: Record<string, number> = {};

  function processNode(node: RootContent, parentListId?: string, itemIndex?: number): void {
    const typeKey = BLOCK_TYPE_MAP[node.type];

    if (typeKey) {
      const count = typeCounts[typeKey] ?? 0;
      typeCounts[typeKey] = count + 1;

      let elementId: ElementId;
      if (parentListId !== undefined && itemIndex !== undefined) {
        elementId = `${parentListId}-item-${itemIndex}` as ElementId;
      } else {
        elementId = `${typeKey}-${count}` as ElementId;
      }

      const textContent = extractTextContent(node);

      // Extract raw source from position info
      let rawSource = '';
      if (node.position) {
        const startLine = node.position.start.line - 1; // 0-indexed
        const endLine = node.position.end.line - 1;
        rawSource = sourceLines.slice(startLine, endLine + 1).join('\n');
      }

      const startLine = node.position?.start.line ?? 0;
      const endLine = node.position?.end.line ?? 0;

      const element: AstBlockElement = {
        elementId,
        type: node.type,
        textContent,
        startLine,
        endLine,
        depth: node.type === 'heading' ? (node as { depth: number }).depth : undefined,
      };

      elements.push(element);
      sourceMap.push({
        elementId,
        startLine,
        endLine,
        rawSource,
      });

      // For lists, also process list items
      if (node.type === 'list' && 'children' in node) {
        const listNode = node as { children: RootContent[] };
        listNode.children.forEach((child, idx) => {
          if (child.type === 'listItem') {
            processNode(child, elementId, idx);
          }
        });
      }
    } else if (node.type === 'listItem' && parentListId !== undefined && itemIndex !== undefined) {
      // List items are handled when their parent list is processed
      const textContent = extractTextContent(node);
      const elementId = `${parentListId}-item-${itemIndex}` as ElementId;

      let rawSource = '';
      if (node.position) {
        const startLine = node.position.start.line - 1;
        const endLine = node.position.end.line - 1;
        rawSource = sourceLines.slice(startLine, endLine + 1).join('\n');
      }

      const startLine = node.position?.start.line ?? 0;
      const endLine = node.position?.end.line ?? 0;

      elements.push({
        elementId,
        type: 'listItem',
        textContent,
        startLine,
        endLine,
      });

      sourceMap.push({
        elementId,
        startLine,
        endLine,
        rawSource,
      });
    }

    // Process children of blockquotes (they contain other blocks)
    if (node.type === 'blockquote' && 'children' in node) {
      // Block-level children inside blockquotes are nested, don't recurse for separate IDs
    }
  }

  for (const child of tree.children) {
    processNode(child);
  }

  return { elements, sourceMap };
}
