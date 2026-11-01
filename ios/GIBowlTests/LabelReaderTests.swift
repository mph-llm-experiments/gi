import CoreGraphics
import GIBowlCore
import Testing
@testable import GIBowl

struct UnavailableModel: LabelModelExtractor {
    var isAvailable: Bool { false }
    func extract(from image: CGImage) async throws -> LabelReading { .empty }
}

struct ThrowingModel: LabelModelExtractor {
    struct Failure: Error {}
    var isAvailable: Bool { true }
    func extract(from image: CGImage) async throws -> LabelReading { throw Failure() }
}

struct StubModel: LabelModelExtractor {
    let reading: LabelReading
    var isAvailable: Bool { true }
    func extract(from image: CGImage) async throws -> LabelReading { reading }
}

struct StubRecognizer: LabelTextRecognizer {
    let lines: [String]
    func lines(in image: CGImage) async throws -> [String] { lines }
}

@Test func readsRenderedUSLabel() async throws {
    let image = LabelFixtures.image(["Nutrition Facts", "Serving size 1 cup (240g)", "Total Carbohydrate 26g", "Dietary Fiber 3g"])
    let r = await LabelReader(recognizer: VisionTextRecognizer(), model: UnavailableModel()).read(image)
    #expect(r.netCarbs == 23)
    #expect(r.servingLabel == "1 cup (240g)")
}

@Test func modelFailureFallsBackToVision() async throws {
    let image = LabelFixtures.image(["Total Carbohydrate 10g", "Dietary Fiber 2g"])
    let r = await LabelReader(recognizer: VisionTextRecognizer(), model: ThrowingModel()).read(image)
    #expect(r.netCarbs == 8)
}

@Test func modelResultPreferred() async throws {
    let model = StubModel(reading: LabelParser.reading(total: 12, fiber: 2, format: .us, serving: nil))
    let r = await LabelReader(recognizer: StubRecognizer(lines: ["Serving size 1 bar", "Total Carbohydrate 10g"]), model: model).read(LabelFixtures.image(["x"]))
    #expect(r.netCarbs == 10)
    #expect(r.fiberMissing == false)
    #expect(r.servingLabel == "1 bar")
}

@Test func blankImageReadsNothing() async {
    let r = await LabelReader(recognizer: VisionTextRecognizer(), model: UnavailableModel()).read(LabelFixtures.image([]))
    #expect(r.netCarbs == nil)
}

@Test func reportsModelAvailability() {
    print("SystemLanguageModel available on this device: \(ModelLabelExtractor().isAvailable)")
}

/// Exercises the real on-device model where available (it is on the iOS 27 simulator).
@Test(.enabled(if: ModelLabelExtractor().isAvailable))
func realModelReadsUSLabel() async throws {
    let r = try await ModelLabelExtractor().extract(from: LabelFixtures.image(LabelFixtures.us))
    print("Model reading: \(r)")
    #expect(r.totalCarbs == 37)
    #expect(r.fiber == 4)
    #expect(r.netCarbs == 33)
}
