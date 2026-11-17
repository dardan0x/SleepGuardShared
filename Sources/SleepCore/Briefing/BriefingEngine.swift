import Foundation

/// Builds the morning briefing (SleepGuard's rules). With two or more nights
/// it varies what it talks about; the latest night's date picks which, so a
/// night always gets the same briefing.
public enum BriefingEngine {
  enum Mode: CaseIterable {
    case lastNightRecap, weeklySnoring, weeklyScore, weeklyDuration, combinedScoreSnoring, combinedDurationScore
  }

  /// `nights`: recent nights, any order. `logs`: the survey's answers.
  public static func make(
    nights: [NightSummary], profile: SleepProfile?, logs: [LifestyleLog], now: Date,
    calendar: Calendar = .current) -> Briefing
  {
    let name = profile?.firstName.flatMap { $0.isEmpty ? nil : $0 }
    let greeting = BriefingGreeting(part: DayPart(hour: calendar.component(.hour, from: now)), name: name)
    let profileNudge = profile.map { $0.completion < 0.5 } ?? false
    let sorted = nights.sorted { $0.start > $1.start }
    guard let latest = sorted.first else {
      return Briefing(
        greeting: greeting, headline: .welcome, stats: [], insight: [], trend: .noData, profileNudge: profileNudge,
        survey: nil)
    }
    let isLastNight = isLastNight(latest, now: now, calendar: calendar)
    let (headline, stats, insight) = content(
      mode: mode(for: sorted, calendar: calendar), latest: latest, nights: sorted, profile: profile,
      isLastNight: isLastNight)
    return Briefing(
      greeting: greeting, headline: headline, stats: stats, insight: insight,
      trend: trend(sorted, now: now, calendar: calendar), profileNudge: profileNudge,
      survey: survey(latest: latest, nights: sorted, logs: logs, calendar: calendar))
  }

  /// One night: the recap. More: one of the six modes, chosen by the latest
  /// night's day.
  static func mode(for nights: [NightSummary], calendar: Calendar) -> Mode {
    guard nights.count >= 2 else { return .lastNightRecap }
    let day = calendar.ordinality(of: .day, in: .era, for: nights[0].start) ?? 0
    return Mode.allCases[day % Mode.allCases.count]
  }

  static func isLastNight(_ night: NightSummary, now: Date, calendar: Calendar) -> Bool {
    guard let yesterday = calendar.date(byAdding: .day, value: -1, to: calendar.startOfDay(for: now)) else {
      return false
    }
    return calendar.isDate(night.start, inSameDayAs: yesterday)
  }

  /// More than 3 days since the latest: a return. Else ±5 points against the
  /// integer average of the up to 6 nights before it.
  static func trend(_ nights: [NightSummary], now: Date, calendar: Calendar) -> BriefingTrend {
    guard let latest = nights.first else { return .noData }
    guard nights.count > 1 else { return .firstNight }
    let days = calendar.dateComponents(
      [.day], from: calendar.startOfDay(for: latest.start), to: calendar.startOfDay(for: now)).day ?? 0
    if days > 3 { return .returningAfterGap(days: days) }
    let difference = latest.score - averageScore(of: nights.dropFirst().prefix(6))
    if difference > 5 { return .improving }
    if difference < -5 { return .declining }
    return .steady
  }

  // MARK: - Content

  private static func content(
    mode: Mode, latest: NightSummary, nights: [NightSummary], profile: SleepProfile?, isLastNight: Bool)
    -> (BriefingHeadline, [BriefingStat], [BriefingInsight])
  {
    let previous = nights.dropFirst().prefix(6)
    let averageScore = averageScore(of: previous)
    let averageSnoring = previous.map(\.snoringDuration).reduce(0, +) / Double(max(previous.count, 1))
    let averageDuration = previous.map(\.duration).reduce(0, +) / Double(max(previous.count, 1))
    let snoringMinutes = Int(latest.snoringDuration / 60)
    let durationChange = Int((latest.duration - averageDuration) / 60)
    let when: BriefingStat.Label = isLastNight ? .lastNight : .lastTime

    switch mode {
    case .lastNightRecap:
      let headline: BriefingHeadline = snoringMinutes == 0
        ? .quiet(duration: latest.duration, isLastNight: isLastNight)
        : .normal(duration: latest.duration, snoringMinutes: snoringMinutes, score: latest.score, isLastNight: isLastNight)
      return (
        headline,
        [.init(.sleep, .duration(latest.duration)), .init(.snoring, .minutes(snoringMinutes)), .init(.score, .points(latest.score))],
        insight(nights: nights, profile: profile))
    case .weeklySnoring:
      let average = Int(averageSnoring / 60)
      let change = snoringMinutes - average
      return (
        .weeklySnoring(minutes: snoringMinutes, averageMinutes: average, isLastNight: isLastNight),
        [.init(when, .minutes(snoringMinutes)), .init(.weeklyAverage, .minutes(average)), .init(.trend, .minutesChange(change))],
        [change > 0 ? .weeklySnoringUp(minutes: abs(change)) : .weeklySnoringDown(minutes: abs(change))])
    case .weeklyScore:
      let change = latest.score - averageScore
      return (
        .weeklyScore(score: latest.score, average: averageScore, isLastNight: isLastNight),
        [.init(when, .points(latest.score)), .init(.weeklyAverage, .points(averageScore)), .init(.trend, .pointsChange(change))],
        [change > 0 ? .weeklyScoreUp(points: abs(change)) : .weeklyScoreDown(points: abs(change))])
    case .weeklyDuration:
      return (
        .weeklyDuration(duration: latest.duration, average: averageDuration, isLastNight: isLastNight),
        [
          .init(when, .duration(latest.duration)), .init(.weeklyAverage, .duration(averageDuration)),
          .init(.trend, .minutesChange(durationChange)),
        ],
        [durationChange > 0 ? .weeklyDurationUp(minutes: abs(durationChange)) : .weeklyDurationDown(minutes: abs(durationChange))])
    case .combinedScoreSnoring:
      return (
        .combinedScoreSnoring(
          score: latest.score, averageScore: averageScore, snoringMinutes: snoringMinutes,
          averageSnoringMinutes: Int(averageSnoring / 60)),
        [
          .init(.score, .points(latest.score)), .init(.snoring, .minutes(snoringMinutes)),
          .init(.trend, .pointsChange(latest.score - averageScore)),
        ],
        insight(nights: nights, profile: nil))
    case .combinedDurationScore:
      return (
        .combinedDurationScore(
          duration: latest.duration, averageDuration: averageDuration, score: latest.score, averageScore: averageScore),
        [.init(.sleep, .duration(latest.duration)), .init(.score, .points(latest.score)), .init(.trend, .minutesChange(durationChange))],
        insight(nights: nights, profile: nil))
    }
  }

  /// The score against the recent average, then a sleep goal shortfall of
  /// more than a quarter hour (SleepGuard's rule, its 3-night average included).
  static func insight(nights: [NightSummary], profile: SleepProfile?) -> [BriefingInsight] {
    guard nights.count >= 2 else { return [] }
    let latest = nights[0]
    let recent = nights.dropFirst().prefix(6)
    let average = averageScore(of: recent)
    let difference = latest.score - average
    var parts: [BriefingInsight] = if difference > 5 {
      [.improving(score: latest.score, average: average)]
    } else if difference < -5 {
      [.declining(score: latest.score, average: average)]
    } else {
      [.steady(average: average)]
    }
    if let target = profile?.targetSleepHours, target > 0 {
      let averageDuration = recent.count >= 3
        ? nights.prefix(3).map(\.duration).reduce(0, +) / Double(min(nights.count, 3))
        : latest.duration
      let shortfall = target - averageDuration / 3600
      if shortfall > 0.25 {
        parts.append(.goalShortfall(
          hours: Int(averageDuration / 3600), minutes: (Int(averageDuration) % 3600) / 60,
          shortMinutes: Int(shortfall * 60), targetHours: Int(target)))
      }
    }
    return parts
  }

  /// Two or more nights, and no answer yet for the latest night's day.
  static func survey(
    latest: NightSummary, nights: [NightSummary], logs: [LifestyleLog], calendar: Calendar) -> BriefingSurvey?
  {
    guard nights.count >= 2 else { return nil }
    guard !logs.contains(where: { calendar.isDate($0.night, inSameDayAs: latest.start) }) else { return nil }
    let isPositive = latest.score >= averageScore(of: nights.dropFirst().prefix(6))
    return BriefingSurvey(isPositive: isPositive, chips: isPositive ? LifestyleChip.positive : LifestyleChip.negative)
  }

  private static func averageScore(of nights: ArraySlice<NightSummary>) -> Int {
    nights.map(\.score).reduce(0, +) / max(nights.count, 1)
  }
}
