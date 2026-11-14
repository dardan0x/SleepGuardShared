import SwiftUI

/// The large glowing button behind start/stop recording. The glow and border
/// use the theme's `destructive` (recording red); the face uses `bgCard`.
public struct RecordingActionButton<Label: View>: View {
  let height: CGFloat
  let action: () -> Void
  let label: Label
  @Environment(\.theme) private var theme
  @State private var tapCount = 0

  public init(height: CGFloat = 56, action: @escaping () -> Void, @ViewBuilder label: () -> Label) {
    self.height = height
    self.action = action
    self.label = label()
  }

  public var body: some View {
    let red = theme.palette.destructive
    ZStack {
      // Outer soft halo
      RoundedRectangle(cornerRadius: theme.radii.card)
        .fill(red.opacity(0.12))
        .frame(maxWidth: .infinity)
        .frame(height: height + 40)
        .blur(radius: 16)
        .offset(y: 6)

      // Inner concentrated glow
      RoundedRectangle(cornerRadius: theme.radii.card)
        .fill(LinearGradient(colors: [red.opacity(0.35), red.opacity(0)], startPoint: .top, endPoint: .bottom))
        .frame(maxWidth: .infinity)
        .frame(height: height + 20)
        .blur(radius: 10)
        .offset(y: 8)

      Button {
        tapCount += 1
        action()
      } label: {
        label
          .frame(maxWidth: .infinity)
          .frame(height: height)
          .background {
            ZStack {
              theme.palette.bgCard
              RoundedRectangle(cornerRadius: theme.radii.card)
                .stroke(
                  LinearGradient(colors: [red.opacity(0.6), red.opacity(0.1)], startPoint: .leading, endPoint: .trailing),
                  lineWidth: 1)
            }
          }
          .clipShape(.rect(cornerRadius: theme.radii.card))
      }
      .buttonStyle(ScaleButtonStyle())
      .sensoryFeedback(.impact(weight: .light, intensity: 0.8), trigger: tapCount)
    }
  }
}

public struct StartRecordingButton: View {
  let height: CGFloat
  let action: () -> Void
  @Environment(\.theme) private var theme

  public init(height: CGFloat = 56, action: @escaping () -> Void) {
    self.height = height
    self.action = action
  }

  public var body: some View {
    RecordingActionButton(height: height, action: action) {
      HStack(spacing: 12) {
        PulsingDot(color: theme.palette.destructive)

        Text(Strings.actionStartRecording)
          .font(theme.typography.font(size: 17, weight: .semibold))
          .foregroundStyle(theme.palette.textPrimary)

        Image(systemName: "chevron.right")
          .font(.system(size: 14, weight: .semibold))
          .foregroundStyle(theme.palette.textPrimary.opacity(0.6))
      }
    }
  }
}

public struct StopRecordingButton: View {
  let height: CGFloat
  let action: () -> Void
  @Environment(\.theme) private var theme

  public init(height: CGFloat = 56, action: @escaping () -> Void) {
    self.height = height
    self.action = action
  }

  public var body: some View {
    RecordingActionButton(height: height, action: action) {
      HStack(spacing: 12) {
        RoundedRectangle(cornerRadius: 3)
          .fill(theme.palette.destructive)
          .frame(width: 12, height: 12)

        Text(Strings.sessionBedsideStopRecording)
          .font(theme.typography.font(size: 17, weight: .semibold))
          .foregroundStyle(theme.palette.textPrimary)
      }
    }
  }
}

private struct PulsingDot: View {
  let color: Color
  @State private var isPulsing = false

  var body: some View {
    ZStack {
      Circle()
        .fill(color.opacity(0.25))
        .frame(width: 20, height: 20)
        .scaleEffect(isPulsing ? 1.4 : 1.0)
      Circle()
        .fill(color)
        .frame(width: 10, height: 10)
    }
    .onAppear { isPulsing = true }
    .animation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true), value: isPulsing)
    .accessibilityHidden(true)
  }
}
