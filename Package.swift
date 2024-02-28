// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "swift-file-downloader",
    platforms: [
        .iOS(.v15),
        .macOS(.v12),
    ],
    products: [
        .library(name: "FileDownloader", targets: ["FileDownloader"]),
    ],
    targets: [
        .target(name: "FileDownloader", swiftSettings: [.enableExperimentalFeature("StrictConcurrency=complete")]),
    ]
)
