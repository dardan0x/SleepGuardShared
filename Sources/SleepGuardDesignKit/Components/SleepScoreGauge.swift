import SwiftUI

/// The sleep score ring (0–100) with the number in the middle.
public struct SleepScoreGauge: View {
  let score: Int
  let size: CGFloat
  @Environment(\.theme) private var theme
  @State private var animatedProgress: CGFloat = 0

  public init(score: Int, size: CGFloat = 160) {
    self.score = score
    self.size = size
  }

  public var body: some View {
    ZStack {
      Circle()
        .stroke(theme.palette.bgElevated, lineWidth: size * 0.08)

      Circle()
        .trim(from: 0, to: animatedProgress)
        .stroke(
          AngularGradient(
            gradient: Gradient(colors: [theme.palette.scoreGreen, theme.palette.scoreAmber, theme.palette.scoreRed]),
            center: .center,
            startAngle: .degrees(-90),
            endAngle: .degrees(270)),
          style: StrokeStyle(lineWidth: size * 0.08, lineCap: .round))
        .rotationEffect(.degrees(-90))
        .animation(.easeOut(duration: 0.8), value: animatedProgress)

      VStack(spacing: 2) {
        Text("\(score)")
          .font(.system(size: size * 0.35, weight: .bold, design: .rounded))
          .foregroundStyle(theme.scoreColor(score))

        Text(Strings.statsMiniChartSleepScoreLabel)
          .font(theme.typography.font(size: size * 0.09, weight: .semibold))
          .foregroundStyle(theme.palette.textTertiary)
          .tracking(1)
      }
    }
    .frame(width: size, height: size)
    .accessibilityElement(children: .ignore)
    .accessibilityLabel(Strings.a11ySleepScore)
    .accessibilityValue(String(format: Strings.a11yScoreOutOf100, score))
    .onAppear { animatedProgress = CGFloat(score) / 100 }
    .onChange(of: score) { _, newScore in animatedProgress = CGFloat(newScore) / 100 }
  }
}
