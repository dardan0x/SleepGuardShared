import SwiftUI
import SleepGuardDesignKit
import SleepStrings

/// Shown instead of the app when the nights database couldn't be opened. The
/// file is kept, so an update that can read it brings the nights back. The
/// host blocks everything else, so nothing is recorded into a store that
/// would be lost. `onUpdate` is the update button's action; `nil` hides it
/// (an app with no store page to open).
public struct StoreUnavailableContent: View {
  let onUpdate: (() -> Void)?
  @Environment(\.theme) private var theme

  public init(onUpdate: (() -> Void)?) {
    self.onUpdate = onUpdate
  }

  public var body: some View {
    ZStack {
      theme.palette.bgPrimary
        .ignoresSafeArea()

      VStack(spacing: 16) {
        Image(systemName: "externaldrive.badge.exclamationmark")
          .font(.system(size: 48))
          .foregroundStyle(theme.palette.accent)
          .accessibilityHidden(true)

        Text(Strings.storeUnavailableTitle)
          .font(.system(size: 22, weight: .bold))
          .foregroundStyle(theme.palette.textPrimary)
          .multilineTextAlignment(.center)

        Text(Strings.storeUnavailableMessage)
          .font(.system(size: 15))
          .foregroundStyle(theme.palette.textSecondary)
          .multilineTextAlignment(.center)

        if let onUpdate {
          Button(action: onUpdate) {
            Text(Strings.storeUnavailableUpdate)
              .font(.system(size: 17, weight: .semibold))
              .foregroundStyle(theme.palette.textPrimary)
              .frame(maxWidth: .infinity)
              .frame(height: 50)
              .background(theme.palette.accent)
              .clipShape(RoundedRectangle(cornerRadius: theme.radii.small))
          }
          .buttonStyle(.plain)
        }
      }
      .padding(28)
      .background(theme.palette.bgCard)
      .clipShape(RoundedRectangle(cornerRadius: theme.radii.card))
      .padding(.horizontal, 32)
    }
  }
}
