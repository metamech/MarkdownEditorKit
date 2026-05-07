import Foundation

/// An in-memory ``MentionProvider`` backed by a fixed array of suggestions.
///
/// Suitable for SwiftUI previews and unit tests. Returns all suggestions whose
/// ``MentionSuggestion/displayText`` contains the query prefix (case-insensitive).
public struct InMemoryMentionProvider: MentionProvider {
    private let suggestions: [MentionSuggestion]

    /// Creates an ``InMemoryMentionProvider`` with the given suggestions.
    ///
    /// - Parameter suggestions: The full list of suggestions to filter against.
    public init(suggestions: [MentionSuggestion]) {
        self.suggestions = suggestions
    }

    /// Returns suggestions whose display text contains `query.prefix` (case-insensitive).
    public func searchUsers(query: AutocompleteQuery) async throws -> [MentionSuggestion] {
        try Task.checkCancellation()
        let needle = query.prefix.lowercased()
        guard !needle.isEmpty else { return suggestions }
        return suggestions.filter {
            $0.displayText.lowercased().contains(needle)
                || $0.secondaryText.lowercased().contains(needle)
        }
    }
}
