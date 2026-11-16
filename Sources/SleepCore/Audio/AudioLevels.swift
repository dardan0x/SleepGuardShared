import Foundation

/// Loudness of one buffer of samples, in dBFS (0 = digital full scale). The
/// detection thresholds are calibrated against exactly these numbers.
public enum AudioLevels {
  /// What an empty or silent buffer reads as.
  public static let floorDB: Float = -160

  /// Root-mean-square level: average energy.
  public static func rmsDB(_ samples: some Collection<Float>) -> Float {
    guard !samples.isEmpty else { return floorDB }
    let sum = samples.reduce(Float(0)) { $0 + $1 * $1 }
    return decibels(sqrt(sum / Float(samples.count)))
  }

  /// Peak level: the loudest sample. Better than RMS for impulsive sounds like
  /// snoring, whose loudness is carried by sharp peaks.
  public static func peakDB(_ samples: some Collection<Float>) -> Float {
    guard !samples.isEmpty else { return floorDB }
    return decibels(samples.reduce(Float(0)) { max($0, abs($1)) })
  }

  private static func decibels(_ amplitude: Float) -> Float {
    20 * log10(max(amplitude, 1e-10))
  }
}
