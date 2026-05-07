import Foundation
import Testing

@testable import MarkdownEditorKit

@Suite("StubProviders")
struct StubProviderTests {
    // MARK: - Fixtures

    private static let mentionSuggestions: [MentionSuggestion] = [
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

    private static let issueSuggestions: [IssueSuggestion] = [
        IssueSuggestion(
            id: 1, displayText: "#1 Fix login crash", secondaryText: "open",
            insertionText: "#1"),
        IssueSuggestion(
            id: 12, displayText: "#12 Improve onboarding", secondaryText: "closed",
            insertionText: "#12"),
        IssueSuggestion(
            id: 42, displayText: "#42 Dark mode support", secondaryText: "open",
            insertionText: "#42"),
    ]

    private static let emojiSuggestions: [EmojiSuggestion] = [
        EmojiSuggestion(id: "thumbsup", glyph: "👍", insertionText: ":thumbsup:"),
        EmojiSuggestion(id: "thumbsdown", glyph: "👎", insertionText: ":thumbsdown:"),
        EmojiSuggestion(id: "thinking", glyph: "🤔", insertionText: ":thinking:"),
        EmojiSuggestion(id: "tada", glyph: "🎉", insertionText: ":tada:"),
    ]

    private func mentionQuery(_ prefix: String) -> AutocompleteQuery {
        AutocompleteQuery(
            prefix: prefix,
            range: NSRange(location: 0, length: 1 + prefix.utf16.count),
            trigger: "@"
        )
    }

    private func issueQuery(_ prefix: String) -> AutocompleteQuery {
        AutocompleteQuery(
            prefix: prefix,
            range: NSRange(location: 0, length: 1 + prefix.utf16.count),
            trigger: "#"
        )
    }

    // MARK: - InMemoryMentionProvider

    @Test("InMemoryMentionProvider empty prefix returns all suggestions")
    func mentionEmptyPrefixReturnsAll() async throws {
        let provider = InMemoryMentionProvider(suggestions: Self.mentionSuggestions)
        let results = try await provider.searchUsers(query: mentionQuery(""))
        #expect(results.count == 3)
    }

    @Test("InMemoryMentionProvider filters case-insensitive on displayText")
    func mentionFiltersCaseInsensitiveDisplayText() async throws {
        let provider = InMemoryMentionProvider(suggestions: Self.mentionSuggestions)
        let results = try await provider.searchUsers(query: mentionQuery("AL"))
        // "@alice" and "@albert" contain "al" case-insensitively; "@bob" does not.
        #expect(results.count == 2)
        let ids = results.map(\.id)
        #expect(ids.contains("alice"))
        #expect(ids.contains("albert"))
        #expect(!ids.contains("bob"))
    }

    @Test("InMemoryMentionProvider filters on secondaryText")
    func mentionFiltersOnSecondaryText() async throws {
        let provider = InMemoryMentionProvider(suggestions: Self.mentionSuggestions)
        // "Brown" is in secondaryText of bob only.
        let results = try await provider.searchUsers(query: mentionQuery("brown"))
        #expect(results.count == 1)
        #expect(results[0].id == "bob")
    }

    @Test("InMemoryMentionProvider returns empty for no-match query")
    func mentionReturnsEmptyForNoMatch() async throws {
        let provider = InMemoryMentionProvider(suggestions: Self.mentionSuggestions)
        let results = try await provider.searchUsers(query: mentionQuery("zzz"))
        #expect(results.isEmpty)
    }

    @Test("InMemoryMentionProvider exact match returns exactly one result")
    func mentionExactMatchReturnsOne() async throws {
        let provider = InMemoryMentionProvider(suggestions: Self.mentionSuggestions)
        let results = try await provider.searchUsers(query: mentionQuery("bob"))
        #expect(results.count == 1)
        #expect(results[0].id == "bob")
    }

    // MARK: - InMemoryIssueProvider

    @Test("InMemoryIssueProvider empty prefix returns all suggestions")
    func issueEmptyPrefixReturnsAll() async throws {
        let provider = InMemoryIssueProvider(suggestions: Self.issueSuggestions)
        let results = try await provider.searchIssues(query: issueQuery(""))
        #expect(results.count == 3)
    }

    @Test("InMemoryIssueProvider filters case-insensitive on displayText")
    func issueFiltersCaseInsensitiveDisplayText() async throws {
        let provider = InMemoryIssueProvider(suggestions: Self.issueSuggestions)
        // "login" appears in "#1 Fix login crash"
        let results = try await provider.searchIssues(query: issueQuery("LOGIN"))
        #expect(results.count == 1)
        #expect(results[0].id == 1)
    }

    @Test("InMemoryIssueProvider filters on secondaryText (open/closed)")
    func issueFiltersOnSecondaryText() async throws {
        let provider = InMemoryIssueProvider(suggestions: Self.issueSuggestions)
        // "closed" appears only in #12's secondaryText
        let results = try await provider.searchIssues(query: issueQuery("closed"))
        #expect(results.count == 1)
        #expect(results[0].id == 12)
    }

    @Test("InMemoryIssueProvider returns empty for no-match query")
    func issueReturnsEmptyForNoMatch() async throws {
        let provider = InMemoryIssueProvider(suggestions: Self.issueSuggestions)
        let results = try await provider.searchIssues(query: issueQuery("xyzzy"))
        #expect(results.isEmpty)
    }

    @Test("InMemoryIssueProvider filters on number string in displayText")
    func issueFiltersOnNumberString() async throws {
        let provider = InMemoryIssueProvider(suggestions: Self.issueSuggestions)
        // "12" matches both "#12 Improve onboarding" and "#42 Dark mode support"
        // (#42 contains "12"? No — let's check: "#42 Dark mode support" does not contain "12")
        // "#12 Improve onboarding" contains "12" — only 1 match.
        let results = try await provider.searchIssues(query: issueQuery("12"))
        #expect(results.count == 1)
        #expect(results[0].id == 12)
    }

    // MARK: - InMemoryEmojiProvider

    @Test("InMemoryEmojiProvider empty prefix returns all suggestions")
    func emojiEmptyPrefixReturnsAll() {
        let provider = InMemoryEmojiProvider(suggestions: Self.emojiSuggestions)
        let results = provider.search(prefix: "")
        #expect(results.count == 4)
    }

    @Test("InMemoryEmojiProvider prefix-matches id case-insensitively")
    func emojiPrefixMatchesCaseInsensitive() {
        let provider = InMemoryEmojiProvider(suggestions: Self.emojiSuggestions)
        // "THUMB" should match "thumbsup" and "thumbsdown"
        let results = provider.search(prefix: "THUMB")
        #expect(results.count == 2)
        let ids = results.map(\.id)
        #expect(ids.contains("thumbsup"))
        #expect(ids.contains("thumbsdown"))
    }

    @Test("InMemoryEmojiProvider prefix match is prefix-only not substring")
    func emojiPrefixNotSubstring() {
        let provider = InMemoryEmojiProvider(suggestions: Self.emojiSuggestions)
        // "umbs" is a substring of "thumbsup" but not a prefix — should return empty.
        let results = provider.search(prefix: "umbs")
        #expect(results.isEmpty)
    }

    @Test("InMemoryEmojiProvider returns empty for no-match prefix")
    func emojiReturnsEmptyForNoMatch() {
        let provider = InMemoryEmojiProvider(suggestions: Self.emojiSuggestions)
        let results = provider.search(prefix: "zzz")
        #expect(results.isEmpty)
    }

    @Test("InMemoryEmojiProvider exact id prefix returns single match")
    func emojiExactIdPrefixReturnsSingleMatch() {
        let provider = InMemoryEmojiProvider(suggestions: Self.emojiSuggestions)
        let results = provider.search(prefix: "tada")
        #expect(results.count == 1)
        #expect(results[0].id == "tada")
    }

    @Test("InMemoryEmojiProvider longer prefix than any id returns empty")
    func emojiLongerPrefixThanAnyIdReturnsEmpty() {
        let provider = InMemoryEmojiProvider(suggestions: Self.emojiSuggestions)
        let results = provider.search(prefix: "thumbsupextra")
        #expect(results.isEmpty)
    }
}
