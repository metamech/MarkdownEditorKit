import AppKit
import Foundation

/// Computes the caret rectangle in the text container's local coordinate space
/// and applies screen-edge clamping for overlay placement.
enum CaretGeometry {
    /// Returns the bounding rect of the glyph at `caretLocation` in the text container's
    /// coordinate space (with `textContainerOrigin` applied), or `nil` if layout is unavailable.
    ///
    /// - Parameters:
    ///   - caretLocation: UTF-16 caret offset in the text storage.
    ///   - layoutManager: The `NSLayoutManager` for the text view.
    ///   - textContainer: The `NSTextContainer` for the text view.
    ///   - containerOrigin: The `textContainerOrigin` of the NSTextView.
    static func caretRect(
        at caretLocation: Int,
        layoutManager: NSLayoutManager,
        textContainer: NSTextContainer,
        containerOrigin: CGPoint
    ) -> CGRect? {
        layoutManager.ensureLayout(for: textContainer)

        let glyphRange: NSRange
        if caretLocation >= layoutManager.numberOfGlyphs {
            guard layoutManager.numberOfGlyphs > 0 else { return nil }
            glyphRange = NSRange(
                location: layoutManager.numberOfGlyphs - 1, length: 1)
        } else {
            glyphRange = layoutManager.glyphRange(
                forCharacterRange: NSRange(location: caretLocation, length: 0),
                actualCharacterRange: nil
            )
        }

        let glyphRect = layoutManager.boundingRect(forGlyphRange: glyphRange, in: textContainer)

        return CGRect(
            x: glyphRect.minX + containerOrigin.x,
            y: glyphRect.minY + containerOrigin.y,
            width: glyphRect.width,
            height: glyphRect.height
        )
    }

    /// Clamps an overlay origin so it stays within `containerSize`.
    ///
    /// Horizontal: pins the overlay's right edge to `containerSize.width`.
    /// Vertical: flips the overlay above the caret when the overlay would overflow below.
    ///
    /// - Parameters:
    ///   - caretRect: The caret bounding rect in container coordinates.
    ///   - overlaySize: Desired size of the autocomplete overlay.
    ///   - containerSize: The size of the enclosing container.
    /// - Returns: The clamped `CGPoint` origin for the overlay, in container coordinates.
    static func clampedOverlayOrigin(
        caretRect: CGRect,
        overlaySize: CGSize,
        containerSize: CGSize
    ) -> CGPoint {
        // Prefer to place overlay just below the caret.
        var x = caretRect.minX
        var y = caretRect.maxY

        // Clamp horizontal so overlay doesn't exceed container width.
        let maxX = containerSize.width - overlaySize.width
        x = min(x, max(0, maxX))

        // Flip above caret if overlay would overflow below.
        if y + overlaySize.height > containerSize.height {
            y = caretRect.minY - overlaySize.height
        }

        // Keep y non-negative.
        y = max(0, y)

        return CGPoint(x: x, y: y)
    }
}
