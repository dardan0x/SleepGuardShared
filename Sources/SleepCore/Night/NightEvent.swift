import Foundation

/// One detected sound event in a night: snoring, sleep talking, or other noise.
public struct NightEvent: Sendable, Equatable, Identifiable {
  public let id: UUID
  public var start: Date
  /// From the first to the last detected sample, natural breathing pauses
  /// included (the usual definition of a snoring epoch).
  public var duration: TimeInterval
  public var category: SoundCategory
  public var intensity: SnoreIntensity
  /// dBFS, not calibrated dB-SPL.
  public var averageDB: Double
  public var peakDB: Double
  /// Mean classifier confidence, 0…1.
  public var averageConfidence: Double
  /// Continuous stretches of sound inside the event, offsets from `start`.
  /// Empty when none closed (very short events, sleep talking).
  public var bursts: [SnoreBurst]
  /// The event's audio clip, as a file name the session file store resolves.
  /// `nil` when no clip was kept.
  public var clipFileName: String?
  /// Mean spectral snore score during the event, 0…1 (0 unless the
  /// spectrum was computed, a debug raw recording).
  public var averageSpectralScore: Double
  /// The clip's spectrum (Hz, Hz, 0…1), averaged over its buffers; 0 when
  /// not measured.
  public var dominantFrequency: Double
  public var spectralCentroid: Double
  public var lowFreqRatio: Double

  public init(
    id: UUID = UUID(),
    start: Date,
    duration: TimeInterval,
    category: SoundCategory = .snoring,
    intensity: SnoreIntensity,
    averageDB: Double = 0,
    peakDB: Double = 0,
    averageConfidence: Double = 0,
    bursts: [SnoreBurst] = [],
    clipFileName: String? = nil,
    averageSpectralScore: Double = 0,
    dominantFrequency: Double = 0,
    spectralCentroid: Double = 0,
    lowFreqRatio: Double = 0)
  {
    precondition(duration >= 0, "An event can't have a negative duration")
    self.id = id
    self.start = start
    self.duration = duration
    self.category = category
    self.intensity = intensity
    self.averageDB = averageDB
    self.peakDB = peakDB
    self.averageConfidence = averageConfidence
    self.bursts = bursts
    self.clipFileName = clipFileName
    self.averageSpectralScore = averageSpectralScore
    self.dominantFrequency = dominantFrequency
    self.spectralCentroid = spectralCentroid
    self.lowFreqRatio = lowFreqRatio
  }

  public var end: Date {
    start.addingTimeInterval(duration)
  }

  /// Sound actually measured: the sum of bursts. Smaller than `duration` when
  /// the event spans pauses or a melody gap. Falls back to `duration` when the
  /// event has no bursts.
  public var measuredDuration: TimeInterval {
    bursts.isEmpty ? duration : bursts.reduce(0) { $0 + $1.duration }
  }
}
