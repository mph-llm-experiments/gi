import ImageIO
import UIKit

/// Photos sized for reading text: upright and at most `maxDimension` pixels on the long side,
/// so a 48MP photo doesn't become several 190MB bitmaps.
enum LabelImage {
    static let maxDimension = 2400

    /// Decodes and downscales in one pass, applying the photo's orientation.
    static func cgImage(from data: Data) -> CGImage? {
        guard let source = CGImageSourceCreateWithData(data as CFData, nil) else { return nil }
        let options: [CFString: Any] = [
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceCreateThumbnailWithTransform: true,
            kCGImageSourceThumbnailMaxPixelSize: maxDimension,
        ]
        return CGImageSourceCreateThumbnailAtIndex(source, 0, options as CFDictionary)
    }
}

extension UIImage {
    /// Upright and no larger than `LabelImage.maxDimension` on the long side.
    func labelReadyCGImage() -> CGImage? {
        let longSide = max(size.width, size.height) * scale
        let factor = min(1, CGFloat(LabelImage.maxDimension) / longSide)
        if factor == 1, imageOrientation == .up, let cgImage { return cgImage }
        let target = CGSize(width: (size.width * scale * factor).rounded(.down), height: (size.height * scale * factor).rounded(.down))
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        return UIGraphicsImageRenderer(size: target, format: format).image { _ in
            draw(in: CGRect(origin: .zero, size: target))
        }.cgImage
    }
}
