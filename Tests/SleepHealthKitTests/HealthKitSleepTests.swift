import Foundation
import HealthKit
import SleepCore
import Testing
@testable import SleepHealthKit

/// What both apps hand to HealthKit (no store needed).
struct HealthKitSleepTests {
  @Test func stagedValuesMapToStagesAndTheRestToNone() {
    #expect(HealthKitSleep.stage(for: HKCategoryValueSleepAnalysis.asleepCore.rawValue) == .light)
    #expect(HealthKitSleep.stage(for: HKCategoryValueSleepAnalysis.asleepDeep.rawValue) == .deep)
    #expect(HealthKitSleep.stage(for: HKCategoryValueSleepAnalysis.asleepREM.rawValue) == .rem)
    #expect(HealthKitSleep.stage(for: HKCategoryValueSleepAnalysis.awake.rawValue) == .awake)
    #expect(HealthKitSleep.stage(for: HKCategoryValueSleepAnalysis.asleepUnspecified.rawValue) == nil)
    #expect(HealthKitSleep.stage(for: HKCategoryValueSleepAnalysis.inBed.rawValue) == nil)
  }

  @Test func aNightIsOneAsleepSampleWithItsSnoring() throws {
    let start = Date(timeIntervalSinceReferenceDate: 800_000_000)
    let night = Night(
      start: start, end: start.addingTimeInterval(8 * 3600), averageDB: -42, peakDB: -12,
      events: [NightEvent(start: start.addingTimeInterval(600), duration: 1440, intensity: .loud)])
    let summary = night.summary()

    let sample = HealthKitSleep.sample(for: night, summary: summary)

    #expect(sample.value == HKCategoryValueSleepAnalysis.asleepUnspecified.rawValue)
    #expect(sample.startDate == night.start && sample.endDate == night.end)
    let metadata = try #require(sample.metadata)
    #expect(metadata["snoreEventsCount"] as? Int == summary.eventCount)
    #expect(metadata["snoringPercentage"] as? Double == summary.snoringShare * 100)
    #expect(metadata["averageDB"] as? Double == -42)
    #expect(metadata["peakDB"] as? Double == -12)
    #expect(metadata[HKMetadataKeyWasUserEntered] as? Bool == true)
  }
}
