// swift-tools-version: 5.8
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "MFirebaseKit",
    platforms: [
        .iOS(.v15),
        .macOS(.v10_15)
    ],
    products: [
        // Products define the executables and libraries a package produces, and make them visible to other packages.
        .library(
            name: "MFirebaseKitAnalyticsCore",
            targets: ["MFirebaseKitAnalyticsCore"]
        ),
        .library(
            name: "MFirebaseKitAnalyticsShared",
            targets: ["MFirebaseKitAnalyticsShared"]
        ),
        .library(
            name: "MFirebaseKitFirestoreCore",
            targets: ["MFirebaseKitFirestoreCore"]
        ),
        .library(
            name: "MFirebaseKitFirestoreShared",
            targets: ["MFirebaseKitFirestoreShared"]
        ),
        .library(
            name: "MFirebaseKitFirestoreDebug",
            targets: ["MFirebaseKitFirestoreDebug"]
        ),
    ],
    dependencies: [
        // Dependencies declare other packages that this package depends on.
        // .package(url: /* package url */, from: "1.0.0"),
        .package(url: "https://github.com/firebase/firebase-ios-sdk", from: "10.24.0"),
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages this package depends on.
        .target(
            name: "MFirebaseKitAnalyticsCore",
            dependencies: []
        ),
        .target(
            name: "MFirebaseKitAnalyticsShared",
            dependencies: [
                "MFirebaseKitAnalyticsCore",
                .product(name: "FirebaseAnalytics", package: "firebase-ios-sdk"),
            ]
        ),
        .target(
            name: "MFirebaseKitFirestoreCore",
            dependencies: []
        ),
        .target(
            name: "MFirebaseKitFirestoreShared",
            dependencies: [
                "MFirebaseKitFirestoreCore",
                .product(name: "FirebaseAuth", package: "firebase-ios-sdk"),
                .product(name: "FirebaseFirestore", package: "firebase-ios-sdk"),
                .product(name: "FirebaseStorage", package: "firebase-ios-sdk"),
                .product(name: "FirebaseFirestoreSwift", package: "firebase-ios-sdk"),
            ]
        ),
        .target(
            name: "MFirebaseKitFirestoreDebug",
            dependencies: ["MFirebaseKitFirestoreCore"]
        ),
        .testTarget(
            name: "MFirebaseKitFirestoreTests",
            dependencies: ["MFirebaseKitFirestoreShared", "MFirebaseKitFirestoreCore", "MFirebaseKitFirestoreDebug"]
        ),
        .testTarget(
            name: "MFirebaseKitAnalyticsTests",
            dependencies: ["MFirebaseKitAnalyticsCore", "MFirebaseKitAnalyticsShared"]
        )
    ]
)
