import Foundation
import Testing
@testable import SleepCore

/// The clip waveform rule (SleepGuard's `WaveformGenerator`).
struct WaveformAccumulatorTests {
  @Test func averagesEachBarAndScalesTheLoudestToOne() {
    var waveform = WaveformAccumulator(frames: 8, pointCount: 4)
    waveform.add([0.1, -0.1, 0.2, -0.2, 0.4, -0.4, 0.2, 0.2])
    #expect(waveform.waveform.map { ($0 * 100).rounded() / 100 } == [0.25, 0.5, 1, 0.5])
  }

  @Test func samplesCanArriveInPieces() {
    var whole = WaveformAccumulator(frames: 6, pointCount: 3)
    whole.add([0.1, 0.3, 0.5, 0.5, 0.9, 0.1])
    var pieces = WaveformAccumulator(frames: 6, pointCount: 3)
    pieces.add([0.1, 0.3, 0.5])
    pieces.add([0.5, 0.9])
    pieces.add([0.1])
    #expect(whole.waveform == pieces.waveform)
  }

  /// Frames past the event's length (trailing silence in the file) are ignored.
  @Test func framesPastTheLimitAreIgnored() {
    var waveform = WaveformAccumulator(frames: 4, pointCount: 2)
    waveform.add([0.5, 0.5, 0.25, 0.25, 1, 1, 1, 1])
    #expect(waveform.isFull)
    #expect(waveform.waveform == [1, 0.5])
  }

  @Test func silenceAndNoFramesAreFlat() {
    var silent = WaveformAccumulator(frames: 4, pointCount: 2)
    silent.add([0, 0, 0, 0])
    #expect(silent.waveform == [0, 0])
    #expect(WaveformAccumulator(frames: 0, pointCount: 3).waveform == [0, 0, 0])
  }
}
