import SleepCore
import SwiftUI
import SleepStrings

public extension Melody {
  /// A built-in's translated name, or the name a recording was saved with.
  var name: String {
    if let customName { return customName }
    return switch id {
    case 1: Strings.melodyFunnyAlarm
    case 2: Strings.melodyClapping
    case 3: Strings.melodySnareClap
    case 4: Strings.melodyBirdChittering
    case 5: Strings.melodyCuteCatMeow
    case 6: Strings.melodyAttentionChime
    case 7: Strings.melodyBabyStopFemale
    case 8: Strings.melodyBabyStopMale
    case 9: Strings.melodyAcousticGuitar
    case 10: Strings.melodySqueakyToy
    case 11: Strings.melodyFunnyCartoon
    default: Strings.snoreInterrupterDefaultMelodyName
    }
  }

  /// "My Sound 3": a new recording's name before anyone renames it.
  static func customName(number: Int) -> String {
    String(format: Strings.melodyCustomNameFormat, number)
  }
}

public extension SnoreInterrupterMode {
  /// "Off", "Always", "5 seconds", …
  var label: String {
    switch self {
    case .never: Strings.snoreInterrupterOffValueFormat
    case .always: Strings.snoreInterrupterAlwaysValueFormat
    case .fiveSeconds: Strings.snoreInterrupterFiveSecondsValueFormat
    case .fifteenSeconds: Strings.snoreInterrupterFifteenSecondsValueFormat
    case .thirtySeconds: Strings.snoreInterrupterThirtySecondsValueFormat
    case .sixtySeconds: Strings.snoreInterrupterSixtySecondsValueFormat
    }
  }
}

/// The prestart's Snore Interrupter row: title, the current mode, and the
/// note to keep the phone unlocked.
public struct SnoreInterrupterRow: View {
  let mode: SnoreInterrupterMode
  let action: () -> Void
  @Environment(\.theme) private var theme

  public init(mode: SnoreInterrupterMode, action: @escaping () -> Void) {
    self.mode = mode
    self.action = action
  }

  public var body: some View {
    Button(action: action) {
      VStack(spacing: 4) {
        HStack(spacing: 12) {
          Image(systemName: "timer")
            .font(.system(size: 18))
            .foregroundStyle(theme.palette.accent)
            .frame(width: 24)
            .accessibilityHidden(true)
          Text(Strings.snoreInterrupterRecordingPrestartViewTitle)
            .font(theme.typography.font(size: 16))
            .foregroundStyle(theme.palette.textPrimary)
          Spacer()
          Text(mode.label)
            .font(theme.typography.font(size: 16))
            .foregroundStyle(theme.palette.textSecondary)
          Image(systemName: "chevron.right")
            .font(.system(size: 14, weight: .semibold))
            .foregroundStyle(theme.palette.textTertiary)
            .accessibilityHidden(true)
        }
        HStack(spacing: 6) {
          Image(systemName: "lock.open.fill")
            .font(.system(size: 12))
            .accessibilityHidden(true)
          Text(Strings.snoreInterrupterLockscreenNote)
            .font(theme.typography.font(size: 13))
          Spacer()
        }
        .foregroundStyle(theme.palette.textTertiary)
        .padding(.top, 4)
        .padding(.leading, 6)
      }
      .padding(.horizontal, 16)
      .padding(.vertical, 12)
      .background(theme.palette.bgCard, in: .rect(cornerRadius: theme.radii.card))
    }
    .buttonStyle(.plain)
  }
}

/// One melody in the picker: the selection ring, a bouncing speaker while it
/// previews, delete for a recording, and the checkmark when chosen.
public struct MelodyRow: View {
  let melody: Melody
  let isSelected: Bool
  let isPreviewing: Bool
  let onTap: () -> Void
  let onDelete: () -> Void
  @Environment(\.theme) private var theme

  public init(
    melody: Melody, isSelected: Bool, isPreviewing: Bool, onTap: @escaping () -> Void,
    onDelete: @escaping () -> Void)
  {
    self.melody = melody
    self.isSelected = isSelected
    self.isPreviewing = isPreviewing
    self.onTap = onTap
    self.onDelete = onDelete
  }

  public var body: some View {
    HStack(spacing: 12) {
      Button(action: onTap) {
        HStack(spacing: 12) {
          ZStack {
            if isSelected {
              Circle().fill(theme.palette.accent).frame(width: 36, height: 36)
            }
            MelodyIcon(isPreviewing: isPreviewing, color: isSelected ? .white : iconColor)
          }
          .frame(width: 36, height: 36)
          .accessibilityHidden(true)
          Text(melody.name)
            .font(theme.typography.font(size: 17, weight: isSelected ? .semibold : .regular))
            .foregroundStyle(theme.palette.textPrimary)
          Spacer()
        }
        .contentShape(.rect)
      }
      .buttonStyle(.plain)
      .accessibilityAddTraits(isSelected ? .isSelected : [])
      if melody.isCustom {
        Button(action: onDelete) {
          Label(Strings.actionDelete, systemImage: "trash").labelStyle(.iconOnly)
            .font(.system(size: 14))
            .foregroundStyle(theme.palette.textTertiary)
            .padding(8)
        }
        .buttonStyle(.plain)
      }
      if isSelected {
        Image(systemName: "checkmark")
          .font(.system(size: 12, weight: .bold))
          .foregroundStyle(.white)
          .frame(width: 24, height: 24)
          .background(theme.palette.accent, in: Circle())
          .accessibilityHidden(true)
      }
    }
    .padding(isSelected ? 14 : 16)
    .background(theme.palette.bgCard, in: .rect(cornerRadius: theme.radii.small))
    .overlay(
      RoundedRectangle(cornerRadius: theme.radii.small)
        .stroke(isSelected ? theme.palette.accent : .clear, lineWidth: 1.5))
  }

  private var iconColor: Color {
    isPreviewing ? theme.palette.accent : theme.palette.textTertiary
  }
}

private struct MelodyIcon: View {
  let isPreviewing: Bool
  let color: Color

  var body: some View {
    if isPreviewing {
      Image(systemName: "speaker.wave.2")
        .font(.system(size: 16))
        .foregroundStyle(color)
        .symbolEffect(.pulse, options: .repeating)
    } else {
      Image(systemName: "music.note")
        .font(.system(size: 16))
        .foregroundStyle(color)
    }
  }
}

/// The picker's first row: record your own sound.
public struct RecordMelodyRow: View {
  let action: () -> Void
  @Environment(\.theme) private var theme

  public init(action: @escaping () -> Void) {
    self.action = action
  }

  public var body: some View {
    Button(action: action) {
      HStack(spacing: 12) {
        Image(systemName: "mic.fill")
          .font(.system(size: 16))
          .foregroundStyle(theme.palette.accent)
          .frame(width: 36, height: 36)
          .background(theme.palette.accent.opacity(0.15), in: Circle())
          .accessibilityHidden(true)
        Text(Strings.recordYoursMelodyPickerSheet)
          .font(theme.typography.font(size: 17, weight: .semibold))
          .foregroundStyle(theme.palette.accent)
        Spacer()
        Image(systemName: "chevron.right")
          .font(.system(size: 14, weight: .semibold))
          .foregroundStyle(theme.palette.textTertiary)
          .accessibilityHidden(true)
      }
      .padding(16)
      .background(theme.palette.bgCard, in: .rect(cornerRadius: theme.radii.small))
      .overlay(
        RoundedRectangle(cornerRadius: theme.radii.small)
          .stroke(theme.palette.accent.opacity(0.3), lineWidth: 1.5))
    }
    .buttonStyle(.plain)
  }
}

/// On the bedside clock while the interrupter is armed: the note, and Mute
/// for this night. Goes in `BedsideClockContent`'s banner slot.
public struct BedsideMelodyDisclaimer: View {
  let onMute: () -> Void
  @Environment(\.theme) private var theme

  public init(onMute: @escaping () -> Void) {
    self.onMute = onMute
  }

  public var body: some View {
    HStack(spacing: 6) {
      Image(systemName: "music.note")
        .font(.system(size: 11, weight: .semibold))
        .foregroundStyle(theme.palette.accent)
        .accessibilityHidden(true)
      Text(Strings.sessionBedsideMelodyEnabled)
        .font(theme.typography.font(size: 14, weight: .medium))
        .foregroundStyle(theme.palette.textSecondary)
      Text("·")
        .font(theme.typography.font(size: 14, weight: .medium))
        .foregroundStyle(theme.palette.textTertiary)
        .accessibilityHidden(true)
      Button(action: onMute) {
        Text(Strings.muteForSession)
          .font(theme.typography.font(size: 14, weight: .semibold))
          .foregroundStyle(theme.palette.accent)
      }
      .buttonStyle(.plain)
      Spacer()
    }
    .padding(.horizontal, 16)
    .padding(.vertical, 15)
    .background(theme.palette.bgCard, in: .rect(cornerRadius: theme.radii.small))
  }
}

/// Over the bedside clock while the melody plays: its name, Mute for this
/// night, and Stop. Goes in `BedsideClockContent`'s overlay slot.
public struct BedsideMelodyOverlay: View {
  let melodyName: String
  let onMute: () -> Void
  let onStop: () -> Void
  @Environment(\.theme) private var theme

  public init(melodyName: String, onMute: @escaping () -> Void, onStop: @escaping () -> Void) {
    self.melodyName = melodyName
    self.onMute = onMute
    self.onStop = onStop
  }

  public var body: some View {
    VStack(spacing: 10) {
      HStack(spacing: 12) {
        Image(systemName: "music.note")
          .font(.system(size: 14, weight: .semibold))
          .foregroundStyle(theme.palette.accent)
          .symbolEffect(.pulse, options: .repeating)
          .accessibilityHidden(true)
        Text(verbatim: "\(Strings.playingSnoreInterrupterPlayer) \(melodyName)")
          .font(theme.typography.font(size: 14, weight: .medium))
          .foregroundStyle(theme.palette.textPrimary)
          .lineLimit(1)
        Spacer()
      }
      HStack(spacing: 12) {
        OverlayButton(title: Strings.muteForSession, color: theme.palette.textSecondary, stroke: theme.palette.border, action: onMute)
        OverlayButton(title: Strings.stopSnoreInterrupterPlayer, color: theme.palette.accent, stroke: theme.palette.accent, action: onStop)
      }
    }
    .padding(.horizontal, 16)
    .padding(.vertical, 12)
    .background(theme.palette.bgCard, in: .rect(cornerRadius: theme.radii.card))
    .overlay(RoundedRectangle(cornerRadius: theme.radii.card).stroke(theme.palette.accent.opacity(0.4), lineWidth: 1))
    .padding(.horizontal, 24)
    .padding(.top, 16)
    .transition(.move(edge: .top).combined(with: .opacity))
  }
}

private struct OverlayButton: View {
  let title: String
  let color: Color
  let stroke: Color
  let action: () -> Void
  @Environment(\.theme) private var theme

  var body: some View {
    Button(action: action) {
      Text(title)
        .font(theme.typography.font(size: 13, weight: .semibold))
        .foregroundStyle(color)
        .frame(maxWidth: .infinity)
        .frame(height: 36)
        .overlay(RoundedRectangle(cornerRadius: 8).stroke(stroke, lineWidth: 1))
    }
    .buttonStyle(.plain)
  }
}
