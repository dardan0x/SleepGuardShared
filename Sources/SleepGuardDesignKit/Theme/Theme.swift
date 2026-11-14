import SwiftUI

/// A brand's visual identity: colours, type and corner radii.
///
/// A value, not a service: each app (or brand) builds one and puts it in the
/// SwiftUI environment (`.environment(\.theme, …)`); components read
/// `@Environment(\.theme)`. Previews and tests pass whatever theme they need.
public struct Theme: Sendable, Equatable {
  public var palette: Palette
  public var typography: Typography
  public var radii: Radii

  public init(palette: Palette, typography: Typography, radii: Radii) {
    self.palette = palette
    self.typography = typography
    self.radii = radii
  }

  /// Score bands: 80+ good, 50–79 fair, below 50 poor.
  public func scoreColor(_ score: Int) -> Color {
    switch score {
    case 80...: palette.scoreGreen
    case 50..<80: palette.scoreAmber
    default: palette.scoreRed
    }
  }
}

public struct Palette: Sendable, Equatable {
  // Backgrounds
  public var bgPrimary: Color
  public var bgSecondary: Color
  public var bgCard: Color
  public var bgElevated: Color
  // Accent and semantic
  public var accent: Color
  /// Also the recording red (start/stop buttons, live indicator).
  public var destructive: Color
  public var border: Color
  // Score
  public var scoreGreen: Color
  public var scoreAmber: Color
  public var scoreRed: Color
  // Snore intensity
  public var snoreQuiet: Color
  public var snoreLight: Color
  public var snoreLoud: Color
  public var snoreEpic: Color
  // Sound category
  public var sleepTalking: Color
  public var noise: Color
  // Sleep stage
  public var stageDeep: Color
  public var stageLight: Color
  public var stageREM: Color
  public var stageAwake: Color
  // Text
  public var textPrimary: Color
  public var textSecondary: Color
  public var textTertiary: Color
  public var textDim: Color
  public var tabInactive: Color

  public var accentDim: Color {
    accent.opacity(0.2)
  }

  public init(
    bgPrimary: Color, bgSecondary: Color, bgCard: Color, bgElevated: Color,
    accent: Color, destructive: Color, border: Color,
    scoreGreen: Color, scoreAmber: Color, scoreRed: Color,
    snoreQuiet: Color, snoreLight: Color, snoreLoud: Color, snoreEpic: Color,
    sleepTalking: Color, noise: Color,
    stageDeep: Color, stageLight: Color, stageREM: Color, stageAwake: Color,
    textPrimary: Color, textSecondary: Color, textTertiary: Color, textDim: Color, tabInactive: Color)
  {
    self.bgPrimary = bgPrimary
    self.bgSecondary = bgSecondary
    self.bgCard = bgCard
    self.bgElevated = bgElevated
    self.accent = accent
    self.destructive = destructive
    self.border = border
    self.scoreGreen = scoreGreen
    self.scoreAmber = scoreAmber
    self.scoreRed = scoreRed
    self.snoreQuiet = snoreQuiet
    self.snoreLight = snoreLight
    self.snoreLoud = snoreLoud
    self.snoreEpic = snoreEpic
    self.sleepTalking = sleepTalking
    self.noise = noise
    self.stageDeep = stageDeep
    self.stageLight = stageLight
    self.stageREM = stageREM
    self.stageAwake = stageAwake
    self.textPrimary = textPrimary
    self.textSecondary = textSecondary
    self.textTertiary = textTertiary
    self.textDim = textDim
    self.tabInactive = tabInactive
  }
}

public struct Typography: Sendable, Equatable {
  /// The design used for text. Large numbers (scores, stat values) stay
  /// `.rounded` in every theme.
  public var design: Font.Design

  public init(design: Font.Design) {
    self.design = design
  }

  public func font(size: CGFloat, weight: Font.Weight = .regular) -> Font {
    .system(size: size, weight: weight, design: design)
  }
}

public struct Radii: Sendable, Equatable {
  public var card: CGFloat
  public var small: CGFloat

  public init(card: CGFloat, small: CGFloat) {
    self.card = card
    self.small = small
  }
}
