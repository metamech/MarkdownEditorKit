import SwiftUI

/// The display mode for a ``MarkdownEditorView``.
///
/// Persisted via ``storageKey`` for use with `@AppStorage` or `@SceneStorage`.
public enum EditorMode: CaseIterable, Hashable, Sendable {
    /// Shows only the raw-text code editor.
    case code
    /// Shows the code editor alongside the rendered preview, side-by-side.
    case split
    /// Shows only the rendered markdown preview.
    case preview

    /// Human-readable label suitable for display in menus or toolbars.
    public var label: String {
        switch self {
        case .code: "Code"
        case .split: "Code + Preview"
        case .preview: "Preview"
        }
    }

    /// SF Symbol name representing this mode.
    public var icon: String {
        switch self {
        case .code: "curlybraces"
        case .split: "rectangle.split.2x1"
        case .preview: "eye"
        }
    }

    /// Stable string key for `@AppStorage` / `@SceneStorage` persistence.
    public var storageKey: String {
        switch self {
        case .code: "code"
        case .split: "split"
        case .preview: "preview"
        }
    }

    /// Reconstructs an ``EditorMode`` from a previously stored ``storageKey``.
    ///
    /// Returns `nil` if the key is not recognised.
    public init?(storageKey: String) {
        switch storageKey {
        case "code": self = .code
        case "split": self = .split
        case "preview": self = .preview
        default: return nil
        }
    }
}

/// A borderless menu button that lets the user switch between ``EditorMode`` values.
public struct EditorModePicker: View {
    @Binding public var mode: EditorMode

    /// Creates a picker bound to `mode`.
    public init(mode: Binding<EditorMode>) {
        _mode = mode
    }

    public var body: some View {
        Menu {
            ForEach(EditorMode.allCases, id: \.self) { m in
                Button {
                    mode = m
                } label: {
                    Label(m.label, systemImage: m.icon)
                }
            }
        } label: {
            Image(systemName: mode.icon)
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
        .menuStyle(.borderlessButton)
        .fixedSize()
    }
}
