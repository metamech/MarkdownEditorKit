import Foundation

/// Scans backwards from the caret position to detect an active autocomplete trigger.
///
/// A trigger is `@`, `#`, or `:` that is either at the start of a line or
/// preceded by whitespace. The characters between the trigger and the caret
/// must all be word characters (letters, digits, `-`, `_`, `+` for emoji).
struct TriggerDetector {
    /// The result of a successful backwards scan.
    struct TriggerMatch {
        /// The detected trigger character.
        let trigger: Character
        /// Text typed after the trigger character.
        let prefix: String
        /// UTF-16 range in the full string covering trigger + prefix.
        let range: NSRange
    }

    /// Characters allowed in mention/issue prefixes (`@` and `#`).
    private static let mentionIssueWordSet: Set<Character> = {
        let chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-_"
        return Set(chars)
    }()

    /// Characters allowed in emoji prefixes (`:`).
    private static let emojiWordSet: Set<Character> = {
        let chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-_+"
        return Set(chars)
    }()

    private static let triggers: Set<Character> = ["@", "#", ":"]

    private static let whitespace: Set<Character> = [" ", "\t", "\n", "\r"]

    /// Scans backward from `caretLocation` in `string` to find an active trigger.
    ///
    /// Returns `nil` when:
    /// - No trigger character is found before reaching whitespace or a newline.
    /// - The trigger character is not at the start of a line or after whitespace.
    /// - `hasMarkedText` is `true` (IME composition in progress).
    ///
    /// - Parameters:
    ///   - string: The full document string (UTF-16 based, matches `NSTextView`).
    ///   - caretLocation: Current UTF-16 caret offset.
    ///   - hasMarkedText: Pass `true` to skip detection during IME composition.
    func detect(in string: String, caretLocation: Int, hasMarkedText: Bool) -> TriggerMatch? {
        guard !hasMarkedText, caretLocation > 0 else { return nil }

        let utf16 = string.utf16
        guard caretLocation <= utf16.count else { return nil }

        // Convert UTF-16 caret offset to a String.Index.
        let utf16CaretIdx = utf16.index(utf16.startIndex, offsetBy: caretLocation)
        guard let caretIdx = utf16CaretIdx.samePosition(in: string) else { return nil }

        // Walk backwards collecting word chars until we hit a trigger or abort.
        var idx = caretIdx
        var prefixChars: [Character] = []

        while idx > string.startIndex {
            let prevIdx = string.index(before: idx)
            let ch = string[prevIdx]

            if Self.triggers.contains(ch) {
                // Check that what precedes the trigger is whitespace / newline / start.
                let triggerIsValid: Bool
                if prevIdx == string.startIndex {
                    triggerIsValid = true
                } else {
                    let beforeTrigger = string.index(before: prevIdx)
                    triggerIsValid = Self.whitespace.contains(string[beforeTrigger])
                }

                guard triggerIsValid else { return nil }

                let prefixString = String(prefixChars.reversed())

                // Compute UTF-16 offset for the trigger character position.
                let triggerUTF16Start =
                    prevIdx.samePosition(in: utf16) ?? utf16.startIndex
                let triggerUTF16Offset = utf16.distance(
                    from: utf16.startIndex, to: triggerUTF16Start)
                let length = caretLocation - triggerUTF16Offset
                let range = NSRange(location: triggerUTF16Offset, length: length)

                return TriggerMatch(trigger: ch, prefix: prefixString, range: range)
            }

            // Check whether the character is allowed in a word prefix.
            guard Self.mentionIssueWordSet.contains(ch) || Self.emojiWordSet.contains(ch)
            else {
                return nil
            }

            prefixChars.append(ch)
            idx = prevIdx
        }

        return nil
    }
}
