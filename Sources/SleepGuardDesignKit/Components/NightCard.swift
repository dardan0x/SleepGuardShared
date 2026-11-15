import SwiftUI

/// A night as a tappable card: small score gauge, title and a detail line.
public struct NightCard: View {
  let score: Int
  let title: String
  let detail: String
  let onTap: () -> Void
  @Environment(\.theme) private var theme

  public init(score: Int, title: String, detail: String, onTap: @escaping () -> Void) {
    self.score = score
    self.title = title
    self.detail = detail
    self.onTap = onTap
  }

  public var body: some View {
    Button(action: onTap) {
      HStack(spacing: 12) {
        SleepScoreGauge(score: score, size: 44)
        VStack(alignment: .leading, spacing: 2) {
          Text(title)
            .font(theme.typography.font(size: 16, weight: .semibold))
            .foregroundStyle(theme.palette.textPrimary)
          Text(detail)
            .font(theme.typography.font(size: 13))
            .foregroundStyle(theme.palette.textSecondary)
        }
        Spacer()
        Image(systemName: "chevron.right")
          .font(.system(size: 13, weight: .semibold))
          .foregroundStyle(theme.palette.textTertiary)
          .accessibilityHidden(true)
      }
      .padding(.horizontal, 16)
      .padding(.vertical, 12)
      .background(theme.palette.bgCard, in: .rect(cornerRadius: theme.radii.card))
      .contentShape(Rectangle())
    }
    .buttonStyle(.plain)
  }
}
