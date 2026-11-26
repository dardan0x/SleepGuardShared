import SleepCore
import SwiftUI
import SleepGuardDesignKit

/// Settings, the profile editor, the start delay and its countdown with sample
/// values, for previews and render tests. Internal: sample data only. The
/// scrolling parts are drawn without their scroll view (`ImageRenderer` can't
/// draw inside one); switches and segmented pickers don't draw either.
struct SettingsContentGallery: View {
  enum Screen: CaseIterable {
    /// Every section and row (SleepGuard in Debug).
    case settingsEverything
    /// No profile, Watch, Health, debug rows or rating.
    case settingsMinimal
    case profileYou
    case profileGoals
    case profileHabits
    case profilePersonal
    case profileControls
    case delayOptions
    case countdown
  }

  let screen: Screen
  @State private var profile = SleepProfile(firstName: "Sam", birthYear: 1990, heightCm: 180, hobbies: ["reading"])

  var body: some View {
    Group {
      switch screen {
      case .settingsEverything:
        Self.settings(everything: true)
      case .settingsMinimal:
        Self.settings(everything: false)
      case .profileYou:
        ProfileIdentityPage(profile: $profile)
      case .profileGoals:
        ProfileGoalsPage(profile: $profile)
      case .profileHabits:
        ProfileHabitsPage(profile: $profile)
      case .profilePersonal:
        ProfilePersonalPage(profile: $profile)
      case .profileControls:
        VStack {
          ProfileEditorBar(page: 1, onClose: {}, onSkip: {})
          ProfileEditorControls(page: 1, onContinue: {}, onBack: {}, onSave: {})
        }
      case .delayOptions:
        PrestartDelayOptions(minutes: .constant(30)).padding(24)
      case .countdown:
        RecordingCountdownContent(seconds: 1_799, onCancel: {}, onStartNow: {}).frame(height: 760)
      }
    }
    .environment(\.profilePageScrolls, false)
    .background(GalleryBackground())
  }

  private static func settings(everything: Bool) -> some View {
    SettingsStack(
      permissions: SettingsPermissions(microphone: .granted, notifications: .notDetermined, onMicrophone: {}, onNotifications: {}),
      recording: SettingsRecording(
        sensitivity: .constant(.medium),
        sleepTalking: everything ? .constant(true) : nil,
        preserveRawAudio: everything ? .constant(false) : nil),
      profile: everything ? SettingsProfile(onOpen: {}, briefing: .constant(true)) : nil,
      watch: everything ? SettingsWatch(isReachable: false, enhancedTracking: .constant(false)) : nil,
      storage: SettingsStorage(
        limitStorage: .constant(true), megabytes: .constant(500), limitDays: .constant(everything), days: .constant(30),
        onTestCleanup: everything ? {} : nil),
      data: SettingsData(healthSync: everything ? .constant(true) : nil, onDeleteAll: {}, onAddSampleNights: everything ? {} : nil),
      about: SettingsAbout(version: "1.4.0", onRate: everything ? {} : nil),
      extra: EmptyView())
  }
}

private struct GalleryBackground: View {
  @Environment(\.theme) private var theme

  var body: some View {
    theme.palette.bgPrimary
  }
}

#Preview("Settings") {
  ScrollView { SettingsContentGallery(screen: .settingsEverything) }
}

#Preview("Profile editor") {
  @Previewable @State var profile = SleepProfile()
  ProfileEditorContent(profile: $profile, onSave: {}, onClose: {})
}

#Preview("Countdown") {
  SettingsContentGallery(screen: .countdown)
}
