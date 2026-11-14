import Foundation

public enum SnoreIntensity: String, Codable, Sendable {
  case quiet
  case light
  case loud
  case epic

  public var rank: Int {
    switch self {
    case .quiet: 0
    case .light: 1
    case .loud: 2
    case .epic: 3
    }
  }
}
