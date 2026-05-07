import SwiftUI

// MARK: - Environment Keys

private struct MentionProviderKey: EnvironmentKey {
    static let defaultValue: (any MentionProvider)? = nil
}

private struct IssueProviderKey: EnvironmentKey {
    static let defaultValue: (any IssueProvider)? = nil
}

private struct EmojiProviderKey: EnvironmentKey {
    static let defaultValue: (any EmojiProvider)? = nil
}

private struct PasteHandlerKey: EnvironmentKey {
    static let defaultValue: (any PasteHandler)? = nil
}

extension EnvironmentValues {
    /// The active ``MentionProvider``, or `nil` if none is configured.
    public var mentionProvider: (any MentionProvider)? {
        get { self[MentionProviderKey.self] }
        set { self[MentionProviderKey.self] = newValue }
    }

    /// The active ``IssueProvider``, or `nil` if none is configured.
    public var issueProvider: (any IssueProvider)? {
        get { self[IssueProviderKey.self] }
        set { self[IssueProviderKey.self] = newValue }
    }

    /// The active ``EmojiProvider``, or `nil` if none is configured.
    public var emojiProvider: (any EmojiProvider)? {
        get { self[EmojiProviderKey.self] }
        set { self[EmojiProviderKey.self] = newValue }
    }

    /// The active ``PasteHandler``, or `nil` if none is configured.
    public var pasteHandler: (any PasteHandler)? {
        get { self[PasteHandlerKey.self] }
        set { self[PasteHandlerKey.self] = newValue }
    }
}

// MARK: - View Modifiers

public extension View {
    /// Injects a ``MentionProvider`` into the environment for ``MarkdownEditorView``.
    ///
    /// - Parameter provider: The provider to inject, or `nil` to disable `@` autocomplete.
    func mentionProvider(_ provider: (any MentionProvider)?) -> some View {
        environment(\.mentionProvider, provider)
    }

    /// Injects an ``IssueProvider`` into the environment for ``MarkdownEditorView``.
    ///
    /// - Parameter provider: The provider to inject, or `nil` to disable `#` autocomplete.
    func issueProvider(_ provider: (any IssueProvider)?) -> some View {
        environment(\.issueProvider, provider)
    }

    /// Injects an ``EmojiProvider`` into the environment for ``MarkdownEditorView``.
    ///
    /// - Parameter provider: The provider to inject, or `nil` to disable `:` autocomplete.
    func emojiProvider(_ provider: (any EmojiProvider)?) -> some View {
        environment(\.emojiProvider, provider)
    }

    /// Injects a ``PasteHandler`` into the environment for ``MarkdownEditorView``.
    ///
    /// - Parameter handler: The handler to inject, or `nil` to use default paste behaviour.
    func pasteHandler(_ handler: (any PasteHandler)?) -> some View {
        environment(\.pasteHandler, handler)
    }
}
