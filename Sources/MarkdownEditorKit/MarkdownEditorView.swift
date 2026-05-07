import SwiftUI

/// A combined markdown editor that supports three display modes: raw text, split, and preview.
///
/// Pass `renderedText` when you have a separately-processed markdown string (e.g. after
/// server-side rendering). When `nil`, the raw `text` binding is used for the preview.
///
/// The active ``EditorMode`` is controlled via the `mode` binding so callers can persist it
/// with `@AppStorage` or `@SceneStorage` using ``EditorMode/storageKey``.
public struct MarkdownEditorView: View {
    @Binding public var text: String
    public var renderedText: String?
    @Binding public var mode: EditorMode

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
        TextEditor(text: $text)
            .font(.system(.body, design: .monospaced))
            .scrollContentBackground(.hidden)
            .padding(.vertical, 10)
            .padding(.horizontal, 6)
            .background(Color(nsColor: .textBackgroundColor))
    }
}

#Preview {
    @Previewable @State var text = """
        # Hello MarkdownEditorKit

        This is a **bold** word and _italic_ text.

        ## Code block

        ```swift
        let x = 42
        print(x)
        ```

        ### Paragraph

        Ordinary prose continues here with `inline code` and more content.
        """
    @Previewable @State var mode: EditorMode = .split

    VStack(spacing: 0) {
        HStack {
            Text("Mode:")
            EditorModePicker(mode: $mode)
        }
        .padding(.horizontal)
        .padding(.vertical, 6)

        Divider()

        MarkdownEditorView(text: $text, mode: $mode)
    }
    .frame(width: 800, height: 500)
}
