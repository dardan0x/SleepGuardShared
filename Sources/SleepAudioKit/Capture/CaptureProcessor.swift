#if os(iOS)
import Accelerate
import AVFoundation
import os
import SleepCore
import SleepLogging
import SoundAnalysis

/// The audio-thread half of `CaptureEngine`.
///
/// AVAudioEngine calls the input tap on its own thread, for every buffer, and
/// that thread can't wait for an actor. So the tap closure is `@Sendable` and
/// everything it touches lives here, behind one lock.
///
/// The lock holds AVFoundation objects that aren't `Sendable` (the sound
/// analyzer, the clip file, the transform), so it uses
/// `OSAllocatedUnfairLock(uncheckedState:)`: the package's one concurrency
/// escape hatch (README). Nothing in the state leaves the lock.
final class CaptureProcessor: Sendable {
  /// Frames per transform: about 23 ms at 44.1 kHz.
  static let transformSize = Spectrum.size

  private struct State {
    var transform = Spectrum.makeTransform()
    var analyzer: SNAudioStreamAnalyzer?
    var framePosition: AVAudioFramePosition = 0
    var clip: AVAudioFile?
    /// The whole night, when the raw audio is kept.
    var raw: AVAudioFile?
    /// The FFT runs only when its score is logged (the raw recording is on):
    /// detection's verdict doesn't use it, and it is the costliest step.
    var computesSpectrum = false
  }

  private let state = OSAllocatedUnfairLock(uncheckedState: State())
  private let classifier = SoundClassifier()

  /// Starts a sound analyzer for buffers of `format` (called at every engine
  /// start, since a new route can bring a new format).
  func begin(format: AVAudioFormat, computesSpectrum: Bool) {
    let analyzer = classifier.makeAnalyzer(format: format)
    state.withLockUnchecked {
      $0.analyzer = analyzer
      $0.framePosition = 0
      $0.computesSpectrum = computesSpectrum
    }
  }

  /// Drops the analyzer and its last confidences.
  func end() {
    state.withLockUnchecked { $0.analyzer = nil }
    classifier.reset()
  }

  /// Buffers from now on are also written to `file`.
  func writeClip(to file: AVAudioFile) {
    state.withLockUnchecked { $0.clip = file }
  }

  /// Stops writing the clip. Releasing the file closes it.
  func closeClip() {
    state.withLockUnchecked { $0.clip = nil }
  }

  /// Every buffer from now on is also written to `file` (the raw recording).
  func writeRaw(to file: AVAudioFile) {
    state.withLockUnchecked { $0.raw = file }
  }

  func closeRaw() {
    state.withLockUnchecked { $0.raw = nil }
  }

  /// Runs on the tap's thread for every buffer.
  func process(_ buffer: AVAudioPCMBuffer, at time: Date) -> CaptureSample {
    let channel = buffer.floatChannelData.map {
      UnsafeBufferPointer(start: $0[0], count: Int(buffer.frameLength))
    } ?? UnsafeBufferPointer(start: nil, count: 0)
    let db = AudioLevels.rmsDB(channel)
    let peakDB = AudioLevels.peakDB(channel)
    let binWidth = Float(buffer.format.sampleRate) / Float(Self.transformSize)

    let spectralScore = state.withLockUnchecked { s in
      s.analyzer?.analyze(buffer, atAudioFramePosition: s.framePosition)
      s.framePosition += AVAudioFramePosition(buffer.frameLength)
      if let clip = s.clip {
        do {
          try clip.write(from: buffer)
        } catch {
          // A new route can bring a format the clip wasn't opened with: keep
          // what was written, stop writing.
          Log.audio.error("Clip write failed, closing the clip: \(error.localizedDescription, privacy: .public)")
          s.clip = nil
        }
      }
      if let raw = s.raw {
        do {
          try raw.write(from: buffer)
        } catch {
          Log.audio.error("Raw audio write failed, closing it: \(error.localizedDescription, privacy: .public)")
          s.raw = nil
        }
      }
      guard s.computesSpectrum, let magnitudes = Self.magnitudes(of: channel, transform: s.transform) else { return Float(0) }
      return SpectralFeatures(magnitudes: magnitudes, binWidth: binWidth).spectralScore
    }

    let confidences = classifier.confidences
    return CaptureSample(
      time: time, db: db, peakDB: peakDB, spectralScore: spectralScore,
      snoreConfidence: confidences.snore, speechConfidence: confidences.speech)
  }

  /// `Spectrum.magnitudes` when the transform could be made.
  private static func magnitudes(
    of channel: UnsafeBufferPointer<Float>,
    transform: vDSP.DiscreteFourierTransform<Float>?) -> [Float]?
  {
    guard let transform else { return nil }
    return Spectrum.magnitudes(of: channel, transform: transform)
  }
}
#endif
