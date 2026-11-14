import Foundation

/// "This week vs last week": the average score of the 7 most recent recorded
/// days minus that of the up to 7 recorded days before them. Days, not
/// calendar weeks: days without a recording are skipped.
public struct ScoreTrend: Sendable, Equatable {
  /// Never 0.
  public let diff: Int

  public var isPositive: Bool {
    diff > 0
  }

  /// `nil` with fewer than 8 recorded days, or when both weeks score the same.
  public static func weekOverWeek(_ nights: [NightSummary], calendar: Calendar = .current) -> ScoreTrend? {
    let newestFirst = NightDay.days(from: nights, calendar: calendar).reversed().map(\.averageScore)
    guard newestFirst.count >= 8 else { return nil }
    let current = newestFirst.prefix(7)
    let previous = newestFirst.dropFirst(7).prefix(7)
    let diff = current.reduce(0, +) / current.count - previous.reduce(0, +) / previous.count
    return diff == 0 ? nil : ScoreTrend(diff: diff)
  }
}
