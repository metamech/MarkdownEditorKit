import SwiftUI

/// Renders a markdown string with proper block-level structure: headings, paragraphs, and fenced code blocks.
///
/// `AttributedString(markdown:)` + `Text` collapses block structure, so blocks are parsed and
/// laid out manually. Inline formatting (bold, italic, code spans, links) is handled by
/// `AttributedString` on a per-block basis.
public struct MarkdownPreviewView: View {
    /// The raw markdown source to render.
    public let markdown: String

    /// Creates a ``MarkdownPreviewView`` for the given markdown string.
    public init(markdown: String) {
        self.markdown = markdown
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            ForEach(Array(blocks.enumerated()), id: \.offset) { _, block in
                blockView(block)
            }
        }
    }

    private enum Block {
        case heading(level: Int, text: String)
        case code(language: String?, lines: [String])
        case paragraph(text: String)
    }

    private var blocks: [Block] {
        var result: [Block] = []
        let lines = markdown.components(separatedBy: "\n")
        var i = 0
        var paragraphLines: [String] = []

        func flushParagraph() {
            let text = paragraphLines.joined(separator: "\n").trimmingCharacters(in: .whitespacesAndNewlines)
            if !text.isEmpty {
                result.append(.paragraph(text: text))
            }
            paragraphLines = []
        }

        while i < lines.count {
            let line = lines[i]

            // Fenced code block
            if line.hasPrefix("```") {
                flushParagraph()
                let lang = String(line.dropFirst(3)).trimmingCharacters(in: .whitespaces)
                var codeLines: [String] = []
                i += 1
                while i < lines.count && !lines[i].hasPrefix("```") {
                    codeLines.append(lines[i])
                    i += 1
                }
                result.append(.code(language: lang.isEmpty ? nil : lang, lines: codeLines))
                i += 1  // skip closing ```
                continue
            }

            // ATX heading
            if let headingMatch = line.headingLevel() {
                flushParagraph()
                result.append(.heading(level: headingMatch.level, text: headingMatch.text))
                i += 1
                continue
            }

            // Blank line ends a paragraph
            if line.trimmingCharacters(in: .whitespaces).isEmpty {
                flushParagraph()
                i += 1
                continue
            }

            paragraphLines.append(line)
            i += 1
        }

        flushParagraph()
        return result
    }

    @ViewBuilder
    private func blockView(_ block: Block) -> some View {
        switch block {
        case .heading(let level, let text):
            Text(markdownInline(text))
                .font(headingFont(level))
                .fontWeight(.bold)

        case .code(_, let lines):
            Text(lines.joined(separator: "\n"))
                .font(.system(.body, design: .monospaced))
                .padding(8)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(.quaternary)
                .clipShape(RoundedRectangle(cornerRadius: 6))

        case .paragraph(let text):
            Text(markdownInline(text))
                .font(.body)
        }
    }

    /// Parses inline markdown (bold, italic, code spans, links) via `AttributedString`.
    private func markdownInline(_ text: String) -> AttributedString {
        (try? AttributedString(markdown: text, options: .init(interpretedSyntax: .inlineOnlyPreservingWhitespace)))
            ?? AttributedString(text)
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

// MARK: - String helpers

extension String {
    /// Returns the ATX heading level and stripped text, or `nil` if the string is not an ATX heading.
    func headingLevel() -> (level: Int, text: String)? {
        var hashes = 0
        for ch in self {
            if ch == "#" { hashes += 1 } else { break }
        }
        guard hashes >= 1 && hashes <= 6 else { return nil }
        guard count > hashes else { return (hashes, "") }
        let rest = String(dropFirst(hashes))
        // ATX headings require a space after the #'s (or the line is just #'s)
        guard rest.first == " " || rest.isEmpty else { return nil }
        let text = rest.trimmingCharacters(in: .whitespaces)
        return (hashes, text)
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

                A paragraph with **bold**, _italic_, and `inline code`.

                ```swift
                struct Foo {
                    var bar: Int
                }
                ```

                Another paragraph with a [link](https://example.com) in it.
                """
        )
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
    }
    .frame(width: 500, height: 600)
}
