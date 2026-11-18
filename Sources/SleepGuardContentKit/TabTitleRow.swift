import SwiftUI

/// A tab's title row: the tab's name in large bold type, its control on the
/// trailing edge. The app hides the navigation bar on a tab's root and shows
/// this instead (Learn, Statistics, Settings).
struct TabTitleRow<Trailing: View>: View {
  let title: String
  let trailing: Trailing
  @Environment(\.theme) private var theme

  init(_ title: String, @ViewBuilder trailing: () -> Trailing) {
    self.title = title
    self.trailing = trailing()
  }

  var body: some View {
    HStack {
      Text(title)
        .font(theme.typography.font(size: 34, weight: .bold))
        .foregroundStyle(theme.palette.textPrimary)
        .accessibilityAddTraits(.isHeader)
      Spacer()
      trailing
    }
  }
}

/// A decorative accent badge with a white symbol (Learn's book, Settings' gear).
struct TabBadge: View {
  let systemImage: String
  @Environment(\.theme) private var theme

  var body: some View {
    Image(systemName: systemImage)
      .font(.system(size: 16))
      .foregroundStyle(.white)
      .frame(width: 30, height: 30)
      .background(theme.palette.accent, in: .rect(cornerRadius: 15))
      .accessibilityHidden(true)
  }
}

/// "Statistics" with the Calendar button.
public struct StatisticsTitleRow: View {
  let onCalendar: () -> Void
  @Environment(\.theme) private var theme

  public init(onCalendar: @escaping () -> Void) {
    self.onCalendar = onCalendar
  }

  public var body: some View {
    TabTitleRow(Strings.tabStatistics) {
      Button(action: onCalendar) {
        HStack(spacing: 4) {
          Image(systemName: "calendar")
            .font(.system(size: 14, weight: .medium))
          Text(Strings.watchCalendar)
            .font(theme.typography.font(size: 14, weight: .semibold))
        }
        .foregroundStyle(theme.palette.accent)
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(theme.palette.bgCard, in: .capsule)
      }
    }
  }
}

/// "Settings" with the gear badge.
public struct SettingsTitleRow: View {
  public init() {}

  public var body: some View {
    TabTitleRow(Strings.tabSettings) { TabBadge(systemImage: "gearshape.fill") }
  }
}
