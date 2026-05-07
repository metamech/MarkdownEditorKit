import AppKit
import SwiftUI

/// `NSViewRepresentable` that wraps an `NSScrollView` + ``MarkdownNSTextView``.
///
/// Reads autocomplete providers from ``ResolvedProviders`` and exposes the
/// ``AutocompleteController`` for the overlay to observe.
struct MarkdownTextView: NSViewRepresentable {
    @Binding var text: String
    var providers: ResolvedProviders
    var controller: AutocompleteController

    func makeNSView(context: Context) -> NSScrollView {
        let scrollView = NSScrollView()
        scrollView.hasVerticalScroller = true
        scrollView.hasHorizontalScroller = false
        scrollView.autohidesScrollers = true
        scrollView.borderType = .noBorder

        let textView = MarkdownNSTextView()
        textView.delegate = context.coordinator

        // Style
        textView.font = .monospacedSystemFont(ofSize: NSFont.systemFontSize, weight: .regular)
        textView.textContainerInset = NSSize(width: 10, height: 6)
        textView.isRichText = false
        textView.isAutomaticSpellingCorrectionEnabled = false
        textView.isAutomaticTextCompletionEnabled = false
        textView.isAutomaticLinkDetectionEnabled = false
        textView.isAutomaticQuoteSubstitutionEnabled = false
        textView.isAutomaticDashSubstitutionEnabled = false
        textView.isAutomaticTextReplacementEnabled = false
        textView.usesFontPanel = false
        textView.usesRuler = false
        textView.isVerticallyResizable = true
        textView.isHorizontallyResizable = false
        textView.maxSize = NSSize(width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude)
        textView.textContainer?.widthTracksTextView = true
        textView.backgroundColor = NSColor.textBackgroundColor
        textView.drawsBackground = true

        // Wire commit callback
        textView.commitSuggestion = { [weak coordinator = context.coordinator] text, range in
            coordinator?.commitSuggestion(text: text, range: range)
        }

        scrollView.documentView = textView

        context.coordinator.textView = textView

        return scrollView
    }

    func updateNSView(_ scrollView: NSScrollView, context: Context) {
        guard let textView = scrollView.documentView as? MarkdownNSTextView else { return }

        // Update providers on controller.
        controller.updateProviders(providers)

        // Update paste handler.
        if let handler = providers.paste {
            textView.imagePasteHandler = { data in
                await handler.handleImagePaste(data)
            }
        } else {
            textView.imagePasteHandler = nil
        }

        // Sync text only when external change occurs (avoids selection thrash).
        let snapshot = context.coordinator.lastAppliedSnapshot
        if textView.string != text && snapshot != text {
            let selection = textView.selectedRanges
            textView.string = text
            textView.selectedRanges = selection
            context.coordinator.lastAppliedSnapshot = text
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(text: $text, controller: controller)
    }

    static func dismantleNSView(_ scrollView: NSScrollView, coordinator: Coordinator) {
        coordinator.controller.dismiss()
    }
}

// MARK: - Coordinator

extension MarkdownTextView {
    @MainActor
    final class Coordinator: NSObject, NSTextViewDelegate {
        var text: Binding<String>
        let controller: AutocompleteController
        weak var textView: MarkdownNSTextView?

        /// The last string value we pushed into NSTextView.string.
        /// Used to distinguish external vs. user-typed changes.
        var lastAppliedSnapshot: String

        private let triggerDetector = TriggerDetector()

        init(text: Binding<String>, controller: AutocompleteController) {
            self.text = text
            self.controller = controller
            self.lastAppliedSnapshot = text.wrappedValue
        }

        // MARK: - NSTextViewDelegate

        func textDidChange(_ notification: Notification) {
            guard let tv = notification.object as? NSTextView else { return }
            let newText = tv.string
            // Update binding.
            text.wrappedValue = newText
            lastAppliedSnapshot = newText

            evaluateTrigger(in: tv)
        }

        func textViewDidChangeSelection(_ notification: Notification) {
            guard let tv = notification.object as? NSTextView else { return }
            evaluateTrigger(in: tv)
        }

        // MARK: - Suggestion commit

        func commitSuggestion(text insertionText: String, range: NSRange) {
            guard let tv = textView else { return }
            tv.insertText(insertionText, replacementRange: range)
        }

        // MARK: - Private

        private func evaluateTrigger(in tv: NSTextView) {
            guard let markdownTV = tv as? MarkdownNSTextView else { return }

            let caretLocation: Int
            if let selectedRange = tv.selectedRanges.first?.rangeValue {
                caretLocation = selectedRange.location
            } else {
                controller.dismiss()
                return
            }

            let match = triggerDetector.detect(
                in: tv.string,
                caretLocation: caretLocation,
                hasMarkedText: tv.hasMarkedText()
            )

            let caretRect = caretGeometryRect(for: tv, at: caretLocation)
            markdownTV.autocompleteController = controller
            controller.handleTrigger(match: match, caretRect: caretRect)
        }

        private func caretGeometryRect(for tv: NSTextView, at caretLocation: Int) -> CGRect {
            guard
                let layoutManager = tv.layoutManager,
                let textContainer = tv.textContainer
            else { return .zero }

            return CaretGeometry.caretRect(
                at: caretLocation,
                layoutManager: layoutManager,
                textContainer: textContainer,
                containerOrigin: tv.textContainerOrigin
            ) ?? .zero
        }
    }
}
