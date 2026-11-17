import Foundation

/// A night's gaps as the interrupter adds them: detection reports a gap with
/// a date, the night stores it as an offset from its start.
public extension [RecordingGap] {
  /// Adds the gap that starts at `start`. An empty gap, or one before the
  /// night started, is left out.
  func adding(start: Date, duration: TimeInterval, nightStart: Date, snoringResumed: Bool = false) -> [RecordingGap] {
    let offset = start.timeIntervalSince(nightStart)
    guard duration > 0, offset >= 0 else { return self }
    return self + [RecordingGap(startOffset: offset, duration: duration, snoringResumed: snoringResumed)]
  }

  /// Marks the latest gap as followed by snoring (it then counts as snoring).
  func markingLastSnoringResumed() -> [RecordingGap] {
    guard !isEmpty else { return self }
    var gaps = self
    gaps[gaps.count - 1].snoringResumed = true
    return gaps
  }
}
