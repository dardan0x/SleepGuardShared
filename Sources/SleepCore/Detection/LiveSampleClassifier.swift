import Foundation

/// One live sample's reading, classified into what the detection engine
/// takes: the snore verdict (the sensitivity's `SnoreClassifier` preset, on
/// the buffer's peak level: snoring is impulsive and RMS under-reports it)
/// and the speech verdict (`SpeechClassifier`, on the RMS level). The same in
/// every app, so the same reading gives the same input everywhere.
///
/// The spectral score stays out of the snore verdict (live detection has only
/// been validated on the sound classifier); it is passed through for the
/// event's averages.
public struct LiveSampleClassifier: Sendable, Equatable {
  /// One analysed reading, as capture produces it.
  public struct Reading: Sendable, Equatable {
    public var db: Float
    /// `nil` when the capture doesn't measure it; `db` is used instead.
    public var peakDB: Float?
    public var spectralScore: Float
    public var snoreConfidence: Float
    public var speechConfidence: Float

    public init(db: Float, peakDB: Float?, spectralScore: Float, snoreConfidence: Float, speechConfidence: Float) {
      self.db = db
      self.peakDB = peakDB
      self.spectralScore = spectralScore
      self.snoreConfidence = snoreConfidence
      self.speechConfidence = speechConfidence
    }
  }

  public private(set) var snore: SnoreClassifier
  public private(set) var speech: SpeechClassifier

  public init(sensitivity: DetectionSensitivity, speech: SpeechClassifier = SpeechClassifier()) {
    snore = .preset(sensitivity)
    self.speech = speech
  }

  /// Takes a new sensitivity from the next reading on (a setting changed
  /// mid-night).
  public mutating func update(sensitivity: DetectionSensitivity) {
    snore = .preset(sensitivity)
  }

  /// The engine's input for `reading`.
  public func input(for reading: Reading, isMelodyPlaying: Bool) -> DetectionInput {
    let state = snore.classify(db: reading.peakDB ?? reading.db, spectralScore: 0, snoreConfidence: reading.snoreConfidence)
    return DetectionInput(
      db: reading.db, spectralScore: reading.spectralScore, snoreConfidence: reading.snoreConfidence,
      snoreState: state, isSpeech: speech.classify(db: reading.db, speechConfidence: reading.speechConfidence),
      isMelodyPlaying: isMelodyPlaying)
  }
}
