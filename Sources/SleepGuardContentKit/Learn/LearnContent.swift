import SwiftUI
import SleepGuardDesignKit
import SleepStrings

/// The Learn tab: its title row, then the Learn page, or "No content
/// available" when the app has no page to show.
public struct LearnContent: View {
  let url: URL?
  @Environment(\.theme) private var theme

  public init(url: URL?) {
    self.url = url
  }

  public var body: some View {
    VStack(spacing: 0) {
      LearnTitleRow()
        .padding(.horizontal, 20)
        .padding(.top, 10)
      if let url {
        #if canImport(UIKit)
        LearnWebView(url: url)
        #endif
      } else {
        LearnEmptyState()
      }
    }
    .background(theme.palette.bgPrimary)
  }
}

/// "Learn" with the book badge.
struct LearnTitleRow: View {
  var body: some View {
    TabTitleRow(Strings.tabLearn) { TabBadge(systemImage: "book.fill") }
  }
}

/// No page to show.
struct LearnEmptyState: View {
  @Environment(\.theme) private var theme

  var body: some View {
    VStack(spacing: 12) {
      Image(systemName: "book.closed")
        .font(.system(size: 48, weight: .medium))
        .foregroundStyle(theme.palette.textTertiary)
        .accessibilityHidden(true)
      Text(Strings.learnErrorNoContent)
        .font(theme.typography.font(size: 17))
        .foregroundStyle(theme.palette.textSecondary)
        .multilineTextAlignment(.center)
    }
    .padding(24)
    .frame(maxWidth: .infinity, maxHeight: .infinity)
  }
}
