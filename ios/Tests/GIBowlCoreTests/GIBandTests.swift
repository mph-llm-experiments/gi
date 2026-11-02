import Testing
@testable import GIBowlCore

@Test(arguments: [(55, GIBand.low), (56, .medium), (69, .medium), (70, .high), (1, .low), (100, .high)])
func bands(_ gi: Int, _ band: GIBand) {
    #expect(giBand(gi) == band)
}

@Test func noGINoBand() {
    #expect(giBand(nil) == nil)
}

@Test func bandTitlesAndStates() {
    #expect(GIBand.low.title == "Low GI")
    #expect(GIBand.medium.title == "Medium GI")
    #expect(GIBand.high.title == "High GI")
    #expect(GIBand.low.state == .roomToSpare)
    #expect(GIBand.medium.state == .close)
    #expect(GIBand.high.state == .over)
}
