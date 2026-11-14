import Foundation

/// The nights that started on one day, added up. Several recordings on one
/// night (a nap, a restart) count as one day.
public struct NightDay: Sendable, Equatable, Identifiable {
  /// Start of the day.
  public let date: Date
  /// In the order they were given; the first is the one a row opens.
  public let nights: [NightSummary]

  public var id: Date {
    date
  }

  public var averageScore: Int {
    nights.map(\.score).reduce(0, +) / max(nights.count, 1)
  }

  /// Total snoring, in whole minutes.
  public var snoringMinutes: Int {
    Int(nights.map(\.snoringDuration).reduce(0, +) / 60)
  }

  public var eventCount: Int {
    nights.map(\.eventCount).reduce(0, +)
  }

  public var duration: TimeInterval {
    nights.map(\.duration).reduce(0, +)
  }

  /// The loudest night's intensity; `.quiet` when no night has events.
  public var loudestIntensity: SnoreIntensity {
    nights.compactMap(\.loudestIntensity).max() ?? .quiet
  }

  public init(date: Date, nights: [NightSummary]) {
    self.date = date
    self.nights = nights
  }

  /// Every recorded day, oldest first.
  public static func days(from nights: [NightSummary], calendar: Calendar = .current) -> [NightDay] {
    Dictionary(grouping: nights) { calendar.startOfDay(for: $0.start) }
      .map { NightDay(date: $0, nights: $1) }
      .sorted { $0.date < $1.date }
  }
}

/// A run of recorded days (the last 7 nights), added up.
public struct NightDayStats: Sendable, Equatable {
  public let days: [NightDay]

  public init(days: [NightDay]) {
    self.days = days
  }

  /// The most recent `count` recorded days, oldest first.
  public static func recent(_ count: Int = 7, from nights: [NightSummary], calendar: Calendar = .current) -> NightDayStats {
    NightDayStats(days: Array(NightDay.days(from: nights, calendar: calendar).suffix(count)))
  }

  /// Mean of the days' average scores; 0 without days.
  public var averageScore: Int {
    days.isEmpty ? 0 : days.map(\.averageScore).reduce(0, +) / days.count
  }

  /// Mean of the days' snoring minutes; 0 without days.
  public var averageSnoringMinutes: Int {
    days.isEmpty ? 0 : days.map(\.snoringMinutes).reduce(0, +) / days.count
  }

  public var eventCount: Int {
    days.map(\.eventCount).reduce(0, +)
  }

  /// The day with the highest average score (the last one on a tie).
  public var best: NightDay? {
    days.max { $0.averageScore < $1.averageScore }
  }

  /// The day with the lowest average score (the first one on a tie).
  public var worst: NightDay? {
    days.min { $0.averageScore < $1.averageScore }
  }
}
