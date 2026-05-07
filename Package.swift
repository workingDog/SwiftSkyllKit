// swift-tools-version: 6.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription


let package = Package(
    name: "SwiftSkyllKit",
    platforms: [
        .iOS(.v26),
        .macOS(.v26)
    ],
    products: [
        .library(
            name: "SwiftSkyllKit",
            targets: ["SwiftSkyllKit"]
        )
    ],
    targets: [
        .target(
            name: "SwiftSkyllKit"
        ),
        .testTarget(
            name: "SwiftSkyllKitTests",
            dependencies: ["SwiftSkyllKit"]
        )
    ]
)
