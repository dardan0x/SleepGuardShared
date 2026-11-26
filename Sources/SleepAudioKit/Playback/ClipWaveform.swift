#if os(iOS)
import AVFoundation
public import Foundation
import SleepCore

/// A clip's waveform for the player: reads the file in 1024-frame buffers and
/// feeds SleepCore's `WaveformAccumulator`. Reads off the caller's actor.
public struct ClipWaveform: Sendable {
  public init() {}

  /// `pointCount` bars of the file at `url`, 0...1, over its first `duration`
  /// seconds (`nil`: all of it). Empty when the file can't be read.
  @concurrent
  public func waveform(of url: URL, duration: TimeInterval?, pointCount: Int = 300) async -> [Float] {
    guard let file = try? AVAudioFile(forReading: url) else { return [] }
    let format = file.processingFormat
    let frames = Int(file.length)
    let limit = duration.map { min(frames, Int($0 * format.sampleRate)) } ?? frames
    guard limit > 0, let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: 1024) else { return [] }

    var waveform = WaveformAccumulator(frames: limit, pointCount: pointCount)
    while file.framePosition < file.length, !waveform.isFull, !Task.isCancelled {
      guard (try? file.read(into: buffer)) != nil, let channel = buffer.floatChannelData?[0] else { break }
      waveform.add(UnsafeBufferPointer(start: channel, count: Int(buffer.frameLength)))
    }
    return waveform.waveform
  }
}
#endif
