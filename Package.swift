// swift-tools-version:5.1
// The swift-tools-version declares the minimum version of Swift required to build this package.
import PackageDescription

let package = Package(
    name: "TimelaneCombineX",
    platforms: [
      .macOS(.v10_14),
      .iOS(.v12),
      .tvOS(.v12),
      .watchOS(.v5)
    ],
    products: [
        .library(
            name: "TimelaneCombineX",
            targets: ["TimelaneCombineX"]),
    ],
    dependencies: [
        .package(url: "https://github.com/icanzilb/TimelaneCore", from: "1.0.0"),
        .package(url: "https://github.com/cx-org/CombineX", from: "0.2.1")
    ],
    targets: [
        .target(
            name: "TimelaneCombineX",
            dependencies: [
                "TimelaneCore",
                "CombineX"
            ]),
        .testTarget(
            name: "TimelaneCombineXTests",
            dependencies: [
                "TimelaneCombineX",
                "TimelaneCoreTestUtils"
            ]),
    ],
    swiftLanguageVersions: [.v5]
)
