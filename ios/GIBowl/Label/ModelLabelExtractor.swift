import CoreGraphics
import FoundationModels
import GIBowlCore

/// The on-device model reading the label image directly. On-device only; never Private Cloud Compute.
struct ModelLabelExtractor: LabelModelExtractor {
    @Generable
    struct Extraction {
        @Guide(description: "Product name if printed, otherwise empty")
        var productName: String?
        @Guide(description: "Serving size exactly as printed, like 2/3 cup (55g)")
        var servingLabel: String?
        @Guide(description: "Total carbohydrate in grams for one serving")
        var totalCarbohydrateGrams: Double?
        @Guide(description: "Dietary fiber in grams for one serving")
        var dietaryFiberGrams: Double?
        @Guide(description: "True for a US-style Nutrition Facts label, false for an EU-style table")
        var isUSLabel: Bool
    }

    static let instructions = "Read this nutrition label. Report the serving size as printed, total carbohydrate in grams for one serving, and dietary fiber in grams for one serving. If a value isn't printed, leave it empty. Don't guess."

    var isAvailable: Bool { SystemLanguageModel.default.isAvailable }

    func extract(from image: CGImage) async throws -> LabelReading {
        let session = LanguageModelSession(model: .default, instructions: Self.instructions)
        let response = try await session.respond(generating: Extraction.self) {
            Attachment(image)
        }
        let e = response.content
        return LabelParser.reading(
            total: e.totalCarbohydrateGrams,
            fiber: e.dietaryFiberGrams,
            format: e.isUSLabel ? .us : .eu,
            serving: e.servingLabel?.isEmpty == false ? e.servingLabel : nil,
            productName: e.productName?.isEmpty == false ? e.productName : nil
        )
    }
}
