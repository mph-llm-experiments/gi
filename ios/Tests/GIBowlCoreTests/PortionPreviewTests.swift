import Testing
@testable import GIBowlCore

private let apple = SearchableFood(customID: "u:x", name: "Apple", gi: 44, portions: [Portion(label: "1 small", carbs: 17), Portion(label: "1 large", carbs: 25.4)])

@Test func previewsShowWhereTheBowlWouldLand() {
    let p = previews(for: apple, bowlTotal: 6, target: 30)
    #expect(p.map(\.landsIn) == [.close, .over])
    #expect(p.map(\.label) == ["about 15g", "about 25g"])
}

@Test func previewsWithoutTargetsHaveNoState() {
    #expect(previews(for: apple, bowlTotal: 0, target: nil).allSatisfy { $0.landsIn == nil })
}
