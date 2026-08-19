import Foundation
import CoreGraphics
import ImageIO
import UniformTypeIdentifiers

// Lays a capture on the app's own blue-to-black gradient at App Store screenshot size.
// CoreGraphics only, so it runs in a plain shell with no window server session.
let a = CommandLine.arguments
guard a.count == 5, let W = Int(a[3]), let H = Int(a[4]),
      let src = CGImageSourceCreateWithURL(URL(fileURLWithPath: a[1]) as CFURL, nil),
      let img = CGImageSourceCreateImageAtIndex(src, 0, nil),
      let cs = CGColorSpace(name: CGColorSpace.sRGB) else { exit(2) }

guard let ctx = CGContext(data: nil, width: W, height: H, bitsPerComponent: 8,
                          bytesPerRow: 0, space: cs,
                          bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue) else { exit(3) }

// AppearanceSettings' default pair: black and rgb(4,65,125). Drawn corner to corner
// so the light sits top-left, the way the app's own gradient reads.
let blue = CGColor(colorSpace: cs, components: [4/255.0, 65/255.0, 125/255.0, 1])!
let black = CGColor(colorSpace: cs, components: [0, 0, 0, 1])!
guard let grad = CGGradient(colorsSpace: cs, colors: [blue, black] as CFArray,
                            locations: [0, 1]) else { exit(4) }
ctx.drawLinearGradient(grad, start: CGPoint(x: 0, y: H), end: CGPoint(x: W, y: 0), options: [])

// Fit with a margin so the capture floats rather than filling the frame.
let margin = 0.10
let maxW = Double(W) * (1 - margin), maxH = Double(H) * (1 - margin)
let scale = min(maxW / Double(img.width), maxH / Double(img.height))
let dw = Double(img.width) * scale, dh = Double(img.height) * scale
let rect = CGRect(x: (Double(W) - dw) / 2, y: (Double(H) - dh) / 2, width: dw, height: dh)

let radius = min(dw, dh) * 0.035
func rounded(_ r: CGRect, _ rad: Double) -> CGPath {
    CGPath(roundedRect: r, cornerWidth: rad, cornerHeight: rad, transform: nil)
}

ctx.saveGState()
ctx.setShadow(offset: CGSize(width: 0, height: -18), blur: 46,
              color: CGColor(colorSpace: cs, components: [0, 0, 0, 0.55])!)
ctx.addPath(rounded(rect, radius))
ctx.setFillColor(black)
ctx.fillPath()
ctx.restoreGState()

ctx.saveGState()
ctx.addPath(rounded(rect, radius))
ctx.clip()
ctx.draw(img, in: rect)
ctx.restoreGState()

guard let out = ctx.makeImage(),
      let dest = CGImageDestinationCreateWithURL(URL(fileURLWithPath: a[2]) as CFURL,
                                                 UTType.png.identifier as CFString, 1, nil) else { exit(5) }
CGImageDestinationAddImage(dest, out, nil)
exit(CGImageDestinationFinalize(dest) ? 0 : 6)
