public import Foundation
public import SleepCore
import SleepLogging

/// The person's profile as one JSON file, written atomically. A missing or
/// unreadable file is the empty profile.
public actor ProfileFile {
  public nonisolated let url: URL

  public init(url: URL) {
    self.url = url
  }

  public func load() -> SleepProfile {
    guard FileManager.default.fileExists(atPath: url.path) else { return SleepProfile() }
    do {
      return try JSONDecoder().decode(SleepProfile.self, from: Data(contentsOf: url))
    } catch {
      Log.storage.error("Profile unreadable, starting empty: \(error.localizedDescription, privacy: .public)")
      return SleepProfile()
    }
  }

  public func save(_ profile: SleepProfile) throws {
    try JSONEncoder().encode(profile).write(to: url, options: .atomic)
  }

  /// Back to the empty profile (delete all data).
  public func clear() {
    try? FileManager.default.removeItem(at: url)
  }
}

/// The briefing survey's answers as one JSON file, oldest first. A new
/// answer for a night replaces that night's earlier one.
public actor LifestyleLogFile {
  public nonisolated let url: URL

  public init(url: URL) {
    self.url = url
  }

  public func logs() -> [LifestyleLog] {
    guard FileManager.default.fileExists(atPath: url.path) else { return [] }
    do {
      return try JSONDecoder().decode([LifestyleLog].self, from: Data(contentsOf: url))
    } catch {
      Log.storage.error("Survey answers unreadable, starting empty: \(error.localizedDescription, privacy: .public)")
      return []
    }
  }

  public func save(_ log: LifestyleLog) throws {
    let all = logs().filter { $0.night != log.night } + [log]
    try JSONEncoder().encode(all).write(to: url, options: .atomic)
  }

  /// Every answer, at once (sample data).
  public func save(_ logs: [LifestyleLog]) throws {
    try JSONEncoder().encode(logs).write(to: url, options: .atomic)
  }

  public func clear() {
    try? FileManager.default.removeItem(at: url)
  }
}
