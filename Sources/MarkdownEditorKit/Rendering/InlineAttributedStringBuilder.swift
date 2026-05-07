import Foundation
import Markdown
import SwiftUI

/// Walks a sequence of `InlineMarkup` nodes and builds an `AttributedString`.
///
/// Supported inline types: `Text`, `Emphasis`, `Strong`, `Strikethrough`,
/// `InlineCode`, `Link`, `Image` (renders alt text), `LineBreak`, `SoftBreak`.
/// All other inline node types fall back to their plain-text literal.
func buildAttributedString(from inlines: some Sequence<InlineMarkup>) -> AttributedString {
    var result = AttributedString()
    for inline in inlines {
        result += attributedString(for: inline)
    }
    return result
}

// MARK: - Private helpers

private func attributedString(for inline: InlineMarkup) -> AttributedString {
    switch inline {
    case let text as Markdown.Text:
        return AttributedString(text.string)

    case let emphasis as Emphasis:
        var inner = buildAttributedString(from: emphasis.inlineChildren)
        inner.inlinePresentationIntent = .emphasized
        return inner

    case let strong as Strong:
        var inner = buildAttributedString(from: strong.inlineChildren)
        inner.inlinePresentationIntent = .stronglyEmphasized
        return inner

    case let strike as Strikethrough:
        var inner = buildAttributedString(from: strike.inlineChildren)
        inner.inlinePresentationIntent = .strikethrough
        return inner

    case let code as InlineCode:
        var span = AttributedString(code.code)
        span.inlinePresentationIntent = .code
        return span

    case let link as Markdown.Link:
        var inner = buildAttributedString(from: link.inlineChildren)
        if let destination = link.destination, let url = URL(string: destination) {
            inner.link = url
        }
        return inner

    case let image as Markdown.Image:
        let alt = image.plainText
        return alt.isEmpty ? AttributedString() : AttributedString(alt)

    case is LineBreak:
        return AttributedString("\n")

    case is SoftBreak:
        return AttributedString(" ")

    default:
        return AttributedString(inline.plainText)
    }
}
