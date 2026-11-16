import Foundation

/// How readily detection reports snoring. Low suits noisier rooms (stricter
/// filtering), Medium a typical quiet bedroom (the default), High very quiet
/// rooms.
public enum DetectionSensitivity: String, CaseIterable, Codable, Sendable {
  case low
  case medium
  case high

  /// The shortest snore event kept: isolated single snores (~1 s) survive on
  /// Medium and High; Low still filters transient sounds. Ground-truthed
  /// against bedroom recordings.
  public var minEventDuration: TimeInterval {
    switch self {
    case .low: 2.0
    case .medium: 1.0
    case .high: 0.5
    }
  }
}

/// Turns one sample (loudness, the sound classifier's snore confidence, the
/// FFT snore score) into a snoring state. Thresholds are dBFS (relative to
/// digital full scale, not calibrated dB-SPL).
public struct SnoreClassifier: Sendable, Equatable {
  public var quietThreshold: Float
  public var lightThreshold: Float
  public var loudThreshold: Float
  public var epicThreshold: Float
  /// Minimum classifier confidence to count as snoring at all.
  public var confidenceGate: Float
  /// Confidence needed for epic.
  public var highConfidenceGate: Float
  /// Counts as quiet even below every dB floor.
  public var quietFallbackGate: Float

  public init(
    quietThreshold: Float, lightThreshold: Float, loudThreshold: Float, epicThreshold: Float,
    confidenceGate: Float, highConfidenceGate: Float, quietFallbackGate: Float)
  {
    self.quietThreshold = quietThreshold
    self.lightThreshold = lightThreshold
    self.loudThreshold = loudThreshold
    self.epicThreshold = epicThreshold
    self.confidenceGate = confidenceGate
    self.highConfidenceGate = highConfidenceGate
    self.quietFallbackGate = quietFallbackGate
  }

  /// SleepGuard's calibrated presets. loud/epic were lowered 5 dB (2026-06-01)
  /// because RMS over 23 ms buffers under-reports impulsive snoring peaks; the
  /// gates were recalibrated from 0.5/0.7/0.6, which missed real bedroom snoring.
  public static func preset(_ sensitivity: DetectionSensitivity) -> SnoreClassifier {
    switch sensitivity {
    case .low:
      SnoreClassifier(
        quietThreshold: -45, lightThreshold: -35, loudThreshold: -15, epicThreshold: -5,
        confidenceGate: 0.45, highConfidenceGate: 0.65, quietFallbackGate: 0.55)
    case .medium:
      SnoreClassifier(
        quietThreshold: -50, lightThreshold: -40, loudThreshold: -20, epicThreshold: -10,
        confidenceGate: 0.35, highConfidenceGate: 0.55, quietFallbackGate: 0.45)
    case .high:
      SnoreClassifier(
        quietThreshold: -55, lightThreshold: -45, loudThreshold: -25, epicThreshold: -15,
        confidenceGate: 0.25, highConfidenceGate: 0.45, quietFallbackGate: 0.35)
    }
  }

  /// The sound classifier's confidence when there is one, else the FFT score.
  /// Never loudness alone: it can't tell snoring from breathing, bed creaks or
  /// traffic.
  public func classify(db: Float, spectralScore: Float = 0, snoreConfidence: Float = 0) -> DetectionState {
    if snoreConfidence > 0 {
      return classifyWithSoundAnalysis(db: db, snoreConfidence: snoreConfidence)
    }
    if spectralScore > 0 {
      return classifyWithSpectral(db: db, spectralScore: spectralScore)
    }
    return .none
  }

  /// Plain dB tiers, inclusive.
  public func classifyWithThresholds(db: Float) -> DetectionState {
    if db >= epicThreshold { return .epic }
    if db >= loudThreshold { return .loud }
    if db >= lightThreshold { return .light }
    if db >= quietThreshold { return .quiet }
    return .none
  }

  /// Gated by the classifier's confidence; loudness picks the tier, and epic
  /// needs `highConfidenceGate`.
  public func classifyWithSoundAnalysis(db: Float, snoreConfidence: Float) -> DetectionState {
    guard snoreConfidence >= confidenceGate else { return .none }
    if db >= epicThreshold, snoreConfidence >= highConfidenceGate { return .epic }
    if db >= loudThreshold { return .loud }
    if db >= lightThreshold { return .light }
    if db >= quietThreshold { return .quiet }
    return snoreConfidence >= quietFallbackGate ? .quiet : .none
  }

  /// FFT path: needs a snore-like spectrum (score ≥ 0.6; breathing reaches
  /// 0.4–0.7) and some loudness; a weaker score raises every threshold.
  public func classifyWithSpectral(db: Float, spectralScore: Float) -> DetectionState {
    guard spectralScore >= 0.6, db >= quietThreshold - 5 else { return .none }
    let slack = 1.0 - spectralScore
    if db >= epicThreshold + slack * 3 { return .epic }
    if db >= loudThreshold + slack * 5 { return .loud }
    if db >= lightThreshold + slack * 8 { return .light }
    if db >= quietThreshold + slack * 10 { return .quiet }
    return .none
  }
}

/// Whether one sample is sleep talking. Runs beside the snore classifier;
/// snoring wins when both fire (the detection state machine decides).
public struct SpeechClassifier: Sendable, Equatable {
  public var confidenceThreshold: Float
  public var dbFloor: Float

  public init(confidenceThreshold: Float = 0.5, dbFloor: Float = -55) {
    self.confidenceThreshold = confidenceThreshold
    self.dbFloor = dbFloor
  }

  public enum Verdict: Sendable, Equatable {
    case speech
    case lowConfidence
    case tooQuiet
  }

  public func verdict(db: Float, speechConfidence: Float) -> Verdict {
    guard speechConfidence >= confidenceThreshold else { return .lowConfidence }
    guard db >= dbFloor else { return .tooQuiet }
    return .speech
  }

  public func classify(db: Float, speechConfidence: Float) -> Bool {
    verdict(db: db, speechConfidence: speechConfidence) == .speech
  }
}
