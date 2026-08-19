import Foundation
import CoreGraphics
import ImageIO
import UniformTypeIdentifiers

// CoreGraphics only — no AppKit, so this works in a plain shell process with no
// window server session (an NSGraphicsContext there traps).
let a = CommandLine.arguments
guard a.count == 5, let w = Int(a[3]), let h = Int(a[4]),
      let src = CGImageSourceCreateWithURL(URL(fileURLWithPath: a[1]) as CFURL, nil),
      let img = CGImageSourceCreateImageAtIndex(src, 0, nil),
      let cs = CGColorSpace(name: CGColorSpace.sRGB) else { exit(2) }

// noneSkipLast => 32bpp with the alpha byte ignored, i.e. an opaque bitmap.
guard let ctx = CGContext(data: nil, width: w, height: h, bitsPerComponent: 8,
                          bytesPerRow: 0, space: cs,
                          bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue) else { exit(3) }
ctx.setFillColor(CGColor(colorSpace: cs, components: [11/255.0, 42/255.0, 74/255.0, 1])!)
ctx.fill(CGRect(x: 0, y: 0, width: w, height: h))

let scale = min(Double(w) / Double(img.width), Double(h) / Double(img.height))
let dw = Double(img.width) * scale, dh = Double(img.height) * scale
ctx.draw(img, in: CGRect(x: (Double(w) - dw) / 2, y: (Double(h) - dh) / 2, width: dw, height: dh))

guard let out = ctx.makeImage(),
      let dest = CGImageDestinationCreateWithURL(URL(fileURLWithPath: a[2]) as CFURL,
                                                 UTType.png.identifier as CFString, 1, nil) else { exit(4) }
CGImageDestinationAddImage(dest, out, nil)
exit(CGImageDestinationFinalize(dest) ? 0 : 5)
