public import Foundation

/// The clips folder: measure, find and remove files by name. Only plain
/// names are accepted, so a stored name can't reach outside the folder.
public struct ClipFolder: Sendable, Equatable {
  public let directory: URL

  public init(directory: URL) {
    self.directory = directory
  }

  /// The file, when it exists.
  public func url(forFileNamed name: String) -> URL? {
    guard Self.isPlain(name) else { return nil }
    let url = directory.appendingPathComponent(name)
    return FileManager.default.fileExists(atPath: url.path) ? url : nil
  }

  /// 0 for a missing file.
  public func size(ofFileNamed name: String) -> Int64 {
    guard Self.isPlain(name),
          let size = try? FileManager.default.attributesOfItem(atPath: directory.appendingPathComponent(name).path)[.size]
          as? Int64 else { return 0 }
    return size
  }

  /// Sizes of the files that exist, by name.
  public func sizes(of names: some Sequence<String>) -> [String: Int64] {
    Dictionary(names.map { ($0, size(ofFileNamed: $0)) }.filter { $0.1 > 0 }, uniquingKeysWith: { first, _ in first })
  }

  public func allFileNames() -> [String] {
    (try? FileManager.default.contentsOfDirectory(atPath: directory.path)) ?? []
  }

  /// A missing file already meets the goal.
  public func removeFiles(named names: some Sequence<String>) {
    for name in names where Self.isPlain(name) {
      try? FileManager.default.removeItem(at: directory.appendingPathComponent(name))
    }
  }

  private static func isPlain(_ name: String) -> Bool {
    !name.isEmpty && !name.contains("/") && name != ".." && name != "."
  }
}
