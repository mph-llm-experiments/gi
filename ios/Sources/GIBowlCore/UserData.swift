import Foundation
import SwiftData

/// A food the user added themselves, typically from a label.
@Model
public final class CustomFood {
    @Attribute(.unique) public var id: String
    public var name: String
    public var gi: Int?
    public var portions: [Portion]
    public var createdAt: Date

    public init(name: String, gi: Int?, portions: [Portion]) {
        id = "u:\(UUID().uuidString)"
        self.name = name
        self.gi = gi
        self.portions = portions
        createdAt = .now
    }

    public var searchable: SearchableFood {
        SearchableFood(customID: id, name: name, gi: gi, portions: portions)
    }
}

/// One portion in the current bowl. Name and carbs are snapshots, so the item
/// stays put if its food is edited or deleted.
@Model
public final class BowlItem {
    public var foodID: String
    public var source: String
    public var name: String
    public var portionLabel: String
    public var carbs: Double
    public var addedAt: Date

    public init(food: SearchableFood, portion: Portion) {
        foodID = food.id
        source = food.source.rawValue
        name = food.name
        portionLabel = portion.label
        carbs = portion.carbs
        addedAt = .now
    }
}

public enum BowlMode: String, CaseIterable, Sendable {
    case meal
    case snack
}

/// The user's carb numbers. Zero or negative means not set.
public struct Targets: Equatable, Sendable {
    public var meal: Int?
    public var snack: Int?

    public init(meal: Int?, snack: Int?) {
        self.meal = meal.flatMap { $0 > 0 ? $0 : nil }
        self.snack = snack.flatMap { $0 > 0 ? $0 : nil }
    }

    public func target(for mode: BowlMode) -> Int? {
        mode == .meal ? meal : snack
    }

    public var isSet: Bool { meal != nil && snack != nil }
}

/// Ask for numbers once, and only when the current mode has none. Numbers are optional.
public func shouldAskForTargets(_ targets: Targets, mode: BowlMode, alreadyAsked: Bool) -> Bool {
    !alreadyAsked && targets.target(for: mode) == nil
}
