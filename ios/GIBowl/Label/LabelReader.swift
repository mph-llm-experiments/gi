import CoreGraphics
import GIBowlCore
import Vision

/// Turns an image into lines of text.
protocol LabelTextRecognizer: Sendable {
    func lines(in image: CGImage) async throws -> [String]
}

/// Reads a label image straight into a reading, when a model is available.
protocol LabelModelExtractor: Sendable {
    var isAvailable: Bool { get }
    func extract(from image: CGImage) async throws -> LabelReading
}

/// Vision text recognition, top to bottom.
struct VisionTextRecognizer: LabelTextRecognizer {
    func lines(in image: CGImage) async throws -> [String] {
        var request = RecognizeTextRequest()
        request.recognitionLevel = .accurate
        request.usesLanguageCorrection = false
        let observations = try await request.perform(on: image)
        return observations
            .sorted { $0.boundingBox.origin.y > $1.boundingBox.origin.y }
            .compactMap { $0.topCandidates(1).first?.string }
    }
}

/// Reads a label with Vision on every device; prefers the on-device model's reading when it has one.
struct LabelReader {
    let recognizer: any LabelTextRecognizer
    let model: any LabelModelExtractor

    init(recognizer: any LabelTextRecognizer = VisionTextRecognizer(), model: any LabelModelExtractor = ModelLabelExtractor()) {
        self.recognizer = recognizer
        self.model = model
    }

    func read(_ image: CGImage) async -> LabelReading {
        let lines = (try? await recognizer.lines(in: image)) ?? []
        let vision = LabelParser.parse(lines: lines)

        // The model can invent numbers for a photo with no label in it, so it only gets a say
        // when Vision can see a carbohydrate line too.
        let seesCarbLine = lines.contains { $0.localizedCaseInsensitiveContains("carb") }
        guard seesCarbLine, model.isAvailable,
              let fromModel = try? await model.extract(from: image), fromModel.totalCarbs != nil else {
            return vision
        }
        // The model's numbers, but Vision's read of the label format and fiber when it has them:
        // a US label misread as EU would otherwise skip the fiber subtraction.
        return LabelParser.reading(
            total: fromModel.totalCarbs,
            fiber: fromModel.fiber ?? vision.fiber,
            format: vision.format == .unknown ? fromModel.format : vision.format,
            serving: fromModel.servingLabel ?? vision.servingLabel,
            productName: fromModel.productName
        )
    }
}
