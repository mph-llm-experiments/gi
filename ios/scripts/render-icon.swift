// Renders the GI Bowl app icon: a sage bowl on paper with two berries. No text.
// Usage: swift render-icon.swift <output.png>
import CoreGraphics
import Foundation
import ImageIO
import UniformTypeIdentifiers

let size = 1024.0
let out = URL(fileURLWithPath: CommandLine.arguments[1])
let space = CGColorSpace(name: CGColorSpace.sRGB)!
let ctx = CGContext(data: nil, width: Int(size), height: Int(size), bitsPerComponent: 8, bytesPerRow: 0, space: space, bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!

func rgb(_ hex: UInt32) -> CGColor {
    CGColor(srgbRed: CGFloat((hex >> 16) & 0xff) / 255, green: CGFloat((hex >> 8) & 0xff) / 255, blue: CGFloat(hex & 0xff) / 255, alpha: 1)
}
let paper = rgb(0xfaf6f1), sage = rgb(0x7a9a5a), rim = rgb(0x55723a), amber = rgb(0xc4a23a), terracotta = rgb(0xc26a4a)

// Paper
ctx.setFillColor(paper)
ctx.fill(CGRect(x: 0, y: 0, width: size, height: size))

// Bowl: lower half of an ellipse. CoreGraphics y is up, so the bowl's open top is at cy.
let cx = 512.0, cy = 590.0, rx = 390.0, ry = 320.0
func bowlPath(inset: CGFloat) -> CGPath {
    let p = CGMutablePath()
    p.move(to: CGPoint(x: cx - rx + inset, y: cy))
    p.addLine(to: CGPoint(x: cx + rx - inset, y: cy))
    // Lower half-ellipse from right to left
    let steps = 120
    for i in 0...steps {
        let t = Double(i) / Double(steps) * Double.pi
        p.addLine(to: CGPoint(x: cx + (rx - inset) * cos(t), y: cy - (ry - inset) * sin(t)))
    }
    p.closeSubpath()
    return p
}
ctx.setFillColor(rim)
ctx.addPath(bowlPath(inset: 0)); ctx.fillPath()
ctx.setFillColor(sage)
ctx.addPath(bowlPath(inset: 28)); ctx.fillPath()

// Rim line across the top (darker)
ctx.setFillColor(rim)
ctx.fill(CGRect(x: cx - rx, y: cy - 14, width: rx * 2, height: 28))

// Foot
ctx.setFillColor(rim)
let foot = CGPath(roundedRect: CGRect(x: cx - 140, y: cy - ry - 30, width: 280, height: 46), cornerWidth: 12, cornerHeight: 12, transform: nil)
ctx.addPath(foot); ctx.fillPath()

// Berries sitting in the bowl, overlapping the rim
func berry(_ x: CGFloat, _ y: CGFloat, _ r: CGFloat, _ color: CGColor) {
    ctx.setFillColor(color)
    ctx.fillEllipse(in: CGRect(x: x - r, y: y - r, width: r * 2, height: r * 2))
}
berry(405, cy + 40, 80, amber)
berry(590, cy + 58, 92, terracotta)

let image = ctx.makeImage()!
let dest = CGImageDestinationCreateWithURL(out as CFURL, UTType.png.identifier as CFString, 1, nil)!
CGImageDestinationAddImage(dest, image, nil)
CGImageDestinationFinalize(dest)
print("wrote \(out.path)")
