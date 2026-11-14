import SleepCore
import SwiftUI

/// The night-detail components on one screen, for previews and render tests.
/// Internal: sample data only.
struct DetailGallery: View {
  @Environment(\.theme) private var theme

  private static let start = Date(timeIntervalSinceReferenceDate: 815_000_000)
  private static let marks = [
    TimelineMark(start: start.addingTimeInterval(1800), duration: 125, category: .snoring, intensity: .loud),
    TimelineMark(start: start.addingTimeInterval(8400), duration: 120, category: .snoring, intensity: .epic),
    TimelineMark(start: start.addingTimeInterval(12000), duration: 12, category: .sleepTalking, intensity: .quiet),
    TimelineMark(start: start.addingTimeInterval(15600), duration: 4, category: .coughing, intensity: .quiet),
    TimelineMark(start: start.addingTimeInterval(24000), duration: 60, category: .snoring, intensity: .quiet),
  ]

  var body: some View {
    VStack(spacing: 16) {
      SessionStatsGrid(duration: 30240, snoringShare: 0.012, snoreTime: 305, eventCount: 5)
      NightTimeline(
        start: Self.start, end: Self.start.addingTimeInterval(8 * 3600), marks: Self.marks,
        gaps: [RecordingGap(startOffset: 18000, duration: 1800)], eventCount: 5, snoringDuration: 305)
      RecordingGapsBanner(totalGap: 1800)
      LowBatteryBanner()
      ForEach(Array(Self.marks.prefix(3).enumerated()), id: \.offset) { index, mark in
        EventRow(
          start: mark.start, duration: mark.duration, category: mark.category, intensity: mark.intensity,
          onPlay: index == 0 ? {} : nil, onShare: index == 0 ? {} : nil)
      }
      Grid(horizontalSpacing: 12) {
        GridRow {
          ForEach(Array(Self.marks.prefix(3).enumerated()), id: \.offset) { index, mark in
            EventCard(
              start: mark.start, duration: mark.duration, category: mark.category, intensity: mark.intensity,
              onPlay: index == 0 ? {} : nil)
          }
        }
      }
      HStack(spacing: 12) {
        ScoreBadge(score: 86, size: 40)
        ScoreBadge(score: 64, size: 40)
        ScoreBadge(score: 31, size: 40)
      }
      NightRow(start: Self.start, end: Self.start.addingTimeInterval(7 * 3600), eventCount: 4, score: 86) {}
        .background(theme.palette.bgCard, in: .rect(cornerRadius: theme.radii.card))
    }
    .padding(16)
    .background(theme.palette.bgPrimary)
  }
}

#Preview("SleepGuard") {
  DetailGallery()
}

#Preview("Alternate theme") {
  DetailGallery()
    .environment(\.theme, .previewAlternate)
}
