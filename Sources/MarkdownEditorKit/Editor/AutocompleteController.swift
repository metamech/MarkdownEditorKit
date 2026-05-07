import Foundation
import SwiftUI

/// Holds the union of resolved providers passed from the environment to ``MarkdownTextView``.
struct ResolvedProviders {
    var mention: (any MentionProvider)?
    var issue: (any IssueProvider)?
    var emoji: (any EmojiProvider)?
    var paste: (any PasteHandler)?
}

/// The set of suggestions that the overlay can display.
enum AutocompleteSuggestions: Sendable {
    case mentions([MentionSuggestion])
    case issues([IssueSuggestion])
    case emojis([EmojiSuggestion])
    case empty

    var count: Int {
        switch self {
        case .mentions(let s): return s.count
        case .issues(let s): return s.count
        case .emojis(let s): return s.count
        case .empty: return 0
        }
    }
}

/// View-model that manages autocomplete state and debounced provider fetches.
///
/// Owned by the `MarkdownTextView` coordinator; observed by ``AutocompleteOverlay``.
@MainActor
@Observable
final class AutocompleteController {
    // MARK: - Observable state

    /// Whether the autocomplete overlay should be shown.
    private(set) var isVisible: Bool = false

    /// The current list of suggestions to display.
    private(set) var suggestions: AutocompleteSuggestions = .empty

    /// Index of the highlighted row in the overlay (0-based).
    var selectedIndex: Int = 0

    /// The caret rectangle in the editor container's SwiftUI coordinate space.
    var caretRect: CGRect = .zero

    // MARK: - Internal state

    /// The active query used to derive suggestions.
    private(set) var activeQuery: AutocompleteQuery?

    private var providers = ResolvedProviders()
    private var fetchTask: Task<Void, Never>?
    private let debouncer: Debouncer

    // MARK: - Init

    init() {
        debouncer = Debouncer(duration: .milliseconds(250))
    }

    // MARK: - Provider injection

    /// Updates the providers used for suggestion fetches.
    func updateProviders(_ resolved: ResolvedProviders) {
        providers = resolved
    }

    // MARK: - Trigger / dismiss

    /// Called by the coordinator when the caret moves or text changes.
    ///
    /// Schedules a debounced fetch if a `match` is provided; dismisses otherwise.
    func handleTrigger(match: TriggerDetector.TriggerMatch?, caretRect: CGRect) {
        self.caretRect = caretRect

        guard let match else {
            dismiss()
            return
        }

        // Guard: dismiss if no provider is registered for the trigger.
        guard hasProvider(for: match.trigger) else {
            dismiss()
            return
        }

        let query = AutocompleteQuery(
            prefix: match.prefix,
            range: match.range,
            trigger: match.trigger
        )

        activeQuery = query

        debouncer.schedule { [weak self] in
            await self?.fetch(query: query)
        }
    }

    /// Immediately dismisses the overlay and cancels any pending fetch.
    func dismiss() {
        debouncer.cancel()
        fetchTask?.cancel()
        fetchTask = nil
        isVisible = false
        suggestions = .empty
        selectedIndex = 0
        activeQuery = nil
    }

    // MARK: - Navigation

    /// Moves the selection up by one row.
    func moveUp() {
        let count = suggestions.count
        guard count > 0 else { return }
        selectedIndex = (selectedIndex - 1 + count) % count
    }

    /// Moves the selection down by one row.
    func moveDown() {
        let count = suggestions.count
        guard count > 0 else { return }
        selectedIndex = (selectedIndex + 1) % count
    }

    // MARK: - Commit

    /// Returns the insertion text for the currently selected suggestion, or `nil`.
    func selectedInsertionText() -> String? {
        switch suggestions {
        case .mentions(let s):
            guard selectedIndex < s.count else { return nil }
            return s[selectedIndex].insertionText
        case .issues(let s):
            guard selectedIndex < s.count else { return nil }
            return s[selectedIndex].insertionText
        case .emojis(let s):
            guard selectedIndex < s.count else { return nil }
            return s[selectedIndex].insertionText
        case .empty:
            return nil
        }
    }

    /// Returns the insertion text for the suggestion at `index`, or `nil`.
    func insertionText(at index: Int) -> String? {
        switch suggestions {
        case .mentions(let s):
            guard index < s.count else { return nil }
            return s[index].insertionText
        case .issues(let s):
            guard index < s.count else { return nil }
            return s[index].insertionText
        case .emojis(let s):
            guard index < s.count else { return nil }
            return s[index].insertionText
        case .empty:
            return nil
        }
    }

    // MARK: - Private

    private func hasProvider(for trigger: Character) -> Bool {
        switch trigger {
        case "@": return providers.mention != nil
        case "#": return providers.issue != nil
        case ":": return providers.emoji != nil
        default: return false
        }
    }

    private func fetch(query: AutocompleteQuery) async {
        fetchTask?.cancel()
        let capturedProviders = providers

        let task = Task { [weak self] in
            guard let self else { return }

            do {
                let result: AutocompleteSuggestions

                switch query.trigger {
                case "@":
                    guard let provider = capturedProviders.mention else {
                        self.hide()
                        return
                    }
                    let items = try await provider.searchUsers(query: query)
                    try Task.checkCancellation()
                    result = .mentions(items)

                case "#":
                    guard let provider = capturedProviders.issue else {
                        self.hide()
                        return
                    }
                    let items = try await provider.searchIssues(query: query)
                    try Task.checkCancellation()
                    result = .issues(items)

                case ":":
                    guard let provider = capturedProviders.emoji else {
                        self.hide()
                        return
                    }
                    // Synchronous — no await needed.
                    let items = provider.search(prefix: query.prefix)
                    result = .emojis(items)

                default:
                    self.hide()
                    return
                }

                // Only apply if this is still the active query.
                guard self.activeQuery == query else { return }

                if result.count == 0 {
                    self.hide()
                } else {
                    self.suggestions = result
                    self.selectedIndex = 0
                    self.isVisible = true
                }

            } catch is CancellationError {
                // Task was cancelled — discard results silently.
            } catch {
                // Provider threw — hide overlay.
                self.hide()
            }
        }

        fetchTask = task
    }

    private func hide() {
        isVisible = false
        suggestions = .empty
        selectedIndex = 0
    }
}
