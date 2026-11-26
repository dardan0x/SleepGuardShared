import Foundation
import SleepCore
import Testing
@testable import SleepSettings

/// The settings both apps store: defaults when unset, a round trip, the
/// validity rules, and per-setting access agreeing with the whole value.
struct PreferencesDefaultsTests {
  private func store() -> (PreferencesDefaults, String) {
    let suite = "prefs-\(UUID().uuidString)"
    return (PreferencesDefaults(suiteName: suite), suite)
  }

  @Test func nothingStoredIsEveryDefault() {
    let (store, suite) = store()
    defer { UserDefaults().removePersistentDomain(forName: suite) }
    #expect(store.load() == SleepPreferences())
  }

  @Test func aSavedValueLoadsBackEqual() {
    let (store, suite) = store()
    defer { UserDefaults().removePersistentDomain(forName: suite) }
    var preferences = SleepPreferences()
    preferences.sensitivity = .high
    preferences.detectSleepTalking = true
    preferences.recordingDelayMinutes = RecordingDelay.options.last ?? 0
    preferences.limitStorage = false
    preferences.storageLimitMB = 1000
    preferences.limitDays = false
    preferences.maxDays = 90
    preferences.syncToHealth = true
    preferences.briefingEnabled = false
    preferences.hasCompletedProfile = true
    preferences.hasCompletedOnboarding = true
    preferences.lastBriefingShown = Date(timeIntervalSinceReferenceDate: 800_000_000)
    preferences.profilePromptDismissCount = 2
    preferences.interrupterMode = .always
    preferences.melodyID = 3

    store.save(preferences)

    #expect(store.load() == preferences)
  }

  @Test func invalidStoredValuesReadAsDefaults() {
    let (store, suite) = store()
    defer { UserDefaults().removePersistentDomain(forName: suite) }
    let defaults = UserDefaults(suiteName: suite)!
    defaults.set("loudest", forKey: PreferencesDefaults.Key.sensitivity)
    defaults.set(7, forKey: PreferencesDefaults.Key.recordingDelayMinutes)
    defaults.set(0, forKey: PreferencesDefaults.Key.storageLimitMB)
    defaults.set(-1, forKey: PreferencesDefaults.Key.melodyID)
    defaults.set("sometimes", forKey: PreferencesDefaults.Key.interrupterMode)

    let fallback = SleepPreferences()
    #expect(store.sensitivity == fallback.sensitivity)
    #expect(store.recordingDelayMinutes == RecordingDelay.valid(7))
    #expect(store.storageLimitMB == fallback.storageLimitMB)
    #expect(store.melodyID == fallback.melodyID)
    #expect(store.interrupterMode == .never)
  }

  @Test func oneSettingAtATimeIsTheWholeValue() {
    let (store, suite) = store()
    defer { UserDefaults().removePersistentDomain(forName: suite) }
    store.maxDays = 14
    store.lastBriefingShown = Date(timeIntervalSinceReferenceDate: 1)
    #expect(store.load().maxDays == 14)
    store.lastBriefingShown = nil
    #expect(store.load().lastBriefingShown == nil)
  }

  @Test func removeAllGoesBackToTheDefaults() {
    let (store, suite) = store()
    defer { UserDefaults().removePersistentDomain(forName: suite) }
    store.hasCompletedOnboarding = true
    store.maxDays = 7
    store.removeAll()
    #expect(store.load() == SleepPreferences())
  }
}
