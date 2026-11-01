import Foundation
import Testing
@testable import GIBowlCore

/// The real foods.json built by plan 1's data pipeline.
let foodsJSONURL = URL(fileURLWithPath: #filePath)
    .deletingLastPathComponent()
    .appendingPathComponent("../../../public/foods.json")
    .standardizedFileURL

@Test func decodesRealFile() throws {
    let catalog = try FoodCatalog(data: Data(contentsOf: foodsJSONURL))
    #expect(catalog.foods.count > 2000)
    let cc = try #require(catalog["c:cottage-cheese"])
    #expect(cc.kind == .canonical && cc.gi == nil && cc.portions.first?.label == "½ cup")
    #expect(catalog["s1078"]?.gi == 44)
    #expect(catalog["s1078"]?.carbsPer100g == 11.6)
}

@Test func rejectsOtherVersions() {
    #expect(throws: FoodCatalog.Error.unsupportedVersion(1)) {
        try FoodCatalog(data: Data(#"{"version":1,"foods":[]}"#.utf8))
    }
}
