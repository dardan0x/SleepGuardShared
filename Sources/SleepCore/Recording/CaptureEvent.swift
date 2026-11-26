public import Foundation

/// One analysed microphone buffer: the inputs the detection rules take
/// (`LiveSampleClassifier.Reading`). Produced by SleepAudioKit's `CaptureEngine`.
public struct CaptureSample: Sendable, Equatable {
  /// When the buffer was taken.
  public let time: Date
  /// RMS level of the buffer, dBFS (`AudioLevels`).
  public let db: Float
  /// Peak level of the buffer, dBFS: tracks impulsive snoring better than RMS.
  public let peakDB: Float
  /// The spectral snore score of the buffer, 0...1 (`SpectralFeatures`); 0
  /// unless the engine computes the spectrum.
  public let spectralScore: Float
  /// The sound classifier's latest snore and speech confidences, 0...1
  /// (`SoundClassLabels`). The classifier answers about twice a second, so
  /// consecutive samples repeat them.
  public let snoreConfidence: Float
  public let speechConfidence: Float

  public init(time: Date, db: Float, peakDB: Float, spectralScore: Float, snoreConfidence: Float, speechConfidence: Float) {
    self.time = time
    self.db = db
    self.peakDB = peakDB
    self.spectralScore = spectralScore
    self.snoreConfidence = snoreConfidence
    self.speechConfidence = speechConfidence
  }

  /// The detection rules' view of this sample.
  public var reading: LiveSampleClassifier.Reading {
    LiveSampleClassifier.Reading(
      db: db, peakDB: peakDB, spectralScore: spectralScore,
      snoreConfidence: snoreConfidence, speechConfidence: speechConfidence)
  }
}

/// What the capture stream carries: buffers, and the moments the system took
/// the microphone away (a call, another app's audio) and gave it back.
public enum CaptureEvent: Sendable, Equatable {
  /// One analysed buffer.
  case sample(CaptureSample)
  /// Listening stopped without being asked to (not `pause`).
  case interrupted(at: Date)
  /// Listening is back after `interrupted`.
  case resumed(at: Date)
}

public enum AudioCaptureError: Error, Equatable {
  /// The device has no microphone input right now.
  case noMicrophone
  /// The input reports no channels or no sample rate.
  case invalidFormat
  /// A clip was asked for while not listening.
  case notListening
}
