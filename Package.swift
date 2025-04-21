// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "arthaus",
    platforms: [
        .iOS(.v15),
        .macOS(.v12)
    ],
    products: [
        // Products define the executables and libraries a package produces, making them visible to other packages.
        .library(
            name: "arthaus",
            targets: ["arthaus"]),
    ],
    dependencies: [
        .package(url: "https://github.com/simibac/ConfettiSwiftUI.git", branch: "master")
    ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .target(
            name: "arthaus",
            dependencies: ["ConfettiSwiftUI"]),
        .testTarget(
            name: "arthausTests",
            dependencies: ["arthaus"]
        ),
    ]
)
