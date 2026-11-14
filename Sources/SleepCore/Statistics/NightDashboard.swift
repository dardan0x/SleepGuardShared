import Foundation

/// What the Statistics dashboard shows. Pure: callers pass the nights and `now`.
public struct NightDashboard: Sendable, Equatable {
  /// The most recent night by start.
  public let latest: NightSummary
  /// Mean score of every night that started on the same day as `latest`.
  public let dayScore: Int
  public let dayNightCount: Int
  /// Up to 7 most recent nights, newest first.
  public let recent: [NightSummary]
  /// `latest` started yesterday relative to `now` (by start, not end: a bedtime
  /// after midnight reads as "last time" the same morning).
  public let isLastNight: Bool

  /// `nil` when there are no nights. `nights` may be in any order.
  public static func make(from nights: [NightSummary], now: Date, calendar: Calendar = .current) -> NightDashboard? {
    let newestFirst = nights.sorted { $0.start > $1.start }
    guard let latest = newestFirst.first else { return nil }
    let sameDay = newestFirst.filter { calendar.isDate($0.start, inSameDayAs: latest.start) }
    let yesterday = calendar.date(byAdding: .day, value: -1, to: now) ?? now
    return NightDashboard(
      latest: latest,
      dayScore: sameDay.map(\.score).reduce(0, +) / sameDay.count,
      dayNightCount: sameDay.count,
      recent: Array(newestFirst.prefix(7)),
      isLastNight: calendar.isDate(latest.start, inSameDayAs: yesterday))
  }
}
