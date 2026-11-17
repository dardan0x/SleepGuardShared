import SleepCore
import SwiftUI

/// Settings, section by section. The screen owns every value: it reads the
/// stores, passes bindings, and decides what a tap does (ask for a
/// permission, confirm a lower limit, delete everything). A section or row
/// passed as `nil` isn't shown, so a brand without Apple Health or a Watch
/// simply leaves them out. `extra` goes at the end (SleepGuard's debug tools).
public struct SettingsContent<Extra: View>: View {
  let permissions: SettingsPermissions
  let recording: SettingsRecording
  let profile: SettingsProfile?
  let watch: SettingsWatch?
  let storage: SettingsStorage
  let data: SettingsData
  let about: SettingsAbout
  let extra: Extra

  public init(
    permissions: SettingsPermissions,
    recording: SettingsRecording,
    profile: SettingsProfile?,
    watch: SettingsWatch?,
    storage: SettingsStorage,
    data: SettingsData,
    about: SettingsAbout,
    @ViewBuilder extra: () -> Extra)
  {
    self.permissions = permissions
    self.recording = recording
    self.profile = profile
    self.watch = watch
    self.storage = storage
    self.data = data
    self.about = about
    self.extra = extra()
  }

  public var body: some View {
    ScrollView {
      SettingsStack(
        permissions: permissions, recording: recording, profile: profile, watch: watch,
        storage: storage, data: data, about: about, extra: extra)
    }
    .scrollContentBackground(.hidden)
  }
}

public extension SettingsContent where Extra == EmptyView {
  init(
    permissions: SettingsPermissions,
    recording: SettingsRecording,
    profile: SettingsProfile?,
    watch: SettingsWatch?,
    storage: SettingsStorage,
    data: SettingsData,
    about: SettingsAbout)
  {
    self.init(
      permissions: permissions, recording: recording, profile: profile, watch: watch,
      storage: storage, data: data, about: about) { EmptyView() }
  }
}

/// The sections inside the scroll view (render tests draw this).
struct SettingsStack<Extra: View>: View {
  let permissions: SettingsPermissions
  let recording: SettingsRecording
  let profile: SettingsProfile?
  let watch: SettingsWatch?
  let storage: SettingsStorage
  let data: SettingsData
  let about: SettingsAbout
  let extra: Extra

  var body: some View {
    VStack(spacing: 24) {
      SettingsPermissionsSection(values: permissions)
      SettingsRecordingSection(values: recording)
      SettingsAppearanceSection()
      if let profile { SettingsProfileSection(values: profile) }
      if let watch { SettingsWatchSection(values: watch) }
      SettingsStorageSection(values: storage)
      SettingsDataSection(values: data)
      SettingsAboutSection(values: about)
      extra
    }
    .padding(.horizontal, 20)
    .padding(.top, 20)
    .padding(.bottom, 24)
  }
}

// MARK: - Values

public struct SettingsPermissions {
  let microphone: SettingsPermission
  let notifications: SettingsPermission
  let onMicrophone: () -> Void
  let onNotifications: () -> Void

  /// A tap asks when not yet asked and opens the system settings when denied:
  /// the screen decides.
  public init(
    microphone: SettingsPermission, notifications: SettingsPermission,
    onMicrophone: @escaping () -> Void, onNotifications: @escaping () -> Void)
  {
    self.microphone = microphone
    self.notifications = notifications
    self.onMicrophone = onMicrophone
    self.onNotifications = onNotifications
  }
}

public struct SettingsRecording {
  let sensitivity: Binding<DetectionSensitivity>
  let sleepTalking: Binding<Bool>?
  let preserveRawAudio: Binding<Bool>?

  /// `sleepTalking` when the app detects talking; `preserveRawAudio` in
  /// Debug builds that keep the night's audio and sample log.
  public init(sensitivity: Binding<DetectionSensitivity>, sleepTalking: Binding<Bool>?, preserveRawAudio: Binding<Bool>?) {
    self.sensitivity = sensitivity
    self.sleepTalking = sleepTalking
    self.preserveRawAudio = preserveRawAudio
  }
}

public struct SettingsProfile {
  let onOpen: () -> Void
  let briefing: Binding<Bool>?

  public init(onOpen: @escaping () -> Void, briefing: Binding<Bool>?) {
    self.onOpen = onOpen
    self.briefing = briefing
  }
}

public struct SettingsWatch {
  let isReachable: Bool
  let enhancedTracking: Binding<Bool>?

  public init(isReachable: Bool, enhancedTracking: Binding<Bool>?) {
    self.isReachable = isReachable
    self.enhancedTracking = enhancedTracking
  }
}

public struct SettingsStorage {
  let limitStorage: Binding<Bool>
  let megabytes: Binding<Int>
  let limitDays: Binding<Bool>
  let days: Binding<Int>
  let onTestCleanup: (() -> Void)?

  /// `megabytes`' setter is the screen's: it confirms before lowering the
  /// limit. `onTestCleanup` in Debug builds.
  public init(
    limitStorage: Binding<Bool>, megabytes: Binding<Int>, limitDays: Binding<Bool>, days: Binding<Int>,
    onTestCleanup: (() -> Void)? = nil)
  {
    self.limitStorage = limitStorage
    self.megabytes = megabytes
    self.limitDays = limitDays
    self.days = days
    self.onTestCleanup = onTestCleanup
  }
}

public struct SettingsData {
  let healthSync: Binding<Bool>?
  let onDeleteAll: () -> Void
  let onAddSampleNights: (() -> Void)?

  /// `healthSync` when the app writes nights to Apple Health;
  /// `onAddSampleNights` in Debug builds.
  public init(healthSync: Binding<Bool>?, onDeleteAll: @escaping () -> Void, onAddSampleNights: (() -> Void)? = nil) {
    self.healthSync = healthSync
    self.onDeleteAll = onDeleteAll
    self.onAddSampleNights = onAddSampleNights
  }
}

public struct SettingsAbout {
  let version: String
  let onRate: (() -> Void)?

  /// `onRate` once the app has an App Store page.
  public init(version: String, onRate: (() -> Void)?) {
    self.version = version
    self.onRate = onRate
  }
}
