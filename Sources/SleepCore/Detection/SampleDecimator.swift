import Foundation

/// Turns audio readings that arrive at whatever rate the tap delivers (about
/// 43–47 Hz for 1024-frame buffers) into the fixed 20 Hz samples detection
/// runs on, so every app feeds the same samples for the same sound.
///
/// Latest-value semantics, the rule SleepGuard's 50 ms sampler has always
/// used: each window's sample is the most recent reading at its end. Windows
/// are anchored to the first reading's time, so they don't drift the way a
/// sleep-based loop does (50 ms plus the work in between).
///
/// A pause in readings (capture interrupted) doesn't replay stale values:
/// after `maxCatchUpWindows` missed windows the decimator re-anchors on the
/// next reading instead of emitting a burst of old samples.
public struct SampleDecimator<Reading: Sendable>: Sendable {
  /// One emitted sample: the reading in effect at the end of its window.
  public struct Sample: Sendable {
    public let reading: Reading
    public let time: Date
  }

  /// 20 Hz, as detection's thresholds and replay fixtures assume.
  public static var interval: TimeInterval { 0.05 }
  /// Up to half a second of late buffers is filled in; longer is a pause.
  public static var maxCatchUpWindows: Int { 10 }

  private var nextWindowEnd: Date?
  private var latest: Reading?

  public init() {}

  /// Adds a reading taken at `time` and returns the samples for every window
  /// that ended at or before it, oldest first (usually zero or one).
  public mutating func add(_ reading: Reading, at time: Date) -> [Sample] {
    defer { latest = reading }
    guard var windowEnd = nextWindowEnd else {
      nextWindowEnd = time.addingTimeInterval(Self.interval)
      return []
    }
    guard let previous = latest else { return [] }
    let missed = Int(time.timeIntervalSince(windowEnd) / Self.interval)
    if missed > Self.maxCatchUpWindows {
      // A pause, not jitter: start fresh from this reading.
      nextWindowEnd = time.addingTimeInterval(Self.interval)
      return []
    }
    var samples: [Sample] = []
    while windowEnd <= time {
      // The window ended before this reading arrived, so the previous one was
      // the most recent at its end. A reading exactly at the end counts.
      samples.append(Sample(reading: windowEnd == time ? reading : previous, time: windowEnd))
      windowEnd = windowEnd.addingTimeInterval(Self.interval)
    }
    nextWindowEnd = windowEnd
    return samples
  }

  /// Forgets the window (a new session, or capture resumed after a pause).
  public mutating func reset() {
    nextWindowEnd = nil
    latest = nil
  }
}
