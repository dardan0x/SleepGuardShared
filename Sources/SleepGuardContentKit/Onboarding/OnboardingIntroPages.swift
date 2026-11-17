import SwiftUI

/// Welcome: the sleepy face with drifting Z's.
struct OnboardingWelcomePage: View {
  let onNext: () -> Void
  @Environment(\.theme) private var theme
  @State private var drift = false

  private static let violet = Color(red: 0.4, green: 0.35, blue: 0.95)
  private static let indigo = Color(red: 0.25, green: 0.35, blue: 0.85)

  var body: some View {
    VStack(spacing: 32) {
      Spacer()
      ZStack {
        Circle()
          .fill(LinearGradient(colors: [Self.violet, Self.indigo], startPoint: .topLeading, endPoint: .bottomTrailing))
          .frame(width: 140, height: 140)
          .shadow(color: Self.indigo.opacity(0.4), radius: 30)
        Text(verbatim: "😴").font(.system(size: 60))
        Text(verbatim: "Z")
          .font(.system(size: 24, weight: .bold))
          .foregroundStyle(.white.opacity(0.8))
          .offset(x: 50, y: drift ? -72 : -60)
          .opacity(drift ? 1 : 0)
        Text(verbatim: "z")
          .font(.system(size: 18, weight: .bold))
          .foregroundStyle(.white.opacity(0.6))
          .offset(x: 70, y: drift ? -90 : -80)
          .opacity(drift ? 1 : 0)
      }
      .accessibilityHidden(true)
      .onAppear {
        withAnimation(.easeInOut(duration: 2).repeatForever(autoreverses: true)) { drift = true }
      }
      VStack(spacing: 16) {
        OnboardingTitle(Strings.onboardingPage1Title)
        OnboardingBody(Strings.onboardingPage4Body)
        Text(Strings.onboardingPage1Subtitle)
          .font(theme.typography.font(size: 13, weight: .medium))
          .foregroundStyle(theme.palette.accent)
          .multilineTextAlignment(.center)
          .padding(.horizontal, 20)
          .padding(.vertical, 10)
          .background(theme.palette.accent.opacity(0.15), in: Capsule())
      }
      Spacer()
      OnboardingPrimaryButton(title: Strings.onboardingPage5Button, action: onNext)
    }
    .padding(.horizontal, 32)
    .padding(.bottom, 48)
  }
}

/// What the app does: three cards.
struct OnboardingFeaturesPage: View {
  let onNext: () -> Void

  var body: some View {
    VStack(spacing: 24) {
      Spacer()
      OnboardingTitle(Strings.onboardingPage2Title)
      VStack(spacing: 12) {
        OnboardingFeatureCard(
          icon: "😴", title: Strings.onboardingPage2SleepScoreTitle,
          description: Strings.onboardingPage2SleepScoreDescription)
        OnboardingFeatureCard(
          icon: "🎤", title: Strings.onboardingPage2SnoreDetectionTitle,
          description: Strings.onboardingPage2SnoreDetectionDescription)
        OnboardingFeatureCard(
          icon: "📊", title: Strings.onboardingPage2SleepTrendsTitle,
          description: Strings.onboardingPage2SleepTrendsDescription)
      }
      Spacer()
      OnboardingPrimaryButton(title: Strings.onboardingPage1Button, action: onNext)
    }
    .padding(.horizontal, 24)
    .padding(.bottom, 40)
  }
}

private struct OnboardingFeatureCard: View {
  let icon: String
  let title: String
  let description: String
  @Environment(\.theme) private var theme

  var body: some View {
    HStack(spacing: 16) {
      Text(verbatim: icon)
        .font(.system(size: 28))
        .frame(width: 48, height: 48)
        .background(theme.palette.bgCard, in: .rect(cornerRadius: theme.radii.small))
        .accessibilityHidden(true)
      VStack(alignment: .leading, spacing: 4) {
        Text(title)
          .font(theme.typography.font(size: 16, weight: .semibold))
          .foregroundStyle(theme.palette.textPrimary)
        Text(description)
          .font(theme.typography.font(size: 13))
          .foregroundStyle(theme.palette.textSecondary)
          .lineLimit(2)
      }
      Spacer()
    }
    .padding(16)
    .background(theme.palette.bgCard, in: .rect(cornerRadius: theme.radii.card))
    .accessibilityElement(children: .combine)
  }
}

/// Privacy: nothing leaves the phone.
struct OnboardingPrivacyPage: View {
  let onNext: () -> Void
  @Environment(\.theme) private var theme
  @State private var pulse = false

  var body: some View {
    VStack(spacing: 32) {
      Spacer()
      ZStack {
        Circle()
          .fill(theme.palette.scoreGreen.opacity(0.15))
          .frame(width: 160, height: 160)
          .scaleEffect(pulse ? 1.15 : 1)
        Image(systemName: "checkmark.shield.fill")
          .font(.system(size: 72))
          .foregroundStyle(theme.palette.scoreGreen)
      }
      .accessibilityHidden(true)
      .onAppear {
        withAnimation(.easeInOut(duration: 2).repeatForever(autoreverses: true)) { pulse = true }
      }
      VStack(spacing: 16) {
        OnboardingTitle(Strings.onboardingPage3Title)
        OnboardingBody(Strings.onboardingPage5Body)
        HStack(spacing: 8) {
          Image(systemName: "lock.shield").font(.system(size: 14)).accessibilityHidden(true)
          Text(Strings.onboardingPage3Badge).font(theme.typography.font(size: 13, weight: .medium))
        }
        .foregroundStyle(theme.palette.scoreGreen)
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .overlay(Capsule().stroke(theme.palette.scoreGreen.opacity(0.4), lineWidth: 1))
      }
      Spacer()
      OnboardingPrimaryButton(title: Strings.onboardingPage3Button, action: onNext)
    }
    .padding(.horizontal, 32)
    .padding(.bottom, 40)
  }
}

/// The last page: start a night, or just look around.
struct OnboardingStartPage: View {
  let onStartRecording: () -> Void
  let onBrowse: () -> Void
  @Environment(\.theme) private var theme

  var body: some View {
    VStack(spacing: 32) {
      Spacer()
      Text(verbatim: "🌙")
        .font(.system(size: 60))
        .frame(width: 140, height: 140)
        .background(theme.palette.accent.opacity(0.15), in: Circle())
        .accessibilityHidden(true)
      VStack(spacing: 16) {
        OnboardingTitle(Strings.onboardingPage5Title)
        OnboardingBody(Strings.onboardingPage2Body)
        Text(Strings.onboardingPrivacyJudgeSilently)
          .font(theme.typography.font(size: 14, weight: .medium))
          .foregroundStyle(theme.palette.textSecondary)
          .multilineTextAlignment(.center)
          .padding(.horizontal, 18)
          .padding(.vertical, 10)
          .background(theme.palette.bgElevated, in: Capsule())
      }
      Spacer()
      VStack(spacing: 12) {
        StartRecordingButton(height: 56, action: onStartRecording)
        OnboardingSecondaryButton(title: Strings.onboardingPage4ButtonSecondary, action: onBrowse)
      }
      .padding(.horizontal, 24)
    }
    .padding(.horizontal, 32)
    .padding(.bottom, 40)
  }
}

struct OnboardingTitle: View {
  let text: String
  @Environment(\.theme) private var theme

  init(_ text: String) {
    self.text = text
  }

  var body: some View {
    Text(text)
      .font(theme.typography.font(size: 28, weight: .bold))
      .foregroundStyle(theme.palette.textPrimary)
      .multilineTextAlignment(.center)
      .accessibilityAddTraits(.isHeader)
  }
}

struct OnboardingBody: View {
  let text: String
  @Environment(\.theme) private var theme

  init(_ text: String) {
    self.text = text
  }

  var body: some View {
    Text(text)
      .font(theme.typography.font(size: 15))
      .foregroundStyle(theme.palette.textSecondary)
      .multilineTextAlignment(.center)
  }
}
