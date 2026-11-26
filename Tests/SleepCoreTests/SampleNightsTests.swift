import Foundation
import Testing
@testable import SleepCore

/// The sample nights both apps seed: stable, valid and varied.
struct SampleNightsTests {
  private let today = Date(timeIntervalSinceReferenceDate: 800_000_000)

  @Test func sameNightsEveryRun() {
    #expect(SampleNights.make(before: today) == SampleNights.make(before: today))
    #expect(SampleNights.lifestyleLogs(for: SampleNights.make(before: today))
      == SampleNights.lifestyleLogs(for: SampleNights.make(before: today)))
  }

  @Test func fourteenValidNightsNewestFirstBeforeToday() throws {
    let nights = SampleNights.make(before: today)
    #expect(nights.count == 14)
    #expect(nights.map(\.start) == nights.map(\.start).sorted(by: >))
    #expect(try #require(nights.first).end < today.addingTimeInterval(12 * 3600))
    for night in nights {
      #expect(night.duration >= 5.5 * 3600 && night.duration <= 9 * 3600)
      #expect(night.events.allSatisfy { $0.start >= night.start && $0.end <= night.end })
      #expect(night.events.map(\.start) == night.events.map(\.start).sorted())
    }
  }

  @Test func nightsVary() {
    let nights = SampleNights.make(before: today)
    #expect(Set(nights.map { $0.score() }).count > 5)
    #expect(nights.contains { !$0.sleepStages.isEmpty } && nights.contains { $0.sleepStages.isEmpty })
    #expect(nights.contains { $0.endReason == .lowBattery })
    #expect(nights.contains { $0.events.contains { $0.category == .sleepTalking } })
  }

  @Test func clipsAreTheSnoringEventsCappedInLength() {
    let nights = SampleNights.make(before: today)
    let clips = SampleNights.clips(of: nights)
    #expect(!clips.isEmpty)
    #expect(clips.allSatisfy { $0.seconds <= SampleNights.maxClipSeconds && $0.name.hasSuffix(".m4a") })
  }

  @Test func surveyAnswersCoverSomeNightsWithOneKindOfChip() {
    let nights = SampleNights.make(before: today)
    let logs = SampleNights.lifestyleLogs(for: nights)
    #expect(!logs.isEmpty && logs.count < nights.count)
    for log in logs {
      #expect(nights.contains { $0.start == log.night })
      #expect(log.chips.isSubset(of: Set(LifestyleChip.positive)) || log.chips.isSubset(of: Set(LifestyleChip.negative)))
    }
  }
}
