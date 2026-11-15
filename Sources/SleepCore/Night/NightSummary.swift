import Foundation

/// What a list row or a chart needs about a night, without its events.
///
/// Meant to be stored next to the night when it is saved, so lists never load
/// events.
public struct NightSummary: Sendable, Equatable, Identifiable {
  public let id: UUID
  public var start: Date
  public var end: Date
  /// 0…100.
  public var score: Int
  /// Time counted as snoring, the score's input (see `SnoringDuration`).
  public var snoringDuration: TimeInterval
  /// Snoring episodes long enough to show, plus other events.
  public var eventCount: Int
  /// The loudest intensity of any event in the night; `nil` when it has none.
  /// Colours a night in the calendar, trends and last 7 nights.
  public var loudestIntensity: SnoreIntensity?

  public init(
    id: UUID, start: Date, end: Date, score: Int, snoringDuration: TimeInterval, eventCount: Int,
    loudestIntensity: SnoreIntensity? = nil)
  {
    self.id = id
    self.start = start
    self.end = end
    self.score = score
    self.snoringDuration = snoringDuration
    self.eventCount = eventCount
    self.loudestIntensity = loudestIntensity
  }

  public var duration: TimeInterval {
    end.timeIntervalSince(start)
  }

  /// Snoring time over the night's length, 0...1; 0 for a night with no length.
  public var snoringShare: Double {
    duration > 0 ? snoringDuration / duration : 0
  }

  /// How much of the night was snoring, as a level: over 15% loud, over 5%
  /// light, otherwise quiet. Colours the dashboard's week strip.
  public var snoringLevel: SnoreIntensity {
    switch snoringShare {
    case let share where share > 0.15: .loud
    case let share where share > 0.05: .light
    default: .quiet
    }
  }
}
