import Foundation

/// The wait before a night starts recording, for someone who needs time to
/// fall asleep. The app counts down, keeps the microphone warm and starts the
/// night when the countdown reaches zero.
public enum RecordingDelay {
  /// The choices on the prestart screen, in minutes. 0 is off.
  public static let options = [0, 15, 30, 45, 60]

  /// A stored value that isn't one of the options becomes off.
  public static func valid(_ minutes: Int) -> Int {
    options.contains(minutes) ? minutes : 0
  }

  /// Whole seconds left until `target`, never below zero.
  public static func secondsLeft(until target: Date, now: Date) -> Int {
    max(0, Int(target.timeIntervalSince(now).rounded(.up)))
  }

  /// "29:59": minutes and seconds, two digits each.
  public static func countdownText(seconds: Int) -> String {
    let seconds = max(0, seconds)
    return String(format: "%02d:%02d", seconds / 60, seconds % 60)
  }
}
