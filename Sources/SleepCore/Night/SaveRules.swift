import Foundation

/// When a stopped night is worth saving. A value the app passes in, so the rule
/// doesn't depend on how the package was built: an app that wants a shorter
/// minimum for testing at a desk passes its own rules in its Debug build.
public struct SaveRules: Sendable, Equatable {
  /// Shorter nights are offered for discard instead of saved.
  public let minimumDuration: TimeInterval

  public init(minimumDuration: TimeInterval) {
    self.minimumDuration = minimumDuration
  }

  /// The shipped rule: 30 minutes.
  public static let standard = SaveRules(minimumDuration: 1800)

  public func isLongEnough(_ duration: TimeInterval) -> Bool {
    duration >= minimumDuration
  }
}
