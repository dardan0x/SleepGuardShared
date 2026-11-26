public import Foundation
public import SleepCore

/// One night's raw log on disk, in `RawLog`'s format (JSON Lines: the
/// metadata, then one sample per line), written the same way by every app.
///
/// Appends as it goes, so a night cut short by a crash keeps what was
/// written. Each batch is written in time order (readers expect it; samples
/// can reach a writer late). A log that never got a sample is removed when
/// it is finished. Errors are thrown for the app to log: this type has no
/// logger of its own.
public actor RawLogFile {
  /// `rawlog_<id>.jsonl`, the name storage limits and cleanup look for.
  public static func fileName(for night: UUID) -> String {
    "rawlog_\(night.uuidString).jsonl"
  }

  public nonisolated let url: URL
  private var handle: FileHandle?
  private var samplesWritten = 0

  /// Creates the file with its metadata line (replacing one left over).
  public init(night: UUID, metadata: RawLogMetadata, directory: URL) throws {
    url = directory.appendingPathComponent(Self.fileName(for: night))
    try RawLog.line(metadata).write(to: url, options: .atomic)
    let handle = try FileHandle(forWritingTo: url)
    try handle.seekToEnd()
    self.handle = handle
  }

  /// Appends `samples`, in time order. Nothing after `finish` or `discard`.
  public func append(_ samples: [SnoreSample]) throws {
    guard let handle, !samples.isEmpty else { return }
    var data = Data()
    for sample in samples.sorted(by: { $0.elapsed < $1.elapsed }) {
      try data.append(RawLog.line(sample))
    }
    try handle.write(contentsOf: data)
    samplesWritten += samples.count
  }

  /// Closes the file. Returns its name, or `nil` (and removes it) when no
  /// sample was ever written.
  @discardableResult
  public func finish() -> String? {
    close()
    guard samplesWritten > 0 else {
      try? FileManager.default.removeItem(at: url)
      return nil
    }
    return url.lastPathComponent
  }

  /// Closes and removes the file (a discarded night).
  public func discard() {
    close()
    try? FileManager.default.removeItem(at: url)
  }

  private func close() {
    try? handle?.close()
    handle = nil
  }
}
