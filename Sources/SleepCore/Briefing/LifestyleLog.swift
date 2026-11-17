import Foundation

/// An answer to the briefing's survey.
public enum LifestyleChip: String, CaseIterable, Codable, Sendable {
  // After a better night.
  case exercised, lessCaffeine, noAlcohol, sleptEarlier, lessStress
  // After a worse night.
  case lateCaffeine, alcohol, stressfulDay, lateMeal, screensInBed

  public static let positive: [LifestyleChip] = [.exercised, .lessCaffeine, .noAlcohol, .sleptEarlier, .lessStress]
  public static let negative: [LifestyleChip] = [.lateCaffeine, .alcohol, .stressfulDay, .lateMeal, .screensInBed]
}

/// What someone said about a night in the survey. A night with a log isn't
/// asked again.
public struct LifestyleLog: Equatable, Codable, Sendable {
  /// The night it's about (its start).
  public var night: Date
  public var chips: Set<LifestyleChip>

  public init(night: Date, chips: Set<LifestyleChip>) {
    self.night = night
    self.chips = chips
  }

  /// SleepGuard's stored flags. Only six chips have one; the other positive
  /// chips are kept in `chips` alone.
  public var hadCaffeineLate: Bool { chips.contains(.lateCaffeine) }
  public var hadAlcohol: Bool { chips.contains(.alcohol) }
  public var exercised: Bool { chips.contains(.exercised) }
  public var stressfulDay: Bool { chips.contains(.stressfulDay) }
  public var lateMeal: Bool { chips.contains(.lateMeal) }
  public var screenBeforeBed: Bool { chips.contains(.screensInBed) }
}
