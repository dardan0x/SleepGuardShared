import SleepCore
import SwiftUI
import SleepGuardDesignKit

/// The sleep-stage card and sheet with a sample night, for previews and
/// render tests. Internal: sample data only.
struct SleepStagesContentGallery: View {
  enum Screen: CaseIterable {
    case card
    /// A night short on deep sleep and restless: badges and a penalty.
    case info
    case infoOnTarget
  }

  let screen: Screen

  static let start = Date(timeIntervalSinceReferenceDate: 815_000_000)
  static let duration: TimeInterval = 7.5 * 3600

  /// Ninety-minute cycles of light, deep, light, REM and a moment awake.
  static func segments(deep: TimeInterval = 20, awake: TimeInterval = 5) -> [SleepStageSegment] {
    let cycle: [(SleepStage, TimeInterval)] = [(.light, 30), (.deep, deep), (.light, 15), (.rem, 20), (.awake, awake)]
    var offset: TimeInterval = 0
    var segments: [SleepStageSegment] = []
    while offset < duration {
      for (stage, minutes) in cycle where offset < duration {
        segments.append(SleepStageSegment(stage: stage, startOffset: offset, duration: minutes * 60))
        offset += minutes * 60
      }
    }
    return segments
  }

  var body: some View {
    Group {
      switch screen {
      case .card:
        if let breakdown = SleepStageBreakdown(segments: Self.segments()) {
          SleepStagesCard(breakdown: breakdown, start: Self.start, duration: Self.duration) {}
            .padding(.vertical, 16)
        }
      case .info:
        if let breakdown = SleepStageBreakdown(segments: Self.segments(deep: 8, awake: 14)) {
          SleepStagesInfoStack(breakdown: breakdown, config: .default) {}
        }
      case .infoOnTarget:
        if let breakdown = SleepStageBreakdown(segments: Self.segments()) {
          SleepStagesInfoStack(breakdown: breakdown, config: .default) {}
        }
      }
    }
    .background(SleepStagesBackground())
  }
}

private struct SleepStagesBackground: View {
  @Environment(\.theme) private var theme

  var body: some View {
    theme.palette.bgPrimary
  }
}

#Preview("Card") {
  SleepStagesContentGallery(screen: .card)
}

#Preview("Info") {
  SleepStagesInfoContent(breakdown: SleepStageBreakdown(segments: SleepStagesContentGallery.segments(deep: 8, awake: 14))!) {}
}
