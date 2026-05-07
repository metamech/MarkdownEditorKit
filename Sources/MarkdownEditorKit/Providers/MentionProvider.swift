import Foundation

/// A single mention (user or team) suggestion returned by ``MentionProvider``.
public struct MentionSuggestion: Sendable, Identifiable, Hashable {
    /// The login or team slug used as a unique identifier.
    public let id: String

    /// Primary label shown in the overlay row (e.g. `@octocat`).
    public let displayText: String

    /// Secondary label shown below `displayText` (e.g. full name). May be empty.
    public let secondaryText: String

    /// Remote URL for an avatar image. `nil` produces a fallback SF Symbol.
    public let avatarURL: URL?

    /// Text inserted into the document when this suggestion is chosen,
    /// replacing the trigger + prefix range. Include the `@` sigil.
    public let insertionText: String

    /// Creates a ``MentionSuggestion``.
    ///
    /// - Parameters:
    ///   - id: The login or team slug.
    ///   - displayText: Primary label (e.g. `@octocat`).
    ///   - secondaryText: Secondary label (e.g. full name). Pass empty string to hide.
    ///   - avatarURL: Optional remote URL for an avatar image.
    ///   - insertionText: Text inserted when suggestion is accepted.
    public init(
        id: String,
        displayText: String,
        secondaryText: String = "",
        avatarURL: URL? = nil,
        insertionText: String
    ) {
        self.id = id
        self.displayText = displayText
        self.secondaryText = secondaryText
        self.avatarURL = avatarURL
        self.insertionText = insertionText
    }
}

/// Supplies mention (user/team) suggestions for the `@` autocomplete overlay.
///
/// Implement this protocol in the host application (e.g. backed by `GitHubKit`)
/// and inject it into ``MarkdownEditorView`` via `.mentionProvider(_:)`.
/// The package never references any concrete implementation.
public protocol MentionProvider: Sendable {
    /// Returns suggestions matching `query.prefix`, or throws if the lookup fails.
    ///
    /// Called with Swift structured concurrency; the active `Task` is cancelled when
    /// the user types further or dismisses the overlay. Implementations should
    /// respect `Task.isCancelled` and throw `CancellationError` early.
    func searchUsers(query: AutocompleteQuery) async throws -> [MentionSuggestion]
}
