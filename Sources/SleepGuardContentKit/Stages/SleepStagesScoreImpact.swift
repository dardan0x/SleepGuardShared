import SleepCore
import SwiftUI
import SleepGuardDesignKit
import SleepStrings

/// How the stages change the score: the formula, this night's penalty, and
/// deep, REM and awake against their targets.
struct SleepStagesScoreImpact: View {
  let breakdown: SleepStageBreakdown
  let config: SleepScoreConfig
  @Environment(\.theme) private var theme

  var body: some View {
    VStack(alignment: .leading, spacing: 16) {
      Text(Strings.sleepStagesInfoScoreImpact)
        .font(theme.typography.font(size: 17, weight: .semibold))
        .foregroundStyle(theme.palette.textPrimary)
      VStack(alignment: .leading, spacing: 12) {
        Text(Strings.sleepStagesInfoScoreFormula)
          .font(theme.typography.font(size: 13))
          .foregroundStyle(theme.palette.textSecondary)
          .lineSpacing(4)
        let penalty = breakdown.penalty(config: config)
        Text(penalty > 0 ? String(format: Strings.sleepStagesInfoPenaltyFormat, penalty) : Strings.sleepStagesInfoNoPenalty)
          .font(theme.typography.font(size: 13, weight: .semibold))
          .foregroundStyle(penalty > 0 ? theme.palette.scoreAmber : theme.palette.scoreGreen)
        VStack(spacing: 10) {
          bar(.deep, target: config.deepPctTarget, isMinimum: true)
          bar(.rem, target: config.remPctTarget, isMinimum: true)
          bar(.awake, target: config.awakePctTarget, isMinimum: false)
        }
        .padding(.top, 4)
      }
      .padding(16)
      .frame(maxWidth: .infinity, alignment: .leading)
      .background(theme.palette.bgCard, in: .rect(cornerRadius: theme.radii.small))
    }
  }

  /// The share as a bar, the target as a dot on it. `isMinimum`: the share
  /// should reach the target (deep, REM); otherwise stay under it (awake).
  private func bar(_ stage: SleepStage, target: Double, isMinimum: Bool) -> some View {
    let value = breakdown.percent(of: stage)
    let isGood = isMinimum ? value >= target : value <= target
    let scale = Self.scale(value: value, target: target, isMinimum: isMinimum)
    return VStack(alignment: .leading, spacing: 4) {
      HStack {
        Text(stage.name)
          .font(theme.typography.font(size: 12, weight: .medium))
          .foregroundStyle(theme.palette.textSecondary)
        Spacer()
        Text(String(format: "%.0f%%", value))
          .font(theme.typography.font(size: 12, weight: .semibold))
          .foregroundStyle(isGood ? theme.palette.scoreGreen : theme.palette.scoreAmber)
      }
      GeometryReader { geometry in
        ZStack(alignment: .leading) {
          RoundedRectangle(cornerRadius: 3)
            .fill(theme.palette.border)
            .frame(height: 6)
          RoundedRectangle(cornerRadius: 3)
            .fill(theme.palette.stageColor(stage))
            .frame(width: max(0, min(value, scale)) / scale * geometry.size.width, height: 6)
          Circle()
            .fill(theme.palette.textPrimary)
            .frame(width: 6, height: 6)
            .offset(x: target / scale * geometry.size.width - 3)
        }
      }
      .frame(height: 6)
    }
  }

  /// The bar's full width in percent: some room past the larger of the two.
  static func scale(value: Double, target: Double, isMinimum: Bool) -> Double {
    max(max(value, target) * (isMinimum ? 1.2 : 1.5), 1)
  }
}
