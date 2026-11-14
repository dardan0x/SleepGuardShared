import Foundation
import Testing
@testable import SleepCore

/// The statistics rules, on a fixed clock and a fixed-zone calendar. The
/// dashboard and week-over-week cases are SleepGuard's, with the same numbers.
struct NightStatisticsTests {
  private let calendar: Calendar = {
    var calendar = Calendar(identifier: .gregorian)
    calendar.timeZone = TimeZone(identifier: "Europe/Berlin")!
    calendar.firstWeekday = 2 // Monday
    return calendar
  }()

  /// 2026-11-10 08:00 local.
  private var now: Date {
    date(day: 10, hour: 8)
  }

  private func date(month: Int = 11, day: Int, hour: Int, minute: Int = 0) -> Date {
    calendar.date(from: DateComponents(year: 2026, month: month, day: day, hour: hour, minute: minute))!
  }

  private func night(
    month: Int = 11, day: Int, hour: Int = 23, minute: Int = 0, hours: Double = 7, score: Int = 80,
    snoring: TimeInterval = 0, events: Int = 0, loudest: SnoreIntensity? = nil) -> NightSummary
  {
    let start = date(month: month, day: day, hour: hour, minute: minute)
    return NightSummary(
      id: UUID(), start: start, end: start.addingTimeInterval(hours * 3600), score: score,
      snoringDuration: snoring, eventCount: events, loudestIntensity: loudest)
  }

  // MARK: - Dashboard (SleepGuard's DashboardStateTests)

  private func dashboard(_ nights: [NightSummary]) -> NightDashboard? {
    NightDashboard.make(from: nights, now: now, calendar: calendar)
  }

  @Test func noNightsIsEmpty() {
    #expect(dashboard([]) == nil)
  }

  @Test func latestNightWinsRegardlessOfInputOrder() throws {
    let older = night(day: 7)
    let latest = night(day: 9)
    let state = try #require(dashboard([older, latest]))
    #expect(state.latest == latest)
    #expect(state.recent.map(\.id) == [latest.id, older.id])
  }

  @Test func recentNightsAreCappedAtSeven() throws {
    let state = try #require(dashboard((1...9).map { night(day: $0) }))
    #expect(state.recent.count == 7)
    #expect(state.recent.first?.start == date(day: 9, hour: 23))
  }

  @Test func nightStartedYesterdayEveningIsLastNight() throws {
    #expect(try #require(dashboard([night(day: 9, minute: 30)])).isLastNight)
  }

  @Test func olderNightIsLastTime() throws {
    #expect(try !#require(dashboard([night(day: 7)])).isLastNight)
  }

  /// "Last night" is judged by start: a bedtime after midnight (today 00:30)
  /// reads as "last time" the same morning.
  @Test func nightStartedAfterMidnightIsNotLastNight() throws {
    #expect(try !#require(dashboard([night(day: 10, hour: 0, minute: 30)])).isLastNight)
  }

  /// A night crossing midnight belongs to the day it started.
  @Test func nightCrossingMidnightGroupsByStartDay() throws {
    let nap = night(day: 9, hour: 15, hours: 1, score: 60)
    let main = night(day: 9, hour: 23, hours: 8, score: 90)
    let state = try #require(dashboard([nap, main]))
    #expect(state.latest == main)
    #expect(state.dayNightCount == 2)
    #expect(state.dayScore == 75)
  }

  @Test func dayScoreIgnoresOtherDays() throws {
    let state = try #require(dashboard([night(day: 8, score: 40), night(day: 9, score: 90)]))
    #expect(state.dayNightCount == 1)
    #expect(state.dayScore == 90)
  }

  // MARK: - Week over week (SleepGuard's WeekOverWeekTrendCalculatorTests)

  /// `recent` scores for days 0…, then `previous` scores for the days after, at midday.
  private func days(recent: [Int], previous: [Int]) -> [NightSummary] {
    (recent + previous).enumerated().map { offset, score in
      night(day: 30 - offset, hour: 12, score: score)
    }
  }

  private func trend(_ nights: [NightSummary]) -> ScoreTrend? {
    ScoreTrend.weekOverWeek(nights, calendar: calendar)
  }

  @Test func noNightsProduceNoTrend() {
    #expect(trend([]) == nil)
  }

  @Test func needsAtLeastEightRecordedDays() {
    #expect(trend(days(recent: Array(repeating: 80, count: 7), previous: [])) == nil)
    #expect(trend(days(recent: Array(repeating: 80, count: 7), previous: [70]))?.diff == 10)
  }

  @Test func betterWeekIsPositive() throws {
    let result = try #require(trend(days(recent: Array(repeating: 85, count: 7), previous: Array(repeating: 80, count: 7))))
    #expect(result.diff == 5)
    #expect(result.isPositive)
  }

  @Test func worseWeekIsNegative() throws {
    let result = try #require(trend(days(recent: Array(repeating: 70, count: 7), previous: Array(repeating: 80, count: 7))))
    #expect(result.diff == -10)
    #expect(!result.isPositive)
  }

  @Test func equalWeeksProduceNoTrend() {
    #expect(trend(days(recent: Array(repeating: 80, count: 7), previous: Array(repeating: 80, count: 7))) == nil)
  }

  @Test func nightsOnTheSameDayAreAveragedFirst() {
    // Day 30 has 60 and 100 → 80, so the recent week averages 80.
    let recent = [night(day: 30, hour: 12, score: 60), night(day: 30, hour: 13, score: 100)]
      + (1..<7).map { night(day: 30 - $0, hour: 12, score: 80) }
    #expect(trend(recent + [night(day: 23, hour: 12, score: 70)])?.diff == 10)
  }

  @Test func onlyFourteenRecordedDaysCount() {
    // A 15th, much older day with score 0 must not drag the previous week down.
    #expect(trend(days(recent: Array(repeating: 80, count: 7), previous: Array(repeating: 70, count: 7) + [0]))?.diff == 10)
  }

  @Test func daysWithoutRecordingsAreSkipped() {
    // 8 recorded days spread over a month still form two "weeks".
    let spread = (0..<8).map { night(day: 30 - $0 * 4, hour: 12, score: $0 < 7 ? 90 : 60) }
    #expect(trend(spread)?.diff == 30)
  }

  // MARK: - Days and the last 7 nights

  @Test func daysGroupByStartDayOldestFirstAndAddUp() throws {
    let nap = night(day: 9, hour: 15, hours: 1, score: 60, snoring: 90, events: 1, loudest: .light)
    let main = night(day: 9, hour: 23, hours: 8, score: 91, snoring: 600, events: 4, loudest: .loud)
    let earlier = night(day: 8, score: 70)
    let result = NightDay.days(from: [nap, main, earlier], calendar: calendar)
    #expect(result.map(\.date) == [calendar.startOfDay(for: earlier.start), calendar.startOfDay(for: nap.start)])
    let day = try #require(result.last)
    #expect(day.nights.map(\.id) == [nap.id, main.id])
    #expect(day.averageScore == 75)
    #expect(day.snoringMinutes == 11) // 690 s
    #expect(day.eventCount == 5)
    #expect(day.duration == 9 * 3600)
    #expect(day.loudestIntensity == .loud)
    #expect(result.first?.loudestIntensity == .quiet) // no events
  }

  @Test func lastSevenNightsTakesTheMostRecentRecordedDays() throws {
    let nights = (1...9).map { night(day: $0, score: 60 + $0, snoring: Double($0) * 60, events: 1) }
    let stats = NightDayStats.recent(from: nights, calendar: calendar)
    #expect(stats.days.count == 7)
    #expect(stats.days.first?.date == calendar.startOfDay(for: date(day: 3, hour: 0)))
    #expect(stats.averageScore == 66) // 63…69
    #expect(stats.averageSnoringMinutes == 6) // 3…9
    #expect(stats.eventCount == 7)
    #expect(stats.best?.averageScore == 69)
    #expect(stats.worst?.averageScore == 63)
  }

  @Test func emptyLastSevenNightsAreZero() {
    let stats = NightDayStats.recent(from: [], calendar: calendar)
    #expect(stats.averageScore == 0)
    #expect(stats.averageSnoringMinutes == 0)
    #expect(stats.best == nil)
  }

  // MARK: - Trends period

  @Test func periodKeepsNightsWithinTheRangeOldestFirst() {
    let inside = night(day: 5, snoring: 150, events: 2) // 2.5 → 2 min
    let latest = night(day: 9, score: 90, snoring: 359, events: 3) // 5.98 → 5 min
    let outside = night(day: 2, score: 10)
    let period = NightPeriod(lastDays: 7, of: [latest, outside, inside], now: now, calendar: calendar)
    #expect(period.nights.map(\.id) == [inside.id, latest.id])
    #expect(period.averageScore == 85)
    #expect(period.averageSnoringMinutes == 3) // whole minutes per night, then averaged
    #expect(period.bestScore == 90)
    #expect(period.worstScore == 80)
    #expect(period.eventCount == 5)
  }

  @Test func emptyPeriodIsZero() {
    let period = NightPeriod(lastDays: 30, of: [], now: now, calendar: calendar)
    #expect(period.averageScore == 0 && period.bestScore == 0 && period.worstScore == 0)
  }

  // MARK: - Calendar month

  @Test func monthCountsItsNightsAndLoudOnes() {
    let nights = [
      night(day: 3, score: 70, loudest: .light), night(day: 4, score: 90, loudest: .epic),
      night(day: 5, score: 80, loudest: .loud), night(day: 6, score: 60),
      night(month: 10, day: 30, score: 10, loudest: .epic),
    ]
    let month = CalendarMonth(month: date(day: 15, hour: 12), nights: nights, calendar: calendar)
    #expect(month.nights.count == 4)
    #expect(month.averageScore == 75)
    #expect(month.loudNightCount == 2)
    #expect(CalendarMonth(month: date(month: 12, day: 1, hour: 12), nights: nights, calendar: calendar).averageScore == nil)
  }

  @Test func gridIsSixWeeksFromTheFirstWeekday() throws {
    // November 2026 starts on a Sunday; weeks start on Monday → 6 leading days.
    let grid = CalendarMonth.grid(for: date(day: 15, hour: 12), calendar: calendar)
    #expect(grid.count == 42)
    #expect(grid.first == date(month: 10, day: 26, hour: 0))
    #expect(grid[6] == date(day: 1, hour: 0))
    #expect(try calendar.component(.weekday, from: #require(grid.first)) == calendar.firstWeekday)
  }

  @Test func dayLookupSearchesAllNights() {
    let october = night(month: 10, day: 31, hour: 22)
    #expect(CalendarMonth.night(on: date(month: 10, day: 31, hour: 0), in: [october], calendar: calendar) == october)
    #expect(CalendarMonth.night(on: date(day: 1, hour: 0), in: [october], calendar: calendar) == nil)
  }

  // MARK: - Loudest intensity

  @Test func loudestIntensityCountsEveryEvent() {
    let start = date(day: 9, hour: 23)
    let event = { (intensity: SnoreIntensity, category: SoundCategory) in
      NightEvent(start: start.addingTimeInterval(600), duration: 30, category: category, intensity: intensity)
    }
    #expect(Night(start: start, end: start.addingTimeInterval(3600)).summary().loudestIntensity == nil)
    let night = Night(start: start, end: start.addingTimeInterval(3600), events: [
      event(.light, .snoring), event(.loud, .coughing), event(.quiet, .sleepTalking),
    ])
    #expect(night.summary().loudestIntensity == .loud)
    #expect([SnoreIntensity.epic, .quiet, .loud, .light].sorted() == [.quiet, .light, .loud, .epic])
  }
}
