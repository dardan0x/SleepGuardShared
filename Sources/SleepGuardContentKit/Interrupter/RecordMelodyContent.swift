import SleepCore
import SwiftUI
import SleepGuardDesignKit
import SleepStrings

/// Where the recorder is, for `RecordMelodyContent`.
public enum MelodyRecordingState: Equatable, Sendable {
  case idle
  case recording
  /// A take is ready; `isPlaying` while it plays back.
  case recorded(isPlaying: Bool)
}

/// Recording your own sound (up to `CustomMelodies.maxRecordingDuration`):
/// the time, record or stop, then play, Save or Re-record. The screen owns
/// the recorder.
public struct RecordMelodyContent: View {
  let state: MelodyRecordingState
  let elapsed: TimeInterval
  let canRecord: Bool
  let onRecordToggle: () -> Void
  let onPlayToggle: () -> Void
  let onSave: () -> Void
  let onReRecord: () -> Void
  let onBack: () -> Void
  @Environment(\.theme) private var theme

  public init(
    state: MelodyRecordingState, elapsed: TimeInterval, canRecord: Bool, onRecordToggle: @escaping () -> Void,
    onPlayToggle: @escaping () -> Void, onSave: @escaping () -> Void, onReRecord: @escaping () -> Void,
    onBack: @escaping () -> Void)
  {
    self.state = state
    self.elapsed = elapsed
    self.canRecord = canRecord
    self.onRecordToggle = onRecordToggle
    self.onPlayToggle = onPlayToggle
    self.onSave = onSave
    self.onReRecord = onReRecord
    self.onBack = onBack
  }

  public var body: some View {
    VStack(spacing: 0) {
      SheetHandle()
      SheetNavHeader(title: Strings.recordMelodySheetNavHeader, onBack: onBack)
      Divider().background(theme.palette.border)
      Spacer()
      RecordMelodyControls(
        state: state, elapsed: elapsed, canRecord: canRecord, onRecordToggle: onRecordToggle,
        onPlayToggle: onPlayToggle)
      Spacer()
      if case .recorded = state {
        VStack(spacing: 12) {
          Button(action: onSave) {
            Text(Strings.saveRecordCustomMelodySheet)
              .font(theme.typography.font(size: 15, weight: .bold))
              .tracking(2)
              .foregroundStyle(theme.palette.textPrimary)
              .frame(maxWidth: .infinity)
              .frame(height: 56)
              .background(theme.palette.bgCard, in: Capsule())
          }
          Button(action: onReRecord) {
            Text(Strings.reRecordCustomMelodySheet)
              .font(theme.typography.font(size: 15, weight: .medium))
              .foregroundStyle(theme.palette.textSecondary)
              .frame(maxWidth: .infinity)
              .frame(height: 44)
          }
        }
        .buttonStyle(.plain)
        .padding(.horizontal, 24)
        .padding(.bottom, 34)
      }
    }
    .background(theme.palette.bgPrimary.ignoresSafeArea())
  }

  /// "4.7": seconds and tenths.
  static func timeText(_ elapsed: TimeInterval) -> String {
    let tenths = Int((max(0, elapsed) * 10).rounded(.down))
    return String(format: "%d.%d", tenths / 10, tenths % 10)
  }
}

/// The time, the record button and, once there's a take, play (render tests draw this).
struct RecordMelodyControls: View {
  let state: MelodyRecordingState
  let elapsed: TimeInterval
  let canRecord: Bool
  let onRecordToggle: () -> Void
  let onPlayToggle: () -> Void
  @Environment(\.theme) private var theme

  private var isRecording: Bool { state == .recording }

  var body: some View {
    VStack(spacing: 32) {
      Text(verbatim: RecordMelodyContent.timeText(elapsed))
        .font(.system(size: 56, weight: .light, design: .monospaced))
        .foregroundStyle(theme.palette.textPrimary)
        .contentTransition(.numericText())
      Button(action: onRecordToggle) {
        ZStack {
          Circle()
            .fill(isRecording ? theme.palette.bgCard : theme.palette.scoreRed)
            .frame(width: 88, height: 88)
          if isRecording {
            RoundedRectangle(cornerRadius: 4).fill(theme.palette.textPrimary).frame(width: 28, height: 28)
          } else {
            Circle().fill(theme.palette.textPrimary).frame(width: 32, height: 32)
          }
        }
        .overlay(
          Circle()
            .stroke(isRecording ? theme.palette.scoreRed.opacity(0.5) : .clear, lineWidth: 4)
            .frame(width: 100, height: 100))
      }
      .buttonStyle(.plain)
      .disabled(!canRecord)
      .accessibilityLabel(isRecording ? Strings.stopRecordCustomMelodySheet : Strings.recordMelodySheetNavHeader)
      if case let .recorded(isPlaying) = state {
        Button(action: onPlayToggle) {
          HStack(spacing: 8) {
            Image(systemName: isPlaying ? "stop.fill" : "play.fill")
              .font(.system(size: 16, weight: .semibold))
              .accessibilityHidden(true)
            Text(isPlaying ? Strings.stopRecordCustomMelodySheet : Strings.playRecordCustomMelodySheet)
              .font(theme.typography.font(size: 15, weight: .semibold))
          }
          .foregroundStyle(theme.palette.accent)
          .frame(width: 140, height: 44)
          .overlay(RoundedRectangle(cornerRadius: 22).stroke(theme.palette.accent, lineWidth: 1.5))
        }
        .buttonStyle(.plain)
      }
    }
  }
}
