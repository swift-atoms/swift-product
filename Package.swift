// swift-tools-version: 6.4

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
        .library(name: "Product", targets: ["Product"]),

        .library(name: "Product Foundation Integration", targets: ["Product Foundation Integration"]),
        .library(name: "Product Test Support", targets: ["Product Test Support"]),
    ],
    dependencies: [

        .package(
            url: "https://github.com/swift-atoms/swift-comparison.git",
            branch: "main"
        ),
        .package(
            url: "https://github.com/swift-atoms/swift-equation.git",
            branch: "main"
        ),
        .package(
            url: "https://github.com/swift-atoms/swift-hash.git",
            branch: "main"
        ),
    ],
    targets: [
        .target(
            name: "Product",
            dependencies: [
                .product(name: "Comparison", package: "swift-comparison"),
                .product(name: "Equation", package: "swift-equation"),
                .product(name: "Hash", package: "swift-hash"),
            ],
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
                .product(name: "Comparison", package: "swift-comparison"),
                .product(name: "Equation", package: "swift-equation"),
                .product(name: "Hash", package: "swift-hash"),
                .target(name: "Product Test Support"),
                .target(name: "Product Foundation Integration"),
            ],
            path: "Tests/Product Tests",
            resources: [.copy("Fixtures")]
        ),
        .testTarget(
            name: "Consolidated Product Comparison Tests",
            dependencies: [

                .target(name: "Product"),
                .product(name: "Comparison", package: "swift-comparison"),
            ],
            path: "Tests/Consolidated swift-product-comparison"
        ),
        .testTarget(
            name: "Consolidated Product Equation Tests",
            dependencies: [

                .target(name: "Product"),
                .product(name: "Equation", package: "swift-equation"),
            ],
            path: "Tests/Consolidated swift-product-equation"
        ),
        .testTarget(
            name: "Consolidated Product Hash Tests",
            dependencies: [

                .target(name: "Product"),
                .product(name: "Hash", package: "swift-hash"),
            ],
            path: "Tests/Consolidated swift-product-hash"
        ),
    ],
    swiftLanguageModes: [.v6]
)

for target in package.targets {
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
