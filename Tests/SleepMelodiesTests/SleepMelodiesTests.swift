import Foundation
import SleepCore
import SleepMelodies
import Testing

struct SleepMelodiesTests {
  @Test func everyBuiltInHasItsFile() throws {
    for melody in Melody.builtIn {
      let url = try #require(SleepMelodies.url(for: melody), "no file for \(melody.filename)")
      #expect(FileManager.default.fileExists(atPath: url.path))
    }
  }

  @Test func aRecordingIsNotHere() {
    #expect(SleepMelodies.url(for: Melody(id: 100, filename: "custom_100.m4a", customName: "Mine")) == nil)
  }
}
