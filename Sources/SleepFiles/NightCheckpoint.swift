public import Foundation
public import SleepCore
import SleepLogging

/// The night in progress as one JSON file, so a crash, a kill in the
/// background or a dead battery doesn't lose it. Writes are atomic (a
/// temporary file, then a rename): a crash mid-write leaves the previous
/// checkpoint. Holds at most one night.
///
/// The file's format is `encode` / `decode`, so an app with its own writer
/// (its own threading, a sequence gate) still writes the same file.
public actor NightCheckpoint {
  /// The checkpoint file's bytes for `night`.
  public static func encode(_ night: Night) throws -> Data {
    try JSONEncoder().encode(File(night))
  }

  /// The night in a checkpoint file. Unknown raw values read as safe
  /// defaults; durations and the end are clamped; events come back in time
  /// order.
  public static func decode(_ data: Data) throws -> Night {
    try JSONDecoder().decode(File.self, from: data).night
  }

  public nonisolated let url: URL

  public init(url: URL) {
    self.url = url
  }

  /// A failed write is logged; the previous checkpoint stays.
  public func save(_ night: Night) {
    do {
      try Self.encode(night).write(to: url, options: .atomic)
    } catch {
      Log.storage.error("Checkpoint write failed: \(error.localizedDescription, privacy: .public)")
    }
  }

  /// `nil` when there is none, or it can't be read (logged).
  public func load() -> Night? {
    guard FileManager.default.fileExists(atPath: url.path) else { return nil }
    do {
      return try Self.decode(Data(contentsOf: url))
    } catch {
      Log.storage.error("Checkpoint unreadable, night not recoverable: \(error.localizedDescription, privacy: .public)")
      return nil
    }
  }

  public func clear() {
    try? FileManager.default.removeItem(at: url)
  }

  /// The file's shape: plain Codable mirrors, so the values stay free of
  /// storage concerns. Unknown raw values read as safe defaults; durations
  /// and the end are clamped.
  struct File: Codable, Equatable {
    struct Event: Codable, Equatable {
      let id: UUID
      let start: Date
      let duration: TimeInterval
      let category: String
      let intensity: String
      let averageDB: Double
      let peakDB: Double
      let averageConfidence: Double
      let bursts: [SnoreBurst]
      let clipFileName: String?
    }

    let id: UUID
    let start: Date
    let end: Date
    let averageDB: Double
    let peakDB: Double
    let events: [Event]
    let recordingGaps: [RecordingGap]
    let sleepStages: [SleepStageSegment]?
    let endReason: String

    init(_ night: Night) {
      id = night.id
      start = night.start
      end = night.end
      averageDB = night.averageDB
      peakDB = night.peakDB
      events = night.events.map {
        Event(
          id: $0.id, start: $0.start, duration: $0.duration, category: $0.category.rawValue,
          intensity: $0.intensity.rawValue, averageDB: $0.averageDB, peakDB: $0.peakDB,
          averageConfidence: $0.averageConfidence, bursts: $0.bursts, clipFileName: $0.clipFileName)
      }
      recordingGaps = night.recordingGaps
      sleepStages = night.sleepStages
      endReason = night.endReason.rawValue
    }

    var night: Night {
      Night(
        id: id, start: start, end: max(end, start), averageDB: averageDB, peakDB: peakDB,
        events: events.map {
          NightEvent(
            id: $0.id, start: $0.start, duration: max(0, $0.duration),
            category: SoundCategory(rawValue: $0.category) ?? .other,
            intensity: SnoreIntensity(rawValue: $0.intensity) ?? .quiet,
            averageDB: $0.averageDB, peakDB: $0.peakDB, averageConfidence: $0.averageConfidence, bursts: $0.bursts,
            clipFileName: $0.clipFileName)
        }.sorted { $0.start < $1.start },
        recordingGaps: recordingGaps,
        sleepStages: sleepStages ?? [],
        endReason: Night.EndReason(rawValue: endReason) ?? .stopped)
    }
  }
}
