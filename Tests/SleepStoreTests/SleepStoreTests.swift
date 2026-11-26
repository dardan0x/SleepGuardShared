import Foundation
import SleepCore
import SwiftData
import Testing
@testable import SleepStore

/// The shared records: a night survives the round trip, unknown raw values
/// read safely, the summary is stamped and found stale, and a broken store is
/// never deleted.
@MainActor
struct SleepStoreTests {
  private let start = Date(timeIntervalSince1970: 1_700_000_000)

  private func night(events: Int = 2) -> Night {
    Night(
      start: start, end: start.addingTimeInterval(8 * 3600), averageDB: -40, peakDB: -12,
      events: (0..<events).reversed().map { index in
        NightEvent(
          start: start.addingTimeInterval(Double(index + 1) * 600), duration: 30, intensity: .loud,
          bursts: [SnoreBurst(startOffset: 0, endOffset: 5)], clipFileName: "clip\(index).m4a",
          averageSpectralScore: 0.4, dominantFrequency: 180, spectralCentroid: 420, lowFreqRatio: 0.7)
      },
      recordingGaps: [], sleepStages: [], endReason: .lowBattery)
  }

  private func context() throws -> ModelContext {
    ModelContext(try SleepStoreSchema.container(at: nil))
  }

  @Test func aNightSurvivesTheRoundTripWithEventsInOrder() throws {
    let context = try context()
    let value = night()
    context.insert(NightRecord.make(from: value))
    try context.save()
    let stored = try #require(try SleepStore.night(id: value.id, in: context))
    let back = stored.night
    #expect(back.events.map(\.start) == value.events.map(\.start).sorted())
    #expect(back.endReason == .lowBattery)
    #expect(back.events.first?.dominantFrequency == 180)
    #expect(Set(back.events.map(\.id)) == Set(value.events.map(\.id)))
  }

  @Test func unknownRawValuesReadAsTheSafestDefault() {
    let event = NightEventRecord()
    event.categoryRawValue = "humming"
    event.intensityRawValue = "deafening"
    #expect(event.category == .other)
    #expect(event.intensity == .quiet)
    let record = NightRecord()
    record.endReasonRawValue = "meteor"
    record.loudestIntensityRawValue = "deafening"
    #expect(record.endReason == .stopped)
    #expect(record.loudestIntensity == .quiet)
  }

  @Test func theSummaryIsStampedAndGoesStaleWithTheFormula() throws {
    let context = try context()
    let record = NightRecord.make(from: night())
    context.insert(record)
    #expect(record.hasStaleSummary(for: .default))
    record.refreshSummary(using: .default)
    try context.save()
    #expect(!record.hasStaleSummary(for: .default))
    #expect(record.summary == record.night.summary(using: .default))
    #expect(record.eventCount == 2 && record.loudestIntensity == .loud)
    #expect(try SleepStore.staleNights(in: context, version: SleepScore.cacheVersion(for: .default), limit: 10).isEmpty)
    #expect(try SleepStore.staleNights(in: context, version: "other", limit: 10).count == 1)
  }

  @Test func replacingEventsLeavesOnlyTheNewOnes() throws {
    let context = try context()
    let record = NightRecord.make(from: night(events: 3))
    context.insert(record)
    try context.save()
    record.replaceEvents(with: night(events: 1).events, in: context)
    try context.save()
    #expect(record.events.count == 1)
    #expect(try context.fetchCount(FetchDescriptor<NightEventRecord>()) == 1)
  }

  @Test func deletingANightDeletesItsEvents() throws {
    let context = try context()
    let record = NightRecord.make(from: night())
    context.insert(record)
    try context.save()
    context.delete(record)
    try context.save()
    #expect(try context.fetchCount(FetchDescriptor<NightEventRecord>()) == 0)
  }

  @Test func aBrokenStoreIsKeptAndBackedUpOncePerVersion() throws {
    let folder = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
    try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
    defer { try? FileManager.default.removeItem(at: folder) }
    let url = folder.appendingPathComponent("Nights.store")
    try Data("not a database".utf8).write(to: url)

    let opening = SleepStore.open(at: url, appVersion: "1.0")
    #expect(opening.failure != nil)
    #expect(try Data(contentsOf: url) == Data("not a database".utf8))
    #expect(try Data(contentsOf: url.appendingPathExtension("bak")) == Data("not a database".utf8))

    try Data("newer".utf8).write(to: url)
    SleepStore.backUpIfNeeded(storeURL: url, appVersion: "1.0")
    #expect(try Data(contentsOf: url.appendingPathExtension("bak")) == Data("not a database".utf8))
  }
}
