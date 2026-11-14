import Foundation

/// The nights of the last week or month (Trends), each night on its own.
public struct NightPeriod: Sendable, Equatable {
  /// Oldest first.
  public let nights: [NightSummary]

  /// Nights that started within `days` days before `now`.
  public init(lastDays days: Int, of nights: [NightSummary], now: Date, calendar: Calendar = .current) {
    guard let cutoff = calendar.date(byAdding: .day, value: -days, to: now) else {
      self.nights = []
      return
    }
    self.nights = nights.filter { $0.start >= cutoff }.sorted { $0.start < $1.start }
  }

  /// 0 without nights.
  public var averageScore: Int {
    nights.isEmpty ? 0 : nights.map(\.score).reduce(0, +) / nights.count
  }

  /// Each night's snoring in whole minutes, averaged; 0 without nights.
  public var averageSnoringMinutes: Int {
    nights.isEmpty ? 0 : nights.map { Int($0.snoringDuration / 60) }.reduce(0, +) / nights.count
  }

  /// 0 without nights.
  public var bestScore: Int {
    nights.map(\.score).max() ?? 0
  }

  /// 0 without nights.
  public var worstScore: Int {
    nights.map(\.score).min() ?? 0
  }

  public var eventCount: Int {
    nights.map(\.eventCount).reduce(0, +)
  }
}
