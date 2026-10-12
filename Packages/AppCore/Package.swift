// swift-tools-version: 6.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "AppCore",
    platforms: [.iOS(.v17), .macOS(.v14)],
    products: [
        .library(
            name: "AppCore", targets: ["AppCore"]
        ),
        // Products define the executables and libraries a package produces, making them visible to other packages.
        .library(
            name: "Networking", targets: ["Networking"]
        ),
        .library(
            name: "Persistence", targets: ["Persistence"]
        )
    ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .target(
            name: "AppCore",
            dependencies: ["Networking", "Persistence"]
        ),
        .target(
            name: "Networking"
        ),
        .target(
            name: "Persistence"
        ),
        .testTarget(
            name: "NetworkingTests",
            dependencies: ["Networking"]
        ),
        .testTarget(
            name: "PersistenceTests",
            dependencies: ["Persistence"]
        )
    ]
)
