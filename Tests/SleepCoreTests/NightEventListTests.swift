import Foundation
import Testing
@testable import SleepCore

/// A night's event list and its filter. Cases from both apps:
/// SleepGuardUIKitWay's `DetailEventsTests` and SleepGuard's
/// `SessionDetailModelTests` (filters).
struct NightEventListTests {
  private func event(at seconds: TimeInterval, duration: TimeInterval = 60, category: SoundCategory = .snoring, intensity: SnoreIntensity = .light) -> NightEvent {
    Sample.event(at: seconds, duration: duration, intensity: intensity, category: category)
  }

  @Test func snoringIsOneRowPerEpisodeFromItsStartKeyedByItsLongestEvent() throws {
    let short = event(at: 0, duration: 30, intensity: .light)
    let long = event(at: 100, duration: 120, intensity: .epic) // same episode
    let rows = EventListRow.rows(for: Sample.night(events: [short, long]))
    #expect(rows.count == 1)
    let row = try #require(rows.first)
    #expect(row.id == long.id)
    #expect(row.start == short.start)
    #expect(row.duration == 150)
    #expect(row.intensity == .epic)
  }

  @Test func otherEventsAreSeparateRowsInTimeOrderUnderTheFilter() {
    let talking = event(at: 3600, duration: 12, category: .sleepTalking)
    let cough = event(at: 600, duration: 4, category: .coughing)
    let snore = event(at: 7200)
    let night = Sample.night(events: [talking, cough, snore])
    #expect(EventListRow.rows(for: night).map(\.id) == [cough.id, talking.id, snore.id])
    #expect(EventListRow.rows(for: night, filter: .noise).map(\.id) == [cough.id])
    #expect(EventListRow.rows(for: night, filter: .snoring).map(\.id) == [snore.id])
    #expect(EventListRow.rows(for: night, filter: .sleepTalking).map(\.id) == [talking.id])
  }

  @Test func hiddenMicroEpisodesHaveNoRow() {
    #expect(EventListRow.rows(for: Sample.night(events: [event(at: 0, duration: 2)])).isEmpty)
  }

  @Test func playPlaysASnoringRowsEpisodeAndOtherEventsAlone() throws {
    let first = event(at: 0, duration: 30)
    let longest = event(at: 100, duration: 120)
    let talking = event(at: 3600, duration: 12, category: .sleepTalking)
    let night = Sample.night(events: [first, longest, talking])
    let rows = EventListRow.rows(for: night)
    #expect(try #require(rows.first { $0.category == .snoring }).playback(in: night.events).map(\.id) == [first.id, longest.id])
    #expect(try #require(rows.first { $0.category == .sleepTalking }).playback(in: night.events).map(\.id) == [talking.id])
  }

  /// SleepGuard's rule: all four as soon as a night has two kinds of event.
  @Test func everyFilterIsOfferedForMoreThanOneKind() {
    #expect(EventFilter.options(for: [event(at: 0), event(at: 600)]).isEmpty)
    #expect(EventFilter.options(for: [event(at: 0), event(at: 600, category: .other)]) == EventFilter.allCases)
  }

  /// Without sleep-talking detection, sleep talking is neither a filter nor a kind.
  @Test func sleepTalkingCountsOnlyWhenDetected() {
    let events = [event(at: 0), event(at: 600, category: .sleepTalking)]
    #expect(EventFilter.options(for: events) == EventFilter.allCases)
    #expect(EventFilter.options(for: events, includeSleepTalking: false).isEmpty)
    let threeKinds = events + [event(at: 900, category: .noise)]
    #expect(EventFilter.options(for: threeKinds, includeSleepTalking: false) == [.all, .snoring, .noise])
  }

  @Test(arguments: [
    (SoundCategory.snoring, EventFilter.snoring),
    (.sleepTalking, .sleepTalking),
    (.noise, .noise),
    (.coughing, .noise),
    (.other, .noise),
  ])
  func categoryFilterMembership(category: SoundCategory, filter: EventFilter) {
    #expect(filter.includes(category))
    #expect(EventFilter.all.includes(category))
  }
}
