# CLAUDE.md — MarkdownEditorKit

Standalone SwiftUI Markdown editor as an SPM package. Public, MIT-licensed.

Platform: **Swift 6.2** | **macOS 26+** | **SwiftUI** | Swift Testing.

## Purpose

Reusable `MarkdownEditorView` consumed by `metamech/HashtagGitHub` and
`metamech/Tenrec-Terminal`. Design spec lives upstream in
`metamech/HashtagGitHub` ADR-023 (this repo intentionally does not host
that ADR).

## Layering rules (non-negotiable)

The package MUST stay GitHub-agnostic. Allowed imports:

- `SwiftUI`
- `Foundation`
- `apple/swift-markdown` (Apache-2)
- `JohnSundell/Splash` (MIT)

Forbidden:

- `GitHubKit`, `HashtagGitHubCore`, `HashtagGitHubUI` — these live in the
  consumer repo and would invert the dependency direction.
- Networking, Keychain, on-disk caches.
- Anything not covered by the MIT or Apache-2 licenses.

GitHub-specific concerns (mention/issue lookups, image upload) reach the
package only through host-injected protocols (`MentionProvider`,
`IssueProvider`, `EmojiProvider`, `PasteHandler`).

## Commands

| What | Command |
| ---- | ------- |
| Build | `swift build` |
| Run all tests | `swift test` |
| Single test | `swift test --filter <SuiteOrTestName>` |
| Lint Swift | `swift-format lint --recursive Sources Tests` |
| SwiftLint | `swiftlint --strict` |
| Format | `swift-format format -i -r Sources Tests` |
| Typo check | `typos` |

## Quality gates (before commit)

1. `swift build` succeeds with no warnings in package code.
2. `swift test` passes (including SwiftUI preview snapshot stubs if added).
3. `swift-format lint --recursive Sources Tests` passes.
4. `swiftlint --strict` passes on touched sources.
5. `typos` passes.

## Versioning and release

Semver tags drive SPM consumers. Pre-1.0 follows `0.y.z`. Tag from `main`
only after CI is green and CHANGELOG entry exists.

## Cross-repo coordination

- Issues describing work *inside* this repo live here.
- The umbrella epic and ADR-023 live in `metamech/HashtagGitHub#159`;
  reference cross-repo, do not duplicate.
- Host integration issues (`@`/`#` providers backed by `GitHubKit`, comment
  composer wiring) live in `metamech/HashtagGitHub`.
- Tenrec-Terminal adoption work lives in `metamech/Tenrec-Terminal`.

## Agents

Specialists live in `.claude/agents/`. Prefer the `orchestrate` skill
(`/orchestrate #<issue>`) to coordinate multi-agent work.

- `architect` — public API surface, layering decisions, cross-repo ADR
  cross-refs
- `swiftui-engineer` — Views and ViewModels in `Sources/MarkdownEditorKit/`
- `test-engineer` — Swift Testing in `Tests/MarkdownEditorKitTests/`
- `test-runner` — runs `swift test`, read-only
- `swift-dependency-scanner` — `Package.swift` edits and license review
- `git-ops` — branches, PRs, release tagging
- `prompt-engineer` — agent and skill prompt maintenance

## AI agent guidelines

- **Filesystem scope.** Agents may write inside this repo's worktree and
  `/tmp/markdowneditorkit-*`. Never under `$HOME/Library` (DerivedData,
  SwiftPM caches) without explicit authorization.
- **Destructive commands.** `rm -rf`, `git reset --hard`, cache wipes, and
  `git clone` of external repos are intercepted by
  `.claude/hooks/block-destructive-bash.sh`.
- **Worktrees.** Prefer `git worktree add .claude/worktrees/<branch>` for
  parallel work.
- **Branch names.** `feature/<issue>-<slug>`, `fix/<issue>-<slug>`,
  `docs/<slug>`, `release/<version>`.
- **Commits.** Follow the style in `git log`. No `Co-Authored-By: Claude`
  tags unless the user asks.
- **Public API discipline.** Anything `public` is a semver promise. Discuss
  before adding or breaking.

## References

- `README.md` — package one-pager
- Upstream design: `metamech/HashtagGitHub` ADR-023
- Upstream epic: `metamech/HashtagGitHub#159`
