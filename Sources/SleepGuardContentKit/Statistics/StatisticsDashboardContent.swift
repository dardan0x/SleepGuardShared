import SleepCore
import SwiftUI

/// The Statistics dashboard below its title: this week, the latest day's
/// score, the latest night's stats, and the last seven nights.
///
/// `latest` is the latest night with its events counted (the dashboard itself
/// can be built from summaries without events). `extra` goes below the stats:
/// SleepGuard's sleep-stage breakdown.
public struct StatisticsDashboardContent<Extra: View>: View {
  let dashboard: NightDashboard
  let latest: NightSummary
  let now: Date
  let compact: Bool
  let onShowTrends: () -> Void
  let onShowLastSevenNights: () -> Void
  let extra: Extra
  @Environment(\.theme) private var theme

  /// `compact` tightens the spacing for short screens.
  public init(
    dashboard: NightDashboard,
    latest: NightSummary,
    now: Date,
    compact: Bool = false,
    onShowTrends: @escaping () -> Void,
    onShowLastSevenNights: @escaping () -> Void,
    @ViewBuilder extra: () -> Extra)
  {
    self.dashboard = dashboard
    self.latest = latest
    self.now = now
    self.compact = compact
    self.onShowTrends = onShowTrends
    self.onShowLastSevenNights = onShowLastSevenNights
    self.extra = extra()
  }

  public var body: some View {
    VStack(spacing: compact ? 10 : 16) {
      VStack(spacing: 8) {
        HStack {
          Text(Strings.statsTrendsThisWeekLabel)
            .font(theme.typography.font(size: 12, weight: .semibold))
            .foregroundStyle(theme.palette.textTertiary)
            .tracking(1)
          Spacer()
          Button(Strings.statsTrendsViewMonth, action: onShowTrends)
            .font(theme.typography.font(size: 14, weight: .medium))
            .foregroundStyle(theme.palette.accent)
        }
        WeekStrip(days: dashboard.week(now: now))
      }

      SleepScoreGauge(score: dashboard.dayScore, size: 120)

      VStack(spacing: 4) {
        Text(Self.summaryLabel(dashboard))
          .font(theme.typography.font(size: 12, weight: .semibold))
          .foregroundStyle(theme.palette.textTertiary)
          .tracking(1)
        Text("\(latest.start.formatted(.dateTime.month(.abbreviated).day())) · \(Self.times(latest))")
          .font(theme.typography.font(size: 15))
          .foregroundStyle(theme.palette.textSecondary)
      }

      SessionStatsGrid(
        duration: latest.duration, snoringShare: latest.snoringShare,
        snoreTime: latest.snoringDuration, eventCount: latest.eventCount)

      extra

      if !dashboard.recent.isEmpty {
        StatisticsWeekChart(nights: dashboard.recent, onSeeAll: onShowLastSevenNights)
      }
    }
    .padding(.horizontal, 20)
    .padding(.vertical, 10)
  }

  /// "LAST NIGHT", "LAST TIME", or "2 RECORDINGS" when the day had several.
  static func summaryLabel(_ dashboard: NightDashboard) -> String {
    if dashboard.dayNightCount > 1 {
      return "\(dashboard.dayNightCount) \(Strings.recordingsStatisticsLoadedView)"
    }
    return dashboard.isLastNight ? Strings.lastNightStatisticsLoadedView : Strings.lastTimeStatisticsLoadedView
  }

  /// "23:10 – 06:45" in the device's short time.
  static func times(_ night: NightSummary) -> String {
    "\(night.start.formatted(date: .omitted, time: .shortened)) – \(night.end.formatted(date: .omitted, time: .shortened))"
  }
}

public extension StatisticsDashboardContent where Extra == EmptyView {
  init(
    dashboard: NightDashboard,
    latest: NightSummary,
    now: Date,
    compact: Bool = false,
    onShowTrends: @escaping () -> Void,
    onShowLastSevenNights: @escaping () -> Void)
  {
    self.init(
      dashboard: dashboard, latest: latest, now: now, compact: compact, onShowTrends: onShowTrends,
      onShowLastSevenNights: onShowLastSevenNights) { EmptyView() }
  }
}

/// "Last 7 Nights": one bar per day's average score (SleepCore's `NightDay`).
struct StatisticsWeekChart: View {
  let nights: [NightSummary]
  let onSeeAll: () -> Void
  @Environment(\.theme) private var theme

  var body: some View {
    VStack(alignment: .leading, spacing: 16) {
      HStack {
        Text(Strings.statsTrendsLastSevenNights)
          .font(theme.typography.font(size: 20, weight: .bold))
          .foregroundStyle(theme.palette.textPrimary)
        Spacer()
        Button(Strings.statsTrendsSeeAll, action: onSeeAll)
          .font(theme.typography.font(size: 14, weight: .medium))
          .foregroundStyle(theme.palette.accent)
      }
      MiniBarChart(data: NightDay.days(from: nights).map { day in
        MiniBarChart.DataPoint(
          label: String(day.date.formatted(.dateTime.weekday(.narrow))),
          value: Double(day.averageScore),
          color: theme.scoreColor(day.averageScore),
          accessibilityLabel: day.date.formatted(.dateTime.weekday(.wide)),
          accessibilityValue: String(format: Strings.a11yScoreOutOf100, day.averageScore))
      })
    }
    .padding(12)
  }
}
