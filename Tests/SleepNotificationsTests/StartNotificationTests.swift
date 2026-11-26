import Foundation
import Testing
import UserNotifications
@testable import SleepNotifications

struct StartNotificationTests {
  @Test func oneRequestAtTheStartAtLeastASecondAway() throws {
    let now = Date(timeIntervalSinceReferenceDate: 0)
    let request = StartNotification.request(startingAt: now.addingTimeInterval(900), now: now)
    #expect(request.identifier == StartNotification.identifier)
    #expect(!request.content.body.isEmpty)
    let trigger = try #require(request.trigger as? UNTimeIntervalNotificationTrigger)
    #expect(trigger.timeInterval == 900)
    let past = try #require(StartNotification.request(startingAt: now, now: now).trigger as? UNTimeIntervalNotificationTrigger)
    #expect(past.timeInterval == 1)
  }
}
