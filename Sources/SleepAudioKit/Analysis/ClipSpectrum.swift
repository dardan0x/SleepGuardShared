#if os(iOS)
import AVFoundation
public import Foundation
import SleepCore

/// A clip's spectrum, read from its file (SleepGuard's event detail): the
/// averages of SleepCore's `SpectralFeatures` over its buffers, and bars for
/// the spectrum view. Reads off the caller's actor.
public struct ClipSpectrum: Sendable, Equatable {
  /// Averages over the clip's buffers, Hz and 0...1; all 0 when unreadable.
  public let dominantFrequency: Double
  public let spectralCentroid: Double
  public let lowFreqRatio: Double

  public init(dominantFrequency: Double, spectralCentroid: Double, lowFreqRatio: Double) {
    self.dominantFrequency = dominantFrequency
    self.spectralCentroid = spectralCentroid
    self.lowFreqRatio = lowFreqRatio
  }

  public static let none = ClipSpectrum(dominantFrequency: 0, spectralCentroid: 0, lowFreqRatio: 0)

  /// The averages of the file at `url`.
  @concurrent
  public static func features(of url: URL) async -> ClipSpectrum {
    var dominant: [Double] = []
    var centroid: [Double] = []
    var lowRatio: [Double] = []
    readSpectra(of: url, fullBuffersOnly: false) { magnitudes, binWidth in
      let features = SpectralFeatures(magnitudes: magnitudes, binWidth: binWidth)
      dominant.append(Double(features.dominantFrequency))
      centroid.append(Double(features.spectralCentroid))
      lowRatio.append(Double(features.lowFreqRatio))
    }
    guard !dominant.isEmpty else { return .none }
    let count = Double(dominant.count)
    return ClipSpectrum(
      dominantFrequency: dominant.reduce(0, +) / count,
      spectralCentroid: centroid.reduce(0, +) / count,
      lowFreqRatio: lowRatio.reduce(0, +) / count)
  }

  /// `barCount` bars of the 0–1000 Hz spectrum averaged over the clip's full
  /// buffers, scaled so the highest is 1; all 0 when unreadable.
  @concurrent
  public static func bars(of url: URL, barCount: Int = 32) async -> [Float] {
    var sums = [Float](repeating: 0, count: barCount)
    var buffers = 0
    readSpectra(of: url, fullBuffersOnly: true) { magnitudes, binWidth in
      let bars = SpectralFeatures.spectrumBars(magnitudes: magnitudes, binWidth: binWidth, barCount: barCount)
      for index in 0..<barCount {
        sums[index] += bars[index]
      }
      buffers += 1
    }
    guard buffers > 0 else { return sums }
    let averages = sums.map { $0 / Float(buffers) }
    guard let highest = averages.max(), highest > 1e-10 else { return averages }
    return averages.map { $0 / highest }
  }

  /// Calls `body` with the magnitudes and bin width of each buffer of the file.
  private static func readSpectra(of url: URL, fullBuffersOnly: Bool, _ body: ([Float], Float) -> Void) {
    guard let file = try? AVAudioFile(forReading: url), let transform = Spectrum.makeTransform(),
          let buffer = AVAudioPCMBuffer(pcmFormat: file.processingFormat, frameCapacity: AVAudioFrameCount(Spectrum.size))
    else { return }
    let binWidth = Float(file.processingFormat.sampleRate) / Float(Spectrum.size)
    while file.framePosition < file.length, !Task.isCancelled {
      guard (try? file.read(into: buffer)) != nil, let channel = buffer.floatChannelData?[0] else { break }
      let frames = Int(buffer.frameLength)
      if fullBuffersOnly, frames < Spectrum.size { continue }
      guard let magnitudes = Spectrum.magnitudes(of: UnsafeBufferPointer(start: channel, count: frames), transform: transform)
      else { continue }
      body(magnitudes, binWidth)
    }
  }
}
#endif
