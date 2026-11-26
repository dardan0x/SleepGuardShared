public import Foundation
import SleepLogging

/// Where an app keeps its nights and files, the same layout in every app:
/// `<app group, or Application Support>/<folder>/` with the database, the
/// clips (and each night's raw recording), the melodies and the small JSON
/// files. The app group, when the app is entitled to it, lets a widget read
/// the same files.
public struct StorageLocation: Sendable, Equatable {
  public let root: URL

  public init(root: URL) {
    self.root = root
  }

  /// Picks the root and creates the folders. `appGroup` is the group id
  /// (from Info.plist or the entitlements); without it, or when the app
  /// isn't entitled, Application Support.
  public static func resolve(appGroup: String?, folder: String, fileManager: FileManager = .default) -> StorageLocation {
    let base: URL
    if let appGroup, let container = fileManager.containerURL(forSecurityApplicationGroupIdentifier: appGroup) {
      base = container
    } else {
      Log.storage.notice("App group unavailable; storing in Application Support")
      base = URL.applicationSupportDirectory
    }
    let location = StorageLocation(root: base.appendingPathComponent(folder, isDirectory: true))
    for directory in [location.clipsDirectory, location.melodiesDirectory] {
      do {
        try fileManager.createDirectory(at: directory, withIntermediateDirectories: true)
      } catch {
        Log.storage.error("Couldn't create \(directory.lastPathComponent, privacy: .public): \(error.localizedDescription, privacy: .public)")
      }
    }
    return location
  }

  /// The nights database (`SleepStore`).
  public var storeURL: URL { root.appendingPathComponent("Nights.store") }
  /// Event clips, and each night's raw recording (`RawRecording` names).
  public var clipsDirectory: URL { root.appendingPathComponent("Clips", isDirectory: true) }
  /// Recorded melodies and their list.
  public var melodiesDirectory: URL { root.appendingPathComponent("Melodies", isDirectory: true) }
  /// The person's profile (`ProfileFile`).
  public var profileURL: URL { root.appendingPathComponent("Profile.json") }
  /// The briefing survey's answers (`LifestyleLogFile`).
  public var lifestyleLogURL: URL { root.appendingPathComponent("LifestyleLogs.json") }
  /// The night in progress (`NightCheckpoint`).
  public var checkpointURL: URL { root.appendingPathComponent("Recording.json") }
}
