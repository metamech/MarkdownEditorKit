# Changelog

All notable changes to MarkdownEditorKit will be documented in this file.

The format is based on
[Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and this
project adheres to
[Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [0.1.0] - 2026-05-07

### Added

- **swift-markdown 0.7.3** (`apple/swift-markdown`, Apache-2.0) for
  GFM-compliant AST parsing, replacing the hand-rolled line scanner.
- **Splash 0.16.0** (`JohnSundell/Splash`, MIT) for Swift syntax
  highlighting inside fenced code blocks (presentation theme).

### Changed

- `MarkdownPreviewView` now renders the full GFM block set: bold,
  italic, strikethrough, inline code, links, block quotes, unordered
  and ordered lists, GFM task lists (checkbox SF Symbols), tables,
  and thematic breaks.
- Rendering internals extracted into `internal` types under
  `Sources/MarkdownEditorKit/Rendering/`: `PreviewBlock`,
  `InlineAttributedStringBuilder`, `MarkdownDocumentParser`,
  and `SplashCodeHighlighter`.
- Removed the hand-rolled `String.headingLevel()` extension and its
  associated tests (superseded by the swift-markdown AST walker).
