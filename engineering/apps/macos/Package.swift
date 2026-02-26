// swift-tools-version: 5.10

import PackageDescription

let package = Package(
    name: "Shepherd",
    platforms: [.macOS(.v14)],
    products: [
        .executable(name: "ShepherdApp", targets: ["ShepherdApp"]),
    ],
    dependencies: [
        .package(url: "https://github.com/pointfreeco/swift-composable-architecture", from: "1.17.0"),
        .package(url: "https://github.com/pointfreeco/swift-snapshot-testing", from: "1.17.0"),
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
            ]
        ),

        // MARK: - Dependency Clients
        .target(
            name: "ShepherdDependencies",
            dependencies: [
                "SharedModels",
                .product(name: "ComposableArchitecture", package: "swift-composable-architecture"),
            ],
            path: "Sources/Dependencies"
        ),

        // MARK: - Feature Modules
        .target(
            name: "FileBrowserFeature",
            dependencies: [
                "SharedModels",
                .product(name: "ComposableArchitecture", package: "swift-composable-architecture"),
            ]
        ),
        .target(
            name: "CodeViewerFeature",
            dependencies: [
                "SharedModels",
                "ShepherdDependencies",
                .product(name: "ComposableArchitecture", package: "swift-composable-architecture"),
            ]
        ),
        .target(
            name: "CommentFeature",
            dependencies: [
                "SharedModels",
                .product(name: "ComposableArchitecture", package: "swift-composable-architecture"),
            ]
        ),
        .target(
            name: "InspectorFeature",
            dependencies: [
                "SharedModels",
                "PromptFeature",
                "ReviewContextFeature",
                .product(name: "ComposableArchitecture", package: "swift-composable-architecture"),
            ]
        ),
        .target(
            name: "PromptFeature",
            dependencies: [
                "SharedModels",
                "ShepherdDependencies",
                .product(name: "ComposableArchitecture", package: "swift-composable-architecture"),
            ]
        ),
        .target(
            name: "SessionFeature",
            dependencies: [
                "SharedModels",
                "ShepherdDependencies",
                .product(name: "ComposableArchitecture", package: "swift-composable-architecture"),
            ]
        ),
        .target(
            name: "ReviewContextFeature",
            dependencies: [
                "SharedModels",
                .product(name: "ComposableArchitecture", package: "swift-composable-architecture"),
            ]
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
            ]
        ),

        // MARK: - App Executable
        .executableTarget(
            name: "ShepherdApp",
            dependencies: ["AppFeature"],
            path: "ShepherdApp",
            exclude: ["Resources/Info.plist"]
        ),

        // MARK: - Tests
        .testTarget(
            name: "SharedModelsTests",
            dependencies: [
                "SharedModels",
                .product(name: "CustomDump", package: "swift-custom-dump"),
            ]
        ),
        .testTarget(
            name: "AppFeatureTests",
            dependencies: [
                "AppFeature",
                .product(name: "ComposableArchitecture", package: "swift-composable-architecture"),
            ]
        ),
        .testTarget(
            name: "FileBrowserFeatureTests",
            dependencies: [
                "FileBrowserFeature",
                .product(name: "ComposableArchitecture", package: "swift-composable-architecture"),
            ]
        ),
        .testTarget(
            name: "CodeViewerFeatureTests",
            dependencies: [
                "CodeViewerFeature",
                .product(name: "ComposableArchitecture", package: "swift-composable-architecture"),
            ]
        ),
        .testTarget(
            name: "CommentFeatureTests",
            dependencies: [
                "CommentFeature",
                .product(name: "ComposableArchitecture", package: "swift-composable-architecture"),
            ]
        ),
        .testTarget(
            name: "InspectorFeatureTests",
            dependencies: [
                "InspectorFeature",
                .product(name: "ComposableArchitecture", package: "swift-composable-architecture"),
            ]
        ),
        .testTarget(
            name: "PromptFeatureTests",
            dependencies: [
                "PromptFeature",
                "ShepherdDependencies",
                .product(name: "ComposableArchitecture", package: "swift-composable-architecture"),
            ]
        ),
        .testTarget(
            name: "SessionFeatureTests",
            dependencies: [
                "SessionFeature",
                "ShepherdDependencies",
                .product(name: "ComposableArchitecture", package: "swift-composable-architecture"),
            ]
        ),
    ]
)
