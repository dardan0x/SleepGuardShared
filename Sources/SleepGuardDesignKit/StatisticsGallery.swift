import SleepCore
import SwiftUI

/// The statistics components on one screen, for previews and render tests.
/// Internal: sample data only.
struct StatisticsGallery: View {
  @Environment(\.theme) private var theme
  @State private var range = 0

  private static let start = Date(timeIntervalSinceReferenceDate: 815_000_000)
  private static let levels: [SnoreIntensity] = [.quiet, .light, .loud, .light, .quiet, .epic, .light]
  private static let bars: [SnoringBar] = {
    let labels = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"]
    let minutes = [4, 18, 42, 12, 0, 55, 20]
    return (0..<7).map { (index: Int) -> SnoringBar in
      SnoringBar(label: labels[index], minutes: minutes[index], intensity: levels[index])
    }
  }()

  private static let month: [CalendarMonthGrid.Day] = (0..<42).map { (offset: Int) -> CalendarMonthGrid.Day in
    let date = start.addingTimeInterval(Double(offset) * 86400)
    let loudest: SnoreIntensity? = offset % 4 == 0 ? levels[offset % 7] : nil
    return CalendarMonthGrid.Day(date: date, isInMonth: offset >= 3 && offset < 33, isSelected: offset == 12, loudest: loudest)
  }

  var body: some View {
    VStack(spacing: 16) {
      PillPicker(options: [0, 1], selection: $range) { $0 == 0 ? "Week" : "Month" }
      SnoringBarChart(bars: Self.bars)
      SnoringDayBars(bars: Self.bars)
      HStack(spacing: 8) {
        StatTile(icon: "scope", iconColor: theme.palette.accent, label: "AVG SCORE", value: "78")
        StatTile(icon: "leaf.fill", iconColor: theme.palette.scoreGreen, label: "BEST", value: "91 Tue", valueSize: 22, valueColor: theme.palette.scoreGreen)
      }
      HStack(spacing: 8) {
        CenteredStatTile(icon: "moon.fill", label: "SESSIONS", value: "12")
        CenteredStatTile(icon: "speaker.wave.3.fill", label: "LOUD NIGHTS", value: "3")
      }
      MonthHeader(title: "November 2026", onPrevious: {}, onNext: {}, onToday: {})
      CalendarMonthGrid(days: Self.month) { _ in }
      NightCard(score: 84, title: "Friday, Nov 13", detail: "Light snoring") {}
      DayRow(score: 72, date: Self.start, duration: 27000, snoringMinutes: 42, loudest: .loud) {}
      SnoringLegend()
    }
    .padding(16)
    .background(theme.palette.bgPrimary)
  }
}

#Preview("SleepGuard") {
  StatisticsGallery()
}

#Preview("Alternate theme") {
  StatisticsGallery()
    .environment(\.theme, .previewAlternate)
}
