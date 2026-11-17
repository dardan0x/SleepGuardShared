import Foundation

/// How long the Snore Interrupter plays its melody once snoring is detected.
/// The raw values are the ones SleepGuard stores, so a saved choice reads back.
public enum SnoreInterrupterMode: String, CaseIterable, Codable, Sendable {
  case never
  case always
  case fiveSeconds
  case fifteenSeconds
  case thirtySeconds
  case sixtySeconds

  /// Whether the interrupter plays at all.
  public var isOn: Bool { self != .never }

  /// The melody repeats until detection stops it.
  public var loops: Bool { self == .always }

  /// How long one play lasts at most; `nil` when it isn't cut short (off, or
  /// looping until stopped). The melody also ends when its file does.
  public var playDuration: TimeInterval? {
    switch self {
    case .never, .always: nil
    case .fiveSeconds: 5
    case .fifteenSeconds: 15
    case .thirtySeconds: 30
    case .sixtySeconds: 60
    }
  }

  /// A stored value that isn't a mode is off.
  public init(stored: String?) {
    self = stored.flatMap(Self.init(rawValue:)) ?? .never
  }
}
