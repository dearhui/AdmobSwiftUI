// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "AdmobSwiftUI",
    defaultLocalization: "en",
    platforms: [.iOS(.v14)],
    products: [
        // Products define the executables and libraries a package produces, and make them visible to other packages.
        .library(
            name: "AdmobSwiftUI",
            targets: ["AdmobSwiftUI"]),
    ],
    dependencies: [
        // Dependencies declare other packages that this package depends on.
        // .package(url: /* package url */, from: "1.0.0"),
        .package(url: "https://github.com/googleads/swift-package-manager-google-mobile-ads.git", "10.0.0"..<"11.0.0"),
        .package(url: "https://github.com/bhlvoong/LBTATools", from: "1.0.17"),
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages this package depends on.
        .target(
            name: "AdmobSwiftUI",
            dependencies: [
                .product(name: "GoogleMobileAds", package: "swift-package-manager-google-mobile-ads"),
                "LBTATools"
            ]),
        .testTarget(
            name: "AdmobSwiftUITests",
            dependencies: ["AdmobSwiftUI"]),
    ]
)
