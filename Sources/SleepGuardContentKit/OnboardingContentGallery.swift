import SleepCore
import SwiftUI
import SleepGuardDesignKit

/// Every onboarding page, and the permission pages once granted, for previews
/// and render tests. Internal: sample states only.
struct OnboardingContentGallery: View {
  enum Screen: CaseIterable {
    case welcome, features, privacy, health, healthGranted, microphone, microphoneRequesting, start
  }

  let screen: Screen

  var body: some View {
    page
      .frame(height: 760)
      .background(OnboardingGalleryBackground())
  }

  private var page: OnboardingPageView {
    let (page, microphone, health): (OnboardingPage, OnboardingPermission, OnboardingPermission) = switch screen {
    case .welcome: (.welcome, .notAsked, .notAsked)
    case .features: (.features, .notAsked, .notAsked)
    case .privacy: (.privacy, .notAsked, .notAsked)
    case .health: (.health, .notAsked, .notAsked)
    case .healthGranted: (.health, .notAsked, .granted)
    case .microphone: (.microphone, .notAsked, .notAsked)
    case .microphoneRequesting: (.microphone, .requesting, .notAsked)
    case .start: (.start, .granted, .granted)
    }
    return OnboardingPageView(
      page: page, microphone: microphone, health: health, onNext: {}, onRequestMicrophone: {},
      onRequestHealth: {}, onStartRecording: {}, onBrowse: {})
  }
}

private struct OnboardingGalleryBackground: View {
  @Environment(\.theme) private var theme

  var body: some View {
    theme.palette.bgPrimary
  }
}

#Preview("Onboarding") {
  @Previewable @State var page = OnboardingPage.welcome
  OnboardingContent(
    pages: OnboardingPages(hasHealth: true), current: $page, microphone: .notAsked, health: .notAsked,
    onRequestMicrophone: {}, onRequestHealth: {}, onStartRecording: {}, onBrowse: {})
}
