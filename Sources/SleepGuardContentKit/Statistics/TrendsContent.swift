import SleepCore
import SwiftUI

/// The period Trends shows.
public enum TrendsRange: CaseIterable, Hashable, Sendable {
  case week
  case month

  /// The days `NightPeriod(lastDays:)` covers.
  public var days: Int {
    self == .week ? 7 : 30
  }

  var title: String {
    self == .week ? Strings.statsTrendsWeek : Strings.statsTrendsMonth
  }
}

/// Trends below its title: the week or month picker, average snoring, a bar
/// per night, and four stats.
///
/// The screen owns `range` and builds `period` for it (`NightPeriod(lastDays:
/// range.days, …)` with full summaries, for each night's loudest snoring).
public struct TrendsContent: View {
  @Binding var range: TrendsRange
  let period: NightPeriod
  @Environment(\.theme) private var theme

  public init(range: Binding<TrendsRange>, period: NightPeriod) {
    _range = range
    self.period = period
  }

  public var body: some View {
    VStack(spacing: 24) {
      PillPicker(options: TrendsRange.allCases, selection: $range, title: \.title)

      VStack(alignment: .leading, spacing: 4) {
        Text(Strings.statsTrendsAvgSnoringLabel)
          .font(theme.typography.font(size: 11, weight: .semibold))
          .foregroundStyle(theme.palette.textTertiary)
          .tracking(1)
        HStack(alignment: .lastTextBaseline, spacing: 6) {
          Text(DurationText.hoursAndMinutes(TimeInterval(period.averageSnoringMinutes * 60)))
            .font(theme.typography.font(size: 36, weight: .bold))
            .foregroundStyle(theme.palette.textPrimary)
          Text(Strings.statsTrendsAvgMinFormat)
            .font(theme.typography.font(size: 14))
            .foregroundStyle(theme.palette.textSecondary)
        }
      }
      .frame(maxWidth: .infinity, alignment: .leading)

      SnoringBarChart(bars: period.nights.map { night in
        SnoringBar(
          id: night.id,
          label: range == .week
            ? night.start.formatted(.dateTime.weekday(.abbreviated))
            : night.start.formatted(.dateTime.day()),
          minutes: Int(night.snoringDuration / 60),
          intensity: night.loudestIntensity ?? .quiet)
      })

      SnoringLegend()

      LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
        StatTile(icon: "scope", iconColor: theme.palette.accent, label: Strings.statsTrendsStatCardAvgScore, value: "\(period.averageScore)")
        StatTile(icon: "star.fill", iconColor: theme.palette.scoreGreen, label: Strings.statsTrendsStatCardBestNight, value: "\(period.bestScore)")
        StatTile(icon: "bolt.fill", iconColor: theme.palette.snoreLoud, label: Strings.statsTrendsStatCardWorstNight, value: "\(period.worstScore)")
        StatTile(icon: "number", iconColor: theme.palette.textTertiary, label: Strings.statsTrendsStatCardTotalEvents, value: "\(period.eventCount)")
      }
    }
    .padding(20)
  }
}
