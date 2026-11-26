import Foundation
import Testing
@testable import SleepCore

/// What a cleanup removes: the plan's nights, and files nothing refers to.
struct StorageSweepTests {
  private let now = Date(timeIntervalSinceReferenceDate: 800_000_000)

  @Test func leftoversAreFilesNoNightOrNightInProgressNames() {
    let saved = NightFiles(id: UUID(), start: now.addingTimeInterval(-86400), clipFileNames: ["a.m4a"])
    let inProgress = Night(
      start: now, end: now.addingTimeInterval(60),
      events: [NightEvent(start: now, duration: 5, intensity: .light, clipFileName: "live.caf")])
    let all = ["a.m4a", "live.caf", "stray.caf"] + RawRecording.fileNames(for: inProgress.id)

    let sweep = StorageSweep.make(
      nights: [saved], sizes: [:], allFiles: all, inProgress: inProgress, now: now, maxDays: nil, maxMB: nil)

    #expect(sweep.leftovers == ["stray.caf"])
    #expect(sweep.plan.all.isEmpty)
  }

  @Test func theDayLimitTakesOldNightsUsingTheirRawFilesToo() {
    let old = NightFiles(id: UUID(), start: now.addingTimeInterval(-40 * 86400), clipFileNames: ["old.m4a"])
    let recent = NightFiles(id: UUID(), start: now.addingTimeInterval(-86400), clipFileNames: [])
    let sizes: [String: Int64] = ["old.m4a": 10, RawRecording.audioFileName(for: old.id): 1000]

    let sweep = StorageSweep.make(
      nights: [old, recent], sizes: sizes, allFiles: Array(sizes.keys), inProgress: nil, now: now, maxDays: 30,
      maxMB: nil)

    #expect(sweep.plan.dayLimited == [old.id])
    #expect(sweep.leftovers.isEmpty)
  }
}
