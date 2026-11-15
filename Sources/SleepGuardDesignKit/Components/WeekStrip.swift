import SleepCore
import SwiftUI

/// Seven days in a row: weekday, day number, and a dot in the night's snoring
/// level colour. Today is highlighted.
public struct WeekStrip: View {
  let days: [NightDashboard.WeekDay]
  @Environment(\.theme) private var theme

  public init(days: [NightDashboard.WeekDay]) {
    self.days = days
  }

  public var body: some View {
    HStack(spacing: 0) {
      ForEach(days, id: \.date) { day in
        VStack(spacing: 4) {
          Text(day.date.formatted(.dateTime.weekday(.abbreviated)).uppercased())
            .font(theme.typography.font(size: 10, weight: .medium))
            .foregroundStyle(day.isToday ? theme.palette.textPrimary : theme.palette.textTertiary)
            .tracking(0.5)
          Text(day.date.formatted(.dateTime.day()))
            .font(theme.typography.font(size: 18, weight: .semibold))
            .foregroundStyle(day.isToday ? theme.palette.textPrimary : theme.palette.textSecondary)
          Circle()
            .fill(day.snoringLevel.map { theme.palette.eventColor(.snoring, intensity: $0) } ?? .clear)
            .frame(width: 4, height: 4)
            .accessibilityHidden(true)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(day.isToday ? theme.palette.bgCard : .clear, in: .rect(cornerRadius: theme.radii.small))
        .accessibilityElement(children: .combine)
      }
    }
    .padding(.horizontal, 8)
    .padding(.vertical, 4)
  }
}
