import SwiftUI

/// The coordinate space name shared between the editor container and the overlay.
let editorCoordinateSpaceName = "MarkdownEditorContainer"

/// A caret-anchored autocomplete suggestion overlay.
///
/// Rendered inside a named `coordinateSpace` on top of the editor. Receives
/// keyboard navigation through the ``AutocompleteController``; mouse clicks
/// commit a suggestion directly.
struct AutocompleteOverlay: View {
    @Bindable var controller: AutocompleteController

    /// Called when the user commits a suggestion (Return, ⌘↩, or click).
    var onCommit: (String) -> Void

    private let maxHeight: CGFloat = 200
    private let overlayWidth: CGFloat = 280

    var body: some View {
        if controller.isVisible {
            overlayContent
                .offset(
                    x: controller.caretRect.minX,
                    y: controller.caretRect.maxY
                )
        }
    }

    @ViewBuilder
    private var overlayContent: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 0) {
                    suggestionRows(scrollProxy: proxy)
                }
            }
            .frame(width: overlayWidth)
            .frame(maxHeight: maxHeight)
            .background(.regularMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .shadow(color: .black.opacity(0.15), radius: 8, x: 0, y: 4)
            .onChange(of: controller.selectedIndex) { _, newIndex in
                withAnimation(.easeInOut(duration: 0.1)) {
                    proxy.scrollTo(newIndex, anchor: .center)
                }
            }
        }
    }

    @ViewBuilder
    private func suggestionRows(scrollProxy: ScrollViewProxy) -> some View {
        switch controller.suggestions {
        case .mentions(let items):
            ForEach(Array(items.enumerated()), id: \.offset) { index, item in
                MentionRow(
                    suggestion: item,
                    isSelected: index == controller.selectedIndex
                )
                .id(index)
                .contentShape(Rectangle())
                .onTapGesture {
                    onCommit(item.insertionText)
                }
            }

        case .issues(let items):
            ForEach(Array(items.enumerated()), id: \.offset) { index, item in
                IssueRow(
                    suggestion: item,
                    isSelected: index == controller.selectedIndex
                )
                .id(index)
                .contentShape(Rectangle())
                .onTapGesture {
                    onCommit(item.insertionText)
                }
            }

        case .emojis(let items):
            ForEach(Array(items.enumerated()), id: \.offset) { index, item in
                EmojiRow(
                    suggestion: item,
                    isSelected: index == controller.selectedIndex
                )
                .id(index)
                .contentShape(Rectangle())
                .onTapGesture {
                    onCommit(item.insertionText)
                }
            }

        case .empty:
            EmptyView()
        }
    }
}

// MARK: - Row Views

private struct MentionRow: View {
    let suggestion: MentionSuggestion
    let isSelected: Bool

    var body: some View {
        HStack(spacing: 8) {
            // Avatar placeholder — host app may provide an actual image loader if needed.
            Image(systemName: "person.circle.fill")
                .resizable()
                .frame(width: 24, height: 24)
                .foregroundStyle(.secondary)

            VStack(alignment: .leading, spacing: 2) {
                Text(suggestion.displayText)
                    .font(.system(size: 13))
                if !suggestion.secondaryText.isEmpty {
                    Text(suggestion.secondaryText)
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(isSelected ? Color.accentColor.opacity(0.15) : Color.clear)
    }
}

private struct IssueRow: View {
    let suggestion: IssueSuggestion
    let isSelected: Bool

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "circle.dotted")
                .frame(width: 16, height: 16)
                .foregroundStyle(.secondary)

            VStack(alignment: .leading, spacing: 2) {
                Text(suggestion.displayText)
                    .font(.system(size: 13))
                if !suggestion.secondaryText.isEmpty {
                    Text(suggestion.secondaryText)
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(isSelected ? Color.accentColor.opacity(0.15) : Color.clear)
    }
}

private struct EmojiRow: View {
    let suggestion: EmojiSuggestion
    let isSelected: Bool

    var body: some View {
        HStack(spacing: 8) {
            Text(suggestion.glyph)
                .font(.system(size: 18))
                .frame(width: 24, height: 24)

            Text(suggestion.insertionText)
                .font(.system(size: 13))

            Spacer()
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(isSelected ? Color.accentColor.opacity(0.15) : Color.clear)
    }
}
