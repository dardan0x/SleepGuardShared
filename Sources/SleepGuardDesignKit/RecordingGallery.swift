import SleepCore
import SwiftUI

/// The recording components on one screen, for previews and render tests.
/// Internal: sample data only.
struct RecordingGallery: View {
  @Environment(\.theme) private var theme
  private static let time = Date(timeIntervalSinceReferenceDate: 815_000_000)
  private static let night = Night(
    start: time, end: time.addingTimeInterval(7 * 3600),
    events: [
      NightEvent(start: time.addingTimeInterval(3600), duration: 600, intensity: .light),
      NightEvent(start: time.addingTimeInterval(4300), duration: 300, intensity: .loud),
      NightEvent(start: time.addingTimeInterval(14400), duration: 40, category: .sleepTalking, intensity: .quiet),
    ])

  var body: some View {
    VStack(spacing: 24) {
      PrestartHeader()
      PrestartTipsCard()
      BedsideEventsBadge(count: 3)
      BedsideClockFace(time: Self.time)
      BedsideRecordingStatus(elapsed: 4320, db: -38, time: Self.time)
      HStack(spacing: 16) {
        BedsideSnoreStatus(state: .none)
        BedsideSnoreStatus(state: .light)
        BedsideSnoreStatus(state: .epic)
      }
      SessionSummaryHeader(duration: 26100, score: 82, snoringPercent: 12, eventCount: 14)
      NightTimeline(night: Self.night, showsTitle: false)
      SessionSummaryActions(onSave: {}, onDiscard: {})
    }
    .padding(24)
    .background(theme.palette.bgPrimary)
  }
}

#Preview("SleepGuard") {
  ScrollView { RecordingGallery() }
}

#Preview("Alternate theme") {
  ScrollView { RecordingGallery() }
    .environment(\.theme, .previewAlternate)
}
