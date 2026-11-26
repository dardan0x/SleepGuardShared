#if os(iOS)
import AVFoundation
import Foundation
import SleepCore
import Testing
@testable import SleepAudioKit

/// SleepGuard's clip extras: the spectrum of a clip, and the event's part of
/// the raw night.
struct ClipAnalysisTests {
  private static let rate = 44100.0

  /// A mono tone at `hz`, `seconds` long, as a CAF file.
  private func tone(hz: Float, seconds: Double) throws -> URL {
    let url = FileManager.default.temporaryDirectory.appendingPathComponent("\(UUID().uuidString).caf")
    let format = try #require(AVAudioFormat(standardFormatWithSampleRate: Self.rate, channels: 1))
    let frames = AVAudioFrameCount(seconds * Self.rate)
    let buffer = try #require(AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frames))
    buffer.frameLength = frames
    let samples = try #require(buffer.floatChannelData?[0])
    for index in 0..<Int(frames) {
      samples[index] = 0.5 * sin(2 * .pi * hz * Float(index) / Float(Self.rate))
    }
    try AVAudioFile(forWriting: url, settings: format.settings).write(from: buffer)
    return url
  }

  @Test func aLowToneIsLowAndDominatesItsSpectrum() async throws {
    let url = try tone(hz: 200, seconds: 0.5)
    defer { try? FileManager.default.removeItem(at: url) }
    let spectrum = await ClipSpectrum.features(of: url)
    #expect(abs(spectrum.dominantFrequency - 200) < 50)
    #expect(spectrum.lowFreqRatio > 0.8)
    let bars = await ClipSpectrum.bars(of: url)
    #expect(bars.count == 32)
    #expect(bars.max() == 1)
    #expect(bars.firstIndex(of: 1) ?? 32 < 16) // in the lower half of 0–1000 Hz
  }

  @Test func anUnreadableClipHasNoSpectrum() async {
    let url = URL(fileURLWithPath: "/nope.caf")
    #expect(await ClipSpectrum.features(of: url) == .none)
    #expect(await ClipSpectrum.bars(of: url) == [Float](repeating: 0, count: 32))
  }

  private let night = Date(timeIntervalSince1970: 1_000)

  @Test func withBurstsTheClipSpansFirstToLastBurst() throws {
    let event = ClipExtractor.Source(
      id: UUID(), start: night.addingTimeInterval(10), snoreDuration: 2,
      bursts: [SnoreBurst(startOffset: 1, endOffset: 2), SnoreBurst(startOffset: 5, endOffset: 6)])
    #expect(ClipExtractor.range(of: event, nightStart: night, totalDuration: 100) == 11...16)
    #expect(ClipExtractor.range(of: event, nightStart: night, totalDuration: 100, padding: 1) == 10...17)
  }

  @Test func withoutBurstsTheClipIsTheSnoringAndStaysInTheRecording() {
    let event = ClipExtractor.Source(id: UUID(), start: night.addingTimeInterval(8), snoreDuration: 4, bursts: nil)
    #expect(ClipExtractor.range(of: event, nightStart: night, totalDuration: 10, padding: 1) == 7...10)
    let late = ClipExtractor.Source(id: UUID(), start: night.addingTimeInterval(20), snoreDuration: 4, bursts: nil)
    #expect(ClipExtractor.range(of: late, nightStart: night, totalDuration: 10) == nil)
  }

  @Test func anEventIsCutFromTheRawNight() async throws {
    let raw = try tone(hz: 200, seconds: 3)
    let clip = FileManager.default.temporaryDirectory.appendingPathComponent("\(UUID().uuidString).m4a")
    defer {
      try? FileManager.default.removeItem(at: raw)
      try? FileManager.default.removeItem(at: clip)
    }
    let event = ClipExtractor.Source(id: UUID(), start: night.addingTimeInterval(1), snoreDuration: 1, bursts: nil)
    #expect(await ClipExtractor.extract(event, from: raw, nightStart: night, to: clip))
    let duration = try await AVURLAsset(url: clip).load(.duration).seconds
    #expect(abs(duration - 1) < 0.1)
  }
}
#endif
