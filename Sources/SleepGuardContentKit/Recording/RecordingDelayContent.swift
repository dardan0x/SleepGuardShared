import SleepCore
import SwiftUI

/// The prestart's start delay: one button per `RecordingDelay.options`, the
/// chosen one filled. Goes in `PrestartContent`'s options slot.
public struct PrestartDelayOptions: View {
  @Binding var minutes: Int
  @Environment(\.theme) private var theme

  public init(minutes: Binding<Int>) {
    _minutes = minutes
  }

  public var body: some View {
    VStack(alignment: .leading, spacing: 12) {
      Text(Strings.sessionPrestartDelayLabel)
        .font(theme.typography.font(size: 15, weight: .semibold))
        .foregroundStyle(theme.palette.textPrimary)

      HStack(spacing: 8) {
        ForEach(RecordingDelay.options, id: \.self) { option in
          let isSelected = option == minutes
          Button {
            withAnimation(.spring(duration: 0.25)) { minutes = option }
          } label: {
            Text(Self.label(minutes: option))
              .font(theme.typography.font(size: 15, weight: isSelected ? .semibold : .medium))
              .foregroundStyle(isSelected ? theme.palette.textPrimary : theme.palette.textSecondary)
              .frame(maxWidth: .infinity)
              .frame(height: 44)
              .background(isSelected ? theme.palette.accent : theme.palette.bgElevated, in: .rect(cornerRadius: 12))
          }
          .buttonStyle(.plain)
          .accessibilityAddTraits(isSelected ? .isSelected : [])
        }
      }
    }
    .padding(16)
    .background(theme.palette.bgCard, in: .rect(cornerRadius: theme.radii.card))
  }

  /// "Off", "15m", "1h" (the system's short units).
  static func label(minutes: Int) -> String {
    guard minutes > 0 else { return Strings.sessionPrestartDelayOff }
    let formatter = DateComponentsFormatter()
    formatter.unitsStyle = .abbreviated
    formatter.allowedUnits = [.hour, .minute]
    return formatter.string(from: TimeInterval(minutes * 60)) ?? "\(minutes)"
  }
}

/// While the start delay runs: the time left, Cancel, and Start now. The
/// screen ticks `seconds` and starts the night at zero.
public struct RecordingCountdownContent: View {
  let seconds: Int
  let onCancel: () -> Void
  let onStartNow: () -> Void
  @Environment(\.theme) private var theme

  public init(seconds: Int, onCancel: @escaping () -> Void, onStartNow: @escaping () -> Void) {
    self.seconds = seconds
    self.onCancel = onCancel
    self.onStartNow = onStartNow
  }

  public var body: some View {
    VStack(spacing: 0) {
      Spacer()
      VStack(spacing: 16) {
        Image(systemName: "moon.stars.fill")
          .font(.system(size: 56))
          .foregroundStyle(theme.palette.accent)
          .accessibilityHidden(true)
        Text(Strings.sessionCountdownLabel)
          .font(theme.typography.font(size: 20, weight: .medium))
          .foregroundStyle(theme.palette.textSecondary)
        Text(verbatim: RecordingDelay.countdownText(seconds: seconds))
          .font(.system(size: 72, weight: .thin, design: .rounded))
          .foregroundStyle(theme.palette.textPrimary)
          .monospacedDigit()
      }
      .accessibilityElement(children: .combine)
      Spacer()
      VStack(spacing: 16) {
        Button(action: onCancel) {
          Text(Strings.actionCancel)
            .font(theme.typography.font(size: 17, weight: .semibold))
            .foregroundStyle(theme.palette.textPrimary)
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .background(theme.palette.bgCard, in: Capsule())
            .overlay(Capsule().stroke(theme.palette.border, lineWidth: 1))
        }
        Button(action: onStartNow) {
          Text(Strings.actionStartNow)
            .font(theme.typography.font(size: 17, weight: .semibold))
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .background(theme.palette.accent, in: Capsule())
        }
      }
      .buttonStyle(.plain)
      .padding(.horizontal, 24)
      .padding(.bottom, 32)
    }
    .background(theme.palette.bgPrimary.ignoresSafeArea())
  }
}
