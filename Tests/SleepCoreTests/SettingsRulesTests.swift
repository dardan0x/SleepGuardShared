import Foundation
import SleepCore
import Testing

/// The storage limits keep the same nights in every app (SleepGuard's cases),
/// the start delay's choices and countdown, and the profile's derived values.
struct StoragePlanTests {
  private static let now = Date(timeIntervalSinceReferenceDate: 800_000_000)
  private static let megabyte: Int64 = 1_024 * 1_024

  private static func night(daysAgo: Double, megabytes: Int64 = 0, bytes: Int64? = nil) -> StoragePlan.Night {
    StoragePlan.Night(id: UUID(), start: now.addingTimeInterval(-daysAgo * 24 * 3600), bytes: bytes ?? megabytes * megabyte)
  }

  @Test func dayLimitTakesEveryOlderNight() {
    let old = Self.night(daysAgo: 10, bytes: 4_000)
    let oldWithoutAudio = Self.night(daysAgo: 9)
    let recent = Self.night(daysAgo: 1, bytes: 1_000)

    let plan = StoragePlan.make(nights: [recent, old, oldWithoutAudio], now: Self.now, maxDays: 7, maxMB: nil)

    #expect(plan.dayLimited == [old.id, oldWithoutAudio.id])
    #expect(plan.sizeLimited.isEmpty)
  }

  @Test func sizeLimitTakesTheOldestUntilUnderTheLimit() {
    let oldest = Self.night(daysAgo: 3, megabytes: 2)
    let middle = Self.night(daysAgo: 2, megabytes: 2)
    let newest = Self.night(daysAgo: 1, megabytes: 2)

    let plan = StoragePlan.make(nights: [newest, middle, oldest], now: Self.now, maxDays: nil, maxMB: 3)

    #expect(plan.sizeLimited == [oldest.id, middle.id])
  }

  @Test func underTheSizeLimitNothingGoes() {
    let plan = StoragePlan.make(nights: [Self.night(daysAgo: 1, megabytes: 2)], now: Self.now, maxDays: nil, maxMB: 3)

    #expect(plan.isEmpty)
  }

  @Test func nightsTakenByTheDayLimitDontCountAgainstTheSize() {
    let old = Self.night(daysAgo: 10, megabytes: 5)
    let recent = Self.night(daysAgo: 1, megabytes: 2)

    let plan = StoragePlan.make(nights: [old, recent], now: Self.now, maxDays: 7, maxMB: 3)

    #expect(plan.dayLimited == [old.id])
    #expect(plan.sizeLimited.isEmpty)
    #expect(plan.all == [old.id])
  }

  @Test func noLimitsMeansNothingGoes() {
    let plan = StoragePlan.make(nights: [Self.night(daysAgo: 100, megabytes: 900)], now: Self.now, maxDays: nil, maxMB: nil)

    #expect(plan.isEmpty)
  }

  @Test func aNightWithoutAudioDoesntCountTowardsTheSize() {
    let empty = Self.night(daysAgo: 3)
    let full = Self.night(daysAgo: 2, megabytes: 4)

    let plan = StoragePlan.make(nights: [full, empty], now: Self.now, maxDays: nil, maxMB: 1)

    #expect(plan.sizeLimited == [empty.id, full.id])
  }
}

struct RecordingDelayTests {
  @Test func optionsAndUnknownValues() {
    #expect(RecordingDelay.options == [0, 15, 30, 45, 60])
    #expect(RecordingDelay.valid(30) == 30)
    #expect(RecordingDelay.valid(20) == 0)
  }

  @Test func countdown() {
    let now = Date(timeIntervalSinceReferenceDate: 0)
    #expect(RecordingDelay.secondsLeft(until: now.addingTimeInterval(1_799.2), now: now) == 1_800)
    #expect(RecordingDelay.secondsLeft(until: now.addingTimeInterval(-5), now: now) == 0)
    #expect(RecordingDelay.countdownText(seconds: 1_800) == "30:00")
    #expect(RecordingDelay.countdownText(seconds: 3_600) == "60:00")
    #expect(RecordingDelay.countdownText(seconds: 61) == "01:01")
    #expect(RecordingDelay.countdownText(seconds: -1) == "00:00")
  }
}

struct SleepProfileTests {
  @Test func completionCountsOnlyFieldsThatCanBeEmpty() {
    var profile = SleepProfile()
    #expect(profile.completion == 0)
    profile.firstName = "Sam"
    profile.birthYear = 1990
    profile.caffeine = .heavy
    #expect(abs(profile.completion - 2.0 / 9.0) < 0.0001)
    profile.firstName = ""
    #expect(abs(profile.completion - 1.0 / 9.0) < 0.0001)
  }

  @Test func ageAndHobbies() {
    #expect(SleepProfile(birthYear: 1990).age(in: 2026) == 36)
    #expect(SleepProfile().age(in: 2026) == nil)
    #expect(SleepProfile.hobbies(from: "reading, running ,, ") == ["reading", "running"])
  }
}
