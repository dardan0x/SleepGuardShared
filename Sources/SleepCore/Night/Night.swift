import Foundation

/// A finished night: what was recorded between `start` and `end`.
///
/// A plain value, not a database record: each app maps its own storage to and
/// from it, and the rules in this folder (episodes, snoring duration, score
/// inputs) run on it, so every app computes the same numbers for a night.
public struct Night: Sendable, Equatable, Identifiable {
  public let id: UUID
  public var start: Date
  public var end: Date
  /// dBFS (relative to digital full scale), not calibrated dB-SPL.
  public var averageDB: Double
  public var peakDB: Double
  /// Every detected event, any category, in no particular order.
  public var events: [NightEvent]
  /// When the microphone was paused (Snore Interrupter playing).
  public var recordingGaps: [RecordingGap]
  /// From Apple Health, when available. Empty otherwise.
  public var sleepStages: [SleepStageSegment]
  public var endReason: EndReason

  public init(
    id: UUID = UUID(),
    start: Date,
    end: Date,
    averageDB: Double = 0,
    peakDB: Double = 0,
    events: [NightEvent] = [],
    recordingGaps: [RecordingGap] = [],
    sleepStages: [SleepStageSegment] = [],
    endReason: EndReason = .stopped)
  {
    precondition(end >= start, "A session can't end before it starts")
    self.id = id
    self.start = start
    self.end = end
    self.averageDB = averageDB
    self.peakDB = peakDB
    self.events = events
    self.recordingGaps = recordingGaps
    self.sleepStages = sleepStages
    self.endReason = endReason
  }

  /// End − start, recording gaps included.
  public var duration: TimeInterval {
    end.timeIntervalSince(start)
  }

  /// Why recording stopped.
  public enum EndReason: String, Sendable, Equatable, CaseIterable {
    /// The user stopped it.
    case stopped
    /// Saved automatically before the battery ran out.
    case lowBattery
  }
}
