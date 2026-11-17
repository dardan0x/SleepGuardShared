import Testing
@testable import SleepCore

struct OnboardingPagesTests {
  @Test func healthShowsOnlyWithHealth() {
    #expect(OnboardingPages(hasHealth: true).pages == [.welcome, .features, .privacy, .health, .microphone, .start])
    #expect(OnboardingPages(hasHealth: false).pages == [.welcome, .features, .privacy, .microphone, .start])
  }

  @Test func nextAndPreviousFollowTheList() {
    let pages = OnboardingPages(hasHealth: false)
    #expect(pages.next(after: .privacy) == .microphone)
    #expect(pages.next(after: .start) == .start)
    #expect(pages.previous(before: .microphone) == .privacy)
    #expect(pages.previous(before: .welcome) == .welcome)
    // A page the app doesn't show moves to the last.
    #expect(pages.next(after: .health) == .start)
  }

  @Test func skipAndBackVisibility() {
    let pages = OnboardingPages(hasHealth: true)
    #expect(pages.last == .start)
    #expect(pages.showsSkip(on: .welcome))
    #expect(!pages.showsSkip(on: .start))
    #expect(!pages.showsBack(on: .welcome))
    #expect(pages.showsBack(on: .health))
    #expect(!pages.showsBack(on: .start))
  }
}
