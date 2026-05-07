import Foundation
import Markdown
import SwiftUI

/// A rendered block ready for display in a SwiftUI view hierarchy.
enum PreviewBlock {
    /// An ATX heading at the given level (1–6) with its inline content.
    case heading(level: Int, inline: AttributedString)
    /// A block-level paragraph.
    case paragraph(AttributedString)
    /// A fenced code block with an optional language hint and raw source.
    case codeBlock(language: String?, source: String)
    /// A block quote containing nested blocks.
    case blockquote([PreviewBlock])
    /// An unordered (bullet) list.
    case unorderedList([PreviewListItem])
    /// An ordered (numbered) list starting at `start`.
    case orderedList(start: Int, items: [PreviewListItem])
    /// A GFM table.
    case table(PreviewTable)
    /// A thematic break (horizontal rule).
    case thematicBreak
}

/// A single item in a list block.
struct PreviewListItem {
    /// Non-nil when the item is a GFM task-list item; `true` = checked, `false` = unchecked.
    let taskState: Bool?
    /// The child blocks nested inside this list item.
    let children: [PreviewBlock]
}

/// A GFM table ready for grid-based rendering.
struct PreviewTable {
    /// Column alignment directives parallel to the header cells.
    let columnAlignments: [Markdown.Table.ColumnAlignment?]
    /// Header row cells as attributed strings.
    let headerCells: [AttributedString]
    /// Body rows, each row is an array of attributed string cells.
    let bodyRows: [[AttributedString]]
}
