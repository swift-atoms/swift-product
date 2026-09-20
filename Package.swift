// swift-tools-version: 6.4

import CompilerPluginSupport
import PackageDescription

let package = Package(
    name: "swift-product",
    platforms: [
        .macOS(.v27),
        .iOS(.v27),
        .tvOS(.v27),
        .watchOS(.v27),
        .visionOS(.v27),
    ],
    products: [
        .library(name: "Structural Macro", targets: ["Structural Macro"]),
        .library(name: "Product Syntax", targets: ["Product Syntax"]),
        .library(name: "Product", targets: ["Product"]),

        .library(name: "Product Foundation Integration", targets: ["Product Foundation Integration"]),
        .library(name: "Product Test Support", targets: ["Product Test Support"]),
        .library(name: "Product Macro", targets: ["Product Macro"]),
    ],
    dependencies: [
        .package(url: "https://github.com/swift-atoms/swift-algebra.git", branch: "main"),
        .package(url: "https://github.com/swift-atoms/swift-operation.git", branch: "main"),
        .package(url: "https://github.com/swiftlang/swift-syntax.git", "603.0.2"..<"604.0.0"),
    ],
    targets: [
        .macro(name: "Structural Macro Plugin", dependencies: [
            "Structural Macro Core",
            .product(name: "SwiftCompilerPlugin", package: "swift-syntax"),
            .product(name: "SwiftSyntaxMacros", package: "swift-syntax"),
        ]),
        .target(name: "Structural Macro", dependencies: ["Structural Macro Plugin"]),
        .target(name: "Structural Macro Core", dependencies: [
                .product(name: "Type Algebra Syntax", package: "swift-algebra"),
            .product(name: "SwiftSyntax", package: "swift-syntax"),
            .product(name: "SwiftSyntaxBuilder", package: "swift-syntax"),
        ]),
        .target(name: "Product Syntax", dependencies: [
            .product(name: "Operation Syntax", package: "swift-operation"),
            .product(name: "SwiftSyntax", package: "swift-syntax"),
        ]),
        .target(
            name: "Product",
            dependencies: [],
            path: "Sources/Product"
        ),

        .target(
            name: "Product Foundation Integration",
            dependencies: [
                .target(name: "Product"),
            ],
            path: "Sources/Product Foundation Integration"
        ),
        .target(
            name: "Product Test Support",
            dependencies: [
                .target(name: "Product"),
            ],
            path: "Tests/Support"
        ),
        .testTarget(
            name: "Product Tests",
            dependencies: [
                .target(name: "Product"),
                .target(name: "Product Test Support"),
                .target(name: "Product Foundation Integration"),
            ],
            path: "Tests/Product Tests",
            resources: [.copy("Fixtures")]
        ),
        .target(
            name: "Product Macro Core",
            dependencies: [
                "Product Syntax",
                .product(name: "Operation Syntax", package: "swift-operation"),
                .product(name: "SwiftSyntax", package: "swift-syntax"),
                .product(name: "SwiftSyntaxBuilder", package: "swift-syntax"),
            ]
        ),
        .macro(
            name: "Product Macro Plugin",
            dependencies: [
                "Product Macro Core",
                .product(name: "Type Algebra Syntax", package: "swift-algebra"),
                .product(name: "SwiftCompilerPlugin", package: "swift-syntax"),
                .product(name: "SwiftSyntax", package: "swift-syntax"),
                .product(name: "SwiftSyntaxMacros", package: "swift-syntax"),
            ]
        ),
        .target(
            name: "Product Macro",
            dependencies: [
                "Structural Macro",
                "Product Macro Plugin",
            ]
        ),
        .testTarget(
            name: "Product Macro Tests",
            dependencies: [
                .product(name: "Operation Syntax", package: "swift-operation"),
                "Product Macro",
                "Product Macro Core",
                "Product Macro Plugin",
                .product(name: "SwiftParser", package: "swift-syntax"),
                .product(name: "SwiftSyntax", package: "swift-syntax"),
                .product(name: "SwiftSyntaxMacroExpansion", package: "swift-syntax"),
                .product(name: "SwiftSyntaxMacrosGenericTestSupport", package: "swift-syntax"),
            ]
        ),
    ],
    swiftLanguageModes: [.v6]
)

for target in package.targets where ![.system, .binary, .plugin, .macro].contains(target.type) {
    target.swiftSettings = [
        .strictMemorySafety(),
        .enableUpcomingFeature("ExistentialAny"),
        .enableUpcomingFeature("InternalImportsByDefault"),
        .enableUpcomingFeature("MemberImportVisibility"),
        .enableUpcomingFeature("NonisolatedNonsendingByDefault"),
        .enableExperimentalFeature("Lifetimes"),
        .enableExperimentalFeature("MoveOnlyTuples"),
        .enableUpcomingFeature("InferIsolatedConformances"),
    ]
}

// Consumer compilation must reject visibility regressions, even when other packages suppress warnings.
for target in package.targets where target.type == .test || target.name.hasSuffix("Consumer Fixtures") {
    target.swiftSettings = (target.swiftSettings ?? []) + [.treatAllWarnings(as: .error)]
}
