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

/// Broad labels for what a photo shows, used only to explain a photo that isn't a label.
protocol LabelImageClassifier: Sendable {
    func labels(in image: CGImage) async throws -> [String]
}

/// Vision's on-device image classifier.
struct VisionImageClassifier: LabelImageClassifier {
    func labels(in image: CGImage) async throws -> [String] {
        let observations = try await ClassifyImageRequest().perform(on: image)
        return observations.filter { $0.confidence > 0.3 }.map(\.identifier)
    }
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
    let classifier: any LabelImageClassifier

    /// Classifier labels that mean someone photographed their food rather than its label.
    static let foodWords = ["food", "dish", "meal", "fruit", "vegetable", "salad", "sandwich", "pizza", "dessert",
                            "breakfast", "pasta", "burger", "soup", "snack", "cake", "bread", "plate", "bowl"]

    init(recognizer: any LabelTextRecognizer = VisionTextRecognizer(),
         model: any LabelModelExtractor = ModelLabelExtractor(),
         classifier: any LabelImageClassifier = VisionImageClassifier()) {
        self.recognizer = recognizer
        self.model = model
        self.classifier = classifier
    }

    func read(_ image: CGImage) async -> LabelReading {
        let lines = (try? await recognizer.lines(in: image)) ?? []
        var vision = LabelParser.parse(lines: lines)

        // No label words at all: say what the photo seems to be instead of a generic "couldn't read"
        guard LabelParser.looksLikeLabel(lines: lines) else {
            let labels = (try? await classifier.labels(in: image)) ?? []
            let isFood = labels.contains { label in Self.foodWords.contains { label.lowercased().contains($0) } }
            vision.notALabel = isFood ? .food : .other
            return vision
        }

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
