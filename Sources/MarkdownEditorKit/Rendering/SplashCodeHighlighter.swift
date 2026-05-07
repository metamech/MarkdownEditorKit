import Foundation
import Splash
import SwiftUI

/// Applies syntax highlighting to a source code string.
///
/// Swift source is highlighted with Splash's presentation theme. All other
/// languages receive a plain monospaced `AttributedString`.
enum SplashCodeHighlighter {
    /// Highlight `source` code, optionally using `language` to select a grammar.
    ///
    /// - Parameters:
    ///   - source: The raw source code to highlight.
    ///   - language: A lowercase language identifier (e.g. `"swift"`).
    /// - Returns: An `AttributedString` with colour and font attributes applied.
    @MainActor
    static func highlight(_ source: String, language: String?) -> AttributedString {
        guard language?.lowercased() == "swift" else {
            return plainMonospaced(source)
        }
        let format = AttributedStringOutputFormat(
            theme: .presentation(withFont: .init(size: 14))
        )
        let highlighter = SyntaxHighlighter(format: format)
        let nsAttributed = highlighter.highlight(source)
        return bridge(nsAttributed) ?? plainMonospaced(source)
    }

    @MainActor
    private static func bridge(_ nsAttributed: NSAttributedString) -> AttributedString? {
        try? AttributedString(nsAttributed, including: \.appKit)
    }

    @MainActor
    private static func plainMonospaced(_ source: String) -> AttributedString {
        let font = NSFont.monospacedSystemFont(ofSize: NSFont.systemFontSize, weight: .regular)
        let nsAttributed = NSAttributedString(
            string: source,
            attributes: [.font: font]
        )
        return (try? AttributedString(nsAttributed, including: \.appKit)) ?? AttributedString(source)
    }
}
