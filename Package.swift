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
        // GoogleMobileAds already depends on UMP ("1.1.0"..<"4.0.0"), but the Swift API
        // surface changed in UMP 3.0 (UMPConsentInformation -> ConsentInformation, etc.).
        // Pin >= 3.0.0 explicitly so ConsentManager always compiles against the new names.
        .package(url: "https://github.com/googleads/swift-package-manager-google-user-messaging-platform.git", from: "3.0.0"),
    ],
    targets: [
        .target(
            name: "AdmobSwiftUI",
            dependencies: [
                .product(name: "GoogleMobileAds", package: "swift-package-manager-google-mobile-ads"),
                .product(name: "GoogleUserMessagingPlatform", package: "swift-package-manager-google-user-messaging-platform"),
            ],
            resources: [
                .process("Resources")
            ],
            swiftSettings: [
                .swiftLanguageMode(.v6),
            ]),
        .testTarget(
            name: "AdmobSwiftUITests",
            dependencies: ["AdmobSwiftUI"],
            swiftSettings: [
                .swiftLanguageMode(.v6),
            ]),
    ]
)
