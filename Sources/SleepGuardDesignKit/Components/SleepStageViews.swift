import SleepCore
import SwiftUI
import SleepStrings

public extension Palette {
  func stageColor(_ stage: SleepStage) -> Color {
    switch stage {
    case .deep: stageDeep
    case .light: stageLight
    case .rem: stageREM
    case .awake: stageAwake
    }
  }
}

public extension SleepStage {
  /// Awake at the top, deep at the bottom: the hypnogram's rows and the
  /// order the stage cards list them.
  static let chartOrder: [SleepStage] = [.awake, .rem, .light, .deep]
}

/// The night's stages as coloured bands, one row per stage (awake at the
/// top), with the hours under it. One accessibility element: "Deep 18%, …".
public struct SleepStageHypnogram: View {
  let breakdown: SleepStageBreakdown
  let start: Date
  let duration: TimeInterval
  @Environment(\.theme) private var theme

  public init(breakdown: SleepStageBreakdown, start: Date, duration: TimeInterval) {
    self.breakdown = breakdown
    self.start = start
    self.duration = duration
  }

  public var body: some View {
    Canvas { context, size in
      let chartHeight = size.height - 16
      let bandHeight = chartHeight / 4
      for row in 1..<4 {
        var line = Path()
        line.move(to: CGPoint(x: 0, y: CGFloat(row) * bandHeight))
        line.addLine(to: CGPoint(x: size.width, y: CGFloat(row) * bandHeight))
        context.stroke(line, with: .color(theme.palette.border.opacity(0.4)), lineWidth: 0.5)
      }
      let total = max(duration, 1)
      for segment in breakdown.segments {
        let row = SleepStage.chartOrder.firstIndex(of: segment.stage) ?? 0
        let rect = CGRect(
          x: segment.startOffset / total * size.width, y: CGFloat(row) * bandHeight,
          width: max(max(segment.duration / total, 0.001) * size.width, 1), height: bandHeight)
        context.fill(Path(roundedRect: rect, cornerRadius: 2), with: .color(theme.palette.stageColor(segment.stage)))
      }
      for marker in Self.hourMarkers(start: start, duration: duration) {
        let label = Text(marker.label)
          .font(theme.typography.font(size: 11, weight: .medium))
          .foregroundColor(theme.palette.textTertiary)
        let x = min(max(marker.ratio * size.width, 8), size.width - 8)
        context.draw(label, at: CGPoint(x: x, y: chartHeight + 10), anchor: .center)
      }
    }
    .frame(height: 100)
    .accessibilityElement()
    .accessibilityLabel(Strings.a11ySleepStagesChart)
    .accessibilityValue(Self.summary(breakdown))
  }

  /// "Deep 18%, REM 22%, Light 52%, Awake 8%" for VoiceOver.
  static func summary(_ breakdown: SleepStageBreakdown) -> String {
    [(SleepStage.deep, Strings.sleepStageDeep), (.rem, Strings.sleepStageRem), (.light, Strings.sleepStageLight),
     (.awake, Strings.sleepStageAwake)]
      .map { "\($1) \(Int(breakdown.percent(of: $0).rounded()))%" }
      .joined(separator: ", ")
  }

  /// Each full hour inside the night: its "HH" label and where it falls (0...1).
  static func hourMarkers(start: Date, duration: TimeInterval, calendar: Calendar = .current) -> [(label: String, ratio: CGFloat)] {
    guard duration > 0 else { return [] }
    var components = calendar.dateComponents([.year, .month, .day, .hour], from: start)
    components.hour = (components.hour ?? 0) + 1
    guard var hour = calendar.date(from: components) else { return [] }
    let end = start.addingTimeInterval(duration)
    var markers: [(String, CGFloat)] = []
    while hour < end {
      markers.append((String(format: "%02d", calendar.component(.hour, from: hour)), hour.timeIntervalSince(start) / duration))
      hour = hour.addingTimeInterval(3600)
    }
    return markers
  }
}

/// Two columns under the hypnogram: each stage's colour and time.
public struct SleepStageLegend: View {
  let breakdown: SleepStageBreakdown
  @Environment(\.theme) private var theme

  public init(breakdown: SleepStageBreakdown) {
    self.breakdown = breakdown
  }

  public var body: some View {
    Grid(horizontalSpacing: 16, verticalSpacing: 10) {
      GridRow {
        item(.awake)
        item(.light)
      }
      GridRow {
        item(.rem)
        item(.deep)
      }
    }
    .frame(maxWidth: .infinity)
  }

  private func item(_ stage: SleepStage) -> some View {
    HStack(spacing: 8) {
      RoundedRectangle(cornerRadius: 4)
        .fill(theme.palette.stageColor(stage))
        .frame(width: 12, height: 12)
      Text("\(stage.name): \(DurationText.hoursAndMinutes(breakdown.duration(of: stage)))")
        .font(theme.typography.font(size: 13, weight: .medium))
        .foregroundStyle(theme.palette.textSecondary)
    }
    .frame(maxWidth: .infinity)
  }
}

public extension SleepStage {
  /// "Deep Sleep", "REM", "Light Sleep", "Awake": the stage cards' and the
  /// legend's names.
  var name: String {
    switch self {
    case .awake: Strings.sleepStageAwake
    case .rem: Strings.sleepStageRem
    case .light: Strings.sleepStageLightSleep
    case .deep: Strings.sleepStageDeepSleep
    }
  }
}
