import Foundation

/// The optional "enhanced audio" treatment of a clip at playback: a band-pass
/// that keeps snoring and drops rumble and hiss, and a boost that brings the
/// clip's loudest sample to −3 dBFS. The saved files are never changed.
public enum PlaybackEnhancement {
  /// Removes HVAC rumble and 50/60 Hz mains hum.
  public static let highPassHz: Float = 80
  /// Removes broadband microphone hiss. Snoring lives at 100 Hz–1 kHz.
  public static let lowPassHz: Float = 1500
}

public enum PlaybackGain {
  /// −3 dBFS.
  public static let targetPeak: Float = 0.708
  /// The EQ's headroom.
  public static let maxBoostDB: Float = 24

  /// The boost, in dB, that brings a clip whose loudest sample is `peak`
  /// (0...1) to `targetPeak`: never negative (never quieter), at most
  /// `maxBoostDB`, 0 for a silent clip.
  public static func boostDB(peak: Float) -> Float {
    guard peak > 0 else { return 0 }
    return min(max(20 * log10(targetPeak / peak), 0), maxBoostDB)
  }
}
