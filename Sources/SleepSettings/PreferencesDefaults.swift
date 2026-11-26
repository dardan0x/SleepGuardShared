public import Foundation
public import SleepCore

/// `SleepPreferences` in `UserDefaults`, the same in every app: the keys, the
/// default when a key is missing, and what counts as a valid stored value
/// (a delay must be one of `RecordingDelay.options`; a limit or a melody id
/// of 0 means "not set").
///
/// Read and write a setting at a time (an app that observes each one), or
/// the whole value (an app that loads and saves settings as one). A value
/// type over a suite name, so it is `Sendable`.
public struct PreferencesDefaults: Sendable {
  public enum Key {
    public static let sensitivity = "detectionSensitivity"
    public static let detectSleepTalking = "detectSleepTalking"
    public static let preserveRawAudio = "preserveRawAudio"
    public static let recordingDelayMinutes = "recordingDelayMinutes"
    public static let limitStorage = "limitStorageEnabled"
    public static let storageLimitMB = "storageLimitMB"
    public static let limitDays = "limitDaysEnabled"
    public static let maxDays = "maxDays"
    public static let syncToHealth = "syncToHealthKit"
    public static let briefingEnabled = "briefingEnabled"
    public static let hasCompletedProfile = "hasCompletedProfile"
    public static let hasCompletedOnboarding = "hasCompletedOnboarding"
    public static let lastBriefingShown = "lastBriefingShownDate"
    public static let profilePromptDismissCount = "profilePromptDismissCount"
    public static let interrupterMode = "snoreInterrupterMode"
    public static let melodyID = "snoreInterrupterMelodyID"

    /// Every key, for clearing them all.
    public static let all = [
      sensitivity, detectSleepTalking, preserveRawAudio, recordingDelayMinutes, limitStorage, storageLimitMB,
      limitDays, maxDays, syncToHealth, briefingEnabled, hasCompletedProfile, hasCompletedOnboarding,
      lastBriefingShown, profilePromptDismissCount, interrupterMode, melodyID,
    ]
  }

  private let suiteName: String?

  /// `nil`: the app's standard defaults. Tests pass a suite of their own.
  public init(suiteName: String? = nil) {
    self.suiteName = suiteName
  }

  private var defaults: UserDefaults {
    suiteName.flatMap(UserDefaults.init(suiteName:)) ?? .standard
  }

  private static let fallback = SleepPreferences()

  // MARK: - The whole value

  public func load() -> SleepPreferences {
    var preferences = SleepPreferences()
    preferences.sensitivity = sensitivity
    preferences.detectSleepTalking = detectSleepTalking
    preferences.preserveRawAudio = preserveRawAudio
    preferences.recordingDelayMinutes = recordingDelayMinutes
    preferences.limitStorage = limitStorage
    preferences.storageLimitMB = storageLimitMB
    preferences.limitDays = limitDays
    preferences.maxDays = maxDays
    preferences.syncToHealth = syncToHealth
    preferences.briefingEnabled = briefingEnabled
    preferences.hasCompletedProfile = hasCompletedProfile
    preferences.hasCompletedOnboarding = hasCompletedOnboarding
    preferences.lastBriefingShown = lastBriefingShown
    preferences.profilePromptDismissCount = profilePromptDismissCount
    preferences.interrupterMode = interrupterMode
    preferences.melodyID = melodyID
    return preferences
  }

  public func save(_ preferences: SleepPreferences) {
    sensitivity = preferences.sensitivity
    detectSleepTalking = preferences.detectSleepTalking
    preserveRawAudio = preferences.preserveRawAudio
    recordingDelayMinutes = preferences.recordingDelayMinutes
    limitStorage = preferences.limitStorage
    storageLimitMB = preferences.storageLimitMB
    limitDays = preferences.limitDays
    maxDays = preferences.maxDays
    syncToHealth = preferences.syncToHealth
    briefingEnabled = preferences.briefingEnabled
    hasCompletedProfile = preferences.hasCompletedProfile
    hasCompletedOnboarding = preferences.hasCompletedOnboarding
    lastBriefingShown = preferences.lastBriefingShown
    profilePromptDismissCount = preferences.profilePromptDismissCount
    interrupterMode = preferences.interrupterMode
    melodyID = preferences.melodyID
  }

  /// Back to every default (delete all data).
  public func removeAll() {
    Key.all.forEach(defaults.removeObject(forKey:))
  }

  // MARK: - One setting at a time

  public var sensitivity: DetectionSensitivity {
    get { defaults.string(forKey: Key.sensitivity).flatMap(DetectionSensitivity.init(rawValue:)) ?? Self.fallback.sensitivity }
    nonmutating set { defaults.set(newValue.rawValue, forKey: Key.sensitivity) }
  }

  public var detectSleepTalking: Bool {
    get { bool(Key.detectSleepTalking) ?? Self.fallback.detectSleepTalking }
    nonmutating set { defaults.set(newValue, forKey: Key.detectSleepTalking) }
  }

  public var preserveRawAudio: Bool {
    get { bool(Key.preserveRawAudio) ?? Self.fallback.preserveRawAudio }
    nonmutating set { defaults.set(newValue, forKey: Key.preserveRawAudio) }
  }

  public var recordingDelayMinutes: Int {
    get { RecordingDelay.valid(defaults.integer(forKey: Key.recordingDelayMinutes)) }
    nonmutating set { defaults.set(newValue, forKey: Key.recordingDelayMinutes) }
  }

  public var limitStorage: Bool {
    get { bool(Key.limitStorage) ?? Self.fallback.limitStorage }
    nonmutating set { defaults.set(newValue, forKey: Key.limitStorage) }
  }

  public var storageLimitMB: Int {
    get { positive(Key.storageLimitMB) ?? Self.fallback.storageLimitMB }
    nonmutating set { defaults.set(newValue, forKey: Key.storageLimitMB) }
  }

  public var limitDays: Bool {
    get { bool(Key.limitDays) ?? Self.fallback.limitDays }
    nonmutating set { defaults.set(newValue, forKey: Key.limitDays) }
  }

  public var maxDays: Int {
    get { positive(Key.maxDays) ?? Self.fallback.maxDays }
    nonmutating set { defaults.set(newValue, forKey: Key.maxDays) }
  }

  public var syncToHealth: Bool {
    get { bool(Key.syncToHealth) ?? Self.fallback.syncToHealth }
    nonmutating set { defaults.set(newValue, forKey: Key.syncToHealth) }
  }

  public var briefingEnabled: Bool {
    get { bool(Key.briefingEnabled) ?? Self.fallback.briefingEnabled }
    nonmutating set { defaults.set(newValue, forKey: Key.briefingEnabled) }
  }

  public var hasCompletedProfile: Bool {
    get { bool(Key.hasCompletedProfile) ?? Self.fallback.hasCompletedProfile }
    nonmutating set { defaults.set(newValue, forKey: Key.hasCompletedProfile) }
  }

  public var hasCompletedOnboarding: Bool {
    get { bool(Key.hasCompletedOnboarding) ?? Self.fallback.hasCompletedOnboarding }
    nonmutating set { defaults.set(newValue, forKey: Key.hasCompletedOnboarding) }
  }

  public var lastBriefingShown: Date? {
    get { defaults.object(forKey: Key.lastBriefingShown) as? Date }
    nonmutating set {
      if let newValue {
        defaults.set(newValue, forKey: Key.lastBriefingShown)
      } else {
        defaults.removeObject(forKey: Key.lastBriefingShown)
      }
    }
  }

  public var profilePromptDismissCount: Int {
    get { defaults.integer(forKey: Key.profilePromptDismissCount) }
    nonmutating set { defaults.set(newValue, forKey: Key.profilePromptDismissCount) }
  }

  public var interrupterMode: SnoreInterrupterMode {
    get { SnoreInterrupterMode(stored: defaults.string(forKey: Key.interrupterMode)) }
    nonmutating set { defaults.set(newValue.rawValue, forKey: Key.interrupterMode) }
  }

  public var melodyID: Int {
    get { positive(Key.melodyID) ?? Self.fallback.melodyID }
    nonmutating set { defaults.set(newValue, forKey: Key.melodyID) }
  }

  // MARK: - Reading

  /// `nil` when the key was never set (so the default applies, even one of true).
  private func bool(_ key: String) -> Bool? {
    defaults.object(forKey: key) == nil ? nil : defaults.bool(forKey: key)
  }

  /// `nil` when unset or not positive ("not set" for limits and ids).
  private func positive(_ key: String) -> Int? {
    let value = defaults.integer(forKey: key)
    return value > 0 ? value : nil
  }
}
