import Testing
@testable import GIBowlCore

@Test(arguments: [(2.9, "a few grams"), (0, "a few grams"), (3, "about 5g"), (7.4, "about 5g"), (7.5, "about 10g"), (21.3, "about 20g")])
func about(_ grams: Double, _ expected: String) {
    #expect(aboutCarbs(grams) == expected)
}

@Test func states() {
    #expect(stateFor(total: 11.2, target: 15) == .roomToSpare)
    #expect(stateFor(total: 11.25, target: 15) == .close)
    #expect(stateFor(total: 15, target: 15) == .close)
    #expect(stateFor(total: 15.01, target: 15) == .over)
    #expect(stateFor(total: 10, target: nil) == nil)
    #expect(stateFor(total: 10, target: 0) == nil)
}

@Test func hints() {
    #expect(hint(total: 5.4, target: 15) == "Room for about 10g more")
    #expect(hint(total: 13, target: 15) == "Right about at it")
    #expect(hint(total: 26, target: 15) == "Roughly 10g past it")
    #expect(hint(total: 15.5, target: 15) == "Roughly 5g past it")
}

@Test func titles() {
    #expect(BowlState.roomToSpare.title == "Room to spare")
    #expect(BowlState.close.title == "Close to your number")
    #expect(BowlState.over.title == "Over your number")
}
