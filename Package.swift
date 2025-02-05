// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "LinkPreview",
    platforms: [.iOS(.v13), .macOS(.v11)],
    products: [
        .library(name: "LinkPreview", targets: ["LinkPreview"])
    ],
    dependencies: [
        .package(url: "https://github.com/scinfu/SwiftSoup.git", from: "2.6.0"),
    ],
    targets: [
        .target(name: "LinkPreview", dependencies: ["SwiftSoup"]),
        .testTarget(name: "LinkPreviewTests", dependencies: ["LinkPreview"])
    ]
)
