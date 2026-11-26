import Foundation
import SleepCore
import SleepStrings

/// The briefing's values as text (the strings SleepGuard's engine used to
/// build). `%@` is filled in order without `String(format:)`, as before.
enum BriefingText {
  static func greeting(_ greeting: BriefingGreeting) -> String {
    let (named, plain): (String, String) = switch greeting.part {
    case .morning: (Strings.briefingGreetingMorning, Strings.briefingGreetingMorningNoName)
    case .afternoon: (Strings.briefingGreetingAfternoon, Strings.briefingGreetingAfternoonNoName)
    case .evening: (Strings.briefingGreetingEvening, Strings.briefingGreetingEveningNoName)
    case .night: (Strings.briefingGreetingNight, Strings.briefingGreetingNightNoName)
    }
    guard let name = greeting.name else { return plain }
    return fill(named, name)
  }

  static func headline(_ headline: BriefingHeadline) -> String {
    switch headline {
    case .welcome:
      Strings.briefingHeadlineWelcome
    case let .quiet(duration, isLastNight):
      fill(isLastNight ? Strings.briefingHeadlineQuiet : Strings.briefingHeadlineQuietLastTime, self.duration(duration))
    case let .normal(duration, minutes, score, isLastNight):
      fill(
        isLastNight ? Strings.briefingHeadlineNormal : Strings.briefingHeadlineNormalLastTime,
        self.duration(duration), "\(minutes)", "\(score)")
    case let .weeklySnoring(minutes, average, isLastNight):
      fill(
        isLastNight ? Strings.briefingHeadlineWeeklySnoring : Strings.briefingHeadlineWeeklySnoringLastTime,
        "\(minutes)", "\(average)")
    case let .weeklyScore(score, average, isLastNight):
      fill(
        isLastNight ? Strings.briefingHeadlineWeeklyScore : Strings.briefingHeadlineWeeklyScoreLastTime,
        "\(score)", "\(average)")
    case let .weeklyDuration(duration, average, isLastNight):
      fill(
        isLastNight ? Strings.briefingHeadlineWeeklyDuration : Strings.briefingHeadlineWeeklyDurationLastTime,
        self.duration(duration), self.duration(average))
    case let .combinedScoreSnoring(score, averageScore, minutes, averageMinutes):
      fill(Strings.briefingHeadlineCombinedScoreSnoring, "\(score)", "\(averageScore)", "\(minutes)", "\(averageMinutes)")
    case let .combinedDurationScore(duration, averageDuration, score, averageScore):
      fill(
        Strings.briefingHeadlineCombinedDurationScore, self.duration(duration), self.duration(averageDuration),
        "\(score)", "\(averageScore)")
    }
  }

  static func label(_ label: BriefingStat.Label) -> String {
    switch label {
    case .sleep: Strings.briefingStatSleep
    case .snoring: Strings.briefingStatSnoring
    case .score: Strings.briefingStatScore
    case .lastNight: Strings.briefingStatLastNight
    case .lastTime: Strings.briefingStatLastTime
    case .weeklyAverage: Strings.briefingStatWeeklyAvg
    case .trend: Strings.briefingStatTrend
    }
  }

  static func value(_ value: BriefingStat.Value) -> String {
    switch value {
    case let .duration(seconds): duration(seconds)
    case let .minutes(minutes): "\(minutes)m"
    case let .points(points): "\(points)"
    case let .minutesChange(minutes): minutes > 0 ? "+\(minutes)m" : "\(minutes)m"
    case let .pointsChange(points): points > 0 ? "+\(points)" : "\(points)"
    }
  }

  static func icon(_ label: BriefingStat.Label) -> String {
    switch label {
    case .sleep: "bed.double.fill"
    case .snoring: "waveform"
    case .score: "star.fill"
    default: "chart.bar.fill"
    }
  }

  static func insight(_ parts: [BriefingInsight]) -> String? {
    guard !parts.isEmpty else { return nil }
    return parts.map(insight).joined(separator: " ")
  }

  static func insight(_ part: BriefingInsight) -> String {
    switch part {
    case let .improving(score, average): fill(Strings.briefingInsightImproving, "\(score)", "\(average)")
    case let .declining(score, average): fill(Strings.briefingInsightDeclining, "\(score)", "\(average)")
    case let .steady(average): fill(Strings.briefingInsightSteady, "\(average)")
    case let .goalShortfall(hours, minutes, short, target):
      fill(Strings.briefingInsightGoalShortfall, "\(hours)", "\(minutes)", "\(short)", "\(target)")
    case let .weeklySnoringUp(minutes): fill(Strings.briefingInsightWeeklySnoringUp, "\(minutes)")
    case let .weeklySnoringDown(minutes): fill(Strings.briefingInsightWeeklySnoringDown, "\(minutes)")
    case let .weeklyScoreUp(points): fill(Strings.briefingInsightWeeklyScoreUp, "\(points)")
    case let .weeklyScoreDown(points): fill(Strings.briefingInsightWeeklyScoreDown, "\(points)")
    case let .weeklyDurationUp(minutes): fill(Strings.briefingInsightWeeklyDurationUp, "\(minutes)m")
    case let .weeklyDurationDown(minutes): fill(Strings.briefingInsightWeeklyDurationDown, "\(minutes)m")
    }
  }

  /// The closing line for how the night compares.
  static func quote(_ trend: BriefingTrend) -> String {
    switch trend {
    case .improving: Strings.briefingQuoteImproving
    case .declining: Strings.briefingQuoteDeclining
    case .steady: Strings.briefingQuoteSteady
    case .firstNight: Strings.briefingQuoteFirstNight
    case .noData: Strings.briefingQuoteNoData
    case .returningAfterGap: Strings.briefingQuoteReturningAfterGap
    }
  }

  static func surveyTitle(_ survey: BriefingSurvey) -> String {
    survey.isPositive ? Strings.briefingSurveyPositiveTitle : Strings.briefingSurveyNegativeTitle
  }

  static func chip(_ chip: LifestyleChip) -> String {
    switch chip {
    case .exercised: Strings.briefingSurveyChipExercised
    case .lessCaffeine: Strings.briefingSurveyChipLessCaffeine
    case .noAlcohol: Strings.briefingSurveyChipNoAlcohol
    case .sleptEarlier: Strings.briefingSurveyChipSleptEarlier
    case .lessStress: Strings.briefingSurveyChipLessStress
    case .lateCaffeine: Strings.briefingSurveyChipLateCaffeine
    case .alcohol: Strings.briefingSurveyChipAlcohol
    case .stressfulDay: Strings.briefingSurveyChipStressfulDay
    case .lateMeal: Strings.briefingSurveyChipLateMeal
    case .screensInBed: Strings.briefingSurveyChipScreensInBed
    }
  }

  /// "7h 30m", or "45m" under an hour.
  static func duration(_ seconds: TimeInterval) -> String {
    let hours = Int(seconds) / 3600
    let minutes = (Int(seconds) % 3600) / 60
    return hours > 0 ? "\(hours)h \(minutes)m" : "\(minutes)m"
  }

  /// Replaces each `%@` in turn.
  static func fill(_ template: String, _ values: String...) -> String {
    var result = template
    for value in values {
      if let range = result.range(of: "%@") { result.replaceSubrange(range, with: value) }
    }
    return result
  }
}
