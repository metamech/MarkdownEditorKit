import Foundation
import Markdown
import SwiftUI

/// Parses a Markdown source string into an ordered array of ``PreviewBlock`` values.
enum MarkdownDocumentParser {
    /// Parse `source` and return a flat list of top-level ``PreviewBlock`` values.
    static func parse(_ source: String) -> [PreviewBlock] {
        let document = Document(parsing: source)
        return blocks(from: document.children)
    }

    // MARK: - Internal recursion

    static func blocks(from children: some Sequence<Markup>) -> [PreviewBlock] {
        children.compactMap { block(from: $0) }
    }

    private static func block(from markup: Markup) -> PreviewBlock? {
        switch markup {
        case let heading as Heading:
            let inline = buildAttributedString(from: heading.inlineChildren)
            return .heading(level: heading.level, inline: inline)

        case let paragraph as Paragraph:
            let inline = buildAttributedString(from: paragraph.inlineChildren)
            return .paragraph(inline)

        case let code as CodeBlock:
            let language = code.language.flatMap { $0.isEmpty ? nil : $0 }
            let source = code.code
            return .codeBlock(language: language, source: source)

        case let quote as BlockQuote:
            let children = blocks(from: quote.children)
            return .blockquote(children)

        case let list as UnorderedList:
            let items = Array(list.listItems.map { listItem($0) })
            return .unorderedList(items)

        case let list as OrderedList:
            let start = Int(list.startIndex)
            let items = Array(list.listItems.map { listItem($0) })
            return .orderedList(start: start, items: items)

        case let table as Markdown.Table:
            return .table(previewTable(from: table))

        case is ThematicBreak:
            return .thematicBreak

        default:
            return nil
        }
    }

    private static func listItem(_ item: ListItem) -> PreviewListItem {
        let taskState: Bool? =
            switch item.checkbox {
            case .checked: true
            case .unchecked: false
            case nil: nil
            }
        let children = blocks(from: item.children)
        return PreviewListItem(taskState: taskState, children: children)
    }

    private static func previewTable(from table: Markdown.Table) -> PreviewTable {
        let alignments = table.columnAlignments

        let headerCells = Array(
            table.head.cells.map { cell in
                buildAttributedString(from: cell.inlineChildren)
            })

        let bodyRows = Array(
            table.body.rows.map { row in
                Array(
                    row.cells.map { cell in
                        buildAttributedString(from: cell.inlineChildren)
                    })
            })

        return PreviewTable(
            columnAlignments: alignments,
            headerCells: headerCells,
            bodyRows: bodyRows
        )
    }
}
