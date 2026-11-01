import SwiftData

/// Version 1 of the saved data: your own foods and the current bowl.
public enum GIBowlSchemaV1: VersionedSchema {
    public static let versionIdentifier = Schema.Version(1, 0, 0)
    public static var models: [any PersistentModel.Type] { [CustomFood.self, BowlItem.self] }
}

/// Add a schema and a stage here whenever the models change.
public enum GIBowlMigrationPlan: SchemaMigrationPlan {
    public static var schemas: [any VersionedSchema.Type] { [GIBowlSchemaV1.self] }
    public static var stages: [MigrationStage] { [] }
}

public func makeModelContainer(inMemory: Bool = false) throws -> ModelContainer {
    try ModelContainer(
        for: Schema(versionedSchema: GIBowlSchemaV1.self),
        migrationPlan: GIBowlMigrationPlan.self,
        configurations: ModelConfiguration(isStoredInMemoryOnly: inMemory)
    )
}
