import Foundation
import Testing

@testable import MarkdownEditorKit

@Suite("MarkdownDocumentParser")
struct MarkdownDocumentParserTests {

    // MARK: - Structural sanity

    @Test("heading + paragraph + fenced code block parse to three blocks of correct kinds")
    func structuralSanity() throws {
        let source = "# Title\n\nSome text.\n\n```swift\nlet x = 1\n```"
        let blocks = MarkdownDocumentParser.parse(source)
        try #require(blocks.count == 3)
        guard case .heading(let level, _) = blocks[0] else {
            Issue.record("Expected heading at index 0, got \(blocks[0])")
            return
        }
        #expect(level == 1)
        guard case .paragraph = blocks[1] else {
            Issue.record("Expected paragraph at index 1, got \(blocks[1])")
            return
        }
        guard case .codeBlock(let language, _) = blocks[2] else {
            Issue.record("Expected codeBlock at index 2, got \(blocks[2])")
            return
        }
        #expect(language == "swift")
    }

    @Test("code block with no language tag has nil language")
    func codeBlockNoLanguage() {
        let blocks = MarkdownDocumentParser.parse("```\nraw\n```")
        guard case .codeBlock(let language, let src) = blocks.first else {
            Issue.record("Expected a codeBlock")
            return
        }
        #expect(language == nil)
        #expect(src.contains("raw"))
    }

    // MARK: - Bold

    @Test("**bold** produces a stronglyEmphasized run")
    func bold() {
        let blocks = MarkdownDocumentParser.parse("**bold**")
        guard case .paragraph(let attributed) = blocks.first else {
            Issue.record("Expected paragraph")
            return
        }
        let hasBold = attributed.runs.contains { run in
            run.inlinePresentationIntent?.contains(.stronglyEmphasized) == true
        }
        #expect(hasBold)
    }

    @Test("plain text does not produce a stronglyEmphasized run")
    func boldNegative() {
        let blocks = MarkdownDocumentParser.parse("plain text")
        guard case .paragraph(let attributed) = blocks.first else {
            Issue.record("Expected paragraph")
            return
        }
        let hasBold = attributed.runs.contains { run in
            run.inlinePresentationIntent?.contains(.stronglyEmphasized) == true
        }
        #expect(!hasBold)
    }

    // MARK: - Italic

    @Test("*italic* produces an emphasized run")
    func italic() {
        let blocks = MarkdownDocumentParser.parse("*italic*")
        guard case .paragraph(let attributed) = blocks.first else {
            Issue.record("Expected paragraph")
            return
        }
        let hasItalic = attributed.runs.contains { run in
            run.inlinePresentationIntent?.contains(.emphasized) == true
        }
        #expect(hasItalic)
    }

    @Test("plain text does not produce an emphasized run")
    func italicNegative() {
        let blocks = MarkdownDocumentParser.parse("plain text")
        guard case .paragraph(let attributed) = blocks.first else {
            Issue.record("Expected paragraph")
            return
        }
        let hasItalic = attributed.runs.contains { run in
            run.inlinePresentationIntent?.contains(.emphasized) == true
        }
        #expect(!hasItalic)
    }

    // MARK: - Inline code

    @Test("`code` produces a .code inline-presentation-intent run")
    func inlineCode() {
        let blocks = MarkdownDocumentParser.parse("`code`")
        guard case .paragraph(let attributed) = blocks.first else {
            Issue.record("Expected paragraph")
            return
        }
        let hasCode = attributed.runs.contains { run in
            run.inlinePresentationIntent?.contains(.code) == true
        }
        #expect(hasCode)
    }

    @Test("plain text does not produce a .code run")
    func inlineCodeNegative() {
        let blocks = MarkdownDocumentParser.parse("not code")
        guard case .paragraph(let attributed) = blocks.first else {
            Issue.record("Expected paragraph")
            return
        }
        let hasCode = attributed.runs.contains { run in
            run.inlinePresentationIntent?.contains(.code) == true
        }
        #expect(!hasCode)
    }

    // MARK: - Links

    @Test("[text](url) produces a run with a .link attribute equal to the URL")
    func link() {
        let blocks = MarkdownDocumentParser.parse("[text](https://example.com)")
        guard case .paragraph(let attributed) = blocks.first else {
            Issue.record("Expected paragraph")
            return
        }
        let expected = URL(string: "https://example.com")
        let hasLink = attributed.runs.contains { run in
            run.link == expected
        }
        #expect(hasLink)
    }

    @Test("plain text does not produce a .link run")
    func linkNegative() {
        let blocks = MarkdownDocumentParser.parse("no link here")
        guard case .paragraph(let attributed) = blocks.first else {
            Issue.record("Expected paragraph")
            return
        }
        let hasLink = attributed.runs.contains { $0.link != nil }
        #expect(!hasLink)
    }

    // MARK: - Tables

    @Test("GFM table parses to a .table block with correct column count, header cells, and body row")
    func table() {
        let source = "| A | B |\n|---|---|\n| 1 | 2 |"
        let blocks = MarkdownDocumentParser.parse(source)
        guard case .table(let previewTable) = blocks.first else {
            Issue.record("Expected table block")
            return
        }
        #expect(previewTable.headerCells.count == 2)
        #expect(previewTable.bodyRows.count == 1)
        #expect(previewTable.bodyRows[0].count == 2)
        #expect(previewTable.columnAlignments.count == 2)
        #expect(String(previewTable.headerCells[0].characters) == "A")
        #expect(String(previewTable.headerCells[1].characters) == "B")
    }

    @Test("GFM table with explicit alignment records alignment per column")
    func tableAlignment() {
        let source = "| L | C | R |\n|:--|:--:|--:|\n| a | b | c |"
        let blocks = MarkdownDocumentParser.parse(source)
        guard case .table(let previewTable) = blocks.first else {
            Issue.record("Expected table block")
            return
        }
        #expect(previewTable.columnAlignments.count == 3)
    }

    // MARK: - Strikethrough

    @Test("~~gone~~ produces a .strikethrough run")
    func strikethrough() {
        let blocks = MarkdownDocumentParser.parse("~~gone~~")
        guard case .paragraph(let attributed) = blocks.first else {
            Issue.record("Expected paragraph")
            return
        }
        let hasStrike = attributed.runs.contains { run in
            run.inlinePresentationIntent?.contains(.strikethrough) == true
        }
        #expect(hasStrike)
    }

    @Test("plain text does not produce a .strikethrough run")
    func strikethroughNegative() {
        let blocks = MarkdownDocumentParser.parse("still here")
        guard case .paragraph(let attributed) = blocks.first else {
            Issue.record("Expected paragraph")
            return
        }
        let hasStrike = attributed.runs.contains { run in
            run.inlinePresentationIntent?.contains(.strikethrough) == true
        }
        #expect(!hasStrike)
    }

    // MARK: - Task lists

    @Test("task list items carry correct taskState values")
    func taskList() throws {
        let source = "- [ ] todo\n- [x] done"
        let blocks = MarkdownDocumentParser.parse(source)
        guard case .unorderedList(let items) = blocks.first else {
            Issue.record("Expected unorderedList")
            return
        }
        try #require(items.count == 2)
        #expect(items[0].taskState == false)
        #expect(items[1].taskState == true)
    }

    @Test("plain list items have nil taskState")
    func plainListTaskStateNil() throws {
        let source = "- alpha\n- beta"
        let blocks = MarkdownDocumentParser.parse(source)
        guard case .unorderedList(let items) = blocks.first else {
            Issue.record("Expected unorderedList")
            return
        }
        try #require(items.count == 2)
        #expect(items[0].taskState == nil)
        #expect(items[1].taskState == nil)
    }
}
