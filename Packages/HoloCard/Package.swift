// swift-tools-version: 6.2

import PackageDescription

let package = Package(
    name: "HoloCard",
    platforms: [.iOS(.v17), .macOS(.v14)],
    products: [
        .library(name: "HoloCard", targets: ["HoloCard"])
    ],
    targets: [
        .target(name: "HoloCard"),
        .testTarget(name: "HoloCardTests", dependencies: ["HoloCard"])
    ]
)
