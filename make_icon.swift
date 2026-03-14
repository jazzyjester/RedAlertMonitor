#!/usr/bin/env swift
// Generates AppIcon.icns for RedAlertMonitor.
// Usage: swift make_icon.swift
import Cocoa

// Draw a single icon frame at the given size
func drawIcon(size: CGFloat) -> NSImage {
    let image = NSImage(size: NSSize(width: size, height: size))
    image.lockFocus()

    let ctx = NSGraphicsContext.current!.cgContext
    let rect = CGRect(x: 0, y: 0, width: size, height: size)
    let pad = size * 0.06

    // ── Background: deep navy circle ────────────────────────────────────────
    ctx.setFillColor(CGColor(red: 0.08, green: 0.09, blue: 0.18, alpha: 1))
    ctx.fillEllipse(in: rect.insetBy(dx: pad, dy: pad))

    // Subtle red glow ring
    let glowColors = [
        CGColor(red: 0.85, green: 0.1, blue: 0.1, alpha: 0.6),
        CGColor(red: 0.85, green: 0.1, blue: 0.1, alpha: 0),
    ]
    let glowLocations: [CGFloat] = [0, 1]
    if let gradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(),
                                  colors: glowColors as CFArray,
                                  locations: glowLocations) {
        let center = CGPoint(x: size / 2, y: size / 2)
        ctx.drawRadialGradient(gradient,
                                startCenter: center, startRadius: size * 0.35,
                                endCenter: center, endRadius: size * 0.5,
                                options: [])
    }

    // ── Missile / rocket shape ───────────────────────────────────────────────
    let mx = size / 2           // center x
    let my = size * 0.52        // center y (slightly lower)
    let mh = size * 0.42        // missile height
    let mw = size * 0.10        // missile body half-width
    let angle = CGFloat.pi / 4  // 45° — heading up-right

    ctx.saveGState()
    ctx.translateBy(x: mx, y: my)
    ctx.rotate(by: angle)

    // Body
    let bodyRect = CGRect(x: -mw, y: -mh / 2, width: mw * 2, height: mh)
    let bodyPath = NSBezierPath(roundedRect: bodyRect, xRadius: mw * 0.6, yRadius: mw * 0.6)
    NSColor(red: 0.92, green: 0.92, blue: 0.96, alpha: 1).setFill()
    bodyPath.fill()

    // Nose cone
    let nosePath = NSBezierPath()
    nosePath.move(to: NSPoint(x: -mw, y: mh / 2))
    nosePath.line(to: NSPoint(x:  mw, y: mh / 2))
    nosePath.line(to: NSPoint(x:   0, y: mh / 2 + mw * 2.2))
    nosePath.close()
    NSColor(red: 0.95, green: 0.25, blue: 0.15, alpha: 1).setFill()
    nosePath.fill()

    // Fins
    let finW = mw * 1.6
    let finH = mh * 0.28
    let finY = -mh / 2
    for xSign: CGFloat in [-1, 1] {
        let finPath = NSBezierPath()
        finPath.move(to: NSPoint(x: xSign * mw, y: finY))
        finPath.line(to: NSPoint(x: xSign * (mw + finW), y: finY - finH * 0.4))
        finPath.line(to: NSPoint(x: xSign * (mw + finW * 0.2), y: finY + finH))
        finPath.close()
        NSColor(red: 0.75, green: 0.20, blue: 0.10, alpha: 1).setFill()
        finPath.fill()
    }

    // Exhaust flame
    let flamePath = NSBezierPath()
    flamePath.move(to: NSPoint(x: -mw * 0.7, y: -mh / 2))
    flamePath.line(to: NSPoint(x:  mw * 0.7, y: -mh / 2))
    flamePath.line(to: NSPoint(x:  mw * 0.3, y: -mh / 2 - mh * 0.28))
    flamePath.line(to: NSPoint(x:  0,          y: -mh / 2 - mh * 0.18))
    flamePath.line(to: NSPoint(x: -mw * 0.3, y: -mh / 2 - mh * 0.28))
    flamePath.close()
    NSColor(red: 1.0, green: 0.55, blue: 0.05, alpha: 1).setFill()
    flamePath.fill()

    ctx.restoreGState()

    // ── Alert triangle (bottom-right) ────────────────────────────────────────
    let ts = size * 0.30        // triangle area
    let tx = size - ts * 0.85
    let ty = CGFloat(0) + ts * 0.05

    let triPath = NSBezierPath()
    triPath.move(to:    NSPoint(x: tx,            y: ty + ts * 0.88))
    triPath.line(to:    NSPoint(x: tx - ts * 0.5, y: ty))
    triPath.line(to:    NSPoint(x: tx + ts * 0.5, y: ty))
    triPath.close()
    NSColor(red: 1.0, green: 0.82, blue: 0.0, alpha: 1).setFill()
    triPath.fill()

    // Exclamation mark
    let exFont = NSFont.boldSystemFont(ofSize: ts * 0.52)
    let attrs: [NSAttributedString.Key: Any] = [
        .font: exFont,
        .foregroundColor: NSColor(red: 0.08, green: 0.09, blue: 0.18, alpha: 1),
    ]
    let exStr = NSAttributedString(string: "!", attributes: attrs)
    let exSize = exStr.size()
    exStr.draw(at: NSPoint(x: tx - exSize.width / 2, y: ty + ts * 0.16))

    image.unlockFocus()
    return image
}

// Write PNG at a given size
func writePNG(_ image: NSImage, to path: String) {
    guard let tiff = image.tiffRepresentation,
          let bitmap = NSBitmapImageRep(data: tiff),
          let png = bitmap.representation(using: .png, properties: [:]) else {
        print("Failed to create PNG for \(path)")
        return
    }
    do {
        try png.write(to: URL(fileURLWithPath: path))
        print("Wrote \(path)")
    } catch {
        print("Error writing \(path): \(error)")
    }
}

// Generate iconset
let iconsetPath = "AppIcon.iconset"
let fm = FileManager.default
try? fm.createDirectory(atPath: iconsetPath, withIntermediateDirectories: true)

let sizes: [(name: String, size: CGFloat)] = [
    ("icon_16x16.png",       16),
    ("icon_16x16@2x.png",    32),
    ("icon_32x32.png",       32),
    ("icon_32x32@2x.png",    64),
    ("icon_128x128.png",    128),
    ("icon_128x128@2x.png", 256),
    ("icon_256x256.png",    256),
    ("icon_256x256@2x.png", 512),
    ("icon_512x512.png",    512),
    ("icon_512x512@2x.png",1024),
]

for entry in sizes {
    let img = drawIcon(size: entry.size)
    writePNG(img, to: "\(iconsetPath)/\(entry.name)")
}

// Convert to .icns
let result = Process()
result.launchPath = "/usr/bin/iconutil"
result.arguments = ["-c", "icns", iconsetPath, "-o", "AppIcon.icns"]
result.launch()
result.waitUntilExit()

if result.terminationStatus == 0 {
    print("Created AppIcon.icns")
    try? fm.removeItem(atPath: iconsetPath)
} else {
    print("iconutil failed — iconset kept at \(iconsetPath)")
}
