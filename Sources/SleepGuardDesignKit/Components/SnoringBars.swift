import Charts
import SleepCore
import SwiftUI
import SleepStrings

/// One bar of snoring minutes, coloured by the loudest intensity.
public struct SnoringBar: Identifiable, Sendable, Equatable {
  public let id: UUID
  public let label: String
  public let minutes: Int
  public let intensity: SnoreIntensity

  public init(id: UUID = UUID(), label: String, minutes: Int, intensity: SnoreIntensity) {
    self.id = id
    self.label = label
    self.minutes = minutes
    self.intensity = intensity
  }
}

/// Snoring minutes per night as a bar chart (Trends). Bars are placed by
/// label, as SleepGuard's are: nights with the same label stack.
public struct SnoringBarChart: View {
  let bars: [SnoringBar]
  @Environment(\.theme) private var theme

  public init(bars: [SnoringBar]) {
    self.bars = bars
  }

  public var body: some View {
    let palette = theme.palette
    Chart(bars) { bar in
      BarMark(x: .value("Day", bar.label), y: .value("Minutes", bar.minutes))
        .foregroundStyle(palette.eventColor(.snoring, intensity: bar.intensity))
        .cornerRadius(4)
    }
    .frame(height: 120)
    .chartYAxis(.hidden)
    .chartXAxis {
      AxisMarks(values: .automatic) { value in
        AxisValueLabel {
          if let label = value.as(String.self) {
            Text(label)
              .font(theme.typography.font(size: 10, weight: .medium))
              .foregroundStyle(palette.textTertiary)
          }
        }
      }
    }
    .padding(16)
    .overlay(RoundedRectangle(cornerRadius: theme.radii.card).stroke(palette.bgCard, lineWidth: 1))
  }
}

/// "SNORING · MIN": a bar per day scaled to the highest, with the legend (Last 7 Nights).
public struct SnoringDayBars: View {
  let bars: [SnoringBar]
  @Environment(\.theme) private var theme

  public init(bars: [SnoringBar]) {
    self.bars = bars
  }

  public var body: some View {
    let highest = max(bars.map(\.minutes).max() ?? 1, 1)
    VStack(spacing: 12) {
      Text(Strings.statsLast7nightsSnoringMin)
        .font(theme.typography.font(size: 11, weight: .semibold))
        .foregroundStyle(theme.palette.textTertiary)
        .tracking(1)
        .frame(maxWidth: .infinity, alignment: .leading)
      HStack(alignment: .bottom, spacing: 4) {
        ForEach(bars) { bar in
          VStack(spacing: 4) {
            RoundedRectangle(cornerRadius: 3)
              .fill(theme.palette.eventColor(.snoring, intensity: bar.intensity))
              .frame(height: max(CGFloat(bar.minutes) / CGFloat(highest) * 80, 4))
            Text(bar.label)
              .font(theme.typography.font(size: 10, weight: .medium))
              .foregroundStyle(theme.palette.textTertiary)
              .frame(maxWidth: .infinity)
          }
        }
      }
      .frame(height: 100, alignment: .bottom)
      SnoringLegend()
    }
    .padding(16)
    .overlay(RoundedRectangle(cornerRadius: theme.radii.card).stroke(theme.palette.bgCard, lineWidth: 1))
  }
}
