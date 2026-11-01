import SwiftData
import Testing
@testable import GIBowlCore

@Test @MainActor func containerBuildsWithMigrationPlan() throws {
    let container = try makeModelContainer(inMemory: true)
    #expect(container.schema.entities.count == 2)
}
