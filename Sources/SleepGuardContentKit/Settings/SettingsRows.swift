import SwiftUI
import SleepGuardDesignKit
import SleepStrings

/// A Settings section: a small caps title over a card of rows.
struct SettingsCard<Rows: View>: View {
  let title: String
  @ViewBuilder let rows: Rows
  @Environment(\.theme) private var theme

  var body: some View {
    VStack(alignment: .leading, spacing: 2) {
      Text(title)
        .font(theme.typography.font(size: 11, weight: .semibold))
        .foregroundStyle(theme.palette.textTertiary)
        .tracking(1)
        .accessibilityAddTraits(.isHeader)
      VStack(spacing: 16) {
        rows
      }
      .padding(16)
      .background(theme.palette.bgCard, in: .rect(cornerRadius: theme.radii.small))
    }
  }
}

/// The coloured square with a symbol at the start of a row.
struct SettingsIcon: View {
  let systemName: String
  let color: Color

  var body: some View {
    Image(systemName: systemName)
      .font(.system(size: 14))
      .foregroundStyle(.white)
      .frame(width: 28, height: 28)
      .background(color, in: .rect(cornerRadius: 7))
      .accessibilityHidden(true)
  }
}

/// Icon, title and an optional line under it; `trailing` at the end.
struct SettingsRow<Trailing: View>: View {
  let icon: String
  let color: Color
  let title: String
  var subtitle: String?
  var titleColor: Color?
  @ViewBuilder let trailing: Trailing
  @Environment(\.theme) private var theme

  var body: some View {
    HStack(spacing: 10) {
      SettingsIcon(systemName: icon, color: color)
      VStack(alignment: .leading, spacing: 2) {
        Text(title)
          .font(theme.typography.font(size: 15))
          .foregroundStyle(titleColor ?? theme.palette.textPrimary)
        if let subtitle {
          Text(subtitle)
            .font(theme.typography.font(size: 12))
            .foregroundStyle(theme.palette.textSecondary)
            .lineLimit(2)
        }
      }
      Spacer(minLength: 8)
      trailing
    }
  }
}

/// A row with a switch.
struct SettingsToggleRow: View {
  let icon: String
  let color: Color
  let title: String
  var subtitle: String?
  @Binding var isOn: Bool
  @Environment(\.theme) private var theme

  var body: some View {
    SettingsRow(icon: icon, color: color, title: title, subtitle: subtitle) {
      Toggle(isOn: $isOn) { Text(title) }
        .labelsHidden()
        .tint(theme.palette.scoreGreen)
    }
  }
}

/// A row that does something when tapped: delete, rate, open the profile.
struct SettingsButtonRow: View {
  let icon: String
  let color: Color
  let title: String
  var titleColor: Color?
  var chevron = false
  let action: () -> Void
  @Environment(\.theme) private var theme

  var body: some View {
    Button(action: action) {
      SettingsRow(icon: icon, color: color, title: title, titleColor: titleColor) {
        if chevron {
          Image(systemName: "chevron.right")
            .font(.system(size: 13, weight: .semibold))
            .foregroundStyle(theme.palette.textTertiary)
            .accessibilityHidden(true)
        }
      }
      .contentShape(Rectangle())
    }
    .buttonStyle(.plain)
  }
}

/// A row with a menu of numbers: "500 MB", "30 days".
struct SettingsMenuRow: View {
  let icon: String
  let title: String
  let options: [Int]
  let unit: String
  @Binding var selection: Int
  @Environment(\.theme) private var theme

  var body: some View {
    SettingsRow(icon: icon, color: theme.palette.textTertiary, title: title) {
      Picker(selection: $selection) {
        ForEach(options, id: \.self) { option in
          Text("\(option) \(unit)").tag(option)
        }
      } label: {
        Text(title)
      }
      .pickerStyle(.menu)
      .tint(theme.palette.accent)
    }
  }
}

/// Microphone or notifications: granted (green dot), denied, or Enable.
public enum SettingsPermission: Sendable, Equatable {
  case granted
  case denied
  case notDetermined
}

struct SettingsPermissionRow: View {
  let icon: String
  let title: String
  let status: SettingsPermission
  let action: () -> Void
  @Environment(\.theme) private var theme

  var body: some View {
    Button(action: action) {
      SettingsRow(icon: icon, color: theme.palette.accent, title: title) {
        HStack(spacing: 4) {
          switch status {
          case .granted:
            Circle().fill(theme.palette.scoreGreen).frame(width: 6, height: 6).accessibilityHidden(true)
            Text(Strings.settingsMicrophoneStatusGranted)
              .font(theme.typography.font(size: 15))
              .foregroundStyle(theme.palette.scoreGreen)
          case .denied:
            Text(Strings.settingsMicrophoneStatusDenied)
              .font(theme.typography.font(size: 15))
              .foregroundStyle(theme.palette.destructive)
            chevron
          case .notDetermined:
            Text(Strings.settingsMicrophoneEnable)
              .font(theme.typography.font(size: 15, weight: .medium))
              .foregroundStyle(theme.palette.accent)
            chevron
          }
        }
      }
      .contentShape(Rectangle())
    }
    .buttonStyle(.plain)
    .disabled(status == .granted)
  }

  private var chevron: some View {
    Image(systemName: "chevron.right")
      .font(.system(size: 13))
      .foregroundStyle(theme.palette.textTertiary)
      .accessibilityHidden(true)
  }
}

/// Icon colours SleepGuard's Settings uses outside the palette.
extension Color {
  static let settingsHealth = Color(red: 1, green: 45 / 255, blue: 85 / 255)
  static let settingsInfo = Color(red: 124 / 255, green: 124 / 255, blue: 1)
  static let settingsRate = Color(red: 1, green: 159 / 255, blue: 10 / 255)
}
