// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "CourtStats",
    platforms: [.macOS(.v15)],
    products: [
        .executable(name: "courtstats", targets: ["CourtStatsCLI"]),
        .library(name: "CourtStatsCore", targets: ["CourtStatsCore"])
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-argument-parser.git",
                 from: "1.3.0")
    ],
    targets: [
        .target(name: "CourtStatsCore", path: "Sources/Core"),
        .executableTarget(
            name: "CourtStatsCLI",
            dependencies: [
                "CourtStatsCore",
                .product(name: "ArgumentParser",
                         package: "swift-argument-parser")
            ],
            path: "Sources/CLI"
        ),
        .testTarget(
            name: "CourtStatsCoreTests",
            dependencies: ["CourtStatsCore"],
            path: "Tests/CourtStatsCoreTests"
        ),
        .testTarget(
            name: "IntegrationTests",
            dependencies: ["CourtStatsCore"],
            path: "Tests/IntegrationTests",
            resources: [.copy("Fixtures")]
        )
    ]
)
