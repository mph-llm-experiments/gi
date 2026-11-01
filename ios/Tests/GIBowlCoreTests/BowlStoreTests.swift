import SwiftData
import Testing
@testable import GIBowlCore

/// Keeps the in-memory container alive for as long as the store is used.
@MainActor
private struct MemoryStore {
    let container: ModelContainer
    let store: BowlStore

    init() throws {
        container = try ModelContainer(for: Schema(schema), configurations: ModelConfiguration(isStoredInMemoryOnly: true))
        store = BowlStore(context: container.mainContext)
    }
}

@Test @MainActor func addsAndTotals() throws {
    let memory = try MemoryStore()
    let store = memory.store
    let cc = SearchableFood(customID: "u:cc", name: "Cottage cheese", gi: nil, portions: [Portion(label: "½ cup", carbs: 5.4)])
    store.add(cc, portion: cc.portions[0])
    store.add(cc, portion: cc.portions[0])
    #expect(store.items().count == 2)
    #expect(abs(store.total() - 10.8) < 0.0001)
    store.remove(store.items()[0])
    #expect(abs(store.total() - 5.4) < 0.0001)
    store.clear()
    #expect(store.items().isEmpty)
}

@Test @MainActor func deletedCustomFoodStaysInBowl() throws {
    let memory = try MemoryStore()
    let store = memory.store
    let food = store.saveCustomFood(name: "Fage 0%", gi: nil, portions: [Portion(label: "1 cup", carbs: 9)])
    store.add(food.searchable, portion: food.portions[0])
    store.delete(food)
    #expect(store.customFoods().isEmpty)
    #expect(store.items().first?.name == "Fage 0%")
    #expect(store.items().first?.source == "custom")
    #expect(store.total() == 9)
}

@Test @MainActor func editKeepsID() throws {
    let memory = try MemoryStore()
    let store = memory.store
    let a = store.saveCustomFood(name: "A", gi: nil, portions: [Portion(label: "1", carbs: 1)])
    let b = store.saveCustomFood(name: "B", gi: 40, portions: [Portion(label: "1", carbs: 2)], replacing: a)
    #expect(a.id == b.id)
    #expect(store.customFoods().count == 1)
    #expect(store.customFoods()[0].name == "B")
    #expect(a.id.hasPrefix("u:"))
}

@Test func targetsClampZero() {
    #expect(Targets(meal: 0, snack: 15) == Targets(meal: nil, snack: 15))
    #expect(Targets(meal: -3, snack: nil).isSet == false)
    #expect(Targets(meal: 45, snack: 15).target(for: .snack) == 15)
    #expect(Targets(meal: 45, snack: 15).isSet)
}
