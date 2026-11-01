import Foundation
import Testing
@testable import GIBowlCore

private let catalog = try! FoodCatalog(data: Data(contentsOf: foodsJSONURL))
private let fage = SearchableFood(customID: "u:1", name: "Greek yogurt, Fage 0%", gi: nil, portions: [Portion(label: "1 cup", carbs: 9)])
private let search = FoodSearch(catalog.foods.map(SearchableFood.init) + [fage])

@Test func findsEverydayFoodsFirst() {
    #expect(search.search("cottage").first?.id == "c:cottage-cheese")
    #expect(search.search("apple").first?.id == "c:apple-raw")
    #expect(search.search("rice white").first?.id == "c:white-rice-cooked")
}

@Test func toleratesTypos() {
    #expect(search.search("cotage").first?.id == "c:cottage-cheese")
}

@Test func findsYourOwnFoods() {
    #expect(search.search("fage").first?.id == "u:1")
}

@Test func emptyAndTinyQueriesReturnNothing() {
    #expect(search.search("").isEmpty)
    #expect(search.search("   ").isEmpty)
    #expect(search.search("a").isEmpty)
    #expect(search.search("½").isEmpty)
}

@Test func normalizesDiacriticsAndPunctuation() {
    #expect(normalize("Crème Fraîche, ½-fat") == ["creme", "fraiche", "fat"])
    _ = search.search("crème")
}

/// Release builds run 200 searches in ~0.06s; the bound allows for unoptimized debug builds.
@Test func isFastEnough() {
    let start = Date()
    for q in Array(repeating: ["apple", "cotage", "rice white", "banana raw"], count: 50).joined() {
        _ = search.search(q)
    }
    #expect(Date().timeIntervalSince(start) < 4)
}
