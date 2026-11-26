import Foundation
import SleepCore
import Testing
@testable import SleepFiles

/// The raw log both apps write: readable by `RawLog.decode`, in time order,
/// removed when empty or discarded.
struct RawLogFileTests {
  private let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
  private let start = Date(timeIntervalSinceReferenceDate: 800_000_000)

  private var metadata: RawLogMetadata {
    RawLogMetadata(sessionStart: start, detectionSensitivity: "medium", detectSleepTalking: true, snoreInterrupterMode: "never")
  }

  private func sample(_ elapsed: TimeInterval) -> SnoreSample {
    SnoreSample(
      elapsed: elapsed, db: -40, peakDB: -30, spectralScore: 0, snoreConfidence: 0.1, speechConfidence: 0,
      state: .none)
  }

  private func makeDirectory() throws {
    try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
  }

  @Test func writtenSamplesReadBackInTimeOrder() async throws {
    try makeDirectory()
    defer { try? FileManager.default.removeItem(at: directory) }
    let night = UUID()
    let file = try RawLogFile(night: night, metadata: metadata, directory: directory)

    try await file.append([sample(0.10), sample(0.05)]) // late sample first
    try await file.append([sample(0.15)])
    let name = await file.finish()

    #expect(name == RawLogFile.fileName(for: night))
    let log = try RawLog.decode(from: Data(contentsOf: directory.appendingPathComponent(try #require(name))))
    #expect(log.metadata == metadata)
    #expect(log.samples.map(\.elapsed) == [0.05, 0.10, 0.15])
  }

  @Test func aLogWithoutSamplesIsRemoved() async throws {
    try makeDirectory()
    defer { try? FileManager.default.removeItem(at: directory) }
    let file = try RawLogFile(night: UUID(), metadata: metadata, directory: directory)
    #expect(await file.finish() == nil)
    #expect(!FileManager.default.fileExists(atPath: file.url.path))
  }

  @Test func discardRemovesTheFileAndLaterAppendsDoNothing() async throws {
    try makeDirectory()
    defer { try? FileManager.default.removeItem(at: directory) }
    let file = try RawLogFile(night: UUID(), metadata: metadata, directory: directory)
    try await file.append([sample(0.05)])
    await file.discard()
    try await file.append([sample(0.10)])
    #expect(!FileManager.default.fileExists(atPath: file.url.path))
  }

  @Test func theNameIsTheOneCleanupLooksFor() {
    let id = UUID()
    #expect(RawLogFile.fileName(for: id) == "rawlog_\(id.uuidString).jsonl")
  }
}
