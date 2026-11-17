import Foundation

/// A sound the Snore Interrupter can play: one of the built-in melodies, or a
/// recording someone made. A built-in has no stored name: the view names it
/// from its id, so the name is translated.
public struct Melody: Identifiable, Hashable, Codable, Sendable {
  public let id: Int
  /// A built-in's resource name (no extension), or a recording's file name.
  public let filename: String
  /// The name someone's recording was saved with; `nil` for a built-in.
  public let customName: String?

  public var isCustom: Bool { customName != nil }

  public init(id: Int, filename: String, customName: String? = nil) {
    self.id = id
    self.filename = filename
    self.customName = customName
  }
}

public extension Melody {
  /// The melodies that ship with the app, in picker order (SleepGuard's ids).
  static let builtIn: [Melody] = [
    Melody(id: 1, filename: "3dabrar-funny-alarm-317531"),
    Melody(id: 2, filename: "freesound_community-clapping-29511"),
    Melody(id: 3, filename: "freesound_community-909-snare-clap-89488"),
    Melody(id: 4, filename: "dragon-studio-bird-chittering-sfx-364487"),
    Melody(id: 5, filename: "dragon-studio-cute-cat-meow-472372"),
    Melody(id: 6, filename: "universfield-attention-chime-123107"),
    Melody(id: 7, filename: "female_voice_baby_stop"),
    Melody(id: 8, filename: "Male_Voice_Saying_Stop"),
    Melody(id: 9, filename: "freesound_community-accoustic-guitar-gloomy-calm-song-30116"),
    Melody(id: 10, filename: "freesound_community-squeaky-toy-1-6059"),
    Melody(id: 11, filename: "lucadialessandro-funny-cartoon-sound-397415"),
  ]

  /// Attention Chime: the choice before someone picks one.
  static let defaultID = 6

  /// The melody for a stored id. A missing or deleted one falls back to the
  /// default, so the interrupter always has something to play.
  static func resolve(id: Int, custom: [Melody]) -> Melody {
    builtIn.first { $0.id == id }
      ?? custom.first { $0.id == id }
      ?? builtIn.first { $0.id == defaultID }!
  }
}

/// The rules for recordings someone makes as their own melody.
public enum CustomMelodies {
  /// A recording stops by itself at this length.
  public static let maxRecordingDuration: TimeInterval = 10

  /// Recordings' ids start here, clear of the built-ins.
  public static let firstID = 100

  /// The id for the next recording: never one already used, never below `firstID`.
  public static func nextID(stored: Int, existing: [Melody]) -> Int {
    max(firstID, stored, (existing.map(\.id).max() ?? 0) + 1)
  }

  /// "custom_<id>.m4a".
  public static func filename(id: Int) -> String {
    "custom_\(id).m4a"
  }

  /// The number in a new recording's default name ("My Sound 3").
  public static func nameNumber(existing: [Melody]) -> Int {
    existing.count + 1
  }
}
