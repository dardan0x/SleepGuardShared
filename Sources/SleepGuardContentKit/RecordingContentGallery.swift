import SleepCore
import SwiftUI

/// The recording screens' content with sample values, for previews and render
/// tests. Internal: sample data only. The scrolling parts are drawn on their
/// own: `ImageRenderer` can't draw inside a `ScrollView` (UIKit-backed); the
/// whole screens are in the previews.
struct RecordingContentGallery: View {
  enum Screen: CaseIterable {
    case prestart
    case prestartWithOptions
    case bedside
    case summary
  }

  let screen: Screen
  private static let start = Date(timeIntervalSinceReferenceDate: 815_000_000)

  private static let night = Night(
    start: start, end: start.addingTimeInterval(7 * 3600),
    events: [
      NightEvent(start: start.addingTimeInterval(3600), duration: 600, intensity: .light),
      NightEvent(start: start.addingTimeInterval(9000), duration: 300, intensity: .loud),
    ],
    recordingGaps: [RecordingGap(startOffset: 5000, duration: 240)])

  var body: some View {
    switch screen {
    case .prestart:
      PrestartStack(compact: false, options: EmptyView())
        .background(RecordingContentBackground())
    case .prestartWithOptions:
      PrestartStack(compact: true, options: Text(verbatim: "Options slot").foregroundStyle(.white))
        .background(RecordingContentBackground())
    case .bedside:
      BedsideClockContent(
        time: Self.start.addingTimeInterval(4320), elapsed: 4320, eventCount: 3, db: -38, snoreState: .light,
        onStop: {}, banner: { Text(verbatim: "Banner slot").foregroundStyle(.white) }, overlay: { EmptyView() })
        .frame(height: 760)
    case .summary:
      SessionSummaryStack(night: Self.night, summary: Self.night.summary(), onSave: {}, onDiscard: {})
        .background(RecordingContentBackground())
    }
  }
}

private struct RecordingContentBackground: View {
  @Environment(\.theme) private var theme

  var body: some View {
    theme.palette.bgPrimary
  }
}

#Preview("Prestart") {
  PrestartContent(compact: false, onStart: {}, onCancel: {})
}

#Preview("Bedside clock") {
  RecordingContentGallery(screen: .bedside)
    .environment(\.theme, .previewAlternate)
}

#Preview("Summary") {
  RecordingContentGallery(screen: .summary)
}
