// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "RedAlertMonitor",
    platforms: [.macOS(.v13)],
    targets: [
        .executableTarget(
            name: "RedAlertMonitor",
            path: "Sources/RedAlertMonitor",
            exclude: ["Resources/Info.plist"]
        )
    ]
)
