// swift-tools-version: 6.2
import PackageDescription

let package = Package(
    name: "MarkdownEditorKit",
    platforms: [.macOS(.v26)],
    products: [
        .library(name: "MarkdownEditorKit", targets: ["MarkdownEditorKit"]),
    ],
    targets: [
        .target(name: "MarkdownEditorKit"),
        .testTarget(
            name: "MarkdownEditorKitTests",
            dependencies: ["MarkdownEditorKit"]
        ),
    ]
)
