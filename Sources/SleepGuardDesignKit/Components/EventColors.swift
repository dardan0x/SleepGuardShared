import SleepCore
import SwiftUI

public extension Palette {
  /// One event's colour: snoring by intensity, sleep talking and noise by
  /// their category colour. The one rule for rows, cards and the timeline.
  func eventColor(_ category: SoundCategory, intensity: SnoreIntensity) -> Color {
    switch category {
    case .snoring:
      switch intensity {
      case .quiet: snoreQuiet
      case .light: snoreLight
      case .loud: snoreLoud
      case .epic: snoreEpic
      }
    case .sleepTalking: sleepTalking
    case .noise, .coughing, .other: noise
    }
  }
}
