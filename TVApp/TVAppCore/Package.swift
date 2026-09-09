// swift-tools-version:5.9
import PackageDescription

/// Pure-Foundation core: models, networking, and HTML stripping — no Combine,
/// no SwiftUI, no UIKit import anywhere in this target. That's what makes it
/// buildable and testable with plain `swift build` / `swift test` on Linux and
/// on the official Swift toolchain for Windows (`winget install --id Swift.Toolchain`),
/// with zero Mac, zero cloud, and zero cost. The iOS app target consumes this
/// package as a local dependency (see ../project.yml) for the real UI layer,
/// which still needs Xcode/macOS to build.
let package = Package(
    name: "TVAppCore",
    platforms: [
        .iOS(.v16),
        .macOS(.v13)
    ],
    products: [
        .library(name: "TVAppCore", targets: ["TVAppCore"])
    ],
    targets: [
        .target(name: "TVAppCore"),
        .testTarget(name: "TVAppCoreTests", dependencies: ["TVAppCore"])
    ]
)
