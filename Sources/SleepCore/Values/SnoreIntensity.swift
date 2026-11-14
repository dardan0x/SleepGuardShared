import Foundation

public enum SnoreIntensity: String, Codable, Sendable, Comparable {
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

  /// Ordered by `rank`: quiet < light < loud < epic.
  public static func < (lhs: SnoreIntensity, rhs: SnoreIntensity) -> Bool {
    lhs.rank < rhs.rank
  }
}
