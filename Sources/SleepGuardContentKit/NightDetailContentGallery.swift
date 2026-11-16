import SleepCore
import SwiftUI

/// The night detail and events grid with a sample night, for previews and
/// render tests. Internal: sample data only.
struct NightDetailContentGallery: View {
  enum Screen: CaseIterable {
    case detail
    case detailWithSlots
    case eventsGrid
  }

  let screen: Screen
  @State private var filter = EventFilter.all

  private static let start = Date(timeIntervalSinceReferenceDate: 815_000_000)

  static let night: Night = {
    func event(_ minutes: Double, _ duration: TimeInterval, _ category: SoundCategory = .snoring, _ intensity: SnoreIntensity = .light) -> NightEvent {
      NightEvent(start: start.addingTimeInterval(minutes * 60), duration: duration, category: category, intensity: intensity)
    }
    return Night(
      start: start, end: start.addingTimeInterval(7.5 * 3600),
      events: [
        event(40, 30), event(41, 90, .snoring, .loud), event(120, 60), event(200, 45, .snoring, .epic),
        event(260, 12, .sleepTalking, .quiet), event(300, 4, .coughing, .quiet), event(380, 75), event(420, 20, .noise, .quiet),
      ],
      recordingGaps: [RecordingGap(startOffset: 3600, duration: 300)],
      endReason: .lowBattery)
  }()

  var body: some View {
    let night = Self.night
    Group {
      switch screen {
      case .detail:
        NightDetailContent(
          night: night, summary: night.summary(), filters: EventFilter.options(for: night.events), filter: $filter,
          onPlay: { _ in }, onShowAll: { _ in })
      case .detailWithSlots:
        NightDetailContent(
          night: night, summary: night.summary(), filters: EventFilter.options(for: night.events), filter: $filter,
          onPlay: { _ in }, onShowAll: { _ in }, onShare: { _ in },
          stages: { Text(verbatim: "Stages slot") },
          footer: { Text(verbatim: "Footer slot") })
      case .eventsGrid:
        EventsGridContent(rows: EventListRow.rows(for: night)) { _ in }
      }
    }
    .background(NightDetailBackground())
  }
}

private struct NightDetailBackground: View {
  @Environment(\.theme) private var theme

  var body: some View {
    theme.palette.bgPrimary
  }
}

#Preview("Night detail") {
  ScrollView { NightDetailContentGallery(screen: .detail) }
}

#Preview("Events grid") {
  ScrollView { NightDetailContentGallery(screen: .eventsGrid) }
    .environment(\.theme, .previewAlternate)
}
