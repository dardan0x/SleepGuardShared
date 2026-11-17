import SwiftUI

/// Apple Health: read the night's sleep stages and write the night back.
struct OnboardingHealthPage: View {
  let permission: OnboardingPermission
  let onRequest: () -> Void
  let onSkip: () -> Void
  @Environment(\.theme) private var theme

  var body: some View {
    VStack(spacing: 0) {
      Spacer().frame(height: 60)
      ZStack {
        Circle().stroke(theme.palette.scoreGreen.opacity(0.2), lineWidth: 1).frame(width: 160, height: 160)
        Circle()
          .fill(Color(hex: "#0A2818"))
          .overlay(Circle().stroke(theme.palette.scoreGreen.opacity(0.33), lineWidth: 1))
          .frame(width: 130, height: 130)
        Circle().fill(Color(hex: "#133D20")).frame(width: 80, height: 80)
        Image(systemName: "bed.double.fill").font(.system(size: 36)).foregroundStyle(theme.palette.scoreGreen)
        Image(systemName: "heart.fill")
          .font(.system(size: 20))
          .foregroundStyle(theme.palette.scoreGreen)
          .offset(x: 55, y: -55)
        Circle().fill(theme.palette.accent).frame(width: 14, height: 14).offset(x: 52, y: 52)
      }
      .frame(width: 180, height: 180)
      .accessibilityHidden(true)
      VStack(spacing: 16) {
        OnboardingTitle(Strings.onboardingHealthWatchTitle)
        OnboardingBody(Strings.onboardingHealthWatchBody)
        HStack(spacing: 6) {
          Image(systemName: "shield.fill").font(.system(size: 13)).accessibilityHidden(true)
          Text(Strings.onboardingHealthWatchBadge).font(theme.typography.font(size: 13, weight: .medium))
        }
        .foregroundStyle(theme.palette.textSecondary)
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
        .background(theme.palette.bgElevated, in: Capsule())
      }
      .padding(.top, 32)
      Spacer()
      VStack(spacing: 16) {
        OnboardingPrimaryButton(
          title: permission == .granted ? Strings.onboardingHealthWatchGranted : Strings.onboardingHealthWatchButtonPrimary,
          color: permission == .granted ? theme.palette.scoreGreen : nil,
          isBusy: permission == .requesting, showsDot: permission == .granted, action: onRequest)
        OnboardingSecondaryButton(title: Strings.onboardingHealthWatchButtonSecondary, action: onSkip)
      }
    }
    .padding(.horizontal, 32)
    .padding(.bottom, 40)
  }
}

/// The microphone: needed to hear snoring.
struct OnboardingMicrophonePage: View {
  let permission: OnboardingPermission
  let onRequest: () -> Void
  let onSkip: () -> Void
  @Environment(\.theme) private var theme
  @State private var ripple = false

  var body: some View {
    VStack(spacing: 32) {
      Spacer()
      ZStack {
        Circle()
          .stroke(theme.palette.accent.opacity(ripple ? 0 : 0.6), lineWidth: 1)
          .frame(width: 180, height: 180)
          .scaleEffect(ripple ? 1.4 : 1)
        Circle()
          .stroke(theme.palette.accent.opacity(ripple ? 0 : 0.3), lineWidth: 1)
          .frame(width: 220, height: 220)
          .scaleEffect(ripple ? 1.4 : 1)
        Circle().fill(theme.palette.accent.opacity(0.15)).frame(width: 120, height: 120)
        Image(systemName: permission == .granted ? "checkmark.circle.fill" : "mic.fill")
          .font(.system(size: 72))
          .foregroundStyle(theme.palette.accent)
      }
      .accessibilityHidden(true)
      .onAppear {
        withAnimation(.easeOut(duration: 1.5).repeatForever(autoreverses: false)) { ripple = true }
      }
      VStack(spacing: 12) {
        OnboardingTitle(Strings.onboardingPage4Title)
        OnboardingBody(Strings.onboardingPage3Body)
      }
      Spacer()
      VStack(spacing: 12) {
        OnboardingPrimaryButton(
          title: permission == .granted ? Strings.onboardingPage4Badge : Strings.onboardingPage4ButtonPrimary,
          color: permission == .granted ? theme.palette.scoreGreen : nil,
          isBusy: permission == .requesting, action: onRequest)
        OnboardingSecondaryButton(title: Strings.onboardingPage2Button, action: onSkip)
      }
    }
    .padding(.horizontal, 32)
    .padding(.bottom, 40)
  }
}
