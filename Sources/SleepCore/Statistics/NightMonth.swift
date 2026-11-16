import Foundation

/// One month of a nights list: the days in it that have nights.
public struct NightMonth: Sendable, Equatable, Identifiable {
  /// Start of the month.
  public let month: Date
  /// Newest first; each day's nights newest first. Never empty.
  public let days: [NightDay]

  public var id: Date {
    month
  }

  public init(month: Date, days: [NightDay]) {
    self.month = month
    self.days = days
  }

  /// Nights grouped by the month, then the day, they started in. Newest first
  /// at every level, so a day's first night is its latest. How both apps'
  /// nights lists group (SleepGuard's `SessionGrouper` before).
  public static func months(from nights: [NightSummary], calendar: Calendar = .current) -> [NightMonth] {
    let byDay: [Date: [NightSummary]] = Dictionary(grouping: nights) { calendar.startOfDay(for: $0.start) }
    let days: [NightDay] = byDay.map { date, dayNights in
      NightDay(date: date, nights: dayNights.sorted { $0.start > $1.start })
    }
    let byMonth: [Date: [NightDay]] = Dictionary(grouping: days) { day in
      calendar.dateInterval(of: .month, for: day.date)?.start ?? day.date
    }
    let months: [NightMonth] = byMonth.map { month, monthDays in
      NightMonth(month: month, days: monthDays.sorted { $0.date > $1.date })
    }
    return months.sorted { $0.month > $1.month }
  }
}
