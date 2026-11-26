import SleepCore
import SwiftUI
import SleepGuardDesignKit
import SleepStrings

/// The morning briefing sheet: greeting, how the night went, an insight, a
/// nudge to finish the profile, a closing line, and the survey. Tapping a
/// survey answer reports it and closes; Skip and Close close.
public struct BriefingContent: View {
  let briefing: Briefing
  let onChip: (LifestyleChip) -> Void
  let onClose: () -> Void
  @Environment(\.theme) private var theme

  public init(briefing: Briefing, onChip: @escaping (LifestyleChip) -> Void, onClose: @escaping () -> Void) {
    self.briefing = briefing
    self.onChip = onChip
    self.onClose = onClose
  }

  public var body: some View {
    ScrollView {
      BriefingStack(briefing: briefing, onChip: onChip, onClose: onClose)
    }
    .background(theme.palette.bgPrimary)
  }
}

/// The sheet's content (render tests draw this; ImageRenderer can't draw a ScrollView).
struct BriefingStack: View {
  let briefing: Briefing
  let onChip: (LifestyleChip) -> Void
  let onClose: () -> Void
  @Environment(\.theme) private var theme

  var body: some View {
    VStack(spacing: 12) {
      HStack {
        Spacer()
        Button(action: onClose) {
          Label(Strings.actionClose, systemImage: "xmark.circle.fill").labelStyle(.iconOnly)
            .font(.system(size: 24))
            .foregroundStyle(theme.palette.textSecondary)
        }
      }
      Text(BriefingText.greeting(briefing.greeting))
        .font(theme.typography.font(size: 28, weight: .bold))
        .foregroundStyle(theme.palette.textPrimary)
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityAddTraits(.isHeader)
      BriefingRecapCard(headline: briefing.headline, stats: briefing.stats)
      if let insight = BriefingText.insight(briefing.insight) {
        BriefingInsightCard(text: insight)
      }
      if briefing.profileNudge {
        BriefingLine(text: Strings.briefingProfileNudge, color: theme.palette.accent)
      }
      BriefingLine(text: BriefingText.quote(briefing.trend), color: theme.palette.textSecondary)
      if let survey = briefing.survey {
        BriefingSurveyCard(survey: survey, onChip: { onChip($0) }, onSkip: onClose)
      }
      Spacer(minLength: 8)
      Button(action: onClose) {
        Text(Strings.actionClose)
          .font(theme.typography.font(size: 17, weight: .semibold))
          .foregroundStyle(theme.palette.bgPrimary)
          .frame(maxWidth: .infinity)
          .padding(.vertical, 12)
          .background(theme.palette.textPrimary, in: .rect(cornerRadius: theme.radii.card))
      }
    }
    .padding(.horizontal, 20)
    .padding(.top, 24)
    .padding(.bottom, 20)
  }
}

private struct BriefingLine: View {
  let text: String
  let color: Color
  @Environment(\.theme) private var theme

  var body: some View {
    Text(text)
      .font(theme.typography.font(size: 15, weight: .medium))
      .foregroundStyle(color)
      .lineSpacing(3)
      .frame(maxWidth: .infinity, alignment: .leading)
      .padding(.horizontal, 4)
  }
}

private struct BriefingRecapCard: View {
  let headline: BriefingHeadline
  let stats: [BriefingStat]
  @Environment(\.theme) private var theme

  var body: some View {
    VStack(alignment: .leading, spacing: 16) {
      Text(BriefingText.headline(headline))
        .font(theme.typography.font(size: 17, weight: .medium))
        .foregroundStyle(theme.palette.textPrimary)
        .lineSpacing(4)
        .frame(maxWidth: .infinity, alignment: .leading)
      if !stats.isEmpty {
        HStack(spacing: 12) {
          ForEach(Array(stats.enumerated()), id: \.offset) { _, stat in
            StatCard(
              icon: BriefingText.icon(stat.label), title: BriefingText.label(stat.label),
              value: BriefingText.value(stat.value))
          }
        }
      }
    }
    .padding(16)
    .background(theme.palette.bgCard, in: .rect(cornerRadius: theme.radii.card))
  }
}

private struct BriefingInsightCard: View {
  let text: String
  @Environment(\.theme) private var theme

  var body: some View {
    HStack(spacing: 12) {
      Image(systemName: "sparkles")
        .font(.system(size: 16, weight: .semibold))
        .foregroundStyle(theme.palette.accent)
        .accessibilityHidden(true)
      Text(text)
        .font(theme.typography.font(size: 15, weight: .medium))
        .foregroundStyle(theme.palette.textSecondary)
        .lineSpacing(3)
      Spacer(minLength: 0)
    }
    .padding(16)
    .background(theme.palette.bgCard, in: .rect(cornerRadius: theme.radii.card))
  }
}

private struct BriefingSurveyCard: View {
  let survey: BriefingSurvey
  let onChip: (LifestyleChip) -> Void
  let onSkip: () -> Void
  @Environment(\.theme) private var theme

  var body: some View {
    VStack(alignment: .leading, spacing: 16) {
      Text(BriefingText.surveyTitle(survey))
        .font(theme.typography.font(size: 17, weight: .semibold))
        .foregroundStyle(theme.palette.textPrimary)
      FlowLayout(spacing: 8) {
        ForEach(survey.chips, id: \.self) { chip in
          Button { onChip(chip) } label: {
            Text(BriefingText.chip(chip))
              .font(theme.typography.font(size: 14, weight: .medium))
              .foregroundStyle(theme.palette.textPrimary)
              .padding(.horizontal, 14)
              .padding(.vertical, 8)
              .background(theme.palette.bgElevated, in: .rect(cornerRadius: theme.radii.small))
          }
          .buttonStyle(.plain)
        }
      }
      Button(action: onSkip) {
        Text(Strings.actionSkip)
          .font(theme.typography.font(size: 15, weight: .medium))
          .foregroundStyle(theme.palette.textTertiary)
      }
      .buttonStyle(.plain)
      .frame(maxWidth: .infinity, alignment: .trailing)
    }
    .padding(16)
    .background(theme.palette.bgCard, in: .rect(cornerRadius: theme.radii.card))
  }
}
