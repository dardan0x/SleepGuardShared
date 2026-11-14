import SwiftUI

public extension Theme {
  /// SleepGuard's tokens, as in its `designs/SleepGuard.pen` and its
  /// `DesignSystem/Theme.swift`. The default theme.
  static let sleepGuard = Theme(
    palette: Palette(
      bgPrimary: Color(hex: "#000000"),
      bgSecondary: Color(hex: "#1C1C1E"),
      bgCard: Color(hex: "#22232B"),
      bgElevated: Color(hex: "#3A3A3C"),
      accent: Color(hex: "#5E9CFF"),
      destructive: Color(hex: "#FF453A"),
      border: Color(hex: "#38383A"),
      scoreGreen: Color(hex: "#30D158"),
      scoreAmber: Color(hex: "#FF9F0A"),
      scoreRed: Color(hex: "#FF453A"),
      snoreQuiet: Color(hex: "#8E8E93"),
      snoreLight: Color(hex: "#FF9F0A"),
      snoreLoud: Color(hex: "#FF453A"),
      snoreEpic: Color(hex: "#FF2D55"),
      sleepTalking: Color(hex: "#BF5AF2"),
      noise: Color(hex: "#FF9F0A"),
      stageDeep: Color(hex: "#5E5CE6"),
      stageLight: Color(hex: "#0A84FF"),
      stageREM: Color(hex: "#64D2FF"),
      stageAwake: Color(hex: "#FFD60A"),
      textPrimary: Color(hex: "#FFFFFF"),
      textSecondary: Color(hex: "#ABABAB"),
      textTertiary: Color(hex: "#8E8E93"),
      textDim: Color(hex: "#FFFFFF").opacity(0.4),
      tabInactive: Color(hex: "#8E8E93")),
    typography: Typography(design: .default),
    radii: Radii(card: 16, small: 12))
}

public extension EnvironmentValues {
  /// The current brand's theme. Defaults to SleepGuard's.
  @Entry var theme: Theme = .sleepGuard
}

public extension Color {
  /// `#RGB`, `#RRGGBB` or `#AARRGGBB`.
  init(hex: String) {
    let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
    var int: UInt64 = 0
    Scanner(string: hex).scanHexInt64(&int)
    let a, r, g, b: UInt64
    switch hex.count {
    case 3: (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
    case 6: (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
    case 8: (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
    default: (a, r, g, b) = (255, 0, 0, 0)
    }
    self.init(.sRGB, red: Double(r) / 255, green: Double(g) / 255, blue: Double(b) / 255, opacity: Double(a) / 255)
  }
}
