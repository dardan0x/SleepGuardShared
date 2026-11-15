import Foundation

/// A night's event clips played one after another as a single timeline: which
/// clip is current, where in it, seeking across or within clips, and what
/// happens when a clip ends. Pure: the audio engine reports and acts.
///
/// A clip's length is its event's duration (the snoring span, or the burst sum
/// for old events). The engine may hold a shorter file; it clamps to that.
public struct ClipPlaylist: Sendable, Equatable {
  public struct Clip: Sendable, Equatable, Identifiable {
    /// The event's id.
    public let id: UUID
    /// `nil` when the event has no clip.
    public let fileName: String?
    public let duration: TimeInterval

    public init(id: UUID, fileName: String?, duration: TimeInterval) {
      self.id = id
      self.fileName = fileName
      self.duration = duration
    }
  }

  public let clips: [Clip]
  /// The current clip.
  public private(set) var index = 0
  /// Seconds into the current clip.
  public var offset: TimeInterval = 0

  public init(clips: [Clip]) {
    self.clips = clips
  }

  /// One clip per event, in the order given.
  public init(events: [NightEvent]) {
    self.init(clips: events.map { Clip(id: $0.id, fileName: $0.clipFileName, duration: $0.duration) })
  }

  public var current: Clip? {
    clips.indices.contains(index) ? clips[index] : nil
  }

  public var totalDuration: TimeInterval {
    clips.map(\.duration).reduce(0, +)
  }

  /// Where the current clip starts on the joined timeline.
  public var currentClipStart: TimeInterval {
    clips.prefix(index).map(\.duration).reduce(0, +)
  }

  public var currentTime: TimeInterval {
    currentClipStart + offset
  }

  /// 0...1 across all clips; 0 when they have no length.
  public var progress: Double {
    totalDuration > 0 ? currentTime / totalDuration : 0
  }

  /// Makes `index` current, from its start. `false` (nothing changes) when
  /// there is no such clip: previous on the first, next on the last.
  @discardableResult
  public mutating func select(_ index: Int) -> Bool {
    guard clips.indices.contains(index) else { return false }
    self.index = index
    offset = 0
    return true
  }

  /// Moves to `progress` (0...1) of the joined timeline: the first clip that
  /// reaches that time, at the matching offset. Past the end: the end of the
  /// last clip. No clips or no length: nothing changes.
  public mutating func seek(toProgress progress: Double) {
    guard totalDuration > 0, !clips.isEmpty else { return }
    let target = progress * totalDuration
    var start: TimeInterval = 0
    for (index, clip) in clips.enumerated() {
      if start + clip.duration >= target {
        self.index = index
        offset = max(0, min(target - start, clip.duration))
        return
      }
      start += clip.duration
    }
    index = clips.count - 1
    offset = clips[index].duration
  }

  /// Moves to `progress` (0...1) of the current clip.
  public mutating func seek(inClip progress: Double) {
    guard let current else { return }
    offset = max(0, min(progress * current.duration, current.duration))
  }

  public enum AfterClip: Sendable, Equatable {
    /// The next clip is current; keep playing.
    case playNext
    /// That was the last clip: back to the first, stopped.
    case stopAtStart
  }

  /// The current clip played to its end.
  public mutating func clipFinished() -> AfterClip {
    offset = 0
    if index + 1 < clips.count {
      index += 1
      return .playNext
    }
    index = 0
    return .stopAtStart
  }
}
