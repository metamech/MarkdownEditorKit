import AppKit
import Foundation

/// `NSTextView` subclass that adds image-paste interception and autocomplete key forwarding.
///
/// Key interception uses `doCommand(by:)` so only autocomplete-relevant actions are
/// consumed when the overlay is visible; all other actions follow the default responder chain.
final class MarkdownNSTextView: NSTextView {
    // MARK: - Dependencies (set by Coordinator)

    /// The autocomplete controller owned by the Coordinator.
    weak var autocompleteController: AutocompleteController?

    /// Called by the Coordinator when an autocomplete suggestion should be committed.
    var commitSuggestion: ((String, NSRange) -> Void)?

    /// Called when the user pastes image data (nil = use default paste behaviour).
    var imagePasteHandler: ((Data) async -> PasteResolution)?

    // MARK: - Paste override

    override func paste(_ sender: Any?) {
        let pasteboard = NSPasteboard.general

        // Check for image data types.
        let imageTypes: [NSPasteboard.PasteboardType] = [
            .tiff, .png,
            NSPasteboard.PasteboardType(rawValue: "public.jpeg"),
        ]

        if let type = imageTypes.first(where: { pasteboard.data(forType: $0) != nil }),
            let data = pasteboard.data(forType: type)
        {
            if let handler = imagePasteHandler {
                Task { @MainActor [weak self] in
                    guard let self else { return }
                    let resolution = await handler(data)
                    switch resolution {
                    case .insert(let text):
                        self.insertText(text, replacementRange: self.selectedRange())
                    case .handled:
                        break  // Handler took full responsibility.
                    case .cancel:
                        break  // Silently ignore.
                    }
                }
            } else {
                insertText(ImagePastePlaceholder.markdown, replacementRange: selectedRange())
            }
            return
        }

        super.paste(sender)
    }

    // MARK: - Key forwarding

    override func doCommand(by selector: Selector) {
        guard let controller = autocompleteController, controller.isVisible else {
            // Overlay is not visible — let default behaviour run.
            super.doCommand(by: selector)
            return
        }

        switch selector {
        case #selector(NSResponder.insertNewline(_:)),
            #selector(NSResponder.insertNewlineIgnoringFieldEditor(_:)):
            commitSelected()

        case #selector(NSResponder.cancelOperation(_:)):
            controller.dismiss()

        case #selector(NSResponder.moveUp(_:)):
            controller.moveUp()

        case #selector(NSResponder.moveDown(_:)):
            controller.moveDown()

        default:
            super.doCommand(by: selector)
        }
    }

    // MARK: - Private

    private func commitSelected() {
        guard let controller = autocompleteController,
            let query = controller.activeQuery,
            let text = controller.selectedInsertionText()
        else { return }

        commitSuggestion?(text, query.range)
        controller.dismiss()
    }
}
