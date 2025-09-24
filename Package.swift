// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
  name: "CirrusAMMGenerator",
  defaultLocalization: "en",
  platforms: [.macOS(.v14)],
  products: [
    // Products define the executables and libraries a package produces, and make them visible to other packages.
    .library(name: "libCirrusAMMGenerator", targets: ["libCirrusAMMGenerator"]),
    .library(name: "libCommon", targets: ["libCommon"]),
    .executable(name: "cirrus-amm-generator", targets: ["CirrusAMMGenerator"])
  ],
  dependencies: [
    // Dependencies declare other packages that this package depends on.
    .package(url: "https://github.com/apple/swift-argument-parser.git", from: "1.5.0"),
    .package(url: "https://github.com/apple/swift-log.git", from: "1.6.1"),
    .package(url: "https://github.com/scinfu/SwiftSoup.git", from: "2.7.5")
  ],
  targets: [
    // Targets are the basic building blocks of a package. A target can define a module or a test suite.
    // Targets can depend on other targets in this package, and on products in packages this package depends on.
    .target(
      name: "libCirrusAMMGenerator",
      dependencies: [
        .target(name: "libCommon"),
        .product(name: "Logging", package: "swift-log"),
        "SwiftSoup"
      ]
    ),
    .target(name: "libCommon"),
    .executableTarget(
      name: "CirrusAMMGenerator",
      dependencies: [
        .target(name: "libCirrusAMMGenerator"),
        .target(name: "libCommon"),
        .product(name: "ArgumentParser", package: "swift-argument-parser"),
        .product(name: "Logging", package: "swift-log")
      ]
    ),
    .testTarget(
      name: "CirrusAMMGeneratorTests",
      dependencies: ["libCirrusAMMGenerator"]
    )
  ],
  swiftLanguageModes: [.v6]
)
