import SleepCore
import SwiftUI
import SleepGuardDesignKit
import SleepStrings

/// Last 7 Nights below its title: the average score and its trend, a bar per
/// day, four stats, and every day (tap opens its first night).
///
/// The screen builds `stats` (`NightDayStats.recent`, with full summaries for
/// the shown days) and `trend` (`ScoreTrend.weekOverWeek`).
public struct LastSevenNightsContent: View {
  let stats: NightDayStats
  let trend: ScoreTrend?
  let onOpen: (NightSummary) -> Void
  @Environment(\.theme) private var theme

  public init(stats: NightDayStats, trend: ScoreTrend?, onOpen: @escaping (NightSummary) -> Void) {
    self.stats = stats
    self.trend = trend
    self.onOpen = onOpen
  }

  public var body: some View {
    VStack(spacing: 16) {
      LastSevenNightsHeader(stats: stats, trend: trend)

      SnoringDayBars(bars: stats.days.map { day in
        SnoringBar(
          label: day.date.formatted(.dateTime.weekday(.narrow)), minutes: day.snoringMinutes,
          intensity: day.loudestIntensity)
      })

      LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
        StatTile(
          icon: "percent", iconColor: theme.palette.scoreAmber, label: Strings.statsLast7nightsAvgSnoring,
          value: DurationText.hoursAndMinutes(TimeInterval(stats.averageSnoringMinutes * 60)), valueSize: 22)
        StatTile(
          icon: "bolt.fill", iconColor: theme.palette.scoreAmber, label: Strings.statsLast7nightsTotalEvents,
          value: "\(stats.eventCount)", valueSize: 22)
        StatTile(
          icon: "leaf.fill", iconColor: theme.palette.scoreGreen, label: Strings.statsLast7nightsBest,
          value: Self.scoreAndDay(stats.best), valueSize: 22, valueColor: theme.palette.scoreGreen)
        StatTile(
          icon: "flame.fill", iconColor: theme.palette.scoreRed, label: Strings.statsLast7nightsWorst,
          value: Self.scoreAndDay(stats.worst), valueSize: 22, valueColor: theme.palette.scoreRed)
      }

      VStack(alignment: .leading, spacing: 12) {
        Text(Strings.statsLast7nightsAllNights)
          .font(theme.typography.font(size: 13, weight: .semibold))
          .foregroundStyle(theme.palette.textTertiary)
          .tracking(0.5)
        VStack(spacing: 8) {
          ForEach(stats.days.reversed()) { day in
            DayRow(
              score: day.averageScore, date: day.date, duration: day.duration,
              snoringMinutes: day.snoringMinutes, loudest: day.loudestIntensity)
            {
              if let night = day.nights.first { onOpen(night) }
            }
          }
        }
      }
    }
    .padding(.horizontal, 20)
    .padding(.vertical, 10)
  }

  /// "91 Tue"; "0 " without days, as SleepGuard showed it.
  static func scoreAndDay(_ day: NightDay?) -> String {
    guard let day else { return "0 " }
    return "\(day.averageScore) \(day.date.formatted(.dateTime.weekday(.abbreviated)))"
  }
}

/// The days' range, the average score, and the trend against the week before.
struct LastSevenNightsHeader: View {
  let stats: NightDayStats
  let trend: ScoreTrend?
  @Environment(\.theme) private var theme

  var body: some View {
    VStack(alignment: .leading, spacing: 6) {
      Text(Self.range(stats))
        .font(theme.typography.font(size: 12, weight: .semibold))
        .foregroundStyle(theme.palette.textTertiary)
        .tracking(1)
      HStack(alignment: .lastTextBaseline, spacing: 12) {
        Text("\(stats.averageScore)")
          .font(theme.typography.font(size: 52, weight: .bold))
          .foregroundStyle(theme.palette.textPrimary)
        VStack(alignment: .leading, spacing: 4) {
          Text(Strings.statsLast7nightsAvgSleepScore)
            .font(theme.typography.font(size: 13))
            .foregroundStyle(theme.palette.textSecondary)
          if let trend {
            HStack(spacing: 4) {
              Image(systemName: trend.isPositive ? "arrow.up.forward" : "arrow.down.forward")
                .font(.system(size: 12, weight: .semibold))
                .accessibilityHidden(true)
              Text(String(format: Strings.statsLast7nightsTrendVsPrevWeek, trend.diff))
                .font(theme.typography.font(size: 12, weight: .medium))
            }
            .foregroundStyle(trend.isPositive ? theme.palette.scoreGreen : theme.palette.scoreRed)
          }
        }
      }
    }
    .frame(maxWidth: .infinity, alignment: .leading)
  }

  /// "NOV 7 – NOV 13"; empty without days.
  static func range(_ stats: NightDayStats) -> String {
    guard let first = stats.days.first?.date, let last = stats.days.last?.date else { return "" }
    let format = Date.FormatStyle.dateTime.month(.abbreviated).day()
    return "\(first.formatted(format)) – \(last.formatted(format))".uppercased()
  }
}
