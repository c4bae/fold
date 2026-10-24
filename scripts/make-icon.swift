// Renders Fold's app icon and writes resources/AppIcon.icns and docs/icon.png.
// Usage: swift scripts/make-icon.swift
//
// The design: a dark squircle with the notch at the top and translucent rows
// fanning ("folding") out below it, one highlighted, like the switcher.
import AppKit

let canvas: CGFloat = 1024

func color(_ hex: UInt32, _ alpha: CGFloat = 1) -> NSColor {
    NSColor(
        srgbRed: CGFloat((hex >> 16) & 0xFF) / 255,
        green: CGFloat((hex >> 8) & 0xFF) / 255,
        blue: CGFloat(hex & 0xFF) / 255,
        alpha: alpha
    )
}

func drawIcon() {
    // macOS icon grid: an 824pt body centered on the 1024pt canvas.
    let body = CGRect(x: 100, y: 100, width: 824, height: 824)
    let bodyPath = NSBezierPath(roundedRect: body, xRadius: 185, yRadius: 185)

    // Drop shadow under the body.
    NSGraphicsContext.saveGraphicsState()
    let shadow = NSShadow()
    shadow.shadowColor = NSColor.black.withAlphaComponent(0.35)
    shadow.shadowOffset = NSSize(width: 0, height: -12)
    shadow.shadowBlurRadius = 28
    shadow.set()
    color(0x0B0C14).setFill()
    bodyPath.fill()
    NSGraphicsContext.restoreGraphicsState()

    NSGraphicsContext.saveGraphicsState()
    bodyPath.addClip()

    // Background: deep navy fading to near-black, with a soft glow under the
    // notch where the rows come from.
    NSGradient(colors: [color(0x262A45), color(0x0C0D18)])!
        .draw(in: body, angle: -90)
    NSGradient(colors: [color(0x5B8CFF, 0.35), color(0x5B8CFF, 0)])!
        .draw(fromCenter: CGPoint(x: 512, y: 820), radius: 0,
              toCenter: CGPoint(x: 512, y: 820), radius: 420, options: [])

    // Notch: hangs from the top edge, square on top, round at the bottom.
    let notch = CGRect(x: 512 - 150, y: 924 - 78, width: 300, height: 78 + 40)
    NSColor.black.setFill()
    NSBezierPath(roundedRect: notch, xRadius: 40, yRadius: 40).fill()

    // Rows folding out of the notch: each wider and lower than the last.
    let rows: [(width: CGFloat, y: CGFloat, highlighted: Bool, alpha: CGFloat)] = [
        (380, 664, false, 0.20),
        (500, 532, true, 1.0),
        (600, 400, false, 0.14),
        (680, 268, false, 0.09),
    ]
    let rowHeight: CGFloat = 100
    for row in rows {
        let rect = CGRect(x: 512 - row.width / 2, y: row.y, width: row.width, height: rowHeight)
        let path = NSBezierPath(roundedRect: rect, xRadius: 26, yRadius: 26)
        if row.highlighted {
            NSGraphicsContext.saveGraphicsState()
            let glow = NSShadow()
            glow.shadowColor = color(0x4F8BFF, 0.6)
            glow.shadowBlurRadius = 40
            glow.shadowOffset = .zero
            glow.set()
            color(0x4F8BFF).setFill()
            path.fill()
            NSGraphicsContext.restoreGraphicsState()
            NSGradient(colors: [color(0x63E6FF), color(0x4F7BFF)])!.draw(in: path, angle: 0)
        } else {
            NSColor.white.withAlphaComponent(row.alpha).setFill()
            path.fill()
        }

        // Icon dot and title bar, like a row in the switcher.
        let contentAlpha: CGFloat = row.highlighted ? 0.95 : min(1, row.alpha * 2.4)
        NSColor.white.withAlphaComponent(contentAlpha).setFill()
        let dot = CGRect(x: rect.minX + 26, y: rect.midY - 22, width: 44, height: 44)
        NSBezierPath(roundedRect: dot, xRadius: 12, yRadius: 12).fill()
        let barWidth = min(rect.width * 0.48, 260)
        let bar = CGRect(x: dot.maxX + 22, y: rect.midY - 9, width: barWidth, height: 18)
        NSColor.white.withAlphaComponent(contentAlpha * 0.8).setFill()
        NSBezierPath(roundedRect: bar, xRadius: 9, yRadius: 9).fill()
    }

    // Subtle inner highlight along the top edge of the body.
    NSColor.white.withAlphaComponent(0.08).setStroke()
    let rim = NSBezierPath(roundedRect: body.insetBy(dx: 2, dy: 2), xRadius: 183, yRadius: 183)
    rim.lineWidth = 4
    rim.stroke()

    NSGraphicsContext.restoreGraphicsState()
}

func renderPNG(size: Int) -> Data {
    let rep = NSBitmapImageRep(
        bitmapDataPlanes: nil, pixelsWide: size, pixelsHigh: size,
        bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false,
        colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0
    )!
    rep.size = NSSize(width: canvas, height: canvas)
    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)
    NSGraphicsContext.current?.imageInterpolation = .high
    drawIcon()
    NSGraphicsContext.restoreGraphicsState()
    return rep.representation(using: .png, properties: [:])!
}

let root = URL(fileURLWithPath: CommandLine.arguments.count > 1 ? CommandLine.arguments[1] : ".")
let fm = FileManager.default
let iconset = fm.temporaryDirectory.appendingPathComponent("AppIcon-\(UUID().uuidString).iconset")
try fm.createDirectory(at: iconset, withIntermediateDirectories: true)
defer { try? fm.removeItem(at: iconset) }

// Every size iconutil expects, each rendered directly at its pixel size.
for points in [16, 32, 128, 256, 512] {
    try renderPNG(size: points).write(to: iconset.appendingPathComponent("icon_\(points)x\(points).png"))
    try renderPNG(size: points * 2).write(to: iconset.appendingPathComponent("icon_\(points)x\(points)@2x.png"))
}
// PNG copy shown in the README; 512px stays sharp at retina display sizes.
let readmeIcon = root.appendingPathComponent("docs/icon.png")
try fm.createDirectory(at: readmeIcon.deletingLastPathComponent(), withIntermediateDirectories: true)
try renderPNG(size: 512).write(to: readmeIcon)

let output = root.appendingPathComponent("resources/AppIcon.icns")
let iconutil = Process()
iconutil.executableURL = URL(fileURLWithPath: "/usr/bin/iconutil")
iconutil.arguments = ["-c", "icns", iconset.path, "-o", output.path]
try iconutil.run()
iconutil.waitUntilExit()
guard iconutil.terminationStatus == 0 else {
    FileHandle.standardError.write("iconutil failed\n".data(using: .utf8)!)
    exit(1)
}
print("Wrote \(output.path) and \(readmeIcon.path)")
