public import Foundation
public import SleepCore
public import SwiftData

/// A stored night: both apps' one SwiftData schema (`SleepStoreSchema`).
///
/// Schema rules: add properties with defaults, never rename or remove one.
/// Enums are stored as raw strings so a value written by a newer version can't
/// fail to decode in an older one; the typed properties read them safely.
@Model
public final class NightRecord {
  // Not `@Attribute(.unique)`: unique constraints rule out CloudKit sync.
  // Writers look a night up by id before inserting.
  public var id = UUID()
  public var start = Date.distantPast
  public var end = Date.distantPast
  /// dBFS, not calibrated dB-SPL.
  public var averageDB = 0.0
  public var peakDB = 0.0
  /// `Night.EndReason` raw value; read it through `endReason`.
  public var endReasonRawValue = Night.EndReason.stopped.rawValue
  public var recordingGaps: [RecordingGap] = []
  /// From Apple Health; empty when there are none.
  public var sleepStages: [SleepStageSegment] = []

  // The summary, stored so lists never read events (faulting them has
  // crashed). Written by `refreshSummary(using:)`.
  public var score = 0
  public var snoringDuration: TimeInterval = 0
  public var eventCount = 0
  /// `SnoreIntensity` raw value; `nil` for a night without events.
  public var loudestIntensityRawValue: String?
  /// `SleepScore.cacheVersion(for:)` of the formula and config that made the
  /// summary; "" (never summarized) reads as stale.
  public var scoreVersion = ""

  @Relationship(deleteRule: .cascade, inverse: \NightEventRecord.session)
  public var events: [NightEventRecord] = []

  /// A night that ends where it starts until it is finished.
  public init(id: UUID = UUID(), start: Date = .distantPast, end: Date? = nil) {
    self.id = id
    self.start = start
    self.end = end ?? start
  }

  public var endReason: Night.EndReason {
    get { Night.EndReason(rawValue: endReasonRawValue) ?? .stopped }
    set { endReasonRawValue = newValue.rawValue }
  }

  /// An intensity this version doesn't know reads as quiet, as events do.
  public var loudestIntensity: SnoreIntensity? {
    loudestIntensityRawValue.map { SnoreIntensity(rawValue: $0) ?? .quiet }
  }
}

/// One stored event of a night.
@Model
public final class NightEventRecord {
  public var id = UUID()
  public var start = Date.distantPast
  public var duration: TimeInterval = 0
  /// `SoundCategory` raw value; read it through `category`.
  public var categoryRawValue = SoundCategory.snoring.rawValue
  /// `SnoreIntensity` raw value; read it through `intensity`.
  public var intensityRawValue = SnoreIntensity.quiet.rawValue
  public var averageDB = 0.0
  public var peakDB = 0.0
  public var averageConfidence = 0.0
  public var averageSpectralScore = 0.0
  public var dominantFrequency = 0.0
  public var spectralCentroid = 0.0
  public var lowFreqRatio = 0.0
  public var bursts: [SnoreBurst] = []
  /// The clip, as a file name in the clips folder; `nil` when none was kept.
  public var clipFileName: String?
  public var session: NightRecord?

  public init(id: UUID = UUID()) {
    self.id = id
  }

  /// Unknown raw values (written by a newer version) read as the safest default.
  public var category: SoundCategory {
    get { SoundCategory(rawValue: categoryRawValue) ?? .other }
    set { categoryRawValue = newValue.rawValue }
  }

  public var intensity: SnoreIntensity {
    get { SnoreIntensity(rawValue: intensityRawValue) ?? .quiet }
    set { intensityRawValue = newValue.rawValue }
  }
}
