/// A food the user can search for and add: from the bundled data or their own.
public struct SearchableFood: Identifiable, Hashable, Sendable {
    public enum Source: String, Sendable {
        case dataset
        case custom
    }

    public let id: String
    public let source: Source
    /// Search ordering: 0 for everyday and your own foods, 1 for GI study rows.
    public let tier: Int
    public let name: String
    public let category: String?
    public let gi: Int?
    public let gl: Int?
    public let portions: [Portion]

    public init(food: Food) {
        id = food.id
        source = .dataset
        tier = food.kind == .canonical ? 0 : 1
        name = food.name
        category = food.category
        gi = food.gi
        gl = food.gl
        portions = food.portions
    }

    public init(customID: String, name: String, gi: Int?, portions: [Portion]) {
        id = customID
        source = .custom
        tier = 0
        self.name = name
        category = nil
        self.gi = gi
        gl = nil
        self.portions = portions
    }
}
