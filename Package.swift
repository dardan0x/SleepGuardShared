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
    // The Snore Interrupter's built-in sound files (the catalog is SleepCore's `Melody`).
    .library(name: "SleepMelodies", targets: ["SleepMelodies"]),
    // Theme tokens and primitive SwiftUI components. No domain types, no DI.
    // Re-exports SleepStrings.
    .library(name: "SleepGuardDesignKit", targets: ["SleepGuardDesignKit"]),
    // Screen content: one screen's loaded layout, values and actions in.
    // Each app hosts it in its own screen (loading, navigation, DI).
    // Re-exports the design kit.
    .library(name: "SleepGuardContentKit", targets: ["SleepGuardContentKit"]),
    // A night in Apple Health (write the night, read its stages), the same in
    // every app. Its own product: an app or brand without HealthKit skips it.
    .library(name: "SleepHealthKit", targets: ["SleepHealthKit"]),
    // Files every app writes the same way: the raw log.
    .library(name: "SleepFiles", targets: ["SleepFiles"]),
    // The settings every app has, in UserDefaults: keys, defaults, validity.
    .library(name: "SleepSettings", targets: ["SleepSettings"]),
    // Unified logging: the same categories in every app and shared product.
    .library(name: "SleepLogging", targets: ["SleepLogging"]),
    // The start-delay notification, the same in every app.
    .library(name: "SleepNotifications", targets: ["SleepNotifications"]),
    /// Microphone capture, clip compression, playback, waveforms, spectra,
    /// clip extraction and the Snore Interrupter's melodies (AVFoundation, iOS).
    .library(name: "SleepAudioKit", targets: ["SleepAudioKit"]),
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
      name: "SleepMelodies",
      dependencies: ["SleepCore"],
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
    .target(
      name: "SleepHealthKit",
      dependencies: ["SleepCore"],
      swiftSettings: [.swiftLanguageMode(.v6)]),
    .target(
      name: "SleepLogging",
      swiftSettings: [.swiftLanguageMode(.v6)]),
    .target(
      name: "SleepNotifications",
      dependencies: ["SleepStrings"],
      swiftSettings: [.swiftLanguageMode(.v6)]),
    .testTarget(
      name: "SleepNotificationsTests",
      dependencies: ["SleepNotifications"],
      swiftSettings: [.swiftLanguageMode(.v6)]),
    .target(
      name: "SleepAudioKit",
      dependencies: ["SleepCore", "SleepLogging", "SleepMelodies"],
      swiftSettings: [.swiftLanguageMode(.v6)]),
    .testTarget(
      name: "SleepAudioKitTests",
      dependencies: ["SleepAudioKit", "SleepCore"],
      swiftSettings: [.swiftLanguageMode(.v6)]),
    .target(
      name: "SleepFiles",
      dependencies: ["SleepCore", "SleepLogging"],
      swiftSettings: [.swiftLanguageMode(.v6)]),
    .target(
      name: "SleepSettings",
      dependencies: ["SleepCore"],
      swiftSettings: [.swiftLanguageMode(.v6)]),
    .testTarget(
      name: "SleepSettingsTests",
      dependencies: ["SleepSettings", "SleepCore"],
      swiftSettings: [.swiftLanguageMode(.v6)]),
    .testTarget(
      name: "SleepHealthKitTests",
      dependencies: ["SleepHealthKit", "SleepCore"],
      swiftSettings: [.swiftLanguageMode(.v6)]),
    .testTarget(
      name: "SleepFilesTests",
      dependencies: ["SleepFiles", "SleepCore"],
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
      name: "SleepMelodiesTests",
      dependencies: ["SleepMelodies", "SleepCore"],
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
