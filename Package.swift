// swift-tools-version: 6.2
import PackageDescription

let package = Package(
    name: "MarkdownEditorKit",
    platforms: [.macOS(.v26)],
    products: [
        .library(name: "MarkdownEditorKit", targets: ["MarkdownEditorKit"]),
    ],
    dependencies: [
        // Apache-2.0
        .package(url: "https://github.com/apple/swift-markdown.git", .upToNextMinor(from: "0.7.3")),
        // MIT
        .package(url: "https://github.com/JohnSundell/Splash.git", .upToNextMinor(from: "0.16.0")),
    ],
    targets: [
        .target(
            name: "MarkdownEditorKit",
            dependencies: [
                .product(name: "Markdown", package: "swift-markdown"),
                .product(name: "Splash", package: "Splash"),
            ]
        ),
        .testTarget(
            name: "MarkdownEditorKitTests",
            dependencies: ["MarkdownEditorKit"]
        ),
    ]
)
