import Foundation
import Testing
@testable import SleepCore

/// The playback rules, as SleepGuard's `ClipPlaybackController` applies them.
struct ClipPlaylistTests {
  /// Three clips: 10 s, 20 s, 30 s (60 s in all).
  private func playlist() -> ClipPlaylist {
    ClipPlaylist(clips: [10, 20, 30].map { ClipPlaylist.Clip(id: UUID(), fileName: "\($0).m4a", duration: $0) })
  }

  @Test func timelineJoinsTheClips() {
    var list = playlist()
    #expect(list.totalDuration == 60)
    #expect(list.currentTime == 0 && list.progress == 0)
    list.select(2)
    list.offset = 15
    #expect(list.currentClipStart == 30)
    #expect(list.currentTime == 45)
    #expect(list.progress == 0.75)
  }

  @Test func seekingFindsTheClipAndOffset() {
    var list = playlist()
    list.seek(toProgress: 0.5) // 30 s: the end of clip 1, which reaches it first
    #expect(list.index == 1 && list.offset == 20)
    list.seek(toProgress: 0.6) // 36 s: 6 s into clip 2
    #expect(list.index == 2)
    #expect(abs(list.offset - 6) < 1e-9)
    list.seek(toProgress: 0)
    #expect(list.index == 0 && list.offset == 0)
  }

  @Test func seekingPastTheEndStopsAtTheLastClipsEnd() {
    var list = playlist()
    list.seek(toProgress: 1.5)
    #expect(list.index == 2 && list.offset == 30)
  }

  @Test func seekingWithinTheClipIsClamped() {
    var list = playlist()
    list.select(1)
    list.seek(inClip: 0.25)
    #expect(list.offset == 5)
    list.seek(inClip: 2)
    #expect(list.offset == 20)
    list.seek(inClip: -1)
    #expect(list.offset == 0)
  }

  @Test func selectingOutOfRangeChangesNothing() {
    var list = playlist()
    list.select(1)
    list.offset = 4
    let before = list.select(-1)
    let after = list.select(3)
    #expect(!before && !after)
    #expect(list.index == 1 && list.offset == 4)
    let valid = list.select(2)
    #expect(valid)
    #expect(list.offset == 0)
  }

  @Test func aFinishedClipPlaysTheNextThenStopsAtTheStart() {
    var list = playlist()
    list.offset = 10
    let first = list.clipFinished()
    #expect(first == .playNext)
    #expect(list.index == 1 && list.offset == 0)
    let second = list.clipFinished()
    let third = list.clipFinished()
    #expect(second == .playNext && third == .stopAtStart)
    #expect(list.index == 0 && list.offset == 0)
  }

  @Test func emptyPlaylistIsInert() {
    var list = ClipPlaylist(clips: [])
    list.seek(toProgress: 0.5)
    list.seek(inClip: 0.5)
    #expect(list.current == nil && list.progress == 0)
    let after = list.clipFinished()
    #expect(after == .stopAtStart)
  }

  @Test func clipsComeFromEvents() {
    let start = Date(timeIntervalSinceReferenceDate: 0)
    let event = NightEvent(start: start, duration: 42, category: .snoring, intensity: .loud, clipFileName: "a.m4a")
    let list = ClipPlaylist(events: [event])
    #expect(list.clips == [ClipPlaylist.Clip(id: event.id, fileName: "a.m4a", duration: 42)])
  }

  @Test func boostBringsThePeakToMinusThreeDecibels() {
    #expect(PlaybackGain.boostDB(peak: 0) == 0)
    #expect(PlaybackGain.boostDB(peak: 0.9) == 0) // never quieter
    #expect(abs(PlaybackGain.boostDB(peak: 0.354) - 6.02) < 0.01) // half the target: +6 dB
    #expect(PlaybackGain.boostDB(peak: 0.0001) == 24) // capped
  }
}
