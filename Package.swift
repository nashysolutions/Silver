// swift-tools-version:5.1
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Silver",
    platforms: [.iOS(.v10)],
    products: [.library(name: "Silver", targets: ["Silver"])],
    targets: [.target(name: "Silver", dependencies: [])]
)
