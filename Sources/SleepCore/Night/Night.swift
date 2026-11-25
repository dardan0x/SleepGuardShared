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

  /// The shortest night worth saving: 30 minutes, 2 in Debug builds so a
  /// night can be tried at a desk. Shorter ones are offered for discard.
  ///
  /// Deprecated in 0.30.0: it branched on how the *consumer* built this
  /// package. Pass `SaveRules` instead (`.standard`, or the app's own Debug
  /// value). Removed in 0.31.0.
  @available(*, deprecated, message: "Use SaveRules (SaveRules.standard, or the app's own Debug rules). Removed in 0.31.0.")
  public static var minimumSaveDuration: TimeInterval {
    #if DEBUG
    return 120
    #else
    return 1800
    #endif
  }

  /// Why recording stopped.
  public enum EndReason: String, Sendable, Equatable, CaseIterable {
    /// The user stopped it.
    case stopped
    /// Saved automatically before the battery ran out.
    case lowBattery
  }
}
