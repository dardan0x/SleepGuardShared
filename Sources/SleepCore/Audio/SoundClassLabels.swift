import Foundation

/// Which of Apple's built-in sound classes (SoundAnalysis, version 1) count as
/// snoring and as sleep talking, and the confidences that follow.
public enum SoundClassLabels {
  public static let snore = ["snore", "snoring"]
  /// Voice sounds a sleeper makes, plus baby sounds (counted as talking).
  public static let speech = [
    "speech", "talking", "conversation", "narration", "monologue",
    "whisper", "mumble", "mutter", "stutter",
    "groan", "moan", "sigh", "grunt", "grumble",
    "exclaim", "gasp", "yell", "scream", "shout",
    "laugh", "giggle", "whimper",
    "baby_crying", "baby_laughter", "babble",
  ]

  public struct Confidences: Sendable, Equatable {
    public let snore: Float
    public let speech: Float

    public init(snore: Float, speech: Float) {
      self.snore = snore
      self.speech = speech
    }
  }

  /// The highest confidence among snore classes and among speech classes. A
  /// class counts when its identifier contains one of the labels (any case).
  public static func confidences(_ classifications: [(identifier: String, confidence: Double)]) -> Confidences {
    var snoreConfidence: Float = 0
    var speechConfidence: Float = 0
    for (identifier, confidence) in classifications {
      let id = identifier.lowercased()
      if snore.contains(where: { id.contains($0) }) { snoreConfidence = max(snoreConfidence, Float(confidence)) }
      if speech.contains(where: { id.contains($0) }) { speechConfidence = max(speechConfidence, Float(confidence)) }
    }
    return Confidences(snore: snoreConfidence, speech: speechConfidence)
  }
}
