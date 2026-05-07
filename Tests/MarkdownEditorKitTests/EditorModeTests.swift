import Testing
@testable import MarkdownEditorKit

@Suite("EditorMode")
struct EditorModeTests {
    // MARK: - storageKey roundtrip

    @Test("storageKey roundtrip for every case", arguments: EditorMode.allCases)
    func storageKeyRoundtrip(_ mode: EditorMode) {
        #expect(EditorMode(storageKey: mode.storageKey) == mode)
    }

    // MARK: - Unknown key

    @Test("init?(storageKey:) returns nil for unknown key")
    func unknownStorageKey() {
        #expect(EditorMode(storageKey: "nope") == nil)
        #expect(EditorMode(storageKey: "") == nil)
        #expect(EditorMode(storageKey: "Code") == nil)  // case-sensitive
    }

    // MARK: - label

    @Test("each case has a non-empty label", arguments: EditorMode.allCases)
    func nonEmptyLabel(_ mode: EditorMode) {
        #expect(!mode.label.isEmpty)
    }

    // MARK: - icon

    @Test("each case has a non-empty icon", arguments: EditorMode.allCases)
    func nonEmptyIcon(_ mode: EditorMode) {
        #expect(!mode.icon.isEmpty)
    }
}
