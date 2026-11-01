import Foundation
import SwiftData

/// Operations on the current bowl and the user's own foods.
@MainActor
public struct BowlStore {
    private let context: ModelContext

    public init(context: ModelContext) {
        self.context = context
    }

    public func items() -> [BowlItem] {
        (try? context.fetch(FetchDescriptor<BowlItem>(sortBy: [SortDescriptor(\.addedAt)]))) ?? []
    }

    public func add(_ food: SearchableFood, portion: Portion) {
        context.insert(BowlItem(food: food, portion: portion))
        save()
    }

    public func remove(_ item: BowlItem) {
        context.delete(item)
        save()
    }

    public func clear() {
        for item in items() { context.delete(item) }
        save()
    }

    public func total() -> Double {
        items().reduce(0) { $0 + $1.carbs }
    }

    @discardableResult
    public func saveCustomFood(name: String, gi: Int?, portions: [Portion], replacing existing: CustomFood? = nil) -> CustomFood {
        if let existing {
            existing.name = name
            existing.gi = gi
            existing.portions = portions
            save()
            return existing
        }
        let food = CustomFood(name: name, gi: gi, portions: portions)
        context.insert(food)
        save()
        return food
    }

    public func delete(_ food: CustomFood) {
        context.delete(food)
        save()
    }

    public func customFoods() -> [CustomFood] {
        (try? context.fetch(FetchDescriptor<CustomFood>(sortBy: [SortDescriptor(\.name)]))) ?? []
    }

    private func save() {
        try? context.save()
    }
}
