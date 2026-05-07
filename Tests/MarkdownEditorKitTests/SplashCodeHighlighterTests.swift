import AppKit
import Foundation
import Testing

@testable import MarkdownEditorKit

@MainActor
@Suite("SplashCodeHighlighter")
struct SplashCodeHighlighterTests {

    private let swiftSnippet = "let x = 1\nfunc greet() { print(\"hello\") }"

    // MARK: - Swift highlighting

    @Test("Swift snippet with language:swift produces multiple distinct foreground colors")
    func swiftHighlightProducesColors() {
        let attributed = SplashCodeHighlighter.highlight(swiftSnippet, language: "swift")
        let colors = Set(
            attributed.runs
                .compactMap { $0.appKit.foregroundColor }
                .map { $0.cgColor }
        )
        #expect(colors.count >= 2)
    }

    // MARK: - Plain fallback

    @Test("nil language returns monospaced plain text with at most one foreground color")
    func nilLanguagePlainMonospaced() {
        let attributed = SplashCodeHighlighter.highlight(swiftSnippet, language: nil)
        let colors = Set(
            attributed.runs
                .compactMap { $0.appKit.foregroundColor }
                .map { $0.cgColor }
        )
        #expect(colors.count <= 1)
        let nsAttributed = NSAttributedString(attributed)
        var hasMonospaced = false
        nsAttributed.enumerateAttribute(.font, in: NSRange(location: 0, length: nsAttributed.length)) { value, _, stop in
            if let font = value as? NSFont,
                font.fontDescriptor.symbolicTraits.contains(.monoSpace)
            {
                hasMonospaced = true
                stop.pointee = true
            }
        }
        #expect(hasMonospaced)
    }

    @Test("unknown language falls back to the same plain monospaced behavior as nil")
    func unknownLanguageFallback() {
        let fromNil = SplashCodeHighlighter.highlight(swiftSnippet, language: nil)
        let fromUnknown = SplashCodeHighlighter.highlight(swiftSnippet, language: "klingon")
        let colorsNil = Set(
            fromNil.runs.compactMap { $0.appKit.foregroundColor }.map { $0.cgColor }
        )
        let colorsUnknown = Set(
            fromUnknown.runs.compactMap { $0.appKit.foregroundColor }.map { $0.cgColor }
        )
        #expect(colorsNil == colorsUnknown)
        #expect(colorsUnknown.count <= 1)
    }

    // MARK: - Case insensitivity

    @Test("language:SWIFT highlights identically to language:swift")
    func caseInsensitiveSwift() {
        let lower = SplashCodeHighlighter.highlight(swiftSnippet, language: "swift")
        let upper = SplashCodeHighlighter.highlight(swiftSnippet, language: "SWIFT")
        let colorsLower = Set(
            lower.runs.compactMap { $0.appKit.foregroundColor }.map { $0.cgColor }
        )
        let colorsUpper = Set(
            upper.runs.compactMap { $0.appKit.foregroundColor }.map { $0.cgColor }
        )
        #expect(colorsLower == colorsUpper)
        #expect(colorsLower.count >= 2)
    }

    // MARK: - Non-empty output

    @Test("highlighted Swift output is non-empty")
    func swiftHighlightNonEmpty() {
        let attributed = SplashCodeHighlighter.highlight(swiftSnippet, language: "swift")
        #expect(attributed.characters.count > 0)
    }
}
