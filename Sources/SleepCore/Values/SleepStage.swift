import Foundation

public enum SleepStage: String, Codable, Sendable {
  case awake
  case rem
  case light
  case deep
}

public struct SleepStageSegment: Codable, Sendable {
  public let stage: SleepStage
  public let startOffset: TimeInterval
  public let duration: TimeInterval

  public init(stage: SleepStage, startOffset: TimeInterval, duration: TimeInterval) {
    self.stage = stage
    self.startOffset = startOffset
    self.duration = duration
  }
}

/// Aggregated sleep stage percentages derived from sleep stage segments.
public struct StageStats: Sendable, Equatable {
  public let awakePct: Double
  public let remPct: Double
  public let lightPct: Double
  public let deepPct: Double

  public init(awakePct: Double, remPct: Double, lightPct: Double, deepPct: Double) {
    self.awakePct = awakePct
    self.remPct = remPct
    self.lightPct = lightPct
    self.deepPct = deepPct
  }
}
