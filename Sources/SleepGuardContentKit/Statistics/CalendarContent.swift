import SleepCore
import SwiftUI
import SleepGuardDesignKit
import SleepStrings

/// The calendar below its title: the month with each night's loudest snoring,
/// the month's counts, the selected day's night, and the legend.
///
/// The screen owns `month` and `selectedDay`. `nights` are full summaries
/// (for the loudest snoring) of at least the nights in the month's grid
/// (`CalendarMonth.grid(for:)`). `onToday`, when given, adds Today to the
/// month header.
public struct CalendarContent: View {
  @Binding var month: Date
  @Binding var selectedDay: Date
  let nights: [NightSummary]
  let onToday: (() -> Void)?
  let onOpen: (NightSummary) -> Void
  @Environment(\.theme) private var theme
  @Environment(\.calendar) private var calendar

  public init(
    month: Binding<Date>,
    selectedDay: Binding<Date>,
    nights: [NightSummary],
    onToday: (() -> Void)? = nil,
    onOpen: @escaping (NightSummary) -> Void)
  {
    _month = month
    _selectedDay = selectedDay
    self.nights = nights
    self.onToday = onToday
    self.onOpen = onOpen
  }

  public var body: some View {
    let stats = CalendarMonth(month: month, nights: nights, calendar: calendar)
    VStack(spacing: 16) {
      MonthHeader(
        title: month.formatted(.dateTime.month(.wide).year()),
        onPrevious: { month = calendar.date(byAdding: .month, value: -1, to: month) ?? month },
        onNext: { month = calendar.date(byAdding: .month, value: 1, to: month) ?? month },
        onToday: onToday)

      CalendarMonthGrid(days: CalendarMonth.grid(for: month, calendar: calendar).map { date in
        CalendarMonthGrid.Day(
          date: date,
          isInMonth: calendar.isDate(date, equalTo: month, toGranularity: .month),
          isSelected: calendar.isDate(date, inSameDayAs: selectedDay),
          loudest: CalendarMonth.night(on: date, in: nights, calendar: calendar)?.loudestIntensity)
      }) { selectedDay = $0 }

      HStack(spacing: 8) {
        CenteredStatTile(icon: "moon.fill", label: Strings.sessionsCalendarStatCardLabel, value: "\(stats.nights.count)")
        CenteredStatTile(icon: "scope", label: Strings.avgScoreCalendarStatCardLabel, value: stats.averageScore.map { "\($0)" } ?? "—")
        CenteredStatTile(icon: "speaker.wave.3.fill", label: Strings.loudNightsCalendarStatCardLabel, value: "\(stats.loudNightCount)")
      }

      if let night = CalendarMonth.night(on: selectedDay, in: nights, calendar: calendar) {
        VStack(alignment: .leading, spacing: 8) {
          Text(Strings.statsCalendarSelectedNightLabel)
            .font(theme.typography.font(size: 11, weight: .semibold))
            .foregroundStyle(theme.palette.textTertiary)
            .tracking(1)
          NightCard(score: night.score, title: Self.dayTitle(selectedDay), detail: Self.detail(night)) { onOpen(night) }
        }
      }

      SnoringLegend()
    }
    .padding(.horizontal, 20)
    .padding(.bottom, 20)
  }

  /// "Monday, Nov 16".
  static func dayTitle(_ day: Date) -> String {
    day.formatted(.dateTime.weekday(.wide).month(.abbreviated).day())
  }

  /// "Loud · 82 out of 100".
  static func detail(_ night: NightSummary) -> String {
    "\(loudnessLabel(night.loudestIntensity)) · \(String(format: Strings.a11yScoreOutOf100, night.score))"
  }

  /// The night's loudest snoring, in words.
  static func loudnessLabel(_ intensity: SnoreIntensity?) -> String {
    switch intensity {
    case .epic: Strings.statsCalendarLegendEpic
    case .loud: Strings.statsCalendarLegendLoud
    case .light: Strings.statsCalendarLegendLight
    case .quiet: Strings.statsCalendarIntensityQuiet
    case nil: Strings.quietIntensityLabel
    }
  }
}
