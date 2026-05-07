import Foundation

/// An in-memory ``PasteHandler`` that records received image data payloads.
///
/// Suitable for SwiftUI previews and unit tests. Each call to
/// ``handleImagePaste(_:)`` appends the raw bytes to an internal log and
/// returns `.insert(ImagePastePlaceholder.markdown)`.
///
/// Data is held only in memory and is never written to disk or logged.
public actor InMemoryPasteHandler: PasteHandler {
    private var _receivedData: [Data] = []

    /// Creates an ``InMemoryPasteHandler`` with an empty data log.
    public init() {}

    /// All image-data payloads received since this instance was created,
    /// in the order they arrived.
    public var receivedData: [Data] {
        _receivedData
    }

    /// Records `data` and returns `.insert(ImagePastePlaceholder.markdown)`.
    ///
    /// - Parameter data: Raw image bytes from the pasteboard.
    /// - Returns: `.insert` with the canonical ``ImagePastePlaceholder/markdown`` string.
    public func handleImagePaste(_ data: Data) async -> PasteResolution {
        _receivedData.append(data)
        return .insert(ImagePastePlaceholder.markdown)
    }
}
