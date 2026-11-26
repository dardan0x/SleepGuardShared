public import Foundation
public import os

/// Unified logging, the same categories in every app and in the shared
/// products. Use these instead of `print`: they reach Console and
/// sysdiagnose in Release builds, so a 4 a.m. problem on a device can be read
/// afterwards.
///
/// Levels: `.debug` for traces (not persisted), `.info` for milestones,
/// `.notice` for notable state changes, `.error` for failures, `.fault` for
/// "this should never happen". Interpolated strings are private by default;
/// mark values `privacy: .public` only when they can't identify the user
/// (numbers, enum cases, error descriptions).
///
/// The subsystem is the app's bundle id, so each app (each brand) streams its
/// own: `log stream --predicate 'subsystem == "<bundle id>"' --level debug`.
public enum Log {
  public static let subsystem = Bundle.main.bundleIdentifier ?? "SleepGuard"

  /// Capture, analysis, clips.
  public static let audio = Logger(subsystem: subsystem, category: "audio")
  /// Classification and the detection engine.
  public static let detection = Logger(subsystem: subsystem, category: "detection")
  /// A night's lifecycle: start, stop, save, recovery.
  public static let session = Logger(subsystem: subsystem, category: "session")
  /// The Snore Interrupter.
  public static let interrupter = Logger(subsystem: subsystem, category: "interrupter")
  /// Files and the database.
  public static let storage = Logger(subsystem: subsystem, category: "storage")
  /// Clip playback.
  public static let playback = Logger(subsystem: subsystem, category: "playback")
  /// Apple Health.
  public static let health = Logger(subsystem: subsystem, category: "health")
  /// Launch, navigation, everything else.
  public static let app = Logger(subsystem: subsystem, category: "app")

  /// Intervals for Instruments (Points of Interest): one per night, one per
  /// snore event.
  public static let signposter = OSSignposter(logger: session)
}
