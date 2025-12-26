// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "CoquiUI",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .executable(name: "CoquiUI", targets: ["CoquiUI"])
    ],
    dependencies: [],
    targets: [
        .executableTarget(
            name: "CoquiUI",
            dependencies: [],
            path: "Sources"
        )
    ]
)
