import Foundation

/// When the briefing opens: once per new night, the morning after.
public enum BriefingSchedule {
  /// There's a scored night, it didn't start today, and the briefing hasn't
  /// been shown since it ended.
  public static func isDue(latest: NightSummary?, lastShown: Date?, now: Date, calendar: Calendar = .current) -> Bool {
    guard let latest else { return false }
    guard !calendar.isDate(latest.start, inSameDayAs: now) else { return false }
    guard let lastShown else { return true }
    return lastShown < latest.end
  }
}

/// The card on Statistics that asks for the profile.
public enum ProfilePrompt {
  /// After three full nights, while the profile is under half complete. Each
  /// dismissal halves the chance it comes back (never zero), then a coin flip,
  /// as SleepGuard does. `roll` and `coin` are drawn once per appearance, so
  /// the card doesn't flicker as the screen redraws.
  public static func shouldShow(fullNights: Int, completion: Double, dismissCount: Int, roll: Double, coin: Bool) -> Bool {
    guard fullNights >= 3, completion < 0.5 else { return false }
    return coin && roll < pow(0.5, Double(max(dismissCount, 0)))
  }
}
