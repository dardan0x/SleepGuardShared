import Foundation
import SleepCore
import Testing

/// What the stage views show: time and share per stage, each stage against
/// its target (SleepGuard's thresholds, now from the score config), and the
/// penalty the score applies.
struct SleepStageBreakdownTests {
  /// Shares are minutes out of 100: deep, REM, light, awake.
  private static func breakdown(deep: Double, rem: Double, light: Double, awake: Double) throws -> SleepStageBreakdown {
    let parts: [(SleepStage, Double)] = [(.deep, deep), (.rem, rem), (.light, light), (.awake, awake)]
    var offset: TimeInterval = 0
    let segments = parts.map { stage, minutes in
      defer { offset += minutes * 60 }
      return SleepStageSegment(stage: stage, startOffset: offset, duration: minutes * 60)
    }
    return try #require(SleepStageBreakdown(segments: segments))
  }

  @Test func noStageTimeIsNoBreakdown() {
    #expect(SleepStageBreakdown(segments: []) == nil)
    #expect(SleepStageBreakdown(segments: [SleepStageSegment(stage: .rem, startOffset: 0, duration: 0)]) == nil)
  }

  @Test func durationsAddUpPerStage() throws {
    let breakdown = try #require(SleepStageBreakdown(segments: [
      SleepStageSegment(stage: .deep, startOffset: 0, duration: 600),
      SleepStageSegment(stage: .light, startOffset: 600, duration: 1200),
      SleepStageSegment(stage: .deep, startOffset: 1800, duration: 600),
    ]))
    #expect(breakdown.duration(of: .deep) == 1200)
    #expect(breakdown.duration(of: .rem) == 0)
    #expect(breakdown.percent(of: .deep) == 50)
    #expect(breakdown.percent(of: .light) == 50)
  }

  @Test func statusesAtTheTargets() throws {
    let atTargets = try Self.breakdown(deep: 15, rem: 18, light: 59, awake: 8)
    #expect([.deep, .rem, .light, .awake].map { atTargets.status(of: $0) } == [.good, .good, .good, .good])

    let off = try Self.breakdown(deep: 14, rem: 17, light: 61, awake: 8)
    #expect(off.status(of: .deep) == .low)
    #expect(off.status(of: .rem) == .low)
    #expect(off.status(of: .light) == .high)

    let restless = try Self.breakdown(deep: 30, rem: 30, light: 31, awake: 9)
    #expect(restless.status(of: .awake) == .high)
    #expect(restless.status(of: .light) == .low)
  }

  @Test func statusFollowsTheConfiguredTargets() throws {
    var config = SleepScoreConfig.default
    config.deepPctTarget = 20
    #expect(try Self.breakdown(deep: 18, rem: 20, light: 54, awake: 8).status(of: .deep, config: config) == .low)
  }

  @Test func penaltyIsTheScoresStagePenalty() throws {
    let breakdown = try Self.breakdown(deep: 10, rem: 10, light: 60, awake: 20)
    // (15-10)*0.6 + (18-10)*0.4 + (20-8)*1.0 = 3 + 3.2 + 12 = 18.2, capped at 15.
    #expect(breakdown.penalty() == 15)
    #expect(try Self.breakdown(deep: 15, rem: 18, light: 59, awake: 8).penalty() == 0)
    #expect(breakdown.penalty() == SleepScore.stagePenalty(breakdown.stats, config: .default))
  }
}
