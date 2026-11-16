import SleepCore
import SwiftUI

/// The Statistics screens' content with sample nights, for previews and
/// render tests. Internal: sample data only.
struct StatisticsContentGallery: View {
  enum Screen: CaseIterable {
    case dashboard
    case trends
    case calendar
    case lastSevenNights
    case empty
    case loading
  }

  let screen: Screen
  @State private var range = TrendsRange.week
  @State private var month = Self.now
  @State private var selectedDay = Calendar.current.startOfDay(for: Self.now.addingTimeInterval(-86400))

  static let now = Date(timeIntervalSinceReferenceDate: 815_000_000)

  /// Ten nights, one a day, ending last night.
  static let nights: [NightSummary] = (1...10).map { daysAgo in
    let start = Calendar.current.startOfDay(for: now).addingTimeInterval(Double(-daysAgo) * 86400 + 23 * 3600)
    let intensities: [SnoreIntensity?] = [.light, .loud, nil, .epic, .quiet]
    return NightSummary(
      id: UUID(), start: start, end: start.addingTimeInterval(7.5 * 3600), score: 55 + (daysAgo * 7) % 40,
      snoringDuration: Double(daysAgo % 4) * 600, eventCount: daysAgo % 5,
      loudestIntensity: intensities[daysAgo % intensities.count])
  }

  var body: some View {
    Group {
      switch screen {
      case .dashboard:
        if let dashboard = NightDashboard.make(from: Self.nights, now: Self.now) {
          StatisticsDashboardContent(
            dashboard: dashboard, latest: dashboard.latest, now: Self.now, onShowTrends: {}, onShowLastSevenNights: {})
        }
      case .trends:
        TrendsContent(range: $range, period: NightPeriod(lastDays: range.days, of: Self.nights, now: Self.now))
      case .calendar:
        CalendarContent(month: $month, selectedDay: $selectedDay, nights: Self.nights, onToday: {}) { _ in }
      case .lastSevenNights:
        LastSevenNightsContent(
          stats: NightDayStats.recent(from: Self.nights), trend: ScoreTrend.weekOverWeek(Self.nights)) { _ in }
      case .empty:
        StatisticsEmptyContent {}
      case .loading:
        StatisticsLoadingContent()
      }
    }
    .background(StatisticsContentBackground())
  }
}

private struct StatisticsContentBackground: View {
  @Environment(\.theme) private var theme

  var body: some View {
    theme.palette.bgPrimary
  }
}

#Preview("Dashboard") {
  ScrollView { StatisticsContentGallery(screen: .dashboard) }
}

#Preview("Trends") {
  ScrollView { StatisticsContentGallery(screen: .trends) }
}

#Preview("Calendar") {
  ScrollView { StatisticsContentGallery(screen: .calendar) }
}

#Preview("Last 7 Nights") {
  ScrollView { StatisticsContentGallery(screen: .lastSevenNights) }
    .environment(\.theme, .previewAlternate)
}
