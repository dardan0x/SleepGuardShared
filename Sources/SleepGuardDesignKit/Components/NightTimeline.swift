import SleepCore
import SwiftUI
import SleepStrings

/// Something to mark on a night's timeline: a snoring episode or another event.
public struct TimelineMark: Sendable, Equatable {
  public let start: Date
  public let duration: TimeInterval
  public let category: SoundCategory
  public let intensity: SnoreIntensity

  public init(start: Date, duration: TimeInterval, category: SoundCategory, intensity: SnoreIntensity) {
    self.start = start
    self.duration = duration
    self.category = category
    self.intensity = intensity
  }
}

/// "SNORING TIMELINE": the night as a bar with its events in their colours,
/// recording gaps as outlined blanks, and the start and end times below.
/// `showsTitle: false` leaves out the heading (SleepGuard's session summary).
public struct NightTimeline: View {
  let start: Date
  let end: Date
  let marks: [TimelineMark]
  let gaps: [RecordingGap]
  let eventCount: Int
  let snoringDuration: TimeInterval
  let showsTitle: Bool
  @Environment(\.theme) private var theme

  public init(
    start: Date, end: Date, marks: [TimelineMark], gaps: [RecordingGap],
    eventCount: Int, snoringDuration: TimeInterval, showsTitle: Bool = true)
  {
    self.start = start
    self.end = end
    self.marks = marks
    self.gaps = gaps
    self.eventCount = eventCount
    self.snoringDuration = snoringDuration
    self.showsTitle = showsTitle
  }

  public var body: some View {
    VStack(alignment: .leading) {
      if showsTitle {
        Text(Strings.recordingsDetailTimelineLabel)
          .font(theme.typography.font(size: 12, weight: .semibold))
          .foregroundStyle(theme.palette.textTertiary)
          .tracking(1)
      }

      bar

      HStack {
        Text(start.formatted(date: .omitted, time: .shortened))
        Spacer()
        Text(end.formatted(date: .omitted, time: .shortened))
      }
      .font(theme.typography.font(size: 11))
      .foregroundStyle(theme.palette.textTertiary)
    }
  }

  private var bar: some View {
    let length = max(end.timeIntervalSince(start), 1)
    let palette = theme.palette
    return Canvas { context, size in
      context.fill(Path(roundedRect: CGRect(x: 0, y: 0, width: size.width, height: 32), cornerRadius: 8), with: .color(palette.bgCard))
      func rect(from offset: TimeInterval, lasting duration: TimeInterval) -> CGRect {
        CGRect(
          x: CGFloat(offset / length) * size.width, y: 6,
          width: max(CGFloat(max(duration / length, 0.002)) * size.width, 2), height: 20)
      }
      for mark in marks {
        let path = Path(roundedRect: rect(from: mark.start.timeIntervalSince(start), lasting: mark.duration), cornerRadius: 2)
        context.fill(path, with: .color(palette.eventColor(mark.category, intensity: mark.intensity)))
      }
      // Gaps: detection was paused (Snore Interrupter), so nothing is known there.
      for gap in gaps {
        let path = Path(roundedRect: rect(from: gap.startOffset, lasting: gap.duration), cornerRadius: 2)
        context.fill(path, with: .color(palette.textTertiary.opacity(0.18)))
        context.stroke(path, with: .color(palette.textTertiary.opacity(0.35)), lineWidth: 1)
      }
    }
    .frame(height: 34)
    .accessibilityElement()
    .accessibilityLabel(Strings.a11ySnoringTimeline)
    .accessibilityValue(String(
      format: Strings.a11ySnoringTimelineValueFormat, eventCount, DurationText.hoursAndMinutes(snoringDuration)))
  }
}
