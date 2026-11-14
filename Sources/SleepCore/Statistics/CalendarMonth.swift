import Foundation

/// One month of the calendar: its nights, their stats, and the day grid.
public struct CalendarMonth: Sendable, Equatable {
  /// Any date in the month.
  public let month: Date
  /// Nights that started in the month, in the order given.
  public let nights: [NightSummary]

  public init(month: Date, nights: [NightSummary], calendar: Calendar = .current) {
    self.month = month
    self.nights = nights.filter { calendar.isDate($0.start, equalTo: month, toGranularity: .month) }
  }

  /// `nil` without nights (shown as a dash).
  public var averageScore: Int? {
    nights.isEmpty ? nil : nights.map(\.score).reduce(0, +) / nights.count
  }

  /// Nights with at least one loud or epic event.
  public var loudNightCount: Int {
    nights.filter { ($0.loudestIntensity ?? .quiet) >= .loud }.count
  }

  /// 42 days (6 weeks) starting on the calendar's first weekday, so the grid
  /// never changes height: the month plus leading and trailing days.
  public static func grid(for month: Date, calendar: Calendar = .current) -> [Date] {
    guard let first = calendar.dateInterval(of: .month, for: month)?.start else { return [] }
    let leading = (calendar.component(.weekday, from: first) - calendar.firstWeekday + 7) % 7
    guard let gridStart = calendar.date(byAdding: .day, value: -leading, to: first) else { return [] }
    return (0..<42).compactMap { calendar.date(byAdding: .day, value: $0, to: gridStart) }
  }

  /// The first night that started on `day`, searched in all nights (the grid
  /// shows neighbouring months' days too).
  public static func night(on day: Date, in nights: [NightSummary], calendar: Calendar = .current) -> NightSummary? {
    nights.first { calendar.isDate($0.start, inSameDayAs: day) }
  }
}
