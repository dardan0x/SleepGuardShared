import Foundation
import Testing
@testable import SleepCore

/// The detection rules, with SleepGuard's `SnoreDetectorTests` and
/// `DetectionSensitivityTests` cases and numbers. Medium: quiet −50, light −40,
/// loud −20, epic −10 dBFS; gates 0.35 / 0.55 / 0.45.
struct SnoreClassifierTests {
  private let medium = SnoreClassifier.preset(.medium)

  // MARK: - Routing

  @Test func noSignalClassifiesAsNone() {
    #expect(medium.classify(db: -5) == .none)
  }

  @Test func soundAnalysisWinsOverSpectral() {
    #expect(medium.classify(db: -5, spectralScore: 1, snoreConfidence: 0.2) == .none)
  }

  @Test func spectralIsUsedWithoutConfidence() {
    #expect(medium.classify(db: -5, spectralScore: 1) == .epic)
  }

  // MARK: - SoundAnalysis

  @Test(arguments: [
    (db: Float(-5), confidence: Float(0.34), expected: DetectionState.none),
    (-55, 0.35, .none),
    (-10, 0.55, .epic),
    (-10, 0.54, .loud),
    (-20, 0.35, .loud),
    (-40, 0.35, .light),
    (-50, 0.35, .quiet),
    (-60, 0.45, .quiet),
    (-60, 0.44, .none),
  ])
  func soundAnalysisTiers(db: Float, confidence: Float, expected: DetectionState) {
    #expect(medium.classifyWithSoundAnalysis(db: db, snoreConfidence: confidence) == expected)
  }

  // MARK: - Spectral

  @Test(arguments: [
    (db: Float(-5), score: Float(0.59), expected: DetectionState.none),
    (-56, 1.0, .none),
    (-10, 1.0, .epic),
    (-20, 1.0, .loud),
    (-40, 1.0, .light),
    (-50, 1.0, .quiet),
    (-51, 1.0, .none),
    (-9, 0.6, .loud),
    (-17.9, 0.6, .loud),
    (-18.1, 0.6, .light),
    (-45.9, 0.6, .quiet),
    (-46.1, 0.6, .none),
  ])
  func spectralTiers(db: Float, score: Float, expected: DetectionState) {
    #expect(medium.classifyWithSpectral(db: db, spectralScore: score) == expected)
  }

  // MARK: - Plain thresholds

  @Test(arguments: [
    (db: Float(-10), expected: DetectionState.epic),
    (-10.1, .loud),
    (-20, .loud),
    (-20.1, .light),
    (-40, .light),
    (-50, .quiet),
    (-50.1, .none),
  ])
  func thresholdBoundariesAreInclusive(db: Float, expected: DetectionState) {
    #expect(medium.classifyWithThresholds(db: db) == expected)
  }

  @Test func customThresholdsApplyToThatValueOnly() {
    var strict = medium
    strict.lightThreshold = -30
    strict.confidenceGate = 0.6
    #expect(strict.classifyWithSoundAnalysis(db: -35, snoreConfidence: 0.7) == .quiet)
    #expect(strict.classifyWithSoundAnalysis(db: -35, snoreConfidence: 0.5) == .none)
    #expect(medium.classifyWithSoundAnalysis(db: -35, snoreConfidence: 0.5) == .light)
  }

  // MARK: - Sensitivity presets

  private func values(_ c: SnoreClassifier) -> [Float] {
    [c.quietThreshold, c.lightThreshold, c.loudThreshold, c.epicThreshold,
     c.confidenceGate, c.highConfidenceGate, c.quietFallbackGate]
  }

  @Test(arguments: [
    (DetectionSensitivity.low, [Float(-45), -35, -15, -5, 0.45, 0.65, 0.55]),
    (.medium, [-50, -40, -20, -10, 0.35, 0.55, 0.45]),
    (.high, [-55, -45, -25, -15, 0.25, 0.45, 0.35]),
  ])
  func presetValues(sensitivity: DetectionSensitivity, expected: [Float]) {
    #expect(values(.preset(sensitivity)) == expected)
  }

  @Test func higherSensitivityLowersEveryThresholdAndGate() {
    let low = values(.preset(.low)), mid = values(.preset(.medium)), high = values(.preset(.high))
    for i in low.indices {
      #expect(low[i] > mid[i])
      #expect(mid[i] > high[i])
    }
  }

  @Test func sameSoundIsClassifiedPerSensitivity() {
    #expect(SnoreClassifier.preset(.low).classify(db: -42, snoreConfidence: 0.3) == .none)
    #expect(SnoreClassifier.preset(.medium).classify(db: -42, snoreConfidence: 0.3) == .none)
    #expect(SnoreClassifier.preset(.high).classify(db: -42, snoreConfidence: 0.3) == .light)
  }

  @Test func minimumEventDurationPerSensitivity() {
    #expect(DetectionSensitivity.allCases.map(\.minEventDuration) == [2, 1, 0.5])
  }

  // MARK: - Speech

  @Test(arguments: [
    (db: Float(-40), confidence: Float(0.5), expected: SpeechClassifier.Verdict.speech),
    (-55, 0.9, .speech),
    (-40, 0.49, .lowConfidence),
    (-55.1, 0.9, .tooQuiet),
  ])
  func speechVerdicts(db: Float, confidence: Float, expected: SpeechClassifier.Verdict) {
    #expect(SpeechClassifier().verdict(db: db, speechConfidence: confidence) == expected)
    #expect(SpeechClassifier().classify(db: db, speechConfidence: confidence) == (expected == .speech))
  }
}
