import Foundation

/// Spelled-out durations, as SleepGuard writes them.
public enum DurationText {
  /// "7h 12 mins", or "45 mins" under an hour.
  public static func hoursAndMinutes(_ interval: TimeInterval) -> String {
    let minutes = Int(interval / 60)
    let (hours, mins) = (minutes / 60, minutes % 60)
    let minLabel = mins == 1 ? Strings.timeMinuteSingular : Strings.timeMinutePlural
    guard hours > 0 else { return "\(mins) \(minLabel)" }
    let hourLabel = hours == 1 ? Strings.timeHourSingular : Strings.timeHourPlural
    return "\(hours)\(hourLabel) \(mins) \(minLabel)"
  }

  /// "over 1 h 5 mins", "over 12 mins", "over 40 sec".
  public static func over(_ interval: TimeInterval) -> String {
    let total = Int(interval)
    let (hours, minutes, seconds) = (total / 3600, total % 3600 / 60, total % 60)
    let minLabel = minutes == 1 ? Strings.timeMinuteSingular : Strings.timeMinutePlural
    if hours > 0 {
      let hourLabel = hours == 1 ? Strings.timeHourSingular : Strings.timeHourPlural
      return "\(Strings.commonOver) \(hours) \(hourLabel) \(minutes) \(minLabel)"
    }
    if minutes > 0 { return "\(Strings.commonOver) \(minutes) \(minLabel)" }
    return "\(Strings.commonOver) \(seconds) \(Strings.settingsUnitSecondsShort)"
  }
}
