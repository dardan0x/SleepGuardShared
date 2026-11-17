import Foundation

/// What a night's PDF report shows, as values (SleepGuard's report): the
/// score and its rating, the stats, the sleep stages and sleep talking when
/// the night has them, and every event, split into pages.
public struct NightReport: Equatable, Sendable {
  public enum Rating: Equatable, Sendable {
    /// 80 and up.
    case excellent
    /// 50 to 79.
    case fair
    case poor

    public init(score: Int) {
      self = score >= 80 ? .excellent : (score >= 50 ? .fair : .poor)
    }
  }

  /// One row of the events table, in time order.
  public struct Row: Equatable, Sendable {
    public enum Kind: Equatable, Sendable {
      case snoring, sleepTalking, noise

      /// Coughing and anything else read as noise, as in SleepGuard's report.
      init(_ category: SoundCategory) {
        self = switch category {
        case .snoring: .snoring
        case .sleepTalking: .sleepTalking
        case .noise, .coughing, .other: .noise
        }
      }
    }

    public var start: Date
    public var kind: Kind
    public var duration: TimeInterval
    public var intensity: SnoreIntensity
  }

  public struct SleepTalking: Equatable, Sendable {
    public var count: Int
    public var duration: TimeInterval
    /// Percent of the night, 0...100.
    public var share: Double
  }

  public var start: Date
  public var score: Int
  public var rating: Rating
  public var duration: TimeInterval
  /// Percent of the night spent snoring, 0...100.
  public var snoringShare: Double
  public var snoringDuration: TimeInterval
  public var eventCount: Int
  /// Sleep stages, when the night has them (the score then counts them too).
  public var stages: StageStats?
  public var sleepTalking: SleepTalking?
  public var rows: [Row]

  public init(night: Night, config: SleepScoreConfig = .default) {
    start = night.start
    score = night.score(using: config)
    rating = Rating(score: score)
    duration = night.duration
    snoringDuration = night.snoringDuration
    snoringShare = night.duration > 0 ? night.snoringDuration / night.duration * 100 : 0
    eventCount = night.eventCount
    stages = night.stageStats
    let talking = night.sleepTalkingEvents
    sleepTalking = talking.isEmpty ? nil : SleepTalking(
      count: talking.count, duration: night.sleepTalkingDuration,
      share: night.duration > 0 ? night.sleepTalkingDuration / night.duration * 100 : 0)
    rows = night.events.sorted { $0.start < $1.start }.map { event in
      Row(start: event.start, kind: Row.Kind(event.category), duration: event.duration, intensity: event.intensity)
    }
  }

  /// The rows per page: the first page has room for `firstPage` under the
  /// summary, each later page for `perPage`. Always at least one page.
  public func pages(firstPage: Int, perPage: Int) -> [[Row]] {
    var pages = [Array(rows.prefix(firstPage))]
    var rest = rows.dropFirst(firstPage)
    while !rest.isEmpty {
      pages.append(Array(rest.prefix(perPage)))
      rest = rest.dropFirst(perPage)
    }
    return pages
  }
}
