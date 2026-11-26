public import Foundation
import SleepStrings
import UserNotifications

/// "Your recording session is starting now", when a night starts after a
/// delay: the same notification, identifier and text in every app. One at a
/// time: scheduling replaces the one before.
public enum StartNotification {
  public static let identifier = "delayed-recording"

  /// The request for a night starting at `date`, at least a second away.
  public static func request(startingAt date: Date, now: Date = Date()) -> UNNotificationRequest {
    let content = UNMutableNotificationContent()
    content.body = Strings.sessionCountdownNotificationBody
    content.sound = .default
    let trigger = UNTimeIntervalNotificationTrigger(timeInterval: max(1, date.timeIntervalSince(now)), repeats: false)
    return UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
  }

  public static func schedule(startingAt date: Date) {
    UNUserNotificationCenter.current().add(request(startingAt: date))
  }

  public static func cancel() {
    UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [identifier])
  }
}
