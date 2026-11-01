import Foundation

/// A household portion and its net carbs in grams.
public struct Portion: Codable, Hashable, Sendable {
    public let label: String
    public let carbs: Double

    public init(label: String, carbs: Double) {
        self.label = label
        self.carbs = carbs
    }
}

/// One food from foods.json v2: an everyday (canonical) food or a GI study row.
public struct Food: Decodable, Identifiable, Hashable, Sendable {
    public enum Kind: String, Decodable, Sendable {
        case canonical
        case study
    }

    public let id: String
    public let kind: Kind
    public let name: String
    public let category: String
    public let gi: Int?
    public let gl: Int?
    public let carbsPer100g: Double?
    public let carbSource: String?
    public let fdcId: Int?
    public let portions: [Portion]
}

/// The bundled food data, looked up by id.
public struct FoodCatalog: Sendable {
    public enum Error: Swift.Error, Equatable {
        case unsupportedVersion(Int)
    }

    private struct File: Decodable {
        let version: Int
        let foods: [Food]
    }

    public let foods: [Food]
    private let byID: [String: Food]

    public init(data: Data) throws {
        let file = try JSONDecoder().decode(File.self, from: data)
        guard file.version == 2 else { throw Error.unsupportedVersion(file.version) }
        foods = file.foods
        byID = Dictionary(file.foods.map { ($0.id, $0) }, uniquingKeysWith: { first, _ in first })
    }

    public subscript(id: String) -> Food? { byID[id] }
}
