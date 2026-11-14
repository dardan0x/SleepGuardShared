import Foundation

public extension SleepScore {
  /// Bump when the formula's *code* changes (a new penalty, different episode
  /// merging, gap rules). Coefficient changes don't need a bump: they change
  /// the config fingerprint in `cacheVersion(for:)`.
  static let formulaVersion = 1

  /// Identifies the formula + config that produced a cached score:
  /// `"<formulaVersion>-<config fingerprint>"`. A stored score whose version
  /// differs is stale.
  static func cacheVersion(for config: SleepScoreConfig) -> String {
    "\(formulaVersion)-\(String(fingerprint(of: config), radix: 16))"
  }

  /// FNV-1a over the config's sorted-key JSON. Unlike `hashValue`, it is the
  /// same on every launch, so it can be persisted.
  private static func fingerprint(of config: SleepScoreConfig) -> UInt64 {
    let encoder = JSONEncoder()
    encoder.outputFormatting = .sortedKeys
    let data = (try? encoder.encode(config)) ?? Data()
    return data.reduce(0xCBF2_9CE4_8422_2325) { ($0 ^ UInt64($1)) &* 0x0000_0100_0000_01B3 }
  }
}
