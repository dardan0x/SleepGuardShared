import Foundation
import Testing
@testable import SleepCore

/// The nights list grouping. Cases from both apps: SleepGuard's
/// `SessionGrouperTests` and SleepGuardUIKitWay's `HistorySectionsTests`.
struct NightMonthTests {
  private let calendar: Calendar = {
    var calendar = Calendar(identifier: .gregorian)
    calendar.timeZone = TimeZone(identifier: "UTC")!
    return calendar
  }()

  private func night(
    day: Int, month: Int = 11, year: Int = 2026, hour: Int = 23, score: Int = 80, hours: Double = 8, events: Int = 2)
    -> NightSummary
  {
    let start = calendar.date(from: DateComponents(year: year, month: month, day: day, hour: hour))!
    return NightSummary(
      id: UUID(), start: start, end: start.addingTimeInterval(hours * 3600), score: score, snoringDuration: 0,
      eventCount: events)
  }

  @Test func noNightsNoMonths() {
    #expect(NightMonth.months(from: [], calendar: calendar).isEmpty)
  }

  @Test func monthsThenDaysNewestFirst() {
    let months = NightMonth.months(from: [night(day: 3), night(day: 20), night(day: 28, month: 10), night(day: 12)], calendar: calendar)
    #expect(months.map { calendar.component(.month, from: $0.month) } == [11, 10])
    #expect(months[0].days.map { calendar.component(.day, from: $0.date) } == [20, 12, 3])
    #expect(months[1].days.count == 1)
  }

  @Test func monthsAreNewestFirstAcrossAYearBoundary() {
    let months = NightMonth.months(from: [night(day: 30, month: 12, year: 2025), night(day: 3, month: 2), night(day: 15, month: 1)], calendar: calendar)
    #expect(months.map { calendar.component(.year, from: $0.month) } == [2026, 2026, 2025])
    #expect(months.map { calendar.component(.month, from: $0.month) } == [2, 1, 12])
  }

  @Test func nightsOfADayShareItNewestFirst() throws {
    let nap = night(day: 5, hour: 14, score: 90, hours: 1, events: 0)
    let late = night(day: 5, hour: 23, score: 60, hours: 7, events: 4)
    let other = night(day: 1)
    let months = NightMonth.months(from: [nap, other, late], calendar: calendar)
    let days = try #require(months.first?.days)
    #expect(days.count == 2)
    #expect(days[0].nights.map(\.id) == [late.id, nap.id])
    #expect(days[1].nights.map(\.id) == [other.id])
  }

  /// A day's totals are `NightDay`'s: integer-division average, summed length and events.
  @Test func dayTotals() throws {
    let months = NightMonth.months(
      from: [night(day: 4, hour: 1, score: 80, hours: 2, events: 1), night(day: 4, hour: 4, score: 71, hours: 3, events: 3)],
      calendar: calendar)
    let day = try #require(months.first?.days.first)
    #expect(day.averageScore == 75) // (80 + 71) / 2
    #expect(day.duration == 5 * 3600)
    #expect(day.eventCount == 4)
  }
}
