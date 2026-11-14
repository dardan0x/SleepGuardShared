import SwiftUI

/// The score in a circle of its band's colour.
public struct ScoreBadge: View {
  let score: Int
  let size: CGFloat
  @Environment(\.theme) private var theme

  public init(score: Int, size: CGFloat) {
    self.score = score
    self.size = size
  }

  public var body: some View {
    Text("\(score)")
      .font(.system(size: size * 0.38, weight: .bold, design: .rounded))
      .foregroundStyle(theme.palette.textPrimary)
      .frame(width: size, height: size)
      .background(theme.scoreColor(score), in: .circle)
  }
}
