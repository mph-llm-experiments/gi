#if DEBUG
import CoreGraphics
import UIKit

/// Renders label text into an image, for tests and the sample-label debug option.
enum LabelFixtures {
    static let us = ["Nutrition Facts", "8 servings per container", "Serving size 2/3 cup (55g)", "Calories 230", "Total Carbohydrate 37g 13%", "Dietary Fiber 4g 14%", "Total Sugars 12g"]
    static let eu = ["Nutrition", "per 100g per portion (30g)", "Energy 1580kJ 474kJ", "Carbohydrate 60,5 g 18,2 g", "of which sugars 20g 6g", "Fibre 8,0g 2,4g"]

    static func image(_ lines: [String]) -> CGImage {
        let size = CGSize(width: 900, height: 120 + 70 * max(lines.count, 1))
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        let image = UIGraphicsImageRenderer(size: size, format: format).image { context in
            UIColor.white.setFill()
            context.fill(CGRect(origin: .zero, size: size))
            let attributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 44, weight: .semibold),
                .foregroundColor: UIColor.black,
            ]
            for (i, line) in lines.enumerated() {
                (line as NSString).draw(at: CGPoint(x: 40, y: 60 + 70 * i), withAttributes: attributes)
            }
        }
        return image.cgImage!
    }

    static func named(_ name: String) -> CGImage {
        switch name {
        case "us": image(us)
        case "eu": image(eu)
        default: image([])
        }
    }
}
#endif
