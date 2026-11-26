#if canImport(UIKit)
// Renders through UIKit, so these tests run on the iOS Simulator lane only
// (scripts/run-tests.sh); `swift test` on macOS compiles this file out.
import SleepCore
import SwiftUI
import Testing
@testable import SleepGuardContentKit
import SleepGuardDesignKit
import SleepStrings

/// Every Statistics screen's content renders in two themes and the theme
/// reaches it. Set `TEST_RUNNER_DESIGN_KIT_RENDER_DIR` to keep the PNGs.
@MainActor
struct StatisticsContentTests {
  @Test(arguments: StatisticsContentGallery.Screen.allCases)
  func rendersInBothThemes(screen: StatisticsContentGallery.Screen) throws {
    let sleepGuard = try render(StatisticsContentGallery(screen: screen).environment(\.theme, .sleepGuard))
    let alternate = try render(StatisticsContentGallery(screen: screen).environment(\.theme, .previewAlternate))
    #expect(sleepGuard.count > 1000)
    #expect(sleepGuard != alternate)
    if let directory = ProcessInfo.processInfo.environment["DESIGN_KIT_RENDER_DIR"] {
      try sleepGuard.write(to: URL(fileURLWithPath: directory).appendingPathComponent("content-\(screen)-sleepguard.png"))
      try alternate.write(to: URL(fileURLWithPath: directory).appendingPathComponent("content-\(screen)-alternate.png"))
    }
  }

  @Test func dashboardLabels() throws {
    let nights = StatisticsContentGallery.nights
    let dashboard = try #require(NightDashboard.make(from: nights, now: StatisticsContentGallery.now))
    #expect(StatisticsDashboardContent<EmptyView>.summaryLabel(dashboard) == Strings.lastNightStatisticsLoadedView)
    let night = nights[0]
    let expected = "\(night.start.formatted(date: .omitted, time: .shortened)) – \(night.end.formatted(date: .omitted, time: .shortened))"
    #expect(StatisticsDashboardContent<EmptyView>.times(night) == expected)
  }

  @Test func calendarTexts() {
    let night = NightSummary(id: UUID(), start: .now, end: .now, score: 82, snoringDuration: 0, eventCount: 1, loudestIntensity: .loud)
    #expect(CalendarContent.detail(night) == "\(Strings.statsCalendarLegendLoud) · \(String(format: Strings.a11yScoreOutOf100, 82))")
    #expect(CalendarContent.loudnessLabel(nil) == Strings.quietIntensityLabel)
    #expect(CalendarContent.loudnessLabel(.quiet) == Strings.statsCalendarIntensityQuiet)
    // SleepGuard's "EEEE, MMM d" template.
    let formatter = DateFormatter()
    formatter.dateFormat = DateFormatter.dateFormat(fromTemplate: "EEEE, MMM d", options: 0, locale: .current)
    let day = StatisticsContentGallery.now
    #expect(CalendarContent.dayTitle(day) == formatter.string(from: day))
  }

  @Test func lastSevenNightsTexts() {
    #expect(LastSevenNightsContent.scoreAndDay(nil) == "0 ")
    #expect(LastSevenNightsHeader.range(NightDayStats(days: [])) == "")
    #expect(TrendsRange.week.days == 7 && TrendsRange.month.days == 30)
  }

  private func render(_ view: some View) throws -> Data {
    let renderer = ImageRenderer(content: view.frame(width: 390))
    renderer.scale = 2
    let image = try #require(renderer.uiImage)
    return try #require(image.pngData())
  }
}
#endif
