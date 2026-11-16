import Foundation
import Testing
@testable import SleepCore

/// Levels, spectral features and sound-class mapping. The spectral cases are
/// SleepGuard's `FFTAnalyzerTests` (44.1 kHz, 1024-point FFT → 43 Hz bins);
/// magnitudes come from a plain DFT of the same generated signals.
struct CaptureRulesTests {
  private static let rate: Double = 44100

  private func sine(hz: Double, frames: Int = 1024, rate: Double = rate) -> [Float] {
    (0..<frames).map { Float(0.5 * sin(2 * .pi * hz * Double($0) / rate)) }
  }

  private func noise(frames: Int = 1024) -> [Float] {
    var state: UInt32 = 0x5EED
    return (0..<frames).map { _ in
      state = state &* 1_664_525 &+ 1_013_904_223
      return Float(state >> 8) / Float(1 << 24) - 0.5
    }
  }

  /// First-half magnitudes of a `size`-point DFT (zero-padded), and Hz per bin.
  private func spectrum(_ samples: [Float], size: Int = 1024, rate: Double = rate) -> ([Float], Float) {
    let padded = (samples + [Float](repeating: 0, count: max(0, size - samples.count))).prefix(size).map(Double.init)
    let magnitudes = (0..<(size / 2)).map { k -> Float in
      var re = 0.0, im = 0.0
      for (n, x) in padded.enumerated() {
        let angle = -2 * .pi * Double(k) * Double(n) / Double(size)
        re += x * cos(angle)
        im += x * sin(angle)
      }
      return Float(hypot(re, im))
    }
    return (magnitudes, Float(rate / Double(size)))
  }

  private func features(_ samples: [Float], rate: Double = rate) -> SpectralFeatures {
    let (magnitudes, width) = spectrum(samples, rate: rate)
    return SpectralFeatures(magnitudes: magnitudes, binWidth: width)
  }

  // MARK: - Levels

  @Test func levelsOfAKnownSignal() {
    let half = [Float](repeating: 0.5, count: 100)
    #expect(abs(AudioLevels.rmsDB(half) - -6.0206) < 0.001)
    #expect(abs(AudioLevels.peakDB([0.1, -0.5, 0.25]) - -6.0206) < 0.001)
    #expect(AudioLevels.rmsDB([Float]()) == AudioLevels.floorDB)
    #expect(AudioLevels.peakDB([Float](repeating: 0, count: 8)) == -200) // 20·log10(1e-10)
  }

  // MARK: - Spectral features (SleepGuard's FFTAnalyzerTests)

  @Test func lowToneHasSnoreLikeFeatures() {
    let result = features(sine(hz: 215))
    #expect(abs(result.dominantFrequency - 215) < 43)
    #expect(result.lowFreqRatio > 0.8)
    #expect(result.spectralCentroid < 400)
    #expect(result.spectralScore > 0.9)
  }

  @Test func highToneIsNotSnoreLike() {
    let result = features(sine(hz: 2000))
    #expect(abs(result.dominantFrequency - 2000) < 43)
    #expect(result.lowFreqRatio < 0.1)
    #expect(result.spectralCentroid > 1500)
    #expect(result.spectralScore < 0.1)
  }

  @Test func whiteNoiseIsBelowTheSpectralGate() {
    let result = features(noise())
    #expect(result.lowFreqRatio < 0.1)
    #expect(result.spectralScore < 0.6)
  }

  @Test func silenceHasNoFrequencyContent() {
    let result = features([Float](repeating: 0, count: 1024))
    #expect(result.lowFreqRatio == 0 && result.dominantFrequency == 0 && result.spectralCentroid == 0)
    #expect(result.spectralScore < 0.6)
  }

  @Test func shortBufferIsZeroPadded() {
    let result = features(sine(hz: 215, frames: 512))
    #expect(abs(result.dominantFrequency - 215) < 43)
    #expect(result.spectralScore > 0.9)
  }

  @Test func dominantFrequencyTracksTheSampleRate() {
    #expect(abs(features(sine(hz: 300, rate: 48000), rate: 48000).dominantFrequency - 300) < 47)
  }

  @Test func noSpectrumIsNone() {
    #expect(SpectralFeatures(magnitudes: [], binWidth: 43) == .none)
  }

  // MARK: - Spectrum bars

  @Test func spectrumBarsCoverAllBars() {
    let (magnitudes, width) = spectrum(sine(hz: 215))
    let bars = SpectralFeatures.spectrumBars(magnitudes: magnitudes, binWidth: width)
    #expect(bars.count == 32)
    #expect(bars.max() == 1)
    #expect(bars.allSatisfy { (0...1).contains($0) })
  }

  @Test func spectrumBarsPeakAtTheTone() throws {
    let (magnitudes, width) = spectrum(sine(hz: 500))
    let bars = SpectralFeatures.spectrumBars(magnitudes: magnitudes, binWidth: width)
    let peak = try #require(bars.firstIndex(of: 1))
    #expect((11...21).contains(peak))
  }

  @Test func silenceGivesFlatZeroBars() {
    let (magnitudes, width) = spectrum([Float](repeating: 0, count: 1024))
    #expect(SpectralFeatures.spectrumBars(magnitudes: magnitudes, binWidth: width, barCount: 16) == [Float](repeating: 0, count: 16))
  }

  // MARK: - Sound classes

  @Test func confidencesTakeTheHighestMatchingClass() {
    let result = SoundClassLabels.confidences([
      ("snoring", 0.62), ("Speech", 0.3), ("whispering", 0.41), ("baby_crying", 0.2), ("dog_bark", 0.9),
    ])
    #expect(result == SoundClassLabels.Confidences(snore: 0.62, speech: 0.41))
    #expect(SoundClassLabels.confidences([("music", 0.8)]) == SoundClassLabels.Confidences(snore: 0, speech: 0))
  }
}
