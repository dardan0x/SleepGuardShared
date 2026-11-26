import SleepCore
import SwiftUI
import SleepGuardDesignKit
import SleepStrings

/// The profile editor: four pages (you, goals, habits, personal) with Skip,
/// Continue, Back and Save. Edits go straight into `profile`; the screen
/// stores it on Save (and, if it likes, on close). `onTap` runs on every
/// button (haptics).
public struct ProfileEditorContent: View {
  @Binding var profile: SleepProfile
  let onSave: () -> Void
  let onClose: () -> Void
  let onTap: () -> Void
  @State private var page = 0
  @Environment(\.theme) private var theme
  static let pageCount = 4

  public init(
    profile: Binding<SleepProfile>, onSave: @escaping () -> Void, onClose: @escaping () -> Void,
    onTap: @escaping () -> Void = {})
  {
    _profile = profile
    self.onSave = onSave
    self.onClose = onClose
    self.onTap = onTap
  }

  public var body: some View {
    VStack(spacing: 0) {
      SheetHandle()
      ProfileEditorBar(page: page, onClose: tap(onClose), onSkip: tap { withAnimation { page += 1 } })
      TabView(selection: $page) {
        ProfileIdentityPage(profile: $profile).tag(0)
        ProfileGoalsPage(profile: $profile).tag(1)
        ProfileHabitsPage(profile: $profile).tag(2)
        ProfilePersonalPage(profile: $profile).tag(3)
      }
      #if os(iOS)
      .tabViewStyle(.page(indexDisplayMode: .never))
      #endif
      ProfileEditorControls(
        page: page,
        onContinue: tap { withAnimation { page += 1 } },
        onBack: tap { withAnimation { page -= 1 } },
        onSave: tap(onSave))
    }
    .background(theme.palette.bgPrimary.ignoresSafeArea())
  }

  private func tap(_ action: @escaping () -> Void) -> () -> Void {
    { onTap(); action() }
  }
}

/// Close on the left, Skip on the right (not on the last page).
struct ProfileEditorBar: View {
  let page: Int
  let onClose: () -> Void
  let onSkip: () -> Void
  @Environment(\.theme) private var theme

  var body: some View {
    HStack {
      Button(action: onClose) {
        Label(Strings.actionClose, systemImage: "xmark")
          .labelStyle(.iconOnly)
          .font(.system(size: 15, weight: .semibold))
          .foregroundStyle(theme.palette.textSecondary)
          .frame(width: 32, height: 32)
      }
      .buttonStyle(ScaleButtonStyle())
      Spacer()
      if page < ProfileEditorContent.pageCount - 1 {
        Button(action: onSkip) {
          Text(Strings.actionSkip)
            .font(theme.typography.font(size: 15, weight: .medium))
            .foregroundStyle(theme.palette.textSecondary)
        }
        .buttonStyle(ScaleButtonStyle())
      }
    }
    .padding(.horizontal, 20)
    .frame(height: 56)
  }
}

/// The privacy note, the page dots, Continue or Save, and Back.
struct ProfileEditorControls: View {
  let page: Int
  let onContinue: () -> Void
  let onBack: () -> Void
  let onSave: () -> Void
  @Environment(\.theme) private var theme

  var body: some View {
    let isLast = page == ProfileEditorContent.pageCount - 1
    VStack(spacing: 16) {
      HStack(spacing: 6) {
        Image(systemName: "lock.shield").font(.system(size: 12)).accessibilityHidden(true)
        Text(Strings.profileEditorPrivacyNotice).font(theme.typography.font(size: 11, weight: .medium))
      }
      .foregroundStyle(theme.palette.scoreGreen)
      .padding(.horizontal, 10)
      .padding(.vertical, 6)
      .overlay(Capsule().stroke(theme.palette.scoreGreen.opacity(0.4), lineWidth: 1))

      HStack(spacing: 8) {
        ForEach(0..<ProfileEditorContent.pageCount, id: \.self) { index in
          RoundedRectangle(cornerRadius: 4)
            .fill(index == page ? theme.palette.accent : theme.palette.bgCard)
            .frame(width: index == page ? 24 : 8, height: 8)
            .animation(.spring(duration: 0.35), value: page)
        }
      }
      .accessibilityHidden(true)

      Button(action: isLast ? onSave : onContinue) {
        Text(isLast ? Strings.profileActionSaveProfile : Strings.actionContinue)
          .font(theme.typography.font(size: 17, weight: .semibold))
          .foregroundStyle(theme.palette.bgPrimary)
          .frame(maxWidth: .infinity)
          .padding(.vertical, 16)
          .background(isLast ? theme.palette.textPrimary : theme.palette.accent, in: .rect(cornerRadius: theme.radii.card))
      }
      .buttonStyle(.plain)

      if page > 0 {
        Button(action: onBack) {
          Text(Strings.actionBack)
            .font(theme.typography.font(size: 15, weight: .medium))
            .foregroundStyle(theme.palette.textSecondary)
        }
        .buttonStyle(ScaleButtonStyle())
      }
    }
    .padding(.horizontal, 20)
    .padding(.bottom, 32)
  }
}
