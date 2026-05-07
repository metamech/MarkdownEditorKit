import Foundation

/// An in-memory ``IssueProvider`` backed by a fixed array of suggestions.
///
/// Suitable for SwiftUI previews and unit tests. Returns all suggestions whose
/// ``IssueSuggestion/displayText`` contains the query prefix (case-insensitive).
public struct InMemoryIssueProvider: IssueProvider {
    private let suggestions: [IssueSuggestion]

    /// Creates an ``InMemoryIssueProvider`` with the given suggestions.
    ///
    /// - Parameter suggestions: The full list of suggestions to filter against.
    public init(suggestions: [IssueSuggestion]) {
        self.suggestions = suggestions
    }

    /// Returns suggestions whose display text contains `query.prefix` (case-insensitive).
    public func searchIssues(query: AutocompleteQuery) async throws -> [IssueSuggestion] {
        try Task.checkCancellation()
        let needle = query.prefix.lowercased()
        guard !needle.isEmpty else { return suggestions }
        return suggestions.filter {
            $0.displayText.lowercased().contains(needle)
                || $0.secondaryText.lowercased().contains(needle)
        }
    }
}
