import Foundation

/// A single issue or pull-request suggestion returned by ``IssueProvider``.
public struct IssueSuggestion: Sendable, Identifiable, Hashable {
    /// The issue or pull-request number used as a unique identifier.
    public let id: Int

    /// Primary label, e.g. `#42 Fix login crash`.
    public let displayText: String

    /// Secondary label, e.g. `open` / `closed`. May be empty.
    public let secondaryText: String

    /// Text inserted into the document, e.g. `#42`.
    public let insertionText: String

    /// Creates an ``IssueSuggestion``.
    ///
    /// - Parameters:
    ///   - id: The issue or pull-request number.
    ///   - displayText: Primary label shown in the overlay row.
    ///   - secondaryText: Secondary label (e.g. state). Pass empty string to hide.
    ///   - insertionText: Text inserted when suggestion is accepted.
    public init(id: Int, displayText: String, secondaryText: String = "", insertionText: String) {
        self.id = id
        self.displayText = displayText
        self.secondaryText = secondaryText
        self.insertionText = insertionText
    }
}

/// Supplies issue and pull-request suggestions for the `#` autocomplete overlay.
///
/// Inject via `.issueProvider(_:)`. Same cancellation contract as ``MentionProvider``.
public protocol IssueProvider: Sendable {
    /// Returns suggestions matching `query.prefix`.
    ///
    /// Called with Swift structured concurrency; the active `Task` is cancelled when
    /// the user types further or dismisses the overlay.
    func searchIssues(query: AutocompleteQuery) async throws -> [IssueSuggestion]
}
