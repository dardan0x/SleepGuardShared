import Foundation

/// The raw recording's files, named by the night's id, so storage limits and
/// cleanup can find them without asking anyone.
public enum RawRecording {
  public static func audioFileName(for night: UUID) -> String {
    "rawaudio_\(night.uuidString).caf"
  }

  public static func logFileName(for night: UUID) -> String {
    "rawlog_\(night.uuidString).jsonl"
  }

  public static func fileNames(for night: UUID) -> [String] {
    [audioFileName(for: night), logFileName(for: night)]
  }
}

/// A night's files: its clips and, by name, its raw recording (which may not
/// exist). What storage limits measure.
public struct NightFiles: Equatable, Sendable {
  public let id: UUID
  public let start: Date
  public let clipFileNames: [String]

  public init(id: UUID, start: Date, clipFileNames: [String]) {
    self.id = id
    self.start = start
    self.clipFileNames = clipFileNames
  }

  /// Its clips and raw recording.
  public var allFileNames: [String] {
    clipFileNames + RawRecording.fileNames(for: id)
  }
}

/// What a storage cleanup removes, decided from values: the nights whose
/// audio goes (`StoragePlan`: older than the day limit, then the oldest over
/// the size limit) and the leftover files no night refers to (a clip a crash
/// left half written, a raw clip whose compression finished but wasn't
/// saved). The night in progress counts as referenced, so run it while
/// nothing records or pass that night. Each app performs it with its own
/// store; `SleepFiles`' `ClipFolder` measures and removes the files.
public struct StorageSweep: Equatable, Sendable {
  public let plan: StoragePlan
  public let leftovers: [String]

  public static func make(
    nights: [NightFiles],
    sizes: [String: Int64],
    allFiles: [String],
    inProgress: Night?,
    now: Date,
    maxDays: Int?,
    maxMB: Int?) -> StorageSweep
  {
    let plan = StoragePlan.make(
      nights: nights.map { night in
        StoragePlan.Night(id: night.id, start: night.start, bytes: night.allFileNames.reduce(0) { $0 + (sizes[$1] ?? 0) })
      },
      now: now, maxDays: maxDays, maxMB: maxMB)
    var referenced = Set(nights.flatMap(\.allFileNames))
    if let inProgress {
      referenced.formUnion(inProgress.events.compactMap(\.clipFileName))
      referenced.formUnion(RawRecording.fileNames(for: inProgress.id))
    }
    return StorageSweep(plan: plan, leftovers: allFiles.filter { !referenced.contains($0) }.sorted())
  }
}
