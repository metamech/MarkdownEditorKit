import Foundation
import Testing

@testable import MarkdownEditorKit

// MARK: - Fake providers for testing

/// A ``MentionProvider`` that records query calls and returns a configurable result.
private final class RecordingMentionProvider: MentionProvider, @unchecked Sendable {
    var callCount = 0
    var lastQuery: AutocompleteQuery?
    var stubbedResults: [MentionSuggestion]
    /// When non-nil, the provider sleeps this long before returning — simulates latency.
    var delay: Duration?

    init(results: [MentionSuggestion] = [], delay: Duration? = nil) {
        stubbedResults = results
        self.delay = delay
    }

    func searchUsers(query: AutocompleteQuery) async throws -> [MentionSuggestion] {
        callCount += 1
        lastQuery = query
        if let d = delay {
            try await Task.sleep(for: d)
        }
        try Task.checkCancellation()
        return stubbedResults
    }
}

/// A ``EmojiProvider`` stub for emoji trigger tests.
private struct FixedEmojiProvider: EmojiProvider {
    let results: [EmojiSuggestion]
    func search(prefix: String) -> [EmojiSuggestion] { results }
}

// MARK: - Helper factories

private func makeMentionMatch(prefix: String = "al") -> TriggerDetector.TriggerMatch {
    TriggerDetector.TriggerMatch(
        trigger: "@",
        prefix: prefix,
        range: NSRange(location: 0, length: 1 + prefix.utf16.count)
    )
}

private func makeIssueMatch(prefix: String = "1") -> TriggerDetector.TriggerMatch {
    TriggerDetector.TriggerMatch(
        trigger: "#",
        prefix: prefix,
        range: NSRange(location: 0, length: 1 + prefix.utf16.count)
    )
}

private func makeEmojiMatch(prefix: String = "thumb") -> TriggerDetector.TriggerMatch {
    TriggerDetector.TriggerMatch(
        trigger: ":",
        prefix: prefix,
        range: NSRange(location: 0, length: 1 + prefix.utf16.count)
    )
}

// MARK: - Test suite

@Suite("AutocompleteController")
@MainActor
struct AutocompleteControllerTests {
    // MARK: - No trigger → not visible

    @Test("handleTrigger with nil match sets isVisible=false")
    func noMatchHidesOverlay() async throws {
        let controller = AutocompleteController()
        controller.handleTrigger(match: nil, caretRect: .zero)
        #expect(controller.isVisible == false)
        #expect(controller.activeQuery == nil)
    }

    @Test("handleTrigger with match but no registered provider dismisses")
    func matchWithNoProviderDismisses() async throws {
        let controller = AutocompleteController()
        // No providers injected — mention provider is nil.
        controller.handleTrigger(match: makeMentionMatch(), caretRect: .zero)
        // After debounce wait: should still be hidden.
        try await Task.sleep(for: .milliseconds(800))
        #expect(controller.isVisible == false)
    }

    // MARK: - With trigger and matching suggestions → visible after debounce

    @Test("handleTrigger with matching mention provider populates suggestions after debounce")
    func matchWithProviderPopulatesSuggestions() async throws {
        let controller = AutocompleteController()
        let alice = MentionSuggestion(
            id: "alice", displayText: "@alice", insertionText: "@alice")
        let provider = RecordingMentionProvider(results: [alice])
        controller.updateProviders(
            ResolvedProviders(mention: provider, issue: nil, emoji: nil, paste: nil))

        controller.handleTrigger(match: makeMentionMatch(prefix: "al"), caretRect: .zero)

        // Before debounce: not yet visible.
        #expect(controller.isVisible == false)

        // Wait for debounce (250 ms) + fetch + margin.
        try await Task.sleep(for: .milliseconds(800))

        #expect(controller.isVisible == true)
        #expect(controller.suggestions.count == 1)
    }

    // MARK: - Rapid two calls → only second fetch observed

    @Test("two rapid handleTrigger calls result in only second query being active")
    func twoRapidCallsOnlySecondQueryActive() async throws {
        let controller = AutocompleteController()
        let alice = MentionSuggestion(
            id: "alice", displayText: "@alice", insertionText: "@alice")
        let albert = MentionSuggestion(
            id: "albert", displayText: "@albert", insertionText: "@albert")
        let provider = RecordingMentionProvider(results: [alice, albert])
        controller.updateProviders(
            ResolvedProviders(mention: provider, issue: nil, emoji: nil, paste: nil))

        // First trigger fires but is immediately superseded.
        controller.handleTrigger(match: makeMentionMatch(prefix: "a"), caretRect: .zero)

        // Very short pause — still within debounce window.
        try await Task.sleep(for: .milliseconds(10))

        // Second trigger.
        controller.handleTrigger(match: makeMentionMatch(prefix: "al"), caretRect: .zero)

        // Wait for debounce + fetch.
        try await Task.sleep(for: .milliseconds(800))

        // The active query should reflect the second prefix.
        #expect(controller.activeQuery?.prefix == "al")
        #expect(controller.isVisible == true)
    }

    // MARK: - dismiss() cancels in-flight and clears state

    @Test("dismiss clears isVisible, suggestions, selectedIndex, and activeQuery")
    func dismissClearsState() async throws {
        let controller = AutocompleteController()
        let alice = MentionSuggestion(
            id: "alice", displayText: "@alice", insertionText: "@alice")
        let provider = RecordingMentionProvider(results: [alice])
        controller.updateProviders(
            ResolvedProviders(mention: provider, issue: nil, emoji: nil, paste: nil))

        controller.handleTrigger(match: makeMentionMatch(prefix: "al"), caretRect: .zero)
        try await Task.sleep(for: .milliseconds(800))

        // Confirm it became visible first.
        #expect(controller.isVisible == true)

        controller.dismiss()

        #expect(controller.isVisible == false)
        #expect(controller.suggestions.count == 0)
        #expect(controller.selectedIndex == 0)
        #expect(controller.activeQuery == nil)
    }

    @Test("dismiss cancels in-flight slow provider and leaves isVisible=false")
    func dismissCancelsInFlight() async throws {
        let controller = AutocompleteController()
        // Slow provider — takes 500 ms to respond.
        let alice = MentionSuggestion(
            id: "alice", displayText: "@alice", insertionText: "@alice")
        let provider = RecordingMentionProvider(
            results: [alice], delay: .milliseconds(500))
        controller.updateProviders(
            ResolvedProviders(mention: provider, issue: nil, emoji: nil, paste: nil))

        controller.handleTrigger(match: makeMentionMatch(prefix: "al"), caretRect: .zero)

        // Wait for debounce to fire but not for provider to finish.
        // Debounce fires at ~250 ms; provider returns at ~750 ms. 450 ms is safely in between.
        try await Task.sleep(for: .milliseconds(450))

        // Dismiss while fetch is in-flight.
        controller.dismiss()

        // Give enough time for the now-cancelled fetch to have returned.
        try await Task.sleep(for: .milliseconds(600))

        // Results from the cancelled fetch must not have been applied.
        #expect(controller.isVisible == false)
    }

    // MARK: - Navigation: moveDown wraps / clamps

    @Test("moveDown advances selectedIndex and wraps around")
    func moveDownWraps() async throws {
        let controller = AutocompleteController()
        let suggestions = [
            MentionSuggestion(id: "a", displayText: "@a", insertionText: "@a"),
            MentionSuggestion(id: "b", displayText: "@b", insertionText: "@b"),
            MentionSuggestion(id: "c", displayText: "@c", insertionText: "@c"),
        ]
        let provider = RecordingMentionProvider(results: suggestions)
        controller.updateProviders(
            ResolvedProviders(mention: provider, issue: nil, emoji: nil, paste: nil))

        controller.handleTrigger(match: makeMentionMatch(prefix: ""), caretRect: .zero)
        try await Task.sleep(for: .milliseconds(800))

        #expect(controller.selectedIndex == 0)
        controller.moveDown()
        #expect(controller.selectedIndex == 1)
        controller.moveDown()
        #expect(controller.selectedIndex == 2)
        // Wrap around.
        controller.moveDown()
        #expect(controller.selectedIndex == 0)
    }

    @Test("moveUp decrements selectedIndex and wraps around")
    func moveUpWraps() async throws {
        let controller = AutocompleteController()
        let suggestions = [
            MentionSuggestion(id: "a", displayText: "@a", insertionText: "@a"),
            MentionSuggestion(id: "b", displayText: "@b", insertionText: "@b"),
        ]
        let provider = RecordingMentionProvider(results: suggestions)
        controller.updateProviders(
            ResolvedProviders(mention: provider, issue: nil, emoji: nil, paste: nil))

        controller.handleTrigger(match: makeMentionMatch(prefix: ""), caretRect: .zero)
        try await Task.sleep(for: .milliseconds(800))

        #expect(controller.selectedIndex == 0)
        // Wrap from 0 → last index.
        controller.moveUp()
        #expect(controller.selectedIndex == 1)
        controller.moveUp()
        #expect(controller.selectedIndex == 0)
    }

    @Test("moveDown on empty suggestions is a no-op")
    func moveDownOnEmptyIsNoOp() {
        let controller = AutocompleteController()
        controller.moveDown()
        #expect(controller.selectedIndex == 0)
    }

    @Test("moveUp on empty suggestions is a no-op")
    func moveUpOnEmptyIsNoOp() {
        let controller = AutocompleteController()
        controller.moveUp()
        #expect(controller.selectedIndex == 0)
    }

    // MARK: - selectedInsertionText returns suggestion at selectedIndex

    @Test("selectedInsertionText returns insertion text for selected mention")
    func selectedInsertionTextReturnsMention() async throws {
        let controller = AutocompleteController()
        let alice = MentionSuggestion(
            id: "alice", displayText: "@alice", insertionText: "@alice")
        let bob = MentionSuggestion(id: "bob", displayText: "@bob", insertionText: "@bob")
        let provider = RecordingMentionProvider(results: [alice, bob])
        controller.updateProviders(
            ResolvedProviders(mention: provider, issue: nil, emoji: nil, paste: nil))

        controller.handleTrigger(match: makeMentionMatch(prefix: ""), caretRect: .zero)
        try await Task.sleep(for: .milliseconds(800))

        #expect(controller.selectedInsertionText() == "@alice")
        controller.moveDown()
        #expect(controller.selectedInsertionText() == "@bob")
    }

    @Test("selectedInsertionText returns nil when suggestions are empty")
    func selectedInsertionTextNilWhenEmpty() {
        let controller = AutocompleteController()
        #expect(controller.selectedInsertionText() == nil)
    }

    // MARK: - insertionText(at:) out-of-bounds returns nil

    @Test("insertionText(at:) returns nil for out-of-bounds index")
    func insertionTextOutOfBoundsReturnsNil() async throws {
        let controller = AutocompleteController()
        let alice = MentionSuggestion(
            id: "alice", displayText: "@alice", insertionText: "@alice")
        let provider = RecordingMentionProvider(results: [alice])
        controller.updateProviders(
            ResolvedProviders(mention: provider, issue: nil, emoji: nil, paste: nil))

        controller.handleTrigger(match: makeMentionMatch(prefix: ""), caretRect: .zero)
        try await Task.sleep(for: .milliseconds(800))

        #expect(controller.insertionText(at: 0) == "@alice")
        #expect(controller.insertionText(at: 1) == nil)
        #expect(controller.insertionText(at: 99) == nil)
    }

    // MARK: - Emoji trigger (synchronous provider)

    @Test("emoji trigger populates emojis after debounce")
    func emojiTriggerPopulatesEmojis() async throws {
        let controller = AutocompleteController()
        let thumbsup = EmojiSuggestion(
            id: "thumbsup", glyph: "👍", insertionText: ":thumbsup:")
        let emojiProvider = FixedEmojiProvider(results: [thumbsup])
        controller.updateProviders(
            ResolvedProviders(mention: nil, issue: nil, emoji: emojiProvider, paste: nil))

        controller.handleTrigger(match: makeEmojiMatch(prefix: "thumb"), caretRect: .zero)
        try await Task.sleep(for: .milliseconds(800))

        #expect(controller.isVisible == true)
        #expect(controller.suggestions.count == 1)
        #expect(controller.selectedInsertionText() == ":thumbsup:")
    }

    // MARK: - caretRect is updated

    @Test("handleTrigger updates caretRect")
    func caretRectIsUpdated() {
        let controller = AutocompleteController()
        let rect = CGRect(x: 10, y: 20, width: 2, height: 16)
        controller.handleTrigger(match: nil, caretRect: rect)
        #expect(controller.caretRect == rect)
    }

    // MARK: - No results → overlay stays hidden

    @Test("handleTrigger with provider returning empty array keeps isVisible=false")
    func emptyResultsKeepsHidden() async throws {
        let controller = AutocompleteController()
        let provider = RecordingMentionProvider(results: [])
        controller.updateProviders(
            ResolvedProviders(mention: provider, issue: nil, emoji: nil, paste: nil))

        controller.handleTrigger(match: makeMentionMatch(prefix: "zzz"), caretRect: .zero)
        try await Task.sleep(for: .milliseconds(800))

        #expect(controller.isVisible == false)
    }
}
