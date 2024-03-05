// swift-tools-version:5.0

import PackageDescription

let package = Package(
    name: "Geodesy",
    products: [
        .library(
            name: "Geodesy",
            targets: ["GeodesySpherical"]),
    ],
    dependencies: [],
    targets: [
        .target(
            name: "GeodesySpherical",
            dependencies: []),
        .testTarget(
            name: "GeodesySphericalTests",
            dependencies: ["GeodesySpherical"]),
    ]
)
