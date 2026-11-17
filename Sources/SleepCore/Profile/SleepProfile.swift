import Foundation

/// What a person tells the app about themselves: kept on the device only, every
/// field optional or with a default. The profile editor edits one; the morning
/// briefing reads it. Each app stores it its own way and maps to this value.
public struct SleepProfile: Codable, Equatable, Sendable {
  public enum BiologicalSex: String, CaseIterable, Codable, Sendable { case unspecified, female, male }
  public enum Goal: String, CaseIterable, Codable, Sendable { case snoreLess, sleepDeeper, moreConsistent, wakeRefreshed }
  public enum Caffeine: String, CaseIterable, Codable, Sendable { case none, light, moderate, heavy }
  public enum Alcohol: String, CaseIterable, Codable, Sendable { case none, occasional, regular }
  /// How often: exercise and screens before bed.
  public enum Frequency: String, CaseIterable, Codable, Sendable { case rarely, sometimes, often }
  public enum Stress: String, CaseIterable, Codable, Sendable { case low, medium, high }
  public enum Occupation: String, CaseIterable, Codable, Sendable { case desk, active, shift, other }

  public var firstName: String?
  public var birthYear: Int?
  public var biologicalSex: BiologicalSex
  public var heightCm: Double?
  public var weightKg: Double?
  /// Only the time of day counts.
  public var targetBedtime: Date?
  public var targetSleepHours: Double?
  public var goal: Goal
  public var caffeine: Caffeine
  public var alcohol: Alcohol
  public var exercise: Frequency
  public var stress: Stress
  public var screensBeforeBed: Frequency
  public var hobbies: [String]
  public var occupation: Occupation

  public init(
    firstName: String? = nil,
    birthYear: Int? = nil,
    biologicalSex: BiologicalSex = .unspecified,
    heightCm: Double? = nil,
    weightKg: Double? = nil,
    targetBedtime: Date? = nil,
    targetSleepHours: Double? = nil,
    goal: Goal = .wakeRefreshed,
    caffeine: Caffeine = .moderate,
    alcohol: Alcohol = .none,
    exercise: Frequency = .sometimes,
    stress: Stress = .medium,
    screensBeforeBed: Frequency = .sometimes,
    hobbies: [String] = [],
    occupation: Occupation = .other)
  {
    self.firstName = firstName
    self.birthYear = birthYear
    self.biologicalSex = biologicalSex
    self.heightCm = heightCm
    self.weightKg = weightKg
    self.targetBedtime = targetBedtime
    self.targetSleepHours = targetSleepHours
    self.goal = goal
    self.caffeine = caffeine
    self.alcohol = alcohol
    self.exercise = exercise
    self.stress = stress
    self.screensBeforeBed = screensBeforeBed
    self.hobbies = hobbies
    self.occupation = occupation
  }

  /// The editor's sleep-hours range and default.
  public static let sleepHoursRange: ClosedRange<Double> = 4...12
  public static let defaultSleepHours = 7.0

  /// Age in `year`, if the birth year is known.
  public func age(in year: Int) -> Int? {
    birthYear.map { year - $0 }
  }

  /// Share of the fields that can be left empty that are filled in (0...1).
  /// The habit fields always have a value, so they don't count.
  public var completion: Double {
    let fields: [Bool] = [
      firstName?.isEmpty == false,
      birthYear != nil,
      biologicalSex != .unspecified,
      heightCm != nil,
      weightKg != nil,
      targetBedtime != nil,
      targetSleepHours != nil,
      !hobbies.isEmpty,
      occupation != .other,
    ]
    return Double(fields.filter(\.self).count) / Double(fields.count)
  }

  /// "reading, running ,," → ["reading", "running"].
  public static func hobbies(from text: String) -> [String] {
    text.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) }.filter { !$0.isEmpty }
  }
}
