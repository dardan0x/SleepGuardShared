import SleepCore
import SwiftUI
import SleepStrings

/// A day in a list of days: score ring, weekday and date, time asleep and
/// snoring (in the loudest intensity's colour). Taps open it.
public struct DayRow: View {
  let score: Int
  let date: Date
  let duration: TimeInterval
  let snoringMinutes: Int
  let loudest: SnoreIntensity
  let onTap: () -> Void
  @Environment(\.theme) private var theme

  public init(
    score: Int, date: Date, duration: TimeInterval, snoringMinutes: Int, loudest: SnoreIntensity,
    onTap: @escaping () -> Void)
  {
    self.score = score
    self.date = date
    self.duration = duration
    self.snoringMinutes = snoringMinutes
    self.loudest = loudest
    self.onTap = onTap
  }

  public var body: some View {
    Button(action: onTap) {
      HStack(spacing: 12) {
        Text("\(score)")
          .font(theme.typography.font(size: 17, weight: .bold))
          .foregroundStyle(theme.palette.textPrimary)
          .frame(width: 44, height: 44)
          .overlay(Circle().stroke(theme.scoreColor(score), lineWidth: 3))
        VStack(alignment: .leading, spacing: 2) {
          Text(date.formatted(.dateTime.weekday(.abbreviated)))
            .font(theme.typography.font(size: 15, weight: .semibold))
            .foregroundStyle(theme.palette.textPrimary)
          Text(date.formatted(.dateTime.month(.abbreviated).day()))
            .font(theme.typography.font(size: 12))
            .foregroundStyle(theme.palette.textTertiary)
        }
        Spacer()
        VStack(alignment: .trailing, spacing: 2) {
          Text(DurationText.hoursAndMinutes(duration))
            .font(.system(size: 14, weight: .medium, design: .monospaced))
            .foregroundStyle(theme.palette.textPrimary)
          Text("\(DurationText.hoursAndMinutes(TimeInterval(snoringMinutes * 60))) \(Strings.totalSnoringDurationColumn)")
            .font(theme.typography.font(size: 12))
            .foregroundStyle(theme.palette.eventColor(.snoring, intensity: loudest))
        }
        Image(systemName: "chevron.right")
          .font(.system(size: 16, weight: .semibold))
          .foregroundStyle(theme.palette.textTertiary)
          .accessibilityHidden(true)
      }
      .padding(16)
      .overlay(RoundedRectangle(cornerRadius: theme.radii.card).stroke(theme.palette.bgCard, lineWidth: 1))
      .contentShape(Rectangle())
    }
    .buttonStyle(.plain)
  }
}
