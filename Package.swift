// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "Shelf",
    platforms: [.macOS(.v13)],
    targets: [
        .executableTarget(
            name: "Shelf",
            path: "Sources/Shelf",
            exclude: ["Resources"],
            swiftSettings: [
                .unsafeFlags(["-parse-as-library"])
            ],
            linkerSettings: [
                .linkedFramework("AppKit"),
                .linkedFramework("Carbon"),
                .linkedFramework("CoreGraphics"),
                .linkedFramework("ServiceManagement")
            ]
        )
    ]
)
