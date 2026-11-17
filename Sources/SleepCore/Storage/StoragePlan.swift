import Foundation

/// Which nights lose their audio under the storage limits. Each app measures
/// its files and deletes them; the choice is made here, so both apps keep the
/// same nights.
///
/// Two rules, applied in order:
/// - **Days:** every night that started more than `maxDays` days before `now`.
/// - **Size:** of the nights left, the oldest first until the audio still kept
///   fits in `maxMB`.
///
/// A chosen night may have no audio left (its files already gone): the app
/// still clears its references, and counts only the files it removes. The
/// nights themselves stay: only their audio goes.
public struct StoragePlan: Equatable, Sendable {
  /// A night as the rule sees it: when it started and how much audio it keeps.
  public struct Night: Equatable, Sendable {
    public let id: UUID
    public let start: Date
    public let bytes: Int64

    public init(id: UUID, start: Date, bytes: Int64) {
      self.id = id
      self.start = start
      self.bytes = bytes
    }
  }

  /// Nights older than the day limit, oldest first.
  public let dayLimited: [UUID]
  /// Nights removed to get under the size limit, oldest first.
  public let sizeLimited: [UUID]

  public init(dayLimited: [UUID] = [], sizeLimited: [UUID] = []) {
    self.dayLimited = dayLimited
    self.sizeLimited = sizeLimited
  }

  /// Every night that loses its audio.
  public var all: [UUID] { dayLimited + sizeLimited }

  public var isEmpty: Bool { all.isEmpty }

  /// `nil` turns that limit off.
  public static func make(nights: [Night], now: Date, maxDays: Int?, maxMB: Int?) -> StoragePlan {
    let sorted = nights.sorted { $0.start < $1.start }
    var kept = sorted
    var dayLimited: [UUID] = []
    if let maxDays {
      let cutoff = now.addingTimeInterval(-TimeInterval(maxDays) * 24 * 3600)
      dayLimited = sorted.filter { $0.start < cutoff }.map(\.id)
      kept = sorted.filter { $0.start >= cutoff }
    }

    var sizeLimited: [UUID] = []
    if let maxMB {
      let maxBytes = Int64(maxMB) * 1_024 * 1_024
      var total = kept.reduce(Int64(0)) { $0 + $1.bytes }
      for night in kept {
        if total <= maxBytes { break }
        sizeLimited.append(night.id)
        total -= night.bytes
      }
    }
    return StoragePlan(dayLimited: dayLimited, sizeLimited: sizeLimited)
  }
}

/// The storage settings' choices and defaults, the same in every app.
public enum StorageLimits {
  public static let megabyteOptions = [100, 250, 500, 1000, 2000]
  public static let dayOptions = [7, 14, 30, 60, 90]
  public static let defaultMegabytes = 500
  public static let defaultDays = 30
}
