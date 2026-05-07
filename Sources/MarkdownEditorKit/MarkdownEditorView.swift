import SwiftUI

/// A combined markdown editor that supports three display modes: raw text, split, and preview.
///
/// Pass `renderedText` when you have a separately-processed markdown string (e.g. after
/// server-side rendering). When `nil`, the raw `text` binding is used for the preview.
///
/// The active ``EditorMode`` is controlled via the `mode` binding so callers can persist it
/// with `@AppStorage` or `@SceneStorage` using ``EditorMode/storageKey``.
///
/// Autocomplete providers are injected via environment view modifiers:
/// ```swift
/// MarkdownEditorView(text: $text, mode: $mode)
///     .mentionProvider(myMentionProvider)
///     .issueProvider(myIssueProvider)
///     .emojiProvider(myEmojiProvider)
///     .pasteHandler(myPasteHandler)
/// ```
public struct MarkdownEditorView: View {
    @Binding public var text: String
    public var renderedText: String?
    @Binding public var mode: EditorMode

    @Environment(\.mentionProvider) private var mentionProvider
    @Environment(\.issueProvider) private var issueProvider
    @Environment(\.emojiProvider) private var emojiProvider
    @Environment(\.pasteHandler) private var pasteHandler

    @State private var autocompleteController = AutocompleteController()

    /// Creates a ``MarkdownEditorView``.
    ///
    /// - Parameters:
    ///   - text: Two-way binding to the raw markdown source.
    ///   - renderedText: Optional pre-rendered markdown string shown in the preview pane.
    ///                   When `nil` the raw `text` is rendered directly.
    ///   - mode: Two-way binding controlling which pane(s) are visible.
    public init(text: Binding<String>, renderedText: String? = nil, mode: Binding<EditorMode>) {
        _text = text
        self.renderedText = renderedText
        _mode = mode
    }

    private var previewContent: String {
        renderedText ?? text
    }

    private var resolvedProviders: ResolvedProviders {
        ResolvedProviders(
            mention: mentionProvider,
            issue: issueProvider,
            emoji: emojiProvider,
            paste: pasteHandler
        )
    }

    public var body: some View {
        switch mode {
        case .code:
            codeEditor

        case .split:
            GeometryReader { geo in
                HStack(spacing: 0) {
                    codeEditor
                        .frame(width: geo.size.width * 0.5)

                    Divider()

                    ScrollView {
                        MarkdownPreviewView(markdown: previewContent)
                            .textSelection(.enabled)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding()
                    }
                    .frame(maxWidth: .infinity)
                }
            }

        case .preview:
            ScrollView {
                MarkdownPreviewView(markdown: previewContent)
                    .textSelection(.enabled)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
            }
        }
    }

    private var codeEditor: some View {
        GeometryReader { geo in
            ZStack(alignment: .topLeading) {
                MarkdownTextView(
                    text: $text,
                    providers: resolvedProviders,
                    controller: autocompleteController
                )
                .coordinateSpace(name: editorCoordinateSpaceName)

                AutocompleteOverlay(
                    controller: autocompleteController,
                    onCommit: { insertionText in
                        commitSuggestion(insertionText)
                    }
                )
            }
            .onChange(of: geo.size) { _, _ in
                // Dismiss overlay on resize to avoid stale position.
                autocompleteController.dismiss()
            }
        }
        .background(Color(nsColor: .textBackgroundColor))
    }

    private func commitSuggestion(_ insertionText: String) {
        guard let query = autocompleteController.activeQuery else { return }
        // Replace the trigger+prefix range with the selected insertion text.
        let nsString = text as NSString
        let newText = nsString.replacingCharacters(in: query.range, with: insertionText)
        text = newText
        autocompleteController.dismiss()
    }
}

#Preview {
    @Previewable @State var text = """
        # Hello MarkdownEditorKit

        This is a **bold** word and _italic_ text.

        ## Autocomplete examples

        Type `@al` to trigger mention autocomplete.
        Type `#1` to trigger issue autocomplete.
        Type `:thumb` to trigger emoji autocomplete.

        ## Code block

        ```swift
        let x = 42
        print(x)
        ```

        ### Paragraph

        Ordinary prose continues here with `inline code` and more content.
        @al #1 :thumb
        """
    @Previewable @State var mode: EditorMode = .split

    let mentions = [
        MentionSuggestion(
            id: "alice", displayText: "@alice", secondaryText: "Alice Smith",
            insertionText: "@alice"),
        MentionSuggestion(
            id: "albert", displayText: "@albert", secondaryText: "Albert Jones",
            insertionText: "@albert"),
        MentionSuggestion(
            id: "bob", displayText: "@bob", secondaryText: "Bob Brown",
            insertionText: "@bob"),
    ]

    let issues = [
        IssueSuggestion(
            id: 1, displayText: "#1 Fix login crash", secondaryText: "open",
            insertionText: "#1"),
        IssueSuggestion(
            id: 12, displayText: "#12 Improve onboarding", secondaryText: "closed",
            insertionText: "#12"),
        IssueSuggestion(
            id: 123, displayText: "#123 Dark mode support", secondaryText: "open",
            insertionText: "#123"),
    ]

    let emojis = [
        EmojiSuggestion(id: "thumbsup", glyph: "👍", insertionText: ":thumbsup:"),
        EmojiSuggestion(id: "thumbsdown", glyph: "👎", insertionText: ":thumbsdown:"),
        EmojiSuggestion(id: "thinking", glyph: "🤔", insertionText: ":thinking:"),
        EmojiSuggestion(id: "tada", glyph: "🎉", insertionText: ":tada:"),
    ]

    VStack(spacing: 0) {
        HStack {
            Text("Mode:")
            EditorModePicker(mode: $mode)
        }
        .padding(.horizontal)
        .padding(.vertical, 6)

        Divider()

        MarkdownEditorView(text: $text, mode: $mode)
            .mentionProvider(InMemoryMentionProvider(suggestions: mentions))
            .issueProvider(InMemoryIssueProvider(suggestions: issues))
            .emojiProvider(InMemoryEmojiProvider(suggestions: emojis))
    }
    .frame(width: 800, height: 500)
}
