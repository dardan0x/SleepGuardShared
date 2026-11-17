import Foundation

/// A page of the first-launch onboarding.
public enum OnboardingPage: String, CaseIterable, Sendable {
  case welcome
  case features
  case privacy
  /// Asks for Apple Health; only in an app that has it.
  case health
  /// Asks for the microphone.
  case microphone
  /// Start a night, or just look around.
  case start
}

/// Which onboarding pages an app shows, in order, and how one moves between
/// them: Next goes one page on, Skip goes to the last page, Back is offered
/// between the first and the last.
public struct OnboardingPages: Equatable, Sendable {
  public let pages: [OnboardingPage]

  /// `hasHealth`: the app can ask for Apple Health (otherwise no Health page).
  public init(hasHealth: Bool) {
    pages = OnboardingPage.allCases.filter { $0 != .health || hasHealth }
  }

  public var first: OnboardingPage { pages[0] }

  /// Skip lands here: the page that finishes onboarding.
  public var last: OnboardingPage { pages[pages.count - 1] }

  /// The page after `page`; the last page stays where it is.
  public func next(after page: OnboardingPage) -> OnboardingPage {
    guard let index = pages.firstIndex(of: page), index + 1 < pages.count else { return last }
    return pages[index + 1]
  }

  /// The page before `page`; the first stays where it is.
  public func previous(before page: OnboardingPage) -> OnboardingPage {
    guard let index = pages.firstIndex(of: page), index > 0 else { return first }
    return pages[index - 1]
  }

  /// Skip shows until the last page.
  public func showsSkip(on page: OnboardingPage) -> Bool {
    page != last
  }

  /// Back shows after the first page and before the last.
  public func showsBack(on page: OnboardingPage) -> Bool {
    page != first && page != last
  }
}
