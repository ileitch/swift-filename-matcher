// swift-tools-version: 5.8

import PackageDescription

let package = Package(
    name: "swift-filename-matcher",
    products: [
        .library(
            name: "FilenameMatcher",
            targets: ["FilenameMatcher"]
        ),
    ],
    targets: [
        .target(
            name: "FilenameMatcher",
            dependencies: []
        ),
        .testTarget(
            name: "FilenameMatcherTests",
            dependencies: ["FilenameMatcher"]
        ),
    ]
)
