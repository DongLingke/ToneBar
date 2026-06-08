import AppKit

// Renders a source image into a macOS-style rounded-square .iconset.
// Usage: swift makeicon.swift <source-image> <output-iconset-dir>

let args = CommandLine.arguments
guard args.count >= 3 else {
    FileHandle.standardError.write("usage: makeicon.swift <src> <outdir>\n".data(using: .utf8)!)
    exit(1)
}
let srcPath = args[1]
let outDir = args[2]

guard let src = NSImage(contentsOfFile: srcPath) else {
    fatalError("could not load image at \(srcPath)")
}

let specs: [(String, Int)] = [
    ("icon_16x16.png", 16),   ("icon_16x16@2x.png", 32),
    ("icon_32x32.png", 32),   ("icon_32x32@2x.png", 64),
    ("icon_128x128.png", 128), ("icon_128x128@2x.png", 256),
    ("icon_256x256.png", 256), ("icon_256x256@2x.png", 512),
    ("icon_512x512.png", 512), ("icon_512x512@2x.png", 1024),
]

for (name, px) in specs {
    let size = CGFloat(px)
    guard let rep = NSBitmapImageRep(
        bitmapDataPlanes: nil, pixelsWide: px, pixelsHigh: px,
        bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true,
        isPlanar: false, colorSpaceName: .deviceRGB,
        bytesPerRow: 0, bitsPerPixel: 0) else { continue }
    rep.size = NSSize(width: size, height: size)

    NSGraphicsContext.saveGraphicsState()
    let ctx = NSGraphicsContext(bitmapImageRep: rep)!
    NSGraphicsContext.current = ctx

    NSColor.clear.set()
    NSRect(x: 0, y: 0, width: size, height: size).fill()

    // Inset slightly so the squircle has breathing room, like Apple's grid.
    let inset = (size * 0.085).rounded()
    let rect = NSRect(x: inset, y: inset, width: size - 2 * inset, height: size - 2 * inset)
    let radius = rect.width * 0.2237   // macOS superellipse-ish corner ratio
    let path = NSBezierPath(roundedRect: rect, xRadius: radius, yRadius: radius)
    path.addClip()

    src.draw(in: rect, from: .zero, operation: .copy, fraction: 1.0)

    ctx.flushGraphics()
    NSGraphicsContext.restoreGraphicsState()

    let url = URL(fileURLWithPath: outDir).appendingPathComponent(name)
    try! rep.representation(using: .png, properties: [:])!.write(to: url)
    print("• \(name) (\(px)px)")
}
print("done")
