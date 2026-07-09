import Foundation
import Markdown

// Implements: FR-mdr-render-commonmark (GFM extensions)

/// Visitor that processes GitHub Flavored Markdown extensions.
///
/// GFM support in swift-markdown:
/// - Tables: Natively supported via Table markup
/// - Strikethrough: Natively supported via Strikethrough markup
/// - Autolinks: Handled by CommonMark parser
/// - Task lists: Represented as list items with checkbox syntax in text
///
/// This visitor extracts additional metadata for GFM features.
public struct GFMVisitor: MarkupWalker {
    public var tables: [Table] = []
    public var taskListItems: [TaskListItem] = []
    public var strikethroughElements: [Strikethrough] = []

    public init() {}

    public mutating func visitTable(_ table: Table) -> () {
        tables.append(table)
        descendInto(table)
    }

    public mutating func visitStrikethrough(_ strikethrough: Strikethrough) -> () {
        strikethroughElements.append(strikethrough)
        descendInto(strikethrough)
    }

    public mutating func visitListItem(_ listItem: ListItem) -> () {
        // Check if this is a task list item (starts with [ ] or [x])
        if isTaskListItem(listItem) {
            let isChecked = isTaskListItemChecked(listItem)
            let item = TaskListItem(listItem: listItem, isChecked: isChecked)
            taskListItems.append(item)
        }
        descendInto(listItem)
    }

    /// Check if a list item is a task list item.
    private func isTaskListItem(_ listItem: ListItem) -> Bool {
        // Extract text by formatting as plain text
        // format() returns markdown like "- [ ] text", so we need to check for checkbox after the bullet
        let text = listItem.format()
        return text.contains("[ ]") || text.contains("[x]") || text.contains("[X]")
    }

    /// Check if a task list item is checked.
    private func isTaskListItemChecked(_ listItem: ListItem) -> Bool {
        let text = listItem.format()
        return text.contains("[x]") || text.contains("[X]")
    }
}

/// Represents a task list item (checkbox in a list).
public struct TaskListItem: Equatable {
    public let listItem: ListItem
    public let isChecked: Bool

    public init(listItem: ListItem, isChecked: Bool) {
        self.listItem = listItem
        self.isChecked = isChecked
    }

    public static func == (lhs: TaskListItem, rhs: TaskListItem) -> Bool {
        lhs.isChecked == rhs.isChecked
    }
}

/// Helper to extract GFM features from a markdown document.
public struct GFMExtractor {

    /// Extract all GFM features from a document.
    public static func extract(from document: Document) -> GFMFeatures {
        var visitor = GFMVisitor()
        visitor.visit(document)

        return GFMFeatures(
            tables: visitor.tables,
            taskListItems: visitor.taskListItems,
            strikethroughElements: visitor.strikethroughElements
        )
    }
}

/// Container for all GFM features found in a document.
public struct GFMFeatures {
    public let tables: [Table]
    public let taskListItems: [TaskListItem]
    public let strikethroughElements: [Strikethrough]

    public init(
        tables: [Table],
        taskListItems: [TaskListItem],
        strikethroughElements: [Strikethrough]
    ) {
        self.tables = tables
        self.taskListItems = taskListItems
        self.strikethroughElements = strikethroughElements
    }

    public var hasGFMContent: Bool {
        !tables.isEmpty || !taskListItems.isEmpty || !strikethroughElements.isEmpty
    }
}
