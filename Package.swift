// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "AdmobSwiftUI",
    defaultLocalization: "en",
    platforms: [.iOS(.v15)],
    products: [
        .library(
            name: "AdmobSwiftUI",
            targets: ["AdmobSwiftUI"]),
    ],
    dependencies: [
        .package(url: "https://github.com/googleads/swift-package-manager-google-mobile-ads.git", from: "13.0.0"),
    ],
    targets: [
        .target(
            name: "AdmobSwiftUI",
            dependencies: [
                .product(name: "GoogleMobileAds", package: "swift-package-manager-google-mobile-ads")
            ],
            resources: [
                .process("Resources")
            ],
            swiftSettings: [
                // Stay on Swift 5 mode for now: surface strict-concurrency issues as
                // warnings first; the switch to Swift 6 mode lands with the test rebuild.
                .swiftLanguageMode(.v5),
                .enableUpcomingFeature("StrictConcurrency"),
            ]),
        .testTarget(
            name: "AdmobSwiftUITests",
            dependencies: ["AdmobSwiftUI"],
            swiftSettings: [
                .swiftLanguageMode(.v5),
                .enableUpcomingFeature("StrictConcurrency"),
            ]),
    ]
)
