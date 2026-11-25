import Foundation

/// A value an app stores as-is (SwiftData transformable blobs, records, JSON).
/// Its coded shape is a persisted format, not just an API: renaming or removing
/// a property, changing a type or a raw value breaks every existing install.
///
/// Rules for every conforming type:
/// - Add properties only, each optional or decoded with a default.
/// - Never rename or remove a property or an enum case's raw value.
/// - Add a fixture under `Tests/SleepCoreTests/Fixtures/StoredValues/<version>/`
///   when the shape changes; `StoredValuesTests` decodes every released one.
public protocol StoredValue: Codable, Sendable {}

// The values the apps store today (SwiftData blobs and raw values, raw logs,
// preferences). `RecordingGap` and its `Kind` conform where they're declared.
extension SleepStageSegment: StoredValue {}
extension SleepStage: StoredValue {}
extension SnoreBurst: StoredValue {}
extension SnoreIntensity: StoredValue {}
extension SoundCategory: StoredValue {}
extension SnoreSample: StoredValue {}
extension DetectionState: StoredValue {}
extension DetectionSensitivity: StoredValue {}
extension SnoreInterrupterMode: StoredValue {}
