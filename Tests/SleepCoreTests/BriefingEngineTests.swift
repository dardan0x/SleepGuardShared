import Foundation
import Testing
@testable import SleepCore

/// SleepGuard's briefing cases on values (they used to check text), plus the
/// cases its random mode left unchecked.
struct BriefingEngineTests {
  let calendar: Calendar = {
    var calendar = Calendar(identifier: .gregorian)
    calendar.timeZone = TimeZone(identifier: "UTC")!
    return calendar
  }()

  func date(hour: Int, dayOffset: Int = 0) -> Date {
    calendar.date(from: DateComponents(year: 2026, month: 6, day: 1 + dayOffset, hour: hour))!
  }

  func night(dayOffset: Int, hours: Double = 1, score: Int = 100, snoring: TimeInterval = 0) -> NightSummary {
    let start = date(hour: 23, dayOffset: dayOffset)
    return NightSummary(
      id: UUID(), start: start, end: start.addingTimeInterval(hours * 3600), score: score, snoringDuration: snoring,
      eventCount: 0)
  }

  func make(_ nights: [NightSummary], profile: SleepProfile? = nil, logs: [LifestyleLog] = [], hour: Int = 8) -> Briefing {
    BriefingEngine.make(nights: nights, profile: profile, logs: logs, now: date(hour: hour), calendar: calendar)
  }

  // MARK: - Trend

  @Test func noNightsIsNoData() {
    let briefing = make([])
    #expect(briefing.trend == .noData)
    #expect(briefing.headline == .welcome)
    #expect(briefing.stats.isEmpty && briefing.insight.isEmpty && briefing.survey == nil)
  }

  @Test func oneNightIsTheFirst() {
    let briefing = make([night(dayOffset: -1)])
    #expect(briefing.trend == .firstNight)
    #expect(briefing.insight.isEmpty)
    #expect(briefing.survey == nil)
    #expect(briefing.stats.count == 3)
  }

  @Test func fiveDaysAwayIsAReturn() {
    #expect(make([night(dayOffset: -5), night(dayOffset: -6)]).trend == .returningAfterGap(days: 5))
  }

  @Test(arguments: [(85, BriefingTrend.improving), (55, .declining), (76, .steady)])
  func trendAgainstTheAverage(latest: Int, trend: BriefingTrend) {
    let previous = latest == 55 ? 80 : (latest == 76 ? 74 : 60)
    #expect(make([night(dayOffset: -1, score: latest), night(dayOffset: -2, score: previous)]).trend == trend)
  }

  // MARK: - Greeting

  @Test(arguments: [(8, DayPart.morning), (14, .afternoon), (20, .evening), (2, .night)])
  func greetingByHour(hour: Int, part: DayPart) {
    #expect(make([], hour: hour).greeting == BriefingGreeting(part: part, name: nil))
  }

  @Test func greetingWithAName() {
    var profile = SleepProfile()
    profile.firstName = "Alex"
    #expect(make([], profile: profile).greeting.name == "Alex")
    profile.firstName = ""
    #expect(make([], profile: profile).greeting.name == nil)
  }

  // MARK: - Headline and stats (one night: always the recap)

  @Test func aQuietNight() {
    #expect(make([night(dayOffset: -1, hours: 8)]).headline == .quiet(duration: 8 * 3600, isLastNight: true))
  }

  @Test func aNightWithSnoring() {
    let briefing = make([night(dayOffset: -1, hours: 8, score: 82, snoring: 1800)])
    #expect(briefing.headline == .normal(duration: 8 * 3600, snoringMinutes: 30, score: 82, isLastNight: true))
    #expect(briefing.stats == [.init(.sleep, .duration(8 * 3600)), .init(.snoring, .minutes(30)), .init(.score, .points(82))])
  }

  @Test func anOlderNightIsLastTime() {
    #expect(make([night(dayOffset: -3, hours: 8)]).headline == .quiet(duration: 8 * 3600, isLastNight: false))
  }

  // MARK: - Insight

  @Test func improvingInsight() {
    let nights = [night(dayOffset: -1, score: 85), night(dayOffset: -2, score: 60)]
    #expect(BriefingEngine.insight(nights: nights, profile: nil) == [.improving(score: 85, average: 60)])
  }

  @Test func goalShortfallFollowsTheComparison() {
    var profile = SleepProfile()
    profile.targetSleepHours = 8
    let nights = [night(dayOffset: -1, hours: 5), night(dayOffset: -2, hours: 5)]
    #expect(BriefingEngine.insight(nights: nights, profile: profile) == [
      .steady(average: 100), .goalShortfall(hours: 5, minutes: 0, shortMinutes: 180, targetHours: 8),
    ])
  }

  // MARK: - Mode

  @Test func theSameNightAlwaysGetsTheSameBriefing() {
    let nights = [night(dayOffset: -1, score: 70), night(dayOffset: -2, score: 80)]
    #expect(make(nights) == make(nights))
  }

  @Test func differentNightsUseEveryMode() {
    let modes = Set((0..<12).map { offset in
      "\(BriefingEngine.mode(for: [night(dayOffset: -offset), night(dayOffset: -offset - 1)], calendar: calendar))"
    })
    #expect(modes.count == BriefingEngine.Mode.allCases.count)
  }

  // MARK: - Survey

  @Test func noSurveyForOneNight() {
    #expect(make([night(dayOffset: -1)]).survey == nil)
  }

  @Test func aSmallRiseIsPositive() {
    #expect(make([night(dayOffset: -1, score: 78), night(dayOffset: -2, score: 75)]).survey?.isPositive == true)
  }

  @Test func answeredNightsAreNotAskedAgain() {
    let latest = night(dayOffset: -1, score: 85)
    let log = LifestyleLog(night: latest.start, chips: [])
    #expect(make([latest, night(dayOffset: -2, score: 60)], logs: [log]).survey == nil)
  }

  @Test func betterAndWorseNightsAskDifferently() {
    let better = make([night(dayOffset: -1, score: 85), night(dayOffset: -2, score: 60)]).survey
    let worse = make([night(dayOffset: -1, score: 55), night(dayOffset: -2, score: 85)]).survey
    #expect(better == BriefingSurvey(isPositive: true, chips: LifestyleChip.positive))
    #expect(worse == BriefingSurvey(isPositive: false, chips: LifestyleChip.negative))
  }

  // MARK: - Profile nudge

  @Test func anIncompleteProfileIsNudged() {
    #expect(make([], profile: SleepProfile()).profileNudge)
    #expect(!make([], profile: nil).profileNudge)
  }
}

struct BriefingRulesTests {
  let now = Date(timeIntervalSinceReferenceDate: 815_000_000)
  var calendar: Calendar {
    var calendar = Calendar(identifier: .gregorian)
    calendar.timeZone = TimeZone(identifier: "UTC")!
    return calendar
  }

  func night(endingHoursAgo hours: Double) -> NightSummary {
    let end = now.addingTimeInterval(-hours * 3600)
    return NightSummary(id: UUID(), start: end.addingTimeInterval(-8 * 3600), end: end, score: 80, snoringDuration: 0, eventCount: 0)
  }

  @Test func dueOncePerNewNight() {
    let latest = night(endingHoursAgo: 30)
    #expect(BriefingSchedule.isDue(latest: latest, lastShown: nil, now: now, calendar: calendar))
    #expect(!BriefingSchedule.isDue(latest: latest, lastShown: latest.end.addingTimeInterval(60), now: now, calendar: calendar))
    #expect(BriefingSchedule.isDue(latest: latest, lastShown: latest.end.addingTimeInterval(-60), now: now, calendar: calendar))
    #expect(!BriefingSchedule.isDue(latest: nil, lastShown: nil, now: now, calendar: calendar))
  }

  @Test func notForANightStartedToday() {
    let today = NightSummary(id: UUID(), start: now.addingTimeInterval(-60), end: now, score: 80, snoringDuration: 0, eventCount: 0)
    #expect(!BriefingSchedule.isDue(latest: today, lastShown: nil, now: now, calendar: calendar))
  }

  @Test func profilePromptRule() {
    #expect(ProfilePrompt.shouldShow(fullNights: 3, completion: 0.2, dismissCount: 0, roll: 0.99, coin: true))
    #expect(!ProfilePrompt.shouldShow(fullNights: 2, completion: 0.2, dismissCount: 0, roll: 0, coin: true))
    #expect(!ProfilePrompt.shouldShow(fullNights: 3, completion: 0.5, dismissCount: 0, roll: 0, coin: true))
    #expect(!ProfilePrompt.shouldShow(fullNights: 3, completion: 0.2, dismissCount: 0, roll: 0, coin: false))
    #expect(ProfilePrompt.shouldShow(fullNights: 3, completion: 0.2, dismissCount: 2, roll: 0.2, coin: true))
    #expect(!ProfilePrompt.shouldShow(fullNights: 3, completion: 0.2, dismissCount: 2, roll: 0.3, coin: true))
  }

  @Test func chipsMapToSleepGuardsFlags() {
    let log = LifestyleLog(night: now, chips: [.lateCaffeine, .exercised, .sleptEarlier])
    #expect(log.hadCaffeineLate && log.exercised)
    #expect(!log.hadAlcohol && !log.stressfulDay && !log.lateMeal && !log.screenBeforeBed)
    #expect(log.chips.contains(.sleptEarlier))
  }
}
