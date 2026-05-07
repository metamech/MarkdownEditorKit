import Foundation
import Testing

@testable import MarkdownEditorKit

@Suite("TriggerDetector")
struct TriggerDetectorTests {
    private let detector = TriggerDetector()

    // MARK: - Trigger at start of buffer

    @Test("@ at start of buffer with no prefix returns empty prefix")
    func atTriggerAtStartOfBuffer() {
        let string = "@"
        let match = detector.detect(in: string, caretLocation: 1, hasMarkedText: false)
        let m = try! #require(match)
        #expect(m.trigger == "@")
        #expect(m.prefix == "")
        #expect(m.range == NSRange(location: 0, length: 1))
    }

    @Test("# at start of buffer with no prefix returns empty prefix")
    func hashTriggerAtStartOfBuffer() {
        let string = "#"
        let match = detector.detect(in: string, caretLocation: 1, hasMarkedText: false)
        let m = try! #require(match)
        #expect(m.trigger == "#")
        #expect(m.prefix == "")
        #expect(m.range == NSRange(location: 0, length: 1))
    }

    @Test(": at start of buffer with no prefix returns empty prefix")
    func colonTriggerAtStartOfBuffer() {
        let string = ":"
        let match = detector.detect(in: string, caretLocation: 1, hasMarkedText: false)
        let m = try! #require(match)
        #expect(m.trigger == ":")
        #expect(m.prefix == "")
        #expect(m.range == NSRange(location: 0, length: 1))
    }

    // MARK: - Trigger with prefix

    @Test("@al with caret at end returns trigger=@ prefix=al")
    func atTriggerWithPrefix() {
        let string = "@al"
        let match = detector.detect(in: string, caretLocation: 3, hasMarkedText: false)
        let m = try! #require(match)
        #expect(m.trigger == "@")
        #expect(m.prefix == "al")
        #expect(m.range == NSRange(location: 0, length: 3))
    }

    @Test("#42 with caret at end returns trigger=# prefix=42")
    func hashTriggerWithPrefix() {
        let string = "#42"
        let match = detector.detect(in: string, caretLocation: 3, hasMarkedText: false)
        let m = try! #require(match)
        #expect(m.trigger == "#")
        #expect(m.prefix == "42")
        #expect(m.range == NSRange(location: 0, length: 3))
    }

    @Test(":thumb with caret at end returns trigger=: prefix=thumb")
    func colonTriggerWithPrefix() {
        let string = ":thumb"
        let match = detector.detect(in: string, caretLocation: 6, hasMarkedText: false)
        let m = try! #require(match)
        #expect(m.trigger == ":")
        #expect(m.prefix == "thumb")
        #expect(m.range == NSRange(location: 0, length: 6))
    }

    // MARK: - Trigger mid-line preceded by whitespace

    @Test("Hi @bo mid-line with preceding whitespace succeeds")
    func atTriggerMidLineWithSpace() {
        let string = "Hi @bo"
        let match = detector.detect(in: string, caretLocation: 6, hasMarkedText: false)
        let m = try! #require(match)
        #expect(m.trigger == "@")
        #expect(m.prefix == "bo")
        #expect(m.range == NSRange(location: 3, length: 3))
    }

    @Test("tab-preceded @ trigger succeeds")
    func atTriggerPrecededByTab() {
        let string = "note\t@user"
        let match = detector.detect(in: string, caretLocation: 10, hasMarkedText: false)
        let m = try! #require(match)
        #expect(m.trigger == "@")
        #expect(m.prefix == "user")
    }

    // MARK: - @ mid-token (no preceding whitespace) returns nil

    @Test("email@host mid-token @ returns nil")
    func atMidTokenReturnsNil() {
        let string = "email@host"
        let match = detector.detect(in: string, caretLocation: 10, hasMarkedText: false)
        #expect(match == nil)
    }

    @Test("word# mid-token # returns nil")
    func hashMidTokenReturnsNil() {
        let string = "word#42"
        let match = detector.detect(in: string, caretLocation: 7, hasMarkedText: false)
        #expect(match == nil)
    }

    // MARK: - Whitespace and newline terminate the backward scan

    @Test("space before trigger word aborts scan and returns nil when no trigger found")
    func spaceBeforeWordAbortsNoTrigger() {
        let string = "hello world"
        let match = detector.detect(in: string, caretLocation: 11, hasMarkedText: false)
        #expect(match == nil)
    }

    @Test("newline terminates scan and trigger on next line succeeds")
    func newlinePrecededTriggerSucceeds() {
        let string = "first line\n@query"
        // caret at end (UTF-16 length = 17)
        let caretLocation = (string as NSString).length
        let match = detector.detect(in: string, caretLocation: caretLocation, hasMarkedText: false)
        let m = try! #require(match)
        #expect(m.trigger == "@")
        #expect(m.prefix == "query")
    }

    @Test("trigger mid-word followed by non-trigger chars returns nil")
    func midWordWithoutTriggerReturnsNil() {
        let string = "hello"
        let match = detector.detect(in: string, caretLocation: 5, hasMarkedText: false)
        #expect(match == nil)
    }

    // MARK: - Emoji prefix allows + character

    @Test(":+1 emoji prefix with plus returns trigger=: prefix=+1")
    func emojiPrefixWithPlus() {
        let string = ":+1"
        let match = detector.detect(in: string, caretLocation: 3, hasMarkedText: false)
        let m = try! #require(match)
        #expect(m.trigger == ":")
        #expect(m.prefix == "+1")
        #expect(m.range == NSRange(location: 0, length: 3))
    }

    @Test("space :+1 emoji prefix with space before trigger succeeds")
    func emojiPrefixWithPlusAfterSpace() {
        let string = "Hello :+1"
        let match = detector.detect(in: string, caretLocation: 9, hasMarkedText: false)
        let m = try! #require(match)
        #expect(m.trigger == ":")
        #expect(m.prefix == "+1")
    }

    // MARK: - hasMarkedText suppresses detection

    @Test("hasMarkedText=true always returns nil")
    func hasMarkedTextReturnsNil() {
        let string = "@alice"
        let match = detector.detect(in: string, caretLocation: 6, hasMarkedText: true)
        #expect(match == nil)
    }

    // MARK: - caretLocation edge cases

    @Test("caretLocation=0 returns nil")
    func caretAtZeroReturnsNil() {
        let string = "@alice"
        let match = detector.detect(in: string, caretLocation: 0, hasMarkedText: false)
        #expect(match == nil)
    }

    @Test("caretLocation beyond string length returns nil")
    func caretBeyondStringLengthReturnsNil() {
        let string = "@al"
        let match = detector.detect(in: string, caretLocation: 100, hasMarkedText: false)
        #expect(match == nil)
    }

    // MARK: - Multibyte / emoji content

    @Test("multibyte emoji before trigger does not corrupt UTF-16 range")
    func multibyteEmojiBeforeTrigger() {
        // "👋 @bob" — "👋" is U+1F44B, encoded as 2 UTF-16 code units
        let string = "👋 @bob"
        let utf16Length = (string as NSString).length
        let match = detector.detect(in: string, caretLocation: utf16Length, hasMarkedText: false)
        let m = try! #require(match)
        #expect(m.trigger == "@")
        #expect(m.prefix == "bob")
        // "👋 " = 2 + 1 = 3 UTF-16 units before "@bob"
        // "@bob" = 4 UTF-16 units, so range location should be 3, length 4
        #expect(m.range.location == 3)
        #expect(m.range.length == 4)
    }

    @Test("multibyte emoji in prefix is not allowed (prefix chars are ASCII only)")
    func multibyteEmojiInPrefixReturnsNil() {
        // "@👋" — emoji is not in mentionIssueWordSet
        let string = "@👋"
        let utf16Length = (string as NSString).length
        // caret after the emoji — the detector should fail on the emoji char
        let match = detector.detect(in: string, caretLocation: utf16Length, hasMarkedText: false)
        #expect(match == nil)
    }

    // MARK: - Caret immediately after a non-trigger word

    @Test("caret immediately after plain word with no trigger returns nil")
    func caretAfterPlainWordReturnsNil() {
        let string = "hello"
        let match = detector.detect(in: string, caretLocation: 5, hasMarkedText: false)
        #expect(match == nil)
    }

    @Test("caret after plain word preceded by @ in separate token returns nil (no whitespace)")
    func caretAfterWordNoWhitespaceBeforeTrigger() {
        // "foo@bar" — @ is mid-token
        let string = "foo@bar"
        let match = detector.detect(in: string, caretLocation: 7, hasMarkedText: false)
        #expect(match == nil)
    }
}
