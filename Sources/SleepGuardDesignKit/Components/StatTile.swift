import SwiftUI

/// A stat with a small icon and label above a large value. Reads as one element.
public struct StatTile: View {
  let icon: String
  let iconColor: Color
  let label: String
  let value: String
  let valueSize: CGFloat
  let valueColor: Color?
  @Environment(\.theme) private var theme

  public init(icon: String, iconColor: Color, label: String, value: String, valueSize: CGFloat = 28, valueColor: Color? = nil) {
    self.icon = icon
    self.iconColor = iconColor
    self.label = label
    self.value = value
    self.valueSize = valueSize
    self.valueColor = valueColor
  }

  public var body: some View {
    VStack(alignment: .leading, spacing: 4) {
      HStack(spacing: 4) {
        Image(systemName: icon)
          .font(.system(size: 12, weight: .semibold))
          .foregroundStyle(iconColor)
        Text(label)
          .font(theme.typography.font(size: 10, weight: .semibold))
          .foregroundStyle(theme.palette.textTertiary)
          .tracking(0.5)
      }
      Text(value)
        .font(theme.typography.font(size: valueSize, weight: .bold))
        .foregroundStyle(valueColor ?? theme.palette.textPrimary)
        .lineLimit(1)
        .minimumScaleFactor(0.7)
    }
    .frame(maxWidth: .infinity, alignment: .leading)
    .padding(12)
    .background(theme.palette.bgCard, in: .rect(cornerRadius: theme.radii.small))
    .accessibilityElement(children: .ignore)
    .accessibilityLabel(label)
    .accessibilityValue(value)
  }
}

/// A small centred stat: icon, value, label (the calendar's month stats).
public struct CenteredStatTile: View {
  let icon: String
  let label: String
  let value: String
  @Environment(\.theme) private var theme

  public init(icon: String, label: String, value: String) {
    self.icon = icon
    self.label = label
    self.value = value
  }

  public var body: some View {
    VStack(spacing: 4) {
      Image(systemName: icon)
        .font(.system(size: 12))
        .foregroundStyle(theme.palette.textTertiary)
      Text(value)
        .font(.system(size: 20, weight: .bold, design: .rounded))
        .foregroundStyle(theme.palette.textPrimary)
      Text(label)
        .font(theme.typography.font(size: 10, weight: .semibold))
        .foregroundStyle(theme.palette.textTertiary)
        .tracking(0.5)
    }
    .frame(maxWidth: .infinity)
    .padding(.vertical, 10)
    .background(theme.palette.bgCard, in: .rect(cornerRadius: theme.radii.small))
    .accessibilityElement(children: .ignore)
    .accessibilityLabel(label)
    .accessibilityValue(value)
  }
}
