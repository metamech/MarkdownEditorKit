import Foundation

/// An in-memory ``EmojiProvider`` backed by a fixed array of suggestions.
///
/// Suitable for SwiftUI previews and unit tests. Returns all suggestions whose
/// ``EmojiSuggestion/id`` starts with the given prefix (case-insensitive).
public struct InMemoryEmojiProvider: EmojiProvider {
    private let suggestions: [EmojiSuggestion]

    /// Creates an ``InMemoryEmojiProvider`` with the given suggestions.
    ///
    /// - Parameter suggestions: The full list of suggestions to filter against.
    public init(suggestions: [EmojiSuggestion]) {
        self.suggestions = suggestions
    }

    /// Returns suggestions whose `id` starts with `prefix` (case-insensitive).
    public func search(prefix: String) -> [EmojiSuggestion] {
        let needle = prefix.lowercased()
        guard !needle.isEmpty else { return suggestions }
        return suggestions.filter { $0.id.lowercased().hasPrefix(needle) }
    }
}
