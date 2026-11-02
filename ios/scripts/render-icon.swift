// Renders the GI Bowl app icon: the puddingtime.org bowl, recoloured, on the app's paper.
// Usage: swift ios/scripts/render-icon.swift ios/scripts/puddingbowl.png ios/GIBowl/Assets.xcassets/AppIcon.appiconset/icon-1024.png lavender
import CoreGraphics
import Foundation
import ImageIO
import UniformTypeIdentifiers

let args = CommandLine.arguments
let src = CGImageSourceCreateWithURL(URL(fileURLWithPath: args[1]) as CFURL, nil)!
let rawMark = CGImageSourceCreateImageAtIndex(src, 0, nil)!
// The source cutout has ragged edges: resample it down and back up so the alpha edge is soft, not jagged
func smoothed(_ img: CGImage, to width: Int) -> CGImage {
    let height = Int(Double(img.height) * Double(width) / Double(img.width))
    let s = CGColorSpace(name: CGColorSpace.sRGB)!
    let c = CGContext(data: nil, width: width, height: height, bitsPerComponent: 8, bytesPerRow: 0, space: s, bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!
    c.interpolationQuality = .high
    c.draw(img, in: CGRect(x: 0, y: 0, width: width, height: height))
    return c.makeImage()!
}
let mark = smoothed(smoothed(rawMark, to: 360), to: rawMark.width)
let out = URL(fileURLWithPath: args[2])
let variant = args[3]
let fill = args.count > 4 ? Double(args[4])! : 0.78

func rgb(_ hex: UInt32) -> CGColor {
    CGColor(srgbRed: CGFloat((hex >> 16) & 0xff) / 255, green: CGFloat((hex >> 8) & 0xff) / 255, blue: CGFloat(hex & 0xff) / 255, alpha: 1)
}
let paper = rgb(0xfaf6f1), sage = rgb(0x7a9a5a), amber = rgb(0xc4a23a), terracotta = rgb(0xc26a4a), lavender = rgb(0xa8a6d6)

// Opaque bounding box of the mark, so it can be centred and scaled
let w = mark.width, h = mark.height
let space = CGColorSpace(name: CGColorSpace.sRGB)!
let scan = CGContext(data: nil, width: w, height: h, bitsPerComponent: 8, bytesPerRow: w * 4, space: space, bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!
scan.draw(mark, in: CGRect(x: 0, y: 0, width: w, height: h))
let px = scan.data!.assumingMemoryBound(to: UInt8.self)
var minX = w, minY = h, maxX = 0, maxY = 0
for y in 0..<h { for x in 0..<w where px[(y * w + x) * 4 + 3] > 20 {
    minX = min(minX, x); maxX = max(maxX, x); minY = min(minY, y); maxY = max(maxY, y)
} }
let bbox = CGRect(x: minX, y: minY, width: maxX - minX + 1, height: maxY - minY + 1)   // CG coords (y up)

let size = 1024.0
// No alpha channel: the App Store rejects icons that have one (ITMS-90717)
let ctx = CGContext(data: nil, width: 1024, height: 1024, bitsPerComponent: 8, bytesPerRow: 0, space: space, bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue)!
ctx.setFillColor(paper)
ctx.fill(CGRect(x: 0, y: 0, width: size, height: size))

// Place the mark: bbox scaled to `fill` of the width, centred, nudged down a little (the spoon is tall)
let scale = size * fill / max(bbox.width, bbox.height)
let drawW = Double(w) * scale, drawH = Double(h) * scale
let drawX = size / 2 - (bbox.midX * scale)
let drawY = size / 2 - (bbox.midY * scale) - 20
let rect = CGRect(x: drawX, y: drawY, width: drawW, height: drawH)

ctx.saveGState()
ctx.interpolationQuality = .high
ctx.clip(to: rect, mask: mark)
ctx.setFillColor(variant == "lavender" ? lavender : sage)
ctx.fill(rect)
ctx.restoreGState()

if variant == "dots" {
    // The three dots inside the bowl, in source pixel coords (y down): recolour as berries
    let dots: [(Double, Double, CGColor)] = [(790, 1012, amber), (784, 1100, terracotta), (872, 1100, sage)]
    for (sx, sy, color) in dots {
        let x = drawX + sx * scale, y = drawY + (Double(h) - sy) * scale, r = 30 * scale
        ctx.setFillColor(paper)
        ctx.fillEllipse(in: CGRect(x: x - r - 2, y: y - r - 2, width: 2 * r + 4, height: 2 * r + 4))
        ctx.setFillColor(color)
        ctx.fillEllipse(in: CGRect(x: x - r, y: y - r, width: 2 * r, height: 2 * r))
    }
}

let image = ctx.makeImage()!
let dest = CGImageDestinationCreateWithURL(out as CFURL, UTType.png.identifier as CFString, 1, nil)!
CGImageDestinationAddImage(dest, image, nil)
CGImageDestinationFinalize(dest)
print("bbox \(bbox) → \(out.lastPathComponent)")
