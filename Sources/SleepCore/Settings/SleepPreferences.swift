import Foundation

/// The settings every SleepGuard app has, with their defaults in one place.
/// An app adds its own extras beside it; how they are stored is
/// `SleepSettings`' `PreferencesDefaults`.
public struct SleepPreferences: Equatable, Sendable {
  public var sensitivity: DetectionSensitivity = .medium
  public var detectSleepTalking = false
  /// Debug builds: keep the night's full audio and its sample log.
  public var preserveRawAudio = false
  /// One of `RecordingDelay.options`.
  public var recordingDelayMinutes = 0
  public var limitStorage = true
  public var storageLimitMB = StorageLimits.defaultMegabytes
  public var limitDays = true
  public var maxDays = StorageLimits.defaultDays
  /// Write each saved night to Apple Health (apps and brands with HealthKit).
  public var syncToHealth = false
  public var briefingEnabled = true
  public var hasCompletedProfile = false
  /// The first-launch onboarding was finished.
  public var hasCompletedOnboarding = false
  /// When the morning briefing was last shown (it shows once per new night).
  public var lastBriefingShown: Date?
  /// Each dismissal of the profile prompt halves its chance of coming back.
  public var profilePromptDismissCount = 0
  /// The Snore Interrupter: how long it plays, and which sound.
  public var interrupterMode: SnoreInterrupterMode = .never
  public var melodyID = Melody.defaultID

  public init() {}

  /// The limits as `StoragePlan` takes them: `nil` when off.
  public var maxDaysLimit: Int? { limitDays ? maxDays : nil }
  public var maxMegabytesLimit: Int? { limitStorage ? storageLimitMB : nil }
}
