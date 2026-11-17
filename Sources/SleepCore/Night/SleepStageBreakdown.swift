import Foundation

public extension StageStats {
  /// Each stage's share of the staged time, in percent; `nil` without stages.
  static func make(from segments: [SleepStageSegment]) -> StageStats? {
    let total = segments.reduce(0) { $0 + $1.duration }
    guard total > 0 else { return nil }
    func percent(_ stage: SleepStage) -> Double {
      segments.filter { $0.stage == stage }.reduce(0) { $0 + $1.duration } / total * 100
    }
    return StageStats(awakePct: percent(.awake), remPct: percent(.rem), lightPct: percent(.light), deepPct: percent(.deep))
  }

  func percent(of stage: SleepStage) -> Double {
    switch stage {
    case .awake: awakePct
    case .rem: remPct
    case .light: lightPct
    case .deep: deepPct
    }
  }
}

/// How a stage's share compares with its target.
public enum StageStatus: Sendable, Equatable {
  case good
  case low
  case high
}

/// A night's sleep stages as the stage views show them: time and share per
/// stage, and how each share compares with the score's targets.
public struct SleepStageBreakdown: Sendable, Equatable {
  /// Light sleep is good between these shares (percent). The other stages'
  /// targets are the score's (`SleepScoreConfig`).
  public static let lightRange = 40.0...60.0

  public let segments: [SleepStageSegment]
  public let stats: StageStats

  /// `nil` when the segments add up to no time.
  public init?(segments: [SleepStageSegment]) {
    guard let stats = StageStats.make(from: segments) else { return nil }
    self.segments = segments
    self.stats = stats
  }

  public func duration(of stage: SleepStage) -> TimeInterval {
    segments.filter { $0.stage == stage }.reduce(0) { $0 + $1.duration }
  }

  public func percent(of stage: SleepStage) -> Double {
    stats.percent(of: stage)
  }

  public func status(of stage: SleepStage, config: SleepScoreConfig = .default) -> StageStatus {
    let pct = percent(of: stage)
    switch stage {
    case .deep: return pct >= config.deepPctTarget ? .good : .low
    case .rem: return pct >= config.remPctTarget ? .good : .low
    case .awake: return pct <= config.awakePctTarget ? .good : .high
    case .light:
      if pct > Self.lightRange.upperBound { return .high }
      if pct < Self.lightRange.lowerBound { return .low }
      return .good
    }
  }

  /// The points the score loses for these stages.
  public func penalty(config: SleepScoreConfig = .default) -> Int {
    SleepScore.stagePenalty(stats, config: config)
  }
}
