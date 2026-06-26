// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "YuzuriKit",
    platforms: [.iOS(.v18), .macOS(.v14)],
    products: [
        .library(name: "YuzuriKit", targets: ["YuzuriKit"]),
    ],
    targets: [
        .target(name: "YuzuriKit"),
        .testTarget(
            name: "YuzuriKitTests",
            dependencies: ["YuzuriKit"],
            resources: [.copy("Resources")]
        ),
    ]
)
