import Foundation
import SleepCore
import Testing
@testable import SleepFiles

/// The files both apps keep: the layout, the clips folder, the checkpoint,
/// the profile and the survey answers.
struct SharedFilesTests {
  private let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)

  private func makeDirectory() throws {
    try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
  }

  @Test func theLayoutIsTheSameForEveryApp() {
    let location = StorageLocation(root: directory)
    #expect(location.storeURL.lastPathComponent == "Nights.store")
    #expect(location.clipsDirectory.lastPathComponent == "Clips")
    #expect(location.melodiesDirectory.lastPathComponent == "Melodies")
    #expect(location.checkpointURL.lastPathComponent == "Recording.json")
    #expect(location.profileURL.lastPathComponent == "Profile.json")
    #expect(location.lifestyleLogURL.lastPathComponent == "LifestyleLogs.json")
  }

  @Test func theClipFolderMeasuresAndRemovesOnlyPlainNames() throws {
    try makeDirectory()
    defer { try? FileManager.default.removeItem(at: directory) }
    let folder = ClipFolder(directory: directory)
    try Data([1, 2, 3]).write(to: directory.appendingPathComponent("a.m4a"))

    #expect(folder.size(ofFileNamed: "a.m4a") == 3)
    #expect(folder.sizes(of: ["a.m4a", "missing.m4a"]) == ["a.m4a": 3])
    #expect(folder.url(forFileNamed: "../a.m4a") == nil)
    #expect(folder.allFileNames() == ["a.m4a"])
    folder.removeFiles(named: ["a.m4a", "../x"])
    #expect(folder.allFileNames().isEmpty)
  }

  @Test func aCheckpointedNightComesBackInTimeOrder() async throws {
    try makeDirectory()
    defer { try? FileManager.default.removeItem(at: directory) }
    let checkpoint = NightCheckpoint(url: directory.appendingPathComponent("Recording.json"))
    let start = Date(timeIntervalSinceReferenceDate: 800_000_000)
    let late = NightEvent(start: start.addingTimeInterval(600), duration: 30, intensity: .loud, clipFileName: "b.caf")
    let early = NightEvent(start: start.addingTimeInterval(60), duration: 10, intensity: .light)
    let night = Night(
      start: start, end: start.addingTimeInterval(3600), averageDB: -40, peakDB: -10, events: [late, early],
      sleepStages: [SleepStageSegment(stage: .deep, startOffset: 0, duration: 600)], endReason: .lowBattery)

    #expect(await checkpoint.load() == nil)
    await checkpoint.save(night)
    let loaded = try #require(await checkpoint.load())
    #expect(loaded.events.map(\.id) == [early.id, late.id])
    #expect(loaded.endReason == .lowBattery && loaded.sleepStages == night.sleepStages)
    await checkpoint.clear()
    #expect(await checkpoint.load() == nil)
  }

  @Test func theProfileRoundTripsAndClears() async throws {
    try makeDirectory()
    defer { try? FileManager.default.removeItem(at: directory) }
    let file = ProfileFile(url: directory.appendingPathComponent("Profile.json"))
    #expect(await file.load() == SleepProfile())
    var profile = SleepProfile()
    profile.biologicalSex = .female
    try await file.save(profile)
    #expect(await file.load() == profile)
    await file.clear()
    #expect(await file.load() == SleepProfile())
  }

  @Test func aNewAnswerForANightReplacesTheOldOne() async throws {
    try makeDirectory()
    defer { try? FileManager.default.removeItem(at: directory) }
    let file = LifestyleLogFile(url: directory.appendingPathComponent("LifestyleLogs.json"))
    let night = Date(timeIntervalSinceReferenceDate: 800_000_000)
    let other = night.addingTimeInterval(86400)
    try await file.save(LifestyleLog(night: night, chips: [.alcohol]))
    try await file.save(LifestyleLog(night: other, chips: [.exercised]))
    try await file.save(LifestyleLog(night: night, chips: [.lateMeal]))
    #expect(await file.logs() == [LifestyleLog(night: other, chips: [.exercised]), LifestyleLog(night: night, chips: [.lateMeal])])
  }
}
