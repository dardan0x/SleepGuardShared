public import Foundation
public import SwiftData

/// Version 1 of the shared schema. While V1 is current it points at the live
/// record classes. Before a breaking change: copy today's classes into this
/// enum as nested types, declare V2 with the live classes, add a
/// `MigrationStage`, and add a test that opens a V1 store on disk.
public enum SleepStoreSchemaV1: VersionedSchema {
  public static let versionIdentifier = Schema.Version(1, 0, 0)

  public static var models: [any PersistentModel.Type] {
    [NightRecord.self, NightEventRecord.self]
  }
}

public enum SleepStoreMigrationPlan: SchemaMigrationPlan {
  public static var schemas: [any VersionedSchema.Type] {
    [SleepStoreSchemaV1.self]
  }

  public static var stages: [MigrationStage] {
    []
  }
}

public enum SleepStoreSchema {
  public typealias Current = SleepStoreSchemaV1

  public static var schema: Schema {
    Schema(versionedSchema: Current.self)
  }

  /// `url == nil` keeps the store in memory (tests, previews).
  public static func container(at url: URL?) throws -> ModelContainer {
    let configuration = url.map { ModelConfiguration(schema: schema, url: $0) }
      ?? ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
    return try ModelContainer(for: schema, migrationPlan: SleepStoreMigrationPlan.self, configurations: [configuration])
  }
}
