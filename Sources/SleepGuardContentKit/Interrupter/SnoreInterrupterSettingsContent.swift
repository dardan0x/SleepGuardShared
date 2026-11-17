import SleepCore
import SwiftUI

/// The Snore Interrupter's settings sheet: what it does, how long it plays,
/// the sound, and whether it's on. The screen owns the draft (`mode`, the
/// melody) and saves it on Save.
public struct SnoreInterrupterSettingsContent: View {
  @Binding var mode: SnoreInterrupterMode
  let melodyName: String
  let onSound: () -> Void
  let onSave: () -> Void
  let onCancel: () -> Void
  @Environment(\.theme) private var theme

  public init(
    mode: Binding<SnoreInterrupterMode>, melodyName: String, onSound: @escaping () -> Void,
    onSave: @escaping () -> Void, onCancel: @escaping () -> Void)
  {
    _mode = mode
    self.melodyName = melodyName
    self.onSound = onSound
    self.onSave = onSave
    self.onCancel = onCancel
  }

  public var body: some View {
    VStack(spacing: 0) {
      SheetHandle()
      SheetNavHeader(title: Strings.snoreInterrupterRecordingPrestartViewTitle.uppercased(), onBack: onCancel)
      Divider().background(theme.palette.border)
      ScrollView {
        SnoreInterrupterSettingsStack(mode: $mode, melodyName: melodyName, onSound: onSound)
          .padding(.top, 24)
          .padding(.horizontal, 20)
      }
      Spacer()
      SaveCancelButtons(onSave: onSave, onCancel: onCancel)
    }
    .background(theme.palette.bgPrimary.ignoresSafeArea())
  }
}

/// The sheet's scrolling part (render tests draw this; ImageRenderer can't draw a ScrollView).
struct SnoreInterrupterSettingsStack: View {
  @Binding var mode: SnoreInterrupterMode
  let melodyName: String
  let onSound: () -> Void
  @Environment(\.theme) private var theme

  var body: some View {
    VStack(spacing: 20) {
      VStack(spacing: 2) {
        Text(Strings.snoreInterrupterSheetDescSectionTitle)
          .foregroundStyle(theme.palette.textPrimary)
        Text(Strings.snoreInterrupterSheetDescSectionSubtitle)
          .foregroundStyle(theme.palette.textDim)
      }
      .font(theme.typography.font(size: 15))
      .multilineTextAlignment(.center)

      Picker(Strings.durationPickerTitle, selection: $mode) {
        ForEach(SnoreInterrupterMode.allCases, id: \.self) { mode in
          Text(mode.label).tag(mode)
        }
      }
      #if os(iOS)
      .pickerStyle(.wheel)
      #endif
      .frame(height: 180)
      .background(theme.palette.bgCard, in: .rect(cornerRadius: theme.radii.small))

      MelodySoundRow(melodyName: melodyName, action: onSound)
      InterrupterStatusBadge(isOn: mode.isOn)
    }
  }
}

private struct MelodySoundRow: View {
  let melodyName: String
  let action: () -> Void
  @Environment(\.theme) private var theme

  var body: some View {
    Button(action: action) {
      HStack(spacing: 12) {
        Image(systemName: "music.note")
          .font(.system(size: 18))
          .foregroundStyle(.white)
          .frame(width: 40, height: 40)
          .background(theme.palette.accent, in: .rect(cornerRadius: 10))
          .accessibilityHidden(true)
        VStack(alignment: .leading, spacing: 2) {
          Text(Strings.snoreInterrupterSoundSheet)
            .font(theme.typography.font(size: 17))
            .foregroundStyle(theme.palette.textPrimary)
          Text(melodyName)
            .font(theme.typography.font(size: 13))
            .foregroundStyle(theme.palette.textSecondary)
        }
        Spacer()
        Image(systemName: "chevron.right")
          .font(.system(size: 14, weight: .semibold))
          .foregroundStyle(theme.palette.textTertiary)
          .accessibilityHidden(true)
      }
      .padding(12)
      .background(theme.palette.bgCard, in: .rect(cornerRadius: theme.radii.small))
    }
    .buttonStyle(.plain)
  }
}

private struct InterrupterStatusBadge: View {
  let isOn: Bool
  @Environment(\.theme) private var theme

  var body: some View {
    HStack(spacing: 4) {
      Circle().fill(theme.palette.accent).frame(width: 6, height: 6).accessibilityHidden(true)
      Text(isOn ? Strings.soundEnabledSnoreInterrupterSheet : Strings.soundDisabledSnoreInterrupterSheet)
        .font(theme.typography.font(size: 12))
        .foregroundStyle(theme.palette.accent)
    }
    .padding(.vertical, 4)
    .padding(.horizontal, 10)
    .background(theme.palette.accent.opacity(0.2), in: Capsule())
    .overlay(Capsule().stroke(theme.palette.accent, lineWidth: 1))
  }
}

/// Save (filled) and Cancel under a sheet.
struct SaveCancelButtons: View {
  let onSave: () -> Void
  let onCancel: () -> Void
  @Environment(\.theme) private var theme

  var body: some View {
    VStack(spacing: 8) {
      Button(action: onSave) {
        Text(Strings.saveMelodyPickerSheet)
          .font(theme.typography.font(size: 15, weight: .bold))
          .tracking(2)
          .foregroundStyle(theme.palette.textPrimary)
          .frame(maxWidth: .infinity)
          .frame(height: 56)
          .background(theme.palette.bgCard, in: Capsule())
      }
      Button(action: onCancel) {
        Text(Strings.actionCancel)
          .font(theme.typography.font(size: 17))
          .foregroundStyle(theme.palette.textPrimary)
          .frame(maxWidth: .infinity)
          .frame(height: 44)
      }
    }
    .buttonStyle(.plain)
    .padding(.horizontal, 24)
    .padding(.bottom, 34)
  }
}
