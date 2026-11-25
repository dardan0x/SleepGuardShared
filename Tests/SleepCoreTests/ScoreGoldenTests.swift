import Foundation
import Testing
@testable import SleepCore

/// Pins the score cache's identity. Apps re-score stored nights only when
/// `SleepScore.cacheVersion(for:)` changes, so a formula change that keeps the
/// version would leave every stored score silently stale.
///
/// If `knownNightScore` fails, the formula's output changed: bump
/// `SleepScore.formulaVersion`, then update both pins here (minor release).
/// If only `defaultCacheVersion` fails, `SleepScoreConfig.default` changed:
/// update that pin (also a minor release, it re-scores every night).
struct ScoreGoldenTests {
  /// Snoring, a loud event, a melody gap where snoring resumed and a 30-min
  /// interruption: touches every rule that version 2 changed.
  private let night = Sample.night(
    events: [
      Sample.event(at: 600, duration: 48 * 60),
      Sample.event(at: 7200, duration: 120, intensity: .loud),
    ],
    gaps: [
      RecordingGap(startOffset: 3600, duration: 60, snoringResumed: true, kind: .melody),
      RecordingGap(startOffset: 4 * 3600, duration: 1800, snoringResumed: false, kind: .interruption),
    ])

  @Test func knownNightScore() {
    #expect(SleepScore.formulaVersion == 2)
    #expect(night.score() == 81)
  }

  @Test func defaultCacheVersion() {
    #expect(SleepScore.cacheVersion(for: .default) == "2-2cd7ee4b3152b44")
  }
}
