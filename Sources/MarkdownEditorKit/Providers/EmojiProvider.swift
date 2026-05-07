import Foundation

/// A single emoji suggestion returned by ``EmojiProvider``.
public struct EmojiSuggestion: Sendable, Identifiable, Hashable {
    /// GFM short-code without colons, e.g. `thumbsup`.
    public let id: String

    /// The rendered glyph, e.g. `👍`.
    public let glyph: String

    /// Text inserted into the document, e.g. `:thumbsup:`.
    public let insertionText: String

    /// Creates an ``EmojiSuggestion``.
    ///
    /// - Parameters:
    ///   - id: GFM short-code without colons.
    ///   - glyph: The rendered emoji character.
    ///   - insertionText: Text inserted when suggestion is accepted.
    public init(id: String, glyph: String, insertionText: String) {
        self.id = id
        self.glyph = glyph
        self.insertionText = insertionText
    }
}

/// Supplies emoji suggestions for the `:` autocomplete overlay.
///
/// Implementations are expected to be synchronous (static list lookup).
/// Inject via `.emojiProvider(_:)`.
public protocol EmojiProvider: Sendable {
    /// Returns emoji suggestions matching `prefix`. Never throws; return `[]` on no match.
    func search(prefix: String) -> [EmojiSuggestion]
}
