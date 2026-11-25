import Foundation

/// Represents an interval during a sleep session when the microphone was paused:
/// Snore Interrupter playback took over the audio session (`.melody`), or the
/// system interrupted capture, e.g. a phone call (`.interruption`).
/// Tracking these gaps allows stats to be calculated over "monitored duration"
/// rather than total session duration, and lets the UI be transparent about
/// detection blind spots.
public struct RecordingGap: Codable, Sendable, Equatable, StoredValue {
  /// Why the microphone was paused. Stored as a raw string; an unknown or
  /// missing value decodes as `.melody` (every gap before 0.30.0 was one).
  public enum Kind: String, Codable, Sendable, StoredValue {
    /// The Snore Interrupter played. Snoring may have continued (`snoringResumed`).
    case melody
    /// Capture stopped (a call, another app). Nothing was measured, so the
    /// score leaves this time out of its percentages.
    case interruption
  }

  /// Seconds from the session start time when this gap begins.
  public let startOffset: TimeInterval
  /// Duration of the paused interval in seconds.
  public let duration: TimeInterval
  /// Whether snoring resumed after this gap within the breathing delay.
  /// Only gaps where snoring resumed count toward snoring duration.
  /// Defaults to `true` for legacy gaps created before this field existed.
  public var snoringResumed: Bool
  public let kind: Kind

  enum CodingKeys: String, CodingKey {
    case startOffset
    case duration
    case snoringResumed
    case kind
  }

  public init(startOffset: TimeInterval, duration: TimeInterval, snoringResumed: Bool = true, kind: Kind = .melody) {
    self.startOffset = startOffset
    self.duration = duration
    self.snoringResumed = snoringResumed
    self.kind = kind
  }

  public init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    startOffset = try container.decode(TimeInterval.self, forKey: .startOffset)
    duration = try container.decode(TimeInterval.self, forKey: .duration)
    snoringResumed = (try? container.decode(Bool.self, forKey: .snoringResumed)) ?? true
    kind = (try? container.decode(Kind.self, forKey: .kind)) ?? .melody
  }
}
