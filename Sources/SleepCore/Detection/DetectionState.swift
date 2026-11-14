import Foundation

/// A snore classifier's verdict for one sample.
public enum DetectionState: String, Sendable, Codable {
  case none
  case quiet
  case light
  case loud
  case epic
}
