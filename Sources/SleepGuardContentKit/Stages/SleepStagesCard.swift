import SleepCore
import SwiftUI

/// The night's sleep stages: the title with an info button and a collapse
/// chevron, the hypnogram and the legend. The host presents the info sheet
/// (`SleepStagesInfoContent`) on `onInfo`.
public struct SleepStagesCard: View {
  let breakdown: SleepStageBreakdown
  let start: Date
  let duration: TimeInterval
  let onInfo: () -> Void
  @State private var isExpanded = true
  @Environment(\.theme) private var theme

  public init(breakdown: SleepStageBreakdown, start: Date, duration: TimeInterval, onInfo: @escaping () -> Void) {
    self.breakdown = breakdown
    self.start = start
    self.duration = duration
    self.onInfo = onInfo
  }

  public var body: some View {
    VStack(alignment: .leading, spacing: 12) {
      HStack {
        Text(Strings.statisticsSleepStagesLabel)
          .font(theme.typography.font(size: 12, weight: .semibold))
          .foregroundStyle(theme.palette.textTertiary)
          .tracking(1)
        Spacer()
        iconButton(Strings.sleepStagesInfoTitle, systemImage: "info.circle", size: 14, action: onInfo)
        iconButton(
          isExpanded ? Strings.actionCollapse : Strings.actionExpand,
          systemImage: isExpanded ? "chevron.up" : "chevron.down", size: 12)
        {
          withAnimation(.easeInOut(duration: 0.2)) { isExpanded.toggle() }
        }
      }
      if isExpanded {
        SleepStageHypnogram(breakdown: breakdown, start: start, duration: duration)
          .padding(.horizontal, 30)
        SleepStageLegend(breakdown: breakdown)
          .padding(.horizontal, 30)
      }
    }
  }

  private func iconButton(_ title: String, systemImage: String, size: CGFloat, action: @escaping () -> Void) -> some View {
    Button(action: action) {
      Label(title, systemImage: systemImage)
        .labelStyle(.iconOnly)
        .font(theme.typography.font(size: size, weight: .semibold))
        .foregroundStyle(theme.palette.textTertiary)
        .frame(width: 28, height: 28)
        .contentShape(Rectangle())
    }
    .buttonStyle(.plain)
  }
}
