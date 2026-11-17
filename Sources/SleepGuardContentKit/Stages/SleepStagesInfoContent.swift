import SleepCore
import SleepGuardDesignKit
import SwiftUI

/// The sleep-stages sheet: what each stage is and how this night's compare
/// with the targets, then how the stages change the score. `config` is the
/// score's (SleepGuard's comes from remote config), so the targets and the
/// penalty shown are the ones applied.
public struct SleepStagesInfoContent: View {
  let breakdown: SleepStageBreakdown
  let config: SleepScoreConfig
  let onClose: () -> Void
  @Environment(\.theme) private var theme

  public init(breakdown: SleepStageBreakdown, config: SleepScoreConfig = .default, onClose: @escaping () -> Void) {
    self.breakdown = breakdown
    self.config = config
    self.onClose = onClose
  }

  public var body: some View {
    ScrollView {
      SleepStagesInfoStack(breakdown: breakdown, config: config, onClose: onClose)
    }
    .background(theme.palette.bgPrimary.ignoresSafeArea())
  }
}

/// The sheet without its scroll view (render tests can't draw a ScrollView).
struct SleepStagesInfoStack: View {
  let breakdown: SleepStageBreakdown
  let config: SleepScoreConfig
  let onClose: () -> Void
  @Environment(\.theme) private var theme

  var body: some View {
    VStack(spacing: 24) {
      HStack {
        Text(Strings.sleepStagesInfoTitle)
          .font(theme.typography.font(size: 17, weight: .semibold))
          .foregroundStyle(theme.palette.textPrimary)
        Spacer()
        Button(action: onClose) {
          Label(Strings.actionClose, systemImage: "xmark.circle.fill")
            .labelStyle(.iconOnly)
            .font(.system(size: 22))
            .foregroundStyle(theme.palette.textTertiary)
        }
        .buttonStyle(.plain)
      }
      SleepStagesYourStages(breakdown: breakdown, config: config)
      SleepStagesScoreImpact(breakdown: breakdown, config: config)
    }
    .padding(20)
  }
}

/// One card per stage: share and time, a status badge, the recommended range
/// when off target, and what the stage is.
struct SleepStagesYourStages: View {
  let breakdown: SleepStageBreakdown
  let config: SleepScoreConfig
  @Environment(\.theme) private var theme

  var body: some View {
    VStack(alignment: .leading, spacing: 16) {
      Text(Strings.sleepStagesInfoYourStages)
        .font(theme.typography.font(size: 17, weight: .semibold))
        .foregroundStyle(theme.palette.textPrimary)
      VStack(spacing: 12) {
        ForEach(SleepStage.chartOrder, id: \.self) { stage in
          card(stage)
        }
      }
    }
  }

  private func card(_ stage: SleepStage) -> some View {
    let status = breakdown.status(of: stage, config: config)
    return VStack(alignment: .leading, spacing: 8) {
      HStack(spacing: 10) {
        RoundedRectangle(cornerRadius: 4)
          .fill(theme.palette.stageColor(stage))
          .frame(width: 12, height: 12)
        Text(stage.name)
          .font(theme.typography.font(size: 15, weight: .semibold))
          .foregroundStyle(theme.palette.textPrimary)
        Spacer()
        Text(Self.label(status))
          .font(theme.typography.font(size: 12, weight: .bold))
          .foregroundStyle(color(status))
          .padding(.horizontal, 8)
          .padding(.vertical, 4)
          .background(color(status).opacity(0.15), in: .rect(cornerRadius: 8))
      }
      Text(String(format: "%.0f%% · %@", breakdown.percent(of: stage), DurationText.hoursAndMinutes(breakdown.duration(of: stage))))
        .font(theme.typography.font(size: 13, weight: .medium))
        .foregroundStyle(theme.palette.textSecondary)
      if status != .good {
        Text(String(format: Strings.sleepStagesInfoRecommended, Self.recommendation(stage)))
          .font(theme.typography.font(size: 12, weight: .medium))
          .foregroundStyle(theme.palette.textTertiary)
      }
      Text(Self.description(stage))
        .font(theme.typography.font(size: 13))
        .foregroundStyle(theme.palette.textTertiary)
        .lineLimit(2)
    }
    .padding(16)
    .frame(maxWidth: .infinity, alignment: .leading)
    .background(theme.palette.bgCard, in: .rect(cornerRadius: theme.radii.small))
  }

  private func color(_ status: StageStatus) -> Color {
    switch status {
    case .good: theme.palette.scoreGreen
    case .low: theme.palette.scoreAmber
    case .high: theme.palette.scoreRed
    }
  }

  static func label(_ status: StageStatus) -> String {
    switch status {
    case .good: Strings.sleepStagesInfoStageStatusGood
    case .low: Strings.sleepStagesInfoStageStatusLow
    case .high: Strings.sleepStagesInfoStageStatusHigh
    }
  }

  static func recommendation(_ stage: SleepStage) -> String {
    switch stage {
    case .awake: Strings.sleepStagesInfoRecommendedAwake
    case .rem: Strings.sleepStagesInfoRecommendedRem
    case .light: Strings.sleepStagesInfoRecommendedLight
    case .deep: Strings.sleepStagesInfoRecommendedDeep
    }
  }

  static func description(_ stage: SleepStage) -> String {
    switch stage {
    case .awake: Strings.sleepStagesInfoAwakeDescription
    case .rem: Strings.sleepStagesInfoRemDescription
    case .light: Strings.sleepStagesInfoLightDescription
    case .deep: Strings.sleepStagesInfoDeepDescription
    }
  }
}
