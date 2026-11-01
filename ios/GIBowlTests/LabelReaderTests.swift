import CoreGraphics
import UIKit
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

/// The model can invent numbers for an image with no label on it; only trust it when Vision sees a carbohydrate line.
@Test func modelIgnoredWhenNoLabelTextSeen() async {
    let model = StubModel(reading: LabelParser.reading(total: 20, fiber: 2, format: .us, serving: "1 bar"))
    let r = await LabelReader(recognizer: StubRecognizer(lines: ["Hello"]), model: model).read(LabelFixtures.image([]))
    #expect(r.netCarbs == nil)
}

@Test(.enabled(if: ModelLabelExtractor().isAvailable))
func realModelOnBlankImageReadsNothing() async {
    let r = await LabelReader().read(LabelFixtures.image([]))
    #expect(r.netCarbs == nil)
}

@Test func visionFormatAndFiberWinOverTheModel() async {
    let usLines = ["Serving size 2/3 cup (55g)", "Total Carbohydrate 37g", "Dietary Fiber 4g"]
    let euGuess = StubModel(reading: LabelParser.reading(total: 37, fiber: nil, format: .eu, serving: nil))
    let r = await LabelReader(recognizer: StubRecognizer(lines: usLines), model: euGuess).read(LabelFixtures.image(["x"]))
    #expect(r.netCarbs == 33 && !r.fiberMissing && r.format == .us)
}

@Test func largePhotosAreDownscaled() {
    let big = UIGraphicsImageRenderer(size: CGSize(width: 6000, height: 4000), format: { let f = UIGraphicsImageRendererFormat(); f.scale = 1; return f }()).image { _ in }
    let cg = big.labelReadyCGImage()
    #expect(cg != nil && max(cg!.width, cg!.height) <= LabelImage.maxDimension)
    let data = big.jpegData(compressionQuality: 0.5)!
    let fromData = LabelImage.cgImage(from: data)
    #expect(fromData != nil && max(fromData!.width, fromData!.height) <= LabelImage.maxDimension)
}

struct StubClassifier: LabelImageClassifier {
    let labels: [String]
    func labels(in image: CGImage) async throws -> [String] { labels }
}

@Test func plateLooksLikeFood() async {
    let r = await LabelReader(recognizer: StubRecognizer(lines: ["Oh hi"]), model: UnavailableModel(), classifier: StubClassifier(labels: ["food", "salad"])).read(LabelFixtures.image([]))
    #expect(r.notALabel == .food)
    #expect(r.netCarbs == nil)
}

@Test func nonFoodNonLabelIsOther() async {
    let r = await LabelReader(recognizer: StubRecognizer(lines: []), model: UnavailableModel(), classifier: StubClassifier(labels: ["document", "text"])).read(LabelFixtures.image([]))
    #expect(r.notALabel == .other)
}

@Test func labelsAreNotFlagged() async {
    let r = await LabelReader(recognizer: StubRecognizer(lines: ["Total Carbohydrate 10g", "Dietary Fiber 2g"]), model: UnavailableModel(), classifier: StubClassifier(labels: ["food"])).read(LabelFixtures.image([]))
    #expect(r.notALabel == nil)
    #expect(r.netCarbs == 8)
}

@Test func realClassifierOnBlankImageIsNotFood() async {
    let r = await LabelReader().read(LabelFixtures.image([]))
    #expect(r.notALabel == .other)
}
