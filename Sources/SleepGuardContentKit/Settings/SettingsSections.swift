import SleepCore
import SwiftUI
import SleepGuardDesignKit
import SleepStrings

struct SettingsPermissionsSection: View {
  let values: SettingsPermissions

  var body: some View {
    SettingsCard(title: Strings.settingsSectionPermissions) {
      SettingsPermissionRow(
        icon: "mic.fill", title: Strings.settingsMicrophoneAccess, status: values.microphone, action: values.onMicrophone)
      SettingsPermissionRow(
        icon: "bell.fill", title: Strings.settingsNotificationsAccess, status: values.notifications,
        action: values.onNotifications)
    }
  }
}

struct SettingsRecordingSection: View {
  let values: SettingsRecording
  @Environment(\.theme) private var theme

  var body: some View {
    SettingsCard(title: Strings.settingsSectionDetection) {
      SettingsRow(icon: "waveform", color: theme.palette.accent, title: Strings.settingsSensitivity) {
        Picker(selection: values.sensitivity) {
          Text(Strings.settingsSensitivityLow).tag(DetectionSensitivity.low)
          Text(Strings.settingsSensitivityMedium).tag(DetectionSensitivity.medium)
          Text(Strings.settingsSensitivityHigh).tag(DetectionSensitivity.high)
        } label: {
          Text(Strings.settingsSensitivity)
        }
        .pickerStyle(.segmented)
        .frame(width: 180)
      }
      if let sleepTalking = values.sleepTalking {
        SettingsToggleRow(
          icon: "bubble.left.fill", color: theme.palette.accent, title: Strings.settingsDetectSleepTalking,
          isOn: sleepTalking)
      }
      if let preserveRawAudio = values.preserveRawAudio {
        SettingsToggleRow(
          icon: "archivebox.fill", color: theme.palette.accent, title: Strings.settingsPreserveRawAudio,
          subtitle: Strings.settingsPreserveRawAudioDescription, isOn: preserveRawAudio)
      }
    }
  }
}

/// The app is always dark.
struct SettingsAppearanceSection: View {
  @Environment(\.theme) private var theme

  var body: some View {
    SettingsCard(title: Strings.settingsSectionAppearance) {
      SettingsRow(icon: "paintpalette", color: theme.palette.scoreGreen, title: Strings.settingsTheme) {
        Text(Strings.settingsThemeAlwaysDark)
          .font(theme.typography.font(size: 15))
          .foregroundStyle(theme.palette.textTertiary)
      }
    }
  }
}

struct SettingsProfileSection: View {
  let values: SettingsProfile
  @Environment(\.theme) private var theme

  var body: some View {
    SettingsCard(title: Strings.settingsSectionProfile) {
      SettingsButtonRow(
        icon: "person.fill", color: theme.palette.accent, title: Strings.settingsProfile, chevron: true,
        action: values.onOpen)
      if let briefing = values.briefing {
        SettingsToggleRow(
          icon: "sunrise.fill", color: theme.palette.accent, title: Strings.settingsBriefing,
          subtitle: Strings.settingsBriefingDescription, isOn: briefing)
      }
    }
  }
}

struct SettingsWatchSection: View {
  let values: SettingsWatch
  @Environment(\.theme) private var theme

  var body: some View {
    SettingsCard(title: Strings.settingsSectionWatch) {
      SettingsRow(icon: "watch.fill", color: theme.palette.accent, title: Strings.watchTitle) {
        let color = values.isReachable ? theme.palette.scoreGreen : theme.palette.textTertiary
        HStack(spacing: 4) {
          Circle().fill(color).frame(width: 8, height: 8).accessibilityHidden(true)
          Text(values.isReachable ? Strings.watchStatusConnected : Strings.watchStatusNotConnected)
            .font(theme.typography.font(size: 15))
            .foregroundStyle(color)
        }
      }
      if let enhancedTracking = values.enhancedTracking {
        SettingsToggleRow(
          icon: "bed.double.fill", color: theme.palette.accent, title: Strings.settingsEnhancedSleepTracking,
          isOn: enhancedTracking)
      }
    }
  }
}

struct SettingsStorageSection: View {
  let values: SettingsStorage
  @Environment(\.theme) private var theme

  var body: some View {
    SettingsCard(title: Strings.settingsSectionStorage) {
      SettingsToggleRow(
        icon: "externaldrive.fill", color: theme.palette.accent, title: Strings.settingsLimitStorage,
        subtitle: Strings.settingsLimitStorageDescription, isOn: values.limitStorage)
      if values.limitStorage.wrappedValue {
        SettingsMenuRow(
          icon: "gauge.with.dots.needle.67percent", title: Strings.settingsStorageLimitMb,
          options: StorageLimits.megabyteOptions, unit: Strings.settingsUnitMb, selection: values.megabytes)
      }
      SettingsToggleRow(
        icon: "calendar.badge.clock", color: theme.palette.accent, title: Strings.settingsLimitDays,
        subtitle: Strings.settingsLimitDaysDescription, isOn: values.limitDays)
      if values.limitDays.wrappedValue {
        SettingsMenuRow(
          icon: "clock.arrow.circlepath", title: Strings.settingsMaxDays,
          options: StorageLimits.dayOptions, unit: Strings.settingsUnitDays, selection: values.days)
      }
      if let onTestCleanup = values.onTestCleanup {
        SettingsButtonRow(
          icon: "testtube.2", color: theme.palette.accent, title: Strings.settingsTestCleanup,
          titleColor: theme.palette.accent, action: onTestCleanup)
      }
    }
  }
}

struct SettingsDataSection: View {
  let values: SettingsData
  @Environment(\.theme) private var theme

  var body: some View {
    SettingsCard(title: Strings.settingsSectionData) {
      if let healthSync = values.healthSync {
        SettingsToggleRow(icon: "heart.fill", color: .settingsHealth, title: Strings.settingsSyncHealth, isOn: healthSync)
      }
      SettingsButtonRow(
        icon: "trash", color: theme.palette.destructive, title: Strings.settingsDeleteAll,
        titleColor: theme.palette.destructive, action: values.onDeleteAll)
      if let onAddSampleNights = values.onAddSampleNights {
        // Debug builds only: not localized.
        SettingsButtonRow(
          icon: "wand.and.stars", color: theme.palette.accent, title: "Generate Mock Data",
          titleColor: theme.palette.accent, action: onAddSampleNights)
      }
    }
  }
}

struct SettingsAboutSection: View {
  let values: SettingsAbout
  @Environment(\.theme) private var theme

  var body: some View {
    SettingsCard(title: Strings.settingsSectionAbout) {
      SettingsRow(icon: "info.circle.fill", color: .settingsInfo, title: Strings.settingsVersion) {
        Text(verbatim: values.version)
          .font(theme.typography.font(size: 15))
          .foregroundStyle(theme.palette.textTertiary)
      }
      if let onRate = values.onRate {
        SettingsButtonRow(
          icon: "star.fill", color: .settingsRate, title: Strings.settingsRateApp, titleColor: theme.palette.accent,
          chevron: true, action: onRate)
      }
    }
  }
}
