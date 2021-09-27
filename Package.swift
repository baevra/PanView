// swift-tools-version:5.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
  name: "PanView",
  platforms: [.iOS(.v11)],
  products: [
    .library(
      name: "PanView",
      targets: ["PanView"]
    )
  ],
  dependencies: [],
  targets: [
    .target(
      name: "PanView",
      dependencies: []
    ),
    .testTarget(
      name: "PanViewTests",
      dependencies: ["PanView"]
    )
  ]
)
