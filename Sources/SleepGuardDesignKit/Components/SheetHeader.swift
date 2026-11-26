import SwiftUI
import SleepStrings

/// The grabber at the top of a custom sheet.
public struct SheetHandle: View {
  @Environment(\.theme) private var theme

  public init() {}

  public var body: some View {
    RoundedRectangle(cornerRadius: 2)
      .fill(theme.palette.textTertiary.opacity(0.5))
      .frame(width: 36, height: 4)
      .frame(maxWidth: .infinity)
      .frame(height: 28)
      .accessibilityHidden(true)
  }
}

/// A sheet's own title bar with a back chevron, for a second page inside a sheet.
public struct SheetNavHeader: View {
  let title: String
  let onBack: () -> Void
  @Environment(\.theme) private var theme

  public init(title: String, onBack: @escaping () -> Void) {
    self.title = title
    self.onBack = onBack
  }

  public var body: some View {
    HStack {
      Button(action: onBack) {
        Label(Strings.actionBack, systemImage: "chevron.left")
          .labelStyle(.iconOnly)
          .font(.system(size: 17))
          .foregroundStyle(theme.palette.accent)
      }
      .buttonStyle(.plain)
      .frame(width: 80, alignment: .leading)

      Spacer()

      Text(title)
        .font(theme.typography.font(size: 13, weight: .semibold))
        .tracking(1.5)
        .foregroundStyle(theme.palette.textPrimary)

      Spacer()

      Color.clear.frame(width: 80)
    }
    .frame(height: 52)
    .padding(.horizontal, 16)
  }
}
