// swift-tools-version: 6.2

import PackageDescription

// Warnings-as-errors for every target — including deprecations. The dependency clients use
// the @DependencyClient macro so there are no `unimplemented` deprecations to exempt. If an
// upstream dependency bump ever introduces a new deprecation and blocks the build, the fix is
// to migrate the call (preferred) or temporarily add `.treatWarning("DeprecatedDeclaration",
// as: .warning)` here.
let warningsAsErrors: [SwiftSetting] = [
    .treatAllWarnings(as: .error),
]

let package = Package(
    name: "Shepherd",
    platforms: [.macOS(.v14)],
    products: [
        .executable(name: "ShepherdApp", targets: ["ShepherdApp"]),
    ],
    dependencies: [
        .package(url: "https://github.com/pointfreeco/swift-composable-architecture", from: "1.17.0"),
        .package(url: "https://github.com/pointfreeco/swift-custom-dump", from: "1.3.0"),
        .package(url: "https://github.com/pointfreeco/swift-identified-collections", from: "1.1.0"),
        .package(url: "https://github.com/pointfreeco/swift-snapshot-testing", from: "1.17.0"),
        // Syntax highlighting: ChimeHQ SwiftTreeSitter runtime + per-language grammars.
        .package(url: "https://github.com/ChimeHQ/SwiftTreeSitter", from: "0.24.0"),
        .package(url: "https://github.com/tree-sitter/tree-sitter-json", exact: "0.24.8"),
        .package(url: "https://github.com/tree-sitter/tree-sitter-javascript", exact: "0.25.0"),
        .package(url: "https://github.com/tree-sitter/tree-sitter-typescript", exact: "0.23.2"),
        .package(url: "https://github.com/tree-sitter/tree-sitter-python", exact: "0.25.0"),
        .package(url: "https://github.com/tree-sitter/tree-sitter-go", exact: "0.25.0"),
        .package(url: "https://github.com/tree-sitter/tree-sitter-rust", exact: "0.24.2"),
        .package(url: "https://github.com/tree-sitter/tree-sitter-java", exact: "0.23.5"),
        .package(url: "https://github.com/tree-sitter/tree-sitter-c", exact: "0.24.2"),
        .package(url: "https://github.com/tree-sitter/tree-sitter-cpp", exact: "0.23.4"),
        .package(url: "https://github.com/tree-sitter/tree-sitter-html", exact: "0.23.2"),
        .package(url: "https://github.com/tree-sitter/tree-sitter-css", exact: "0.25.0"),
        .package(url: "https://github.com/tree-sitter-grammars/tree-sitter-yaml", exact: "0.7.2"),
        .package(url: "https://github.com/tree-sitter-grammars/tree-sitter-markdown", exact: "0.5.3"),
        // Markdown parsing for rendered view
        .package(url: "https://github.com/apple/swift-markdown.git", from: "0.5.0"),
    ],
    targets: [
        // MARK: - Vendored TreeSitter scanners
        // css/javascript/python/yaml ship an external scanner (scanner.c) but their
        // SwiftPM manifest only compiles it when `FileManager.fileExists("src/scanner.c")`
        // is true — which it isn't when the grammar is consumed as a dependency (the
        // manifest's CWD is the consumer, not the grammar). That drops the scanner and
        // leaves `tree_sitter_<lang>_external_scanner_*` undefined at link time. We vendor
        // those four scanners here so the symbols are provided.
        .target(
            name: "CTreeSitterScanners",
            path: "Sources/CTreeSitterScanners",
            exclude: ["schema.core.c"],   // #included by yaml_scanner.c, not compiled standalone
            sources: [
                "css_scanner.c",
                "javascript_scanner.c",
                "python_scanner.c",
                "yaml_scanner.c",
            ],
            publicHeadersPath: "include",
            cSettings: [.headerSearchPath(".")]
        ),

        // MARK: - Shared Models
        .target(
            name: "SharedModels",
            dependencies: [
                .product(name: "IdentifiedCollections", package: "swift-identified-collections"),
                .product(name: "ComposableArchitecture", package: "swift-composable-architecture"),
            ],
            swiftSettings: warningsAsErrors
        ),

        // MARK: - Dependency Clients
        .target(
            name: "ShepherdDependencies",
            dependencies: [
                "SharedModels",
                .product(name: "ComposableArchitecture", package: "swift-composable-architecture"),
                .product(name: "SwiftTreeSitter", package: "SwiftTreeSitter"),
                .product(name: "TreeSitterJSON", package: "tree-sitter-json"),
                .product(name: "TreeSitterJavaScript", package: "tree-sitter-javascript"),
                .product(name: "TreeSitterTypeScript", package: "tree-sitter-typescript"),
                .product(name: "TreeSitterPython", package: "tree-sitter-python"),
                .product(name: "TreeSitterGo", package: "tree-sitter-go"),
                .product(name: "TreeSitterRust", package: "tree-sitter-rust"),
                .product(name: "TreeSitterJava", package: "tree-sitter-java"),
                .product(name: "TreeSitterC", package: "tree-sitter-c"),
                .product(name: "TreeSitterCPP", package: "tree-sitter-cpp"),
                .product(name: "TreeSitterHTML", package: "tree-sitter-html"),
                .product(name: "TreeSitterCSS", package: "tree-sitter-css"),
                .product(name: "TreeSitterYAML", package: "tree-sitter-yaml"),
                .product(name: "TreeSitterMarkdown", package: "tree-sitter-markdown"),
                "CTreeSitterScanners",
            ],
            path: "Sources/Dependencies",
            resources: [
                .copy("Resources/queries"),
            ],
            swiftSettings: warningsAsErrors
        ),

        // MARK: - Feature Modules
        .target(
            name: "FileBrowserFeature",
            dependencies: [
                "SharedModels",
                .product(name: "ComposableArchitecture", package: "swift-composable-architecture"),
            ],
            swiftSettings: warningsAsErrors
        ),
        .target(
            name: "CodeViewerFeature",
            dependencies: [
                "SharedModels",
                "ShepherdDependencies",
                .product(name: "ComposableArchitecture", package: "swift-composable-architecture"),
            ],
            swiftSettings: warningsAsErrors
        ),
        .target(
            name: "CommentFeature",
            dependencies: [
                "SharedModels",
                .product(name: "ComposableArchitecture", package: "swift-composable-architecture"),
            ],
            swiftSettings: warningsAsErrors
        ),
        .target(
            name: "InspectorFeature",
            dependencies: [
                "SharedModels",
                "PromptFeature",
                "ReviewContextFeature",
                .product(name: "ComposableArchitecture", package: "swift-composable-architecture"),
            ],
            swiftSettings: warningsAsErrors
        ),
        .target(
            name: "PromptFeature",
            dependencies: [
                "SharedModels",
                "ShepherdDependencies",
                .product(name: "ComposableArchitecture", package: "swift-composable-architecture"),
            ],
            swiftSettings: warningsAsErrors
        ),
        .target(
            name: "SessionFeature",
            dependencies: [
                "SharedModels",
                "ShepherdDependencies",
                .product(name: "ComposableArchitecture", package: "swift-composable-architecture"),
            ],
            swiftSettings: warningsAsErrors
        ),
        .target(
            name: "ReviewContextFeature",
            dependencies: [
                "SharedModels",
                .product(name: "ComposableArchitecture", package: "swift-composable-architecture"),
            ],
            swiftSettings: warningsAsErrors
        ),
        .target(
            name: "AppFeature",
            dependencies: [
                "SharedModels",
                "ShepherdDependencies",
                "FileBrowserFeature",
                "CodeViewerFeature",
                "CommentFeature",
                "InspectorFeature",
                "PromptFeature",
                "SessionFeature",
                "ReviewContextFeature",
                .product(name: "ComposableArchitecture", package: "swift-composable-architecture"),
            ],
            swiftSettings: warningsAsErrors
        ),

        // MARK: - App Executable
        .executableTarget(
            name: "ShepherdApp",
            dependencies: ["AppFeature"],
            path: "ShepherdApp",
            exclude: ["Resources/Info.plist"],
            swiftSettings: warningsAsErrors
        ),

        // MARK: - Tests
        .testTarget(
            name: "SharedModelsTests",
            dependencies: [
                "SharedModels",
                .product(name: "CustomDump", package: "swift-custom-dump"),
                .product(name: "InlineSnapshotTesting", package: "swift-snapshot-testing"),
            ],
            swiftSettings: warningsAsErrors
        ),
        .testTarget(
            name: "AppFeatureTests",
            dependencies: [
                "AppFeature",
                "ShepherdDependencies",
                .product(name: "ComposableArchitecture", package: "swift-composable-architecture"),
            ],
            swiftSettings: warningsAsErrors
        ),
        // Demo screenshot capture (gated by CAPTURE_DEMOS=1; see scripts/capture-demos.sh).
        .testTarget(
            name: "DemoCaptureTests",
            dependencies: [
                "AppFeature",
                "SharedModels",
                .product(name: "ComposableArchitecture", package: "swift-composable-architecture"),
                .product(name: "SnapshotTesting", package: "swift-snapshot-testing"),
            ]
        ),
        .testTarget(
            name: "FileBrowserFeatureTests",
            dependencies: [
                "FileBrowserFeature",
                .product(name: "ComposableArchitecture", package: "swift-composable-architecture"),
            ],
            swiftSettings: warningsAsErrors
        ),
        .testTarget(
            name: "CodeViewerFeatureTests",
            dependencies: [
                "CodeViewerFeature",
                .product(name: "ComposableArchitecture", package: "swift-composable-architecture"),
            ],
            swiftSettings: warningsAsErrors
        ),
        .testTarget(
            name: "CommentFeatureTests",
            dependencies: [
                "CommentFeature",
                .product(name: "ComposableArchitecture", package: "swift-composable-architecture"),
            ],
            swiftSettings: warningsAsErrors
        ),
        .testTarget(
            name: "InspectorFeatureTests",
            dependencies: [
                "InspectorFeature",
                .product(name: "ComposableArchitecture", package: "swift-composable-architecture"),
            ],
            swiftSettings: warningsAsErrors
        ),
        .testTarget(
            name: "ReviewContextFeatureTests",
            dependencies: [
                "ReviewContextFeature",
                .product(name: "ComposableArchitecture", package: "swift-composable-architecture"),
            ],
            swiftSettings: warningsAsErrors
        ),
        .testTarget(
            name: "PromptFeatureTests",
            dependencies: [
                "PromptFeature",
                "ShepherdDependencies",
                .product(name: "ComposableArchitecture", package: "swift-composable-architecture"),
            ],
            swiftSettings: warningsAsErrors
        ),
        .testTarget(
            name: "SessionFeatureTests",
            dependencies: [
                "SessionFeature",
                "ShepherdDependencies",
                .product(name: "ComposableArchitecture", package: "swift-composable-architecture"),
            ],
            swiftSettings: warningsAsErrors
        ),
    ]
)
