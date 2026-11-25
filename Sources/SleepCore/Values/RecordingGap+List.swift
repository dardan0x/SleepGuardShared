import Foundation

/// A night's gaps as the interrupter adds them: detection reports a gap with
/// a date, the night stores it as an offset from its start.
public extension [RecordingGap] {
  /// Adds the gap that starts at `start`. An empty gap, or one before the
  /// night started, is left out.
  func adding(
    start: Date,
    duration: TimeInterval,
    nightStart: Date,
    snoringResumed: Bool = false,
    kind: RecordingGap.Kind = .melody) -> [RecordingGap]
  {
    let offset = start.timeIntervalSince(nightStart)
    guard duration > 0, offset >= 0 else { return self }
    return self + [RecordingGap(startOffset: offset, duration: duration, snoringResumed: snoringResumed, kind: kind)]
  }

  /// Marks the latest melody gap as followed by snoring (it then counts as
  /// snoring). An interruption since then doesn't take the mark.
  func markingLastSnoringResumed() -> [RecordingGap] {
    guard let index = lastIndex(where: { $0.kind == .melody }) else { return self }
    var gaps = self
    gaps[index].snoringResumed = true
    return gaps
  }
}
