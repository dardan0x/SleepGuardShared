import Foundation

/// The morning briefing, as values: the view turns each into text. Built by
/// `BriefingEngine` from the recent nights, the profile and the lifestyle logs.
public struct Briefing: Equatable, Sendable {
  public var greeting: BriefingGreeting
  public var headline: BriefingHeadline
  public var stats: [BriefingStat]
  /// One or two sentences (a comparison, then a goal shortfall), in order.
  public var insight: [BriefingInsight]
  /// How the latest night compares; the closing quote follows from it.
  public var trend: BriefingTrend
  /// The profile is under half complete: suggest finishing it.
  public var profileNudge: Bool
  /// "What did you do differently?", once per night.
  public var survey: BriefingSurvey?

  public init(
    greeting: BriefingGreeting, headline: BriefingHeadline, stats: [BriefingStat], insight: [BriefingInsight],
    trend: BriefingTrend, profileNudge: Bool, survey: BriefingSurvey?)
  {
    self.greeting = greeting
    self.headline = headline
    self.stats = stats
    self.insight = insight
    self.trend = trend
    self.profileNudge = profileNudge
    self.survey = survey
  }
}

/// The time of day the briefing is read at.
public enum DayPart: Equatable, Sendable {
  case morning, afternoon, evening, night

  /// 5–11 morning, 12–17 afternoon, 18–22 evening, else night (SleepGuard's hours).
  public init(hour: Int) {
    self = switch hour {
    case 5..<12: .morning
    case 12..<18: .afternoon
    case 18..<23: .evening
    default: .night
    }
  }
}

public struct BriefingGreeting: Equatable, Sendable {
  public var part: DayPart
  /// The profile's first name, when it has one.
  public var name: String?

  public init(part: DayPart, name: String?) {
    self.part = part
    self.name = name
  }
}

/// How the latest night compares with the ones before it.
public enum BriefingTrend: Equatable, Sendable {
  case improving
  case declining
  case steady
  case firstNight
  case noData
  case returningAfterGap(days: Int)
}

/// The briefing's opening line. `isLastNight`: the night started yesterday
/// ("last night"), otherwise "last time".
public enum BriefingHeadline: Equatable, Sendable {
  case welcome
  case quiet(duration: TimeInterval, isLastNight: Bool)
  case normal(duration: TimeInterval, snoringMinutes: Int, score: Int, isLastNight: Bool)
  case weeklySnoring(minutes: Int, averageMinutes: Int, isLastNight: Bool)
  case weeklyScore(score: Int, average: Int, isLastNight: Bool)
  case weeklyDuration(duration: TimeInterval, average: TimeInterval, isLastNight: Bool)
  case combinedScoreSnoring(score: Int, averageScore: Int, snoringMinutes: Int, averageSnoringMinutes: Int)
  case combinedDurationScore(duration: TimeInterval, averageDuration: TimeInterval, score: Int, averageScore: Int)
}

/// One labelled number on the recap card.
public struct BriefingStat: Equatable, Sendable {
  public enum Label: Equatable, Sendable {
    case sleep, snoring, score, lastNight, lastTime, weeklyAverage, trend
  }

  public enum Value: Equatable, Sendable {
    /// "7h 30m".
    case duration(TimeInterval)
    /// "12m".
    case minutes(Int)
    /// "82".
    case points(Int)
    /// "+12m" / "-4m".
    case minutesChange(Int)
    /// "+6" / "-3".
    case pointsChange(Int)
  }

  public var label: Label
  public var value: Value

  public init(_ label: Label, _ value: Value) {
    self.label = label
    self.value = value
  }
}

public enum BriefingInsight: Equatable, Sendable {
  case improving(score: Int, average: Int)
  case declining(score: Int, average: Int)
  case steady(average: Int)
  /// Averaging `hours`h `minutes`m, `shortMinutes` short of a `targetHours`h goal.
  case goalShortfall(hours: Int, minutes: Int, shortMinutes: Int, targetHours: Int)
  case weeklySnoringUp(minutes: Int)
  case weeklySnoringDown(minutes: Int)
  case weeklyScoreUp(points: Int)
  case weeklyScoreDown(points: Int)
  case weeklyDurationUp(minutes: Int)
  case weeklyDurationDown(minutes: Int)
}

/// The survey after a night: after a better one, what went right; after a
/// worse one, what was unusual.
public struct BriefingSurvey: Equatable, Sendable {
  public var isPositive: Bool
  public var chips: [LifestyleChip]

  public init(isPositive: Bool, chips: [LifestyleChip]) {
    self.isPositive = isPositive
    self.chips = chips
  }
}
