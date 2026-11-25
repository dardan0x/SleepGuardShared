import Foundation
import Testing
@testable import SleepCore

/// Per-buffer readings become 20 Hz samples with the latest-value rule
/// SleepGuard's sampler used, whatever rate the tap delivers.
struct SampleDecimatorTests {
  private let t0 = Date(timeIntervalSinceReferenceDate: 0)

  /// A level that steps every 0.5 s, read at `hz`, decimated.
  private func samples(hz: Double, seconds: Double) -> [(value: Int, time: TimeInterval)] {
    var decimator = SampleDecimator<Int>()
    var out: [(Int, TimeInterval)] = []
    var elapsed = 0.0
    while elapsed <= seconds {
      let level = Int(elapsed / 0.5)
      for sample in decimator.add(level, at: t0.addingTimeInterval(elapsed)) {
        out.append((sample.reading, sample.time.timeIntervalSince(t0)))
      }
      elapsed += 1 / hz
    }
    return out
  }

  @Test func emitsTwentySamplesASecondOnAFixedGrid() {
    let out = samples(hz: 47, seconds: 2)
    #expect(out.count == 39 || out.count == 40)
    for (index, sample) in out.enumerated() {
      #expect(abs(sample.time - Double(index + 1) * 0.05) < 1e-9)
    }
  }

  @Test func fortyThreeAndFortySevenHertzGiveTheSameSamples() {
    let slow = samples(hz: 43, seconds: 3)
    let fast = samples(hz: 47, seconds: 3)
    let count = min(slow.count, fast.count)
    #expect(count >= 58)
    // Away from the steps, the latest reading at a window's end is the same level.
    for index in 0..<count where (fast[index].time.truncatingRemainder(dividingBy: 0.5)) > 0.06 {
      #expect(slow[index].value == fast[index].value)
      #expect(abs(slow[index].time - fast[index].time) < 1e-9)
    }
  }

  @Test func aLateBufferFillsTheWindowsItMissedWithThePreviousReading() {
    var decimator = SampleDecimator<Int>()
    _ = decimator.add(1, at: t0)
    let out = decimator.add(2, at: t0.addingTimeInterval(0.16))
    #expect(out.map(\.reading) == [1, 1, 1])
    #expect(out.map { $0.time.timeIntervalSince(t0) } == [0.05, 0.1, 0.15000000000000002])
  }

  @Test func aPauseDoesNotReplayStaleReadings() {
    var decimator = SampleDecimator<Int>()
    _ = decimator.add(1, at: t0)
    #expect(decimator.add(2, at: t0.addingTimeInterval(30)).isEmpty)
    let after = decimator.add(3, at: t0.addingTimeInterval(30.06))
    #expect(after.map(\.reading) == [2])
  }
}
