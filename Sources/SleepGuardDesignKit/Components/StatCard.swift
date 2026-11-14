import SwiftUI

/// A small card: icon, value, uppercase title. Reads as one element to VoiceOver.
public struct StatCard: View {
  let icon: String
  let title: String
  let value: String
  /// `nil` uses the theme accent.
  let iconColor: Color?
  @Environment(\.theme) private var theme

  public init(icon: String, title: String, value: String, iconColor: Color? = nil) {
    self.icon = icon
    self.title = title
    self.value = value
    self.iconColor = iconColor
  }

  public var body: some View {
    VStack(alignment: .leading, spacing: 8) {
      Image(systemName: icon)
        .font(.system(size: 12, weight: .semibold))
        .foregroundStyle(iconColor ?? theme.palette.accent)

      VStack(alignment: .leading, spacing: 2) {
        Text(value)
          .font(.system(size: 16, weight: .bold, design: .rounded))
          .foregroundStyle(theme.palette.textPrimary)
          .lineLimit(1)
          .fixedSize(horizontal: true, vertical: false)

        Text(title)
          .font(theme.typography.font(size: 10, weight: .medium))
          .foregroundStyle(theme.palette.textTertiary)
          .textCase(.uppercase)
      }
    }
    .padding(12)
    .frame(maxWidth: .infinity, alignment: .leading)
    .background(theme.palette.bgCard)
    .clipShape(.rect(cornerRadius: theme.radii.card))
    .accessibilityElement(children: .ignore)
    .accessibilityLabel(title)
    .accessibilityValue(value)
  }
}
