import Foundation

/// The text prefix the user has typed after a trigger character (e.g. `@` or `#`).
///
/// Carries both the string and its byte range in the full document so the editor
/// can replace it precisely on selection.
public struct AutocompleteQuery: Sendable, Hashable {
    /// The raw prefix the user typed, not including the trigger character.
    public let prefix: String

    /// UTF-16 range of the trigger character plus `prefix` in the full document string.
    public let range: NSRange

    /// The trigger character that caused this query (`@`, `#`, or `:`).
    public let trigger: Character

    /// Creates an ``AutocompleteQuery``.
    ///
    /// - Parameters:
    ///   - prefix: The text typed after the trigger character.
    ///   - range: UTF-16 range covering the trigger character and prefix.
    ///   - trigger: The character that initiated autocomplete (`@`, `#`, or `:`).
    public init(prefix: String, range: NSRange, trigger: Character) {
        self.prefix = prefix
        self.range = range
        self.trigger = trigger
    }
}
