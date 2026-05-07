import Foundation

/// Canonical inline placeholder for image pastes.
///
/// ADR-023 specifies the image-paste UX (placeholder + open-browser affordance)
/// but does not define the placeholder markdown. This constant is the
/// canonical value the package inserts when no host-supplied text is provided.
/// Hosts may use it verbatim or substitute their own string via
/// `PasteResolution.insert`.
public enum ImagePastePlaceholder {
    /// Default markdown placeholder inserted on image paste.
    public static let markdown = "![Uploading image…](upload-pending)"
}

/// Outcome returned by ``PasteHandler/handleImagePaste(_:)``.
public enum PasteResolution: Sendable {
    /// Replace the paste site with `text` (e.g. a Markdown image link or placeholder).
    case insert(String)

    /// The handler took full responsibility; the editor takes no further action.
    case handled

    /// The handler could not process the paste; the editor ignores the data silently.
    case cancel
}

/// Handles image data pasted into the editor.
///
/// The package detects image data on the pasteboard and delegates entirely to this
/// handler. Inject via `.pasteHandler(_:)`. If no handler is set the editor
/// falls through to default pasteboard behaviour.
///
/// Implementations must be GitHub-agnostic at the protocol level; a HashtagGitHub
/// host may open an upload page, while Tenrec-Terminal may insert a local path.
public protocol PasteHandler: Sendable {
    /// Called when the user pastes image data.
    ///
    /// - Parameter data: Raw image bytes from the pasteboard.
    /// - Returns: A ``PasteResolution`` directing the editor how to proceed.
    func handleImagePaste(_ data: Data) async -> PasteResolution
}
