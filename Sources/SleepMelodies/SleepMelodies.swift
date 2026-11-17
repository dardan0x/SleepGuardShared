import Foundation
import SleepCore

/// The built-in melodies' sound files. A recording someone made isn't here:
/// the app that stored it knows where it is.
public enum SleepMelodies {
  /// The file for a built-in melody; `nil` for a recording.
  public static func url(for melody: Melody) -> URL? {
    guard !melody.isCustom else { return nil }
    return Bundle.module.url(forResource: melody.filename, withExtension: "mp3")
  }
}
