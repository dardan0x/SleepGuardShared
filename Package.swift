// swift-tools-version: 6.2
import PackageDescription

/// Code shared by the SleepGuard apps. One repo and one version, so a change
/// to the score, detection, strings or design tokens reaches every app the same way.
let package = Package(
  name: "SleepGuardShared",
  platforms: [.iOS(.v17), .watchOS(.v10), .macOS(.v14)],
  products: [
    // Pure values and rules: sleep score, detection state machine. Foundation only.
    .library(name: "SleepCore", targets: ["SleepCore"]),
    // The string catalog and its generated `Strings` accessor.
    .library(name: "SleepStrings", targets: ["SleepStrings"]),
    // Theme tokens and primitive SwiftUI components. No domain types, no DI.
    // Re-exports SleepStrings.
    .library(name: "SleepGuardDesignKit", targets: ["SleepGuardDesignKit"]),
    // Screen content: one screen's loaded layout, values and actions in.
    // Each app hosts it in its own screen (loading, navigation, DI).
    // Re-exports the design kit.
    .library(name: "SleepGuardContentKit", targets: ["SleepGuardContentKit"]),
  ],
  targets: [
    .target(
      name: "SleepCore",
      swiftSettings: [.swiftLanguageMode(.v6)]),
    .target(
      name: "SleepStrings",
      resources: [.process("Resources")],
      swiftSettings: [.swiftLanguageMode(.v6)]),
    .target(
      name: "SleepGuardDesignKit",
      dependencies: ["SleepStrings", "SleepCore"],
      swiftSettings: [.swiftLanguageMode(.v6)]),
    .target(
      name: "SleepGuardContentKit",
      dependencies: ["SleepGuardDesignKit", "SleepCore"],
      swiftSettings: [.swiftLanguageMode(.v6)]),
    .testTarget(
      name: "SleepCoreTests",
      dependencies: ["SleepCore"],
      resources: [.copy("Fixtures")],
      swiftSettings: [.swiftLanguageMode(.v6)]),
    .testTarget(
      name: "SleepStringsTests",
      dependencies: ["SleepStrings"],
      swiftSettings: [.swiftLanguageMode(.v6)]),
    .testTarget(
      name: "SleepGuardDesignKitTests",
      dependencies: ["SleepGuardDesignKit"],
      swiftSettings: [.swiftLanguageMode(.v6)]),
    .testTarget(
      name: "SleepGuardContentKitTests",
      dependencies: ["SleepGuardContentKit"],
      swiftSettings: [.swiftLanguageMode(.v6)]),
  ])
