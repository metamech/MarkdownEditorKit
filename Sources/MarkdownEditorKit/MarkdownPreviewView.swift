import Markdown
import SwiftUI

/// Renders a markdown string with full block-level structure: headings, paragraphs,
/// fenced code blocks, block quotes, ordered and unordered lists (including GFM task
/// lists), tables, and thematic breaks.
///
/// Inline formatting (bold, italic, strikethrough, inline code, links) is handled
/// by `AttributedString` on a per-block basis via ``InlineAttributedStringBuilder``.
/// Swift code blocks are syntax-highlighted with Splash.
public struct MarkdownPreviewView: View {
    /// The raw markdown source to render.
    public let markdown: String

    /// Creates a ``MarkdownPreviewView`` for the given markdown string.
    public init(markdown: String) {
        self.markdown = markdown
    }

    public var body: some View {
        PreviewBlockListView(blocks: MarkdownDocumentParser.parse(markdown))
    }
}

/// Renders an ordered sequence of ``PreviewBlock`` values as a `VStack`.
struct PreviewBlockListView: View {
    let blocks: [PreviewBlock]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            ForEach(Array(blocks.enumerated()), id: \.offset) { _, block in
                PreviewBlockView(block: block)
            }
        }
    }
}

/// Renders a single ``PreviewBlock``.
struct PreviewBlockView: View {
    let block: PreviewBlock

    var body: some View {
        switch block {
        case .heading(let level, let inline):
            Text(inline)
                .font(headingFont(level))
                .fontWeight(.bold)

        case .paragraph(let inline):
            Text(inline)
                .font(.body)

        case .codeBlock(let language, let source):
            Text(SplashCodeHighlighter.highlight(source, language: language))
                .padding(8)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(.quaternary)
                .clipShape(RoundedRectangle(cornerRadius: 6))

        case .blockquote(let children):
            PreviewBlockquoteView(children: children)

        case .unorderedList(let items):
            VStack(alignment: .leading, spacing: 4) {
                ForEach(Array(items.enumerated()), id: \.offset) { _, item in
                    PreviewListItemView(item: item, marker: "•")
                }
            }

        case .orderedList(let start, let items):
            VStack(alignment: .leading, spacing: 4) {
                ForEach(Array(items.enumerated()), id: \.offset) { index, item in
                    PreviewListItemView(item: item, marker: "\(start + index).")
                }
            }

        case .table(let table):
            PreviewTableView(table: table)

        case .thematicBreak:
            Divider()
        }
    }

    private func headingFont(_ level: Int) -> Font {
        switch level {
        case 1: .title
        case 2: .title2
        case 3: .title3
        default: .headline
        }
    }
}

/// Renders a block quote with a leading left-border accent.
struct PreviewBlockquoteView: View {
    let children: [PreviewBlock]

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Rectangle()
                .fill(Color.secondary)
                .frame(width: 3)
                .clipShape(RoundedRectangle(cornerRadius: 1.5))
            PreviewBlockListView(blocks: children)
        }
        .padding(.leading, 4)
    }
}

/// Renders a single list item, with optional task-list checkbox.
struct PreviewListItemView: View {
    let item: PreviewListItem
    let marker: String

    var body: some View {
        HStack(alignment: .top, spacing: 6) {
            if let checked = item.taskState {
                Image(systemName: checked ? "checkmark.square" : "square")
                    .foregroundStyle(.secondary)
            } else {
                Text(marker)
                    .foregroundStyle(.secondary)
                    .frame(minWidth: 16, alignment: .trailing)
            }
            PreviewBlockListView(blocks: item.children)
        }
    }
}

/// Renders a GFM table using `Grid`.
struct PreviewTableView: View {
    let table: PreviewTable

    var body: some View {
        Grid(alignment: .leading, horizontalSpacing: 12, verticalSpacing: 4) {
            GridRow {
                ForEach(Array(table.headerCells.enumerated()), id: \.offset) { index, cell in
                    Text(cell)
                        .fontWeight(.semibold)
                        .gridColumnAlignment(columnAlignment(index))
                }
            }
            Divider()
                .gridCellUnsizedAxes(.horizontal)
            ForEach(Array(table.bodyRows.enumerated()), id: \.offset) { _, row in
                GridRow {
                    ForEach(Array(row.enumerated()), id: \.offset) { _, cell in
                        Text(cell)
                    }
                }
            }
        }
        .padding(8)
        .background(.quaternary)
        .clipShape(RoundedRectangle(cornerRadius: 6))
    }

    private func columnAlignment(_ index: Int) -> HorizontalAlignment {
        guard index < table.columnAlignments.count else { return .leading }
        switch table.columnAlignments[index] {
        case .center: return .center
        case .right: return .trailing
        default: return .leading
        }
    }
}

#Preview {
    ScrollView {
        MarkdownPreviewView(
            markdown: """
                # Heading 1

                ## Heading 2

                ### Heading 3

                #### Heading 4 (headline font)

                A paragraph with **bold**, _italic_, ~~strikethrough~~, and `inline code`.

                ```swift
                struct Foo {
                    var bar: Int
                    func greet() { print("hello") }
                }
                ```

                > A block quote with **bold** inside.

                - First item
                - Second item
                - [ ] Unchecked task
                - [x] Checked task

                1. One
                2. Two
                3. Three

                | Name   | Role   |
                |--------|--------|
                | Alice  | Admin  |
                | Bob    | User   |

                Another paragraph with a [link](https://example.com) in it.

                ---
                """
        )
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
    }
    .frame(width: 500, height: 700)
}
