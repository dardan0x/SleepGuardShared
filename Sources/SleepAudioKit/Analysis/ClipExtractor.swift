#if os(iOS)
import AVFoundation
public import Foundation
public import SleepCore

/// Cuts an event's clip out of the night's raw recording (`RawRecording`),
/// for a night whose event clips weren't kept. With bursts, the clip spans
/// the first burst's start to the last one's end, so the breathing gaps stay
/// in it; without, the event's measured snoring.
public enum ClipExtractor {
  /// What extraction needs from an event.
  public struct Source: Sendable, Equatable {
    public let id: UUID
    public let start: Date
    /// Measured snoring length (the event span, or the bursts' sum without one).
    public let snoreDuration: TimeInterval
    public let bursts: [SnoreBurst]?

    public init(id: UUID, start: Date, snoreDuration: TimeInterval, bursts: [SnoreBurst]?) {
      self.id = id
      self.start = start
      self.snoreDuration = snoreDuration
      self.bursts = bursts
    }
  }

  /// The event's part of the night, in seconds from the recording's start,
  /// widened by `padding` and kept inside `0...totalDuration`; `nil` when
  /// nothing of it is in the recording.
  public static func range(
    of event: Source, nightStart: Date, totalDuration: TimeInterval, padding: TimeInterval = 0) -> ClosedRange<TimeInterval>?
  {
    let offset = event.start.timeIntervalSince(nightStart)
    let span: (start: TimeInterval, end: TimeInterval) = if let bursts = event.bursts, let first = bursts.first, let last = bursts.last {
      (offset + first.startOffset, offset + last.endOffset)
    } else {
      (offset, offset + event.snoreDuration)
    }
    let start = max(0, span.start - padding)
    let end = min(totalDuration, span.end + padding)
    return end > start ? start...end : nil
  }

  /// Writes `event`'s clip (AAC, .m4a) from the raw recording at `rawURL` to
  /// `outputURL`, replacing what is there. `false` when it couldn't.
  public static func extract(
    _ event: Source, from rawURL: URL, nightStart: Date, padding: TimeInterval = 0, to outputURL: URL) async -> Bool
  {
    let asset = AVURLAsset(url: rawURL)
    guard let total = try? await asset.load(.duration).seconds,
          let range = range(of: event, nightStart: nightStart, totalDuration: total, padding: padding),
          let export = AVAssetExportSession(asset: asset, presetName: AVAssetExportPresetAppleM4A)
    else { return false }
    try? FileManager.default.removeItem(at: outputURL)
    export.timeRange = CMTimeRange(
      start: CMTime(seconds: range.lowerBound, preferredTimescale: 600),
      duration: CMTime(seconds: range.upperBound - range.lowerBound, preferredTimescale: 600))
    if #available(iOS 18, *) {
      do {
        try await export.export(to: outputURL, as: .m4a)
        return true
      } catch {
        return false
      }
    }
    export.outputURL = outputURL
    export.outputFileType = .m4a
    await export.export()
    return export.status == .completed
  }
}
#endif
