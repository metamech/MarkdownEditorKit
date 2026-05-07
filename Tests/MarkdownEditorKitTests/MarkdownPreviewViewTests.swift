import Testing
@testable import MarkdownEditorKit

@Suite("String.headingLevel()")
struct HeadingLevelTests {
    // MARK: - Valid headings

    @Test("single hash")
    func singleHash() {
        let result = "# Hello".headingLevel()
        #expect(result?.level == 1)
        #expect(result?.text == "Hello")
    }

    @Test("triple hash")
    func tripleHash() {
        let result = "### Triple".headingLevel()
        #expect(result?.level == 3)
        #expect(result?.text == "Triple")
    }

    @Test("six hashes")
    func sixHashes() {
        let result = "###### Six".headingLevel()
        #expect(result?.level == 6)
        #expect(result?.text == "Six")
    }

    @Test("bare hash returns (1, empty string)")
    func bareHash() {
        // count == hashes triggers the early-return path: (hashes, "")
        let result = "#".headingLevel()
        #expect(result?.level == 1)
        #expect(result?.text == "")
    }

    @Test("hash followed only by space returns (2, empty string)")
    func hashWithTrailingSpace() {
        // rest is " "; trimmingCharacters(in: .whitespaces) → ""
        let result = "## ".headingLevel()
        #expect(result?.level == 2)
        #expect(result?.text == "")
    }

    // MARK: - Invalid / nil cases

    @Test("seven hashes returns nil")
    func sevenHashes() {
        #expect("####### Seven".headingLevel() == nil)
    }

    @Test("hash without space returns nil")
    func noSpace() {
        #expect("#NoSpace".headingLevel() == nil)
    }

    @Test("plain text returns nil")
    func plainText() {
        #expect("Plain text".headingLevel() == nil)
    }
}
