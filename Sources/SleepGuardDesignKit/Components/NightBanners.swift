import SwiftUI

/// Shown when the Snore Interrupter paused detection: how long in total.
public struct RecordingGapsBanner: View {
  let totalGap: TimeInterval
  @Environment(\.theme) private var theme

  public init(totalGap: TimeInterval) {
    self.totalGap = totalGap
  }

  public var body: some View {
    InfoBanner(
      icon: "speaker.wave.2.fill", iconColor: theme.palette.accent,
      text: String(format: Strings.sessionSummaryMelodyGapsTimeInfo, DurationText.over(totalGap)))
  }
}

/// Shown when capture was interrupted (a call, another app): how long nothing
/// was measured, and that the score leaves it out.
public struct InterruptionGapsBanner: View {
  let totalGap: TimeInterval
  @Environment(\.theme) private var theme

  public init(totalGap: TimeInterval) {
    self.totalGap = totalGap
  }

  public var body: some View {
    InfoBanner(
      icon: "phone.fill", iconColor: theme.palette.textTertiary,
      text: String(format: Strings.sessionSummaryInterruptionsTimeInfo, DurationText.over(totalGap)))
  }
}

/// Shown when the night was saved early because the battery ran low.
public struct LowBatteryBanner: View {
  @Environment(\.theme) private var theme

  public init() {}

  public var body: some View {
    InfoBanner(icon: "bolt.fill", iconColor: theme.palette.scoreAmber, text: Strings.sessionSummaryLowBatteryForceSaveInfo)
  }
}

struct InfoBanner: View {
  let icon: String
  let iconColor: Color
  let text: String
  @Environment(\.theme) private var theme

  var body: some View {
    HStack(spacing: 10) {
      Image(systemName: icon)
        .font(.system(size: 14))
        .foregroundStyle(iconColor)
        .accessibilityHidden(true)
      Text(text)
        .font(theme.typography.font(size: 13, weight: .medium))
        .foregroundStyle(theme.palette.textSecondary)
        .fixedSize(horizontal: false, vertical: true)
      Spacer()
    }
    .padding(.horizontal, 14)
    .padding(.vertical, 12)
    .background(theme.palette.bgCard, in: .rect(cornerRadius: theme.radii.small))
  }
}
