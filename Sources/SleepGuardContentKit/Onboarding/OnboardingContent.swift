import SleepCore
import SwiftUI
import SleepGuardDesignKit
import SleepStrings

/// Where a permission the onboarding asks for stands.
public enum OnboardingPermission: Equatable, Sendable {
  case notAsked
  /// The system prompt is up.
  case requesting
  case granted
}

/// The first-launch onboarding: one page per `OnboardingPages` entry, swiped
/// or moved with Skip (to the last page), Back and each page's buttons; dots
/// show where you are. The screen owns the page and asks for permissions,
/// then moves on (SleepGuard waits 0.8 s on "granted"). The last page's
/// buttons finish onboarding.
public struct OnboardingContent: View {
  let pages: OnboardingPages
  @Binding var current: OnboardingPage
  let microphone: OnboardingPermission
  let health: OnboardingPermission
  let onRequestMicrophone: () -> Void
  let onRequestHealth: () -> Void
  let onStartRecording: () -> Void
  let onBrowse: () -> Void
  @Environment(\.theme) private var theme

  public init(
    pages: OnboardingPages, current: Binding<OnboardingPage>, microphone: OnboardingPermission,
    health: OnboardingPermission, onRequestMicrophone: @escaping () -> Void, onRequestHealth: @escaping () -> Void,
    onStartRecording: @escaping () -> Void, onBrowse: @escaping () -> Void)
  {
    self.pages = pages
    _current = current
    self.microphone = microphone
    self.health = health
    self.onRequestMicrophone = onRequestMicrophone
    self.onRequestHealth = onRequestHealth
    self.onStartRecording = onStartRecording
    self.onBrowse = onBrowse
  }

  public var body: some View {
    VStack(spacing: 0) {
      HStack {
        Spacer()
        if pages.showsSkip(on: current) {
          Button { move(to: pages.last) } label: {
            Text(Strings.actionSkip)
              .font(theme.typography.font(size: 15, weight: .medium))
              .foregroundStyle(theme.palette.textSecondary)
              .padding(.trailing, 20)
          }
          .buttonStyle(ScaleButtonStyle())
        }
      }
      .frame(height: 44)

      TabView(selection: $current) {
        ForEach(pages.pages, id: \.self) { page in
          OnboardingPageView(
            page: page, microphone: microphone, health: health,
            onNext: { move(to: pages.next(after: page)) },
            onRequestMicrophone: onRequestMicrophone, onRequestHealth: onRequestHealth,
            onStartRecording: onStartRecording, onBrowse: onBrowse)
            .tag(page)
        }
      }
      #if os(iOS)
      .tabViewStyle(.page(indexDisplayMode: .never))
      #endif

      VStack(spacing: 16) {
        OnboardingDots(pages: pages.pages, current: current)
        Button { move(to: pages.previous(before: current)) } label: {
          Text(Strings.actionBack)
            .font(theme.typography.font(size: 15, weight: .medium))
            .foregroundStyle(theme.palette.textSecondary)
        }
        .buttonStyle(ScaleButtonStyle())
        .opacity(pages.showsBack(on: current) ? 1 : 0)
        .disabled(!pages.showsBack(on: current))
      }
      .padding(.bottom, 32)
    }
    .background(theme.palette.bgPrimary.ignoresSafeArea())
  }

  private func move(to page: OnboardingPage) {
    withAnimation { current = page }
  }
}

/// One page's layout, for a container that pages on its own (render tests
/// draw these too; ImageRenderer can't draw a paged TabView).
public struct OnboardingPageView: View {
  let page: OnboardingPage
  let microphone: OnboardingPermission
  let health: OnboardingPermission
  let onNext: () -> Void
  let onRequestMicrophone: () -> Void
  let onRequestHealth: () -> Void
  let onStartRecording: () -> Void
  let onBrowse: () -> Void

  public init(
    page: OnboardingPage, microphone: OnboardingPermission, health: OnboardingPermission,
    onNext: @escaping () -> Void, onRequestMicrophone: @escaping () -> Void, onRequestHealth: @escaping () -> Void,
    onStartRecording: @escaping () -> Void, onBrowse: @escaping () -> Void)
  {
    self.page = page
    self.microphone = microphone
    self.health = health
    self.onNext = onNext
    self.onRequestMicrophone = onRequestMicrophone
    self.onRequestHealth = onRequestHealth
    self.onStartRecording = onStartRecording
    self.onBrowse = onBrowse
  }

  public var body: some View {
    switch page {
    case .welcome: OnboardingWelcomePage(onNext: onNext)
    case .features: OnboardingFeaturesPage(onNext: onNext)
    case .privacy: OnboardingPrivacyPage(onNext: onNext)
    case .health: OnboardingHealthPage(permission: health, onRequest: onRequestHealth, onSkip: onNext)
    case .microphone: OnboardingMicrophonePage(permission: microphone, onRequest: onRequestMicrophone, onSkip: onNext)
    case .start: OnboardingStartPage(onStartRecording: onStartRecording, onBrowse: onBrowse)
    }
  }
}

/// Where you are in the onboarding: the current page is a wide pill.
public struct OnboardingDots: View {
  let pages: [OnboardingPage]
  let current: OnboardingPage
  @Environment(\.theme) private var theme

  public init(pages: [OnboardingPage], current: OnboardingPage) {
    self.pages = pages
    self.current = current
  }

  public var body: some View {
    HStack(spacing: 8) {
      ForEach(pages, id: \.self) { page in
        RoundedRectangle(cornerRadius: 4)
          .fill(page == current ? theme.palette.accent : theme.palette.bgCard)
          .frame(width: page == current ? 24 : 8, height: 8)
          .animation(.spring(duration: 0.35), value: current)
      }
    }
    .accessibilityHidden(true)
  }
}

/// A page's main button: filled, full width, a spinner while asking and a
/// dot once granted.
struct OnboardingPrimaryButton: View {
  let title: String
  var color: Color?
  var isBusy = false
  var showsDot = false
  let action: () -> Void
  @Environment(\.theme) private var theme

  var body: some View {
    Button(action: action) {
      HStack(spacing: 8) {
        if showsDot {
          Circle().fill(.white).frame(width: 10, height: 10).accessibilityHidden(true)
        }
        if isBusy {
          ProgressView().tint(.white)
        }
        Text(title)
          .font(theme.typography.font(size: 17, weight: .semibold))
      }
      .foregroundStyle(.white)
      .frame(maxWidth: .infinity)
      .frame(height: 56)
      .background(color ?? theme.palette.accent, in: Capsule())
    }
    .buttonStyle(ScaleButtonStyle())
    .disabled(isBusy)
    .padding(.horizontal, 24)
  }
}

/// A page's quiet second button ("Not now").
struct OnboardingSecondaryButton: View {
  let title: String
  let action: () -> Void
  @Environment(\.theme) private var theme

  var body: some View {
    Button(action: action) {
      Text(title)
        .font(theme.typography.font(size: 15, weight: .medium))
        .foregroundStyle(theme.palette.textSecondary)
    }
    .buttonStyle(ScaleButtonStyle())
  }
}
