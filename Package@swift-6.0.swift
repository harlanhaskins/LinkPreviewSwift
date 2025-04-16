// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "LinkPreview",
    platforms: [.iOS(.v13), .macOS(.v11)],
    products: [
        .library(name: "LinkPreview", targets: ["LinkPreview"]),
        .executable(name: "linkpreviewcli", targets: ["LinkPreviewCLI"])
    ],
    dependencies: [
        .package(url: "https://github.com/scinfu/SwiftSoup.git", from: "2.6.0"),
        .package(url: "https://github.com/apple/swift-argument-parser", from: "1.3.0"),
        .package(url: "https://github.com/swift-server/async-http-client", from: "1.24.0")
    ],
    targets: [
        .target(
            name: "LinkPreview",
            dependencies: [
                "SwiftSoup",
                .product(name: "AsyncHTTPClient", package: "async-http-client")
            ],
            swiftSettings: [
                .enableUpcomingFeature("InternalImportsByDefault")
            ]
        ),
        .executableTarget(name: "LinkPreviewCLI", dependencies: [
            "LinkPreview",
            .product(name: "ArgumentParser", package: "swift-argument-parser")
        ]),
        .testTarget(name: "LinkPreviewTests", dependencies: ["LinkPreview"])
    ]
)
