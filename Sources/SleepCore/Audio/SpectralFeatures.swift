import Foundation

/// How snore-like a buffer's spectrum is, from its magnitude spectrum (the
/// first half of a real FFT, bin 0 = 0 Hz). The app does the transform; the
/// rules live here.
public struct SpectralFeatures: Sendable, Equatable {
  /// Share of energy in 100–500 Hz, where snoring lives.
  public let lowFreqRatio: Float
  /// Energy-weighted average frequency (Hz).
  public let spectralCentroid: Float
  /// The loudest bin's frequency (Hz).
  public let dominantFrequency: Float
  /// 0...1: 0.7 × low-band ratio score + 0.3 × centroid score. An ideal snore
  /// has ratio > 0.6 and centroid < 400 Hz.
  public let spectralScore: Float

  public init(lowFreqRatio: Float, spectralCentroid: Float, dominantFrequency: Float, spectralScore: Float) {
    self.lowFreqRatio = lowFreqRatio
    self.spectralCentroid = spectralCentroid
    self.dominantFrequency = dominantFrequency
    self.spectralScore = spectralScore
  }

  /// No spectrum (no samples, or the transform couldn't run).
  public static let none = SpectralFeatures(lowFreqRatio: 0, spectralCentroid: 0, dominantFrequency: 0, spectralScore: 0)

  /// `binWidth`: Hz per bin (sample rate / transform length).
  public init(magnitudes: [Float], binWidth: Float) {
    let count = magnitudes.count
    guard count > 1, binWidth > 0 else {
      self = .none
      return
    }
    let lowBin = max(1, Int(100.0 / Double(binWidth)))
    let highBin = min(count, Int(500.0 / Double(binWidth)))

    var lowEnergy: Float = 0
    if lowBin < highBin {
      for i in lowBin..<highBin {
        lowEnergy += magnitudes[i] * magnitudes[i]
      }
    }
    var totalEnergy: Float = 0
    var weightedSum: Float = 0
    var loudest: Float = 0
    var loudestIndex = 0
    for i in 1..<count {
      let energy = magnitudes[i] * magnitudes[i]
      totalEnergy += energy
      weightedSum += Float(i) * binWidth * energy
      if magnitudes[i] > loudest {
        loudest = magnitudes[i]
        loudestIndex = i
      }
    }
    let ratio = totalEnergy > 1e-10 ? lowEnergy / totalEnergy : 0
    let centroid = totalEnergy > 1e-10 ? weightedSum / totalEnergy : 0
    let ratioScore = min(1, max(0, (ratio - 0.3) / 0.4))
    let centroidScore = min(1, max(0, (800 - centroid) / 600))
    self.init(
      lowFreqRatio: ratio, spectralCentroid: centroid, dominantFrequency: Float(loudestIndex) * binWidth,
      spectralScore: ratioScore * 0.7 + centroidScore * 0.3)
  }

  /// The 0–1000 Hz part of the spectrum averaged into `barCount` bars,
  /// normalised so the highest is 1 (all 0 for silence). With fewer bins than
  /// bars, neighbouring bars share a bin.
  public static func spectrumBars(magnitudes: [Float], binWidth: Float, barCount: Int = 32) -> [Float] {
    guard magnitudes.count > 1, binWidth > 0, barCount > 0 else { return [Float](repeating: 0, count: max(0, barCount)) }
    let maxBin = max(2, min(magnitudes.count, Int(1000 / binWidth)))
    let usable = maxBin - 1
    var bars = (0..<barCount).map { bar -> Float in
      let start = 1 + bar * usable / barCount
      let end = max(start + 1, 1 + (bar + 1) * usable / barCount)
      return magnitudes[start..<end].reduce(0, +) / Float(max(1, end - start))
    }
    if let highest = bars.max(), highest > 1e-10 {
      bars = bars.map { $0 / highest }
    }
    return bars
  }
}
