// swift-tools-version:5.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Stack",
    products: [
        // Products define the executables and libraries a package produces, and make them visible to other packages.
        .library(
            name: "Stack",
            targets: ["Stack"]),
    ],
    dependencies: [
        // Dependencies declare other packages that this package depends on.
        .package(url: "https://github.com/vale-cocoa/Queue.git", from: "1.0.1"),
        .package(url: "https://github.com/vale-cocoa/CircularBuffer.git", from: "2.0.2"),
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages this package depends on.
        .target(
            name: "Stack",
            dependencies: ["Queue", "CircularBuffer"]),
        .testTarget(
            name: "StackTests",
            dependencies: ["Stack", "Queue", "CircularBuffer"]),
    ]
)
