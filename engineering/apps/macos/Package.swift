// swift-tools-version: 6.2

import PackageDescription

// Warnings-as-errors for every target. Upstream API *deprecations* (e.g. the Dependencies
// library's `unimplemented`) are kept as warnings so a dependency bump can't hard-break the
// build; those are migrated deliberately (see the @DependencyClient follow-up in Phase 2).
let warningsAsErrors: [SwiftSetting] = [
    .treatAllWarnings(as: .error),
    .treatWarning("DeprecatedDeclaration", as: .warning),
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
    ],
    targets: [
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
            ],
            path: "Sources/Dependencies",
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
            ],
            swiftSettings: warningsAsErrors
        ),
        .testTarget(
            name: "AppFeatureTests",
            dependencies: [
                "AppFeature",
                .product(name: "ComposableArchitecture", package: "swift-composable-architecture"),
            ],
            swiftSettings: warningsAsErrors
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
