public import Foundation
import SleepLogging
public import SwiftData

/// Opens the nights database without ever deleting it.
///
/// Before opening, the store is copied beside itself once per app version, so
/// a failed migration in a new version still leaves the old version's copy. A
/// store that fails to open is left on disk for a fixed build; the app runs
/// on an in-memory store and is told why.
public enum SleepStore {
  public struct Opening {
    public let container: ModelContainer
    /// Why the store at the URL couldn't be opened; `nil` when it opened.
    public let failure: (any Error)?
  }

  public static func open(at url: URL, appVersion: String) -> Opening {
    backUpIfNeeded(storeURL: url, appVersion: appVersion)
    do {
      return try Opening(container: SleepStoreSchema.container(at: url), failure: nil)
    } catch {
      Log.storage.fault("Store failed to open: \(String(describing: error), privacy: .public)")
      do {
        return try Opening(container: SleepStoreSchema.container(at: nil), failure: error)
      } catch {
        fatalError("Could not create an in-memory ModelContainer: \(error)")
      }
    }
  }

  /// Copies the store (and its `-wal` / `-shm` files) to `<name>.bak` once
  /// per `appVersion`. Nothing when there is no store yet.
  public static func backUpIfNeeded(storeURL: URL, appVersion: String) {
    let fileManager = FileManager.default
    guard fileManager.fileExists(atPath: storeURL.path) else { return }
    let marker = storeURL.appendingPathExtension("bak-version")
    guard (try? String(contentsOf: marker, encoding: .utf8)) != appVersion else { return }
    do {
      for source in storeFiles(at: storeURL) where fileManager.fileExists(atPath: source.path) {
        let backup = source.appendingPathExtension("bak")
        try? fileManager.removeItem(at: backup)
        try fileManager.copyItem(at: source, to: backup)
      }
      try appVersion.write(to: marker, atomically: true, encoding: .utf8)
      Log.storage.notice("Store backed up for \(appVersion, privacy: .public)")
    } catch {
      Log.storage.error("Store backup failed: \(String(describing: error), privacy: .public)")
    }
  }

  /// The nights whose summary is missing or was made by another formula,
  /// oldest first, at most `limit`. Doesn't read events.
  public static func staleNights(in context: ModelContext, version: String, limit: Int) throws -> [NightRecord] {
    var descriptor = FetchDescriptor<NightRecord>(
      predicate: #Predicate { $0.scoreVersion != version }, sortBy: [SortDescriptor(\.start)])
    descriptor.fetchLimit = limit
    return try context.fetch(descriptor)
  }

  /// The night with `id`, if stored.
  public static func night(id: UUID, in context: ModelContext) throws -> NightRecord? {
    var descriptor = FetchDescriptor<NightRecord>(predicate: #Predicate { $0.id == id })
    descriptor.fetchLimit = 1
    return try context.fetch(descriptor).first
  }

  private static func storeFiles(at url: URL) -> [URL] {
    [url, URL(fileURLWithPath: url.path + "-wal"), URL(fileURLWithPath: url.path + "-shm")]
  }
}
