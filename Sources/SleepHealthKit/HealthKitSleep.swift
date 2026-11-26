public import Foundation
public import HealthKit
public import SleepCore

/// A night in Apple Health, the same way in every app: written as one
/// "asleep" sample carrying the night's snoring as metadata, and its sleep
/// stages read back from the staged samples (an Apple Watch's) inside it.
///
/// Each app wraps this in its own service or port (its state, its DI, its
/// logging): what is shared is what HealthKit sees. Its own product, so an
/// app or brand without HealthKit doesn't link it.
public struct HealthKitSleep: Sendable {
  private let store: HKHealthStore

  public init(store: HKHealthStore = HKHealthStore()) {
    self.store = store
  }

  /// False on a device without Health (an iPad) or a brand that's off.
  public static var isAvailable: Bool {
    HKHealthStore.isHealthDataAvailable()
  }

  private static var sleepType: HKCategoryType {
    HKCategoryType(.sleepAnalysis)
  }

  /// Asks to read and write sleep. True when writing is allowed: HealthKit
  /// never says whether reading is (privacy), so that is the only answer.
  public func requestAuthorization() async throws -> Bool {
    guard Self.isAvailable else { return false }
    try await store.requestAuthorization(toShare: [Self.sleepType], read: [Self.sleepType])
    return canWrite
  }

  /// Writing sleep is allowed.
  public var canWrite: Bool {
    Self.isAvailable && store.authorizationStatus(for: Self.sleepType) == .sharingAuthorized
  }

  /// The staged sleep between `start` and `end`, as offsets from `start`.
  /// Empty without Health, without stages, or when reading wasn't allowed
  /// (HealthKit then returns nothing rather than an error).
  public func stages(from start: Date, to end: Date) async throws -> [SleepStageSegment] {
    guard Self.isAvailable else { return [] }
    let descriptor = HKSampleQueryDescriptor(
      predicates: [.categorySample(type: Self.sleepType, predicate: HKQuery.predicateForSamples(withStart: start, end: end))],
      sortDescriptors: [SortDescriptor(\.startDate)])
    return try await descriptor.result(for: store).compactMap { sample in
      Self.stage(for: sample.value).map {
        SleepStageSegment(
          stage: $0, startOffset: sample.startDate.timeIntervalSince(start),
          duration: sample.endDate.timeIntervalSince(sample.startDate))
      }
    }
  }

  /// Writes the night when writing is allowed; does nothing otherwise.
  public func save(_ night: Night, summary: NightSummary) async throws {
    guard canWrite else { return }
    try await store.save(Self.sample(for: night, summary: summary))
  }

  // MARK: - The mapping (tested)

  /// HealthKit's staged values as stages. Unstaged sleep ("asleep", in bed,
  /// a night these apps wrote) is no stage.
  public static func stage(for value: Int) -> SleepStage? {
    switch HKCategoryValueSleepAnalysis(rawValue: value) {
    case .asleepCore: .light
    case .asleepDeep: .deep
    case .asleepREM: .rem
    case .awake: .awake
    default: nil
    }
  }

  /// The sample a night is written as. The metadata keys are the ones the
  /// apps have always written, so nights saved before stay comparable.
  public static func sample(for night: Night, summary: NightSummary) -> HKCategorySample {
    HKCategorySample(
      type: sleepType,
      value: HKCategoryValueSleepAnalysis.asleepUnspecified.rawValue,
      start: night.start,
      end: night.end,
      metadata: [
        HKMetadataKeyWasUserEntered: true,
        "snoreEventsCount": summary.eventCount,
        "snoringPercentage": summary.snoringShare * 100,
        "averageDB": night.averageDB,
        "peakDB": night.peakDB,
      ])
  }
}
