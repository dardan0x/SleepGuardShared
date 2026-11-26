import SleepCore
import SwiftUI
import SleepStrings

/// One event as a small card (the all-events grid): start time, length in the
/// event's colour, and Play when that action is given.
public struct EventCard: View {
  let start: Date
  let duration: TimeInterval
  let category: SoundCategory
  let intensity: SnoreIntensity
  let onPlay: (() -> Void)?
  @Environment(\.theme) private var theme

  public init(
    start: Date, duration: TimeInterval, category: SoundCategory, intensity: SnoreIntensity,
    onPlay: (() -> Void)? = nil)
  {
    self.start = start
    self.duration = duration
    self.category = category
    self.intensity = intensity
    self.onPlay = onPlay
  }

  public var body: some View {
    let color = theme.palette.eventColor(category, intensity: intensity)
    VStack(spacing: 10) {
      HStack(spacing: 2) {
        Text(Strings.startTimeEventCard)
        Text(start.formatted(date: .omitted, time: .shortened))
      }
      .font(theme.typography.font(size: 11, weight: .semibold))
      .foregroundStyle(theme.palette.textSecondary)
      .lineLimit(1)
      .minimumScaleFactor(0.7)

      Spacer()

      HStack(spacing: 6) {
        Circle().fill(color).frame(width: 8, height: 8).accessibilityHidden(true)
        Text(Duration.seconds(duration).formatted(.time(pattern: .minuteSecond)))
          .font(.system(size: 22, weight: .bold, design: .rounded))
          .foregroundStyle(color)
          .monospacedDigit()
      }

      if let onPlay {
        Button(action: onPlay) {
          HStack(spacing: 4) {
            Image(systemName: "play.fill").font(.system(size: 12, weight: .semibold))
            Text(Strings.actionPlay).font(theme.typography.font(size: 13, weight: .semibold))
          }
          .foregroundStyle(theme.palette.accent)
          .padding(.horizontal, 12)
          .padding(.vertical, 6)
          .background(theme.palette.accent.opacity(0.12), in: .rect(cornerRadius: 8))
        }
      } else {
        Spacer()
      }
    }
    .padding(12)
    .frame(maxWidth: .infinity)
    .frame(height: onPlay == nil ? 120 : 140)
    .background(theme.palette.bgCard, in: .rect(cornerRadius: theme.radii.card))
  }
}
