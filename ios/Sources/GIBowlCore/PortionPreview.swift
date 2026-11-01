/// A portion button's content: rough carbs and where the bowl would land if added.
public struct PortionPreview: Sendable, Hashable {
    public let portion: Portion
    public let label: String
    public let landsIn: BowlState?
}

public func previews(for food: SearchableFood, bowlTotal: Double, target: Int?) -> [PortionPreview] {
    food.portions.map { portion in
        PortionPreview(
            portion: portion,
            label: aboutCarbs(portion.carbs),
            landsIn: stateFor(total: bowlTotal + portion.carbs, target: target)
        )
    }
}
