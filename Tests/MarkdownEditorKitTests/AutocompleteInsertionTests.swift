import Foundation
import Testing

@testable import MarkdownEditorKit

/// Tests for the text-insertion logic used by `MarkdownEditorView.commitSuggestion`.
///
/// The function under test is not exposed as a separate free function, so these
/// tests directly verify the `NSString.replacingCharacters(in:with:)` invariant
/// that `commitSuggestion` relies on.
@Suite("AutocompleteInsertion")
struct AutocompleteInsertionTests {
    // MARK: - Helpers

    /// Simulates the replacement performed by `MarkdownEditorView.commitSuggestion`.
    private func applyInsertion(
        text: String,
        range: NSRange,
        insertionText: String
    ) -> String {
        (text as NSString).replacingCharacters(in: range, with: insertionText)
    }

    // MARK: - Basic mention replacement

    @Test("@al replaced by @alice produces correct new text")
    func mentionReplacement() {
        // Query range covers "@al" (location 0, length 3)
        let result = applyInsertion(
            text: "@al",
            range: NSRange(location: 0, length: 3),
            insertionText: "@alice"
        )
        #expect(result == "@alice")
    }

    @Test("@al in sentence is replaced correctly leaving surrounding text intact")
    func mentionReplacementMidSentence() {
        // "Hi @al there" — "@al" at location 3, length 3
        let result = applyInsertion(
            text: "Hi @al there",
            range: NSRange(location: 3, length: 3),
            insertionText: "@alice"
        )
        #expect(result == "Hi @alice there")
    }

    // MARK: - Issue replacement

    @Test("#1 replaced by #42 produces correct new text")
    func issueReplacement() {
        let result = applyInsertion(
            text: "#1",
            range: NSRange(location: 0, length: 2),
            insertionText: "#42"
        )
        #expect(result == "#42")
    }

    // MARK: - Emoji replacement

    @Test(":thumb replaced by :thumbsup: produces correct new text")
    func emojiReplacement() {
        let result = applyInsertion(
            text: ":thumb",
            range: NSRange(location: 0, length: 6),
            insertionText: ":thumbsup:"
        )
        #expect(result == ":thumbsup:")
    }

    // MARK: - Replacement at end of buffer

    @Test("replacement at exact end of buffer does not append extra characters")
    func replacementAtEndOfBuffer() {
        let text = "Hello @bob"
        // "@bob" is the last 4 characters; UTF-16 length is 10
        let range = NSRange(location: 6, length: 4)
        let result = applyInsertion(text: text, range: range, insertionText: "@bobby")
        #expect(result == "Hello @bobby")
        #expect((result as NSString).length == 12)
    }

    // MARK: - Replacement at start of buffer

    @Test("replacement at location=0 covers start of buffer correctly")
    func replacementAtStartOfBuffer() {
        let text = "@al continues"
        let result = applyInsertion(
            text: text,
            range: NSRange(location: 0, length: 3),
            insertionText: "@alice"
        )
        #expect(result == "@alice continues")
    }

    // MARK: - Multibyte text before trigger

    @Test("replacement with multibyte emoji before trigger uses correct UTF-16 range")
    func multibyteBeforeTrigger() {
        // "👋 @al" — "👋" = 2 UTF-16 units, " " = 1, "@al" at location 3, length 3
        let text = "👋 @al"
        let result = applyInsertion(
            text: text,
            range: NSRange(location: 3, length: 3),
            insertionText: "@alice"
        )
        #expect(result == "👋 @alice")
    }

    @Test("replacement with multibyte emoji after trigger preserves emoji")
    func multibyteAfterTrigger() {
        // "@al 👋" — "@al" at location 0, length 3
        let text = "@al 👋"
        let result = applyInsertion(
            text: text,
            range: NSRange(location: 0, length: 3),
            insertionText: "@alice"
        )
        #expect(result == "@alice 👋")
    }

    // MARK: - Empty prefix (trigger only)

    @Test("trigger-only match (@) replaced by full insertion text")
    func triggerOnlyReplacement() {
        // Just typed "@", range covers the "@" (length 1)
        let result = applyInsertion(
            text: "@",
            range: NSRange(location: 0, length: 1),
            insertionText: "@alice"
        )
        #expect(result == "@alice")
    }

    // MARK: - Resulting string length invariant

    @Test("result length equals (original - range.length + insertionText.utf16Count)")
    func resultLengthInvariant() {
        let text = "Say @hi world"
        let range = NSRange(location: 4, length: 3)  // "@hi"
        let insertionText = "@howdy"
        let result = applyInsertion(text: text, range: range, insertionText: insertionText)
        let expectedLength =
            (text as NSString).length - range.length
            + (insertionText as NSString).length
        #expect((result as NSString).length == expectedLength)
    }
}
