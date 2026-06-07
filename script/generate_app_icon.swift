#!/usr/bin/env swift

import AppKit
import Foundation

let root = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
let resources = root.appendingPathComponent("Resources", isDirectory: true)
let iconset = resources.appendingPathComponent("AppIcon.iconset", isDirectory: true)
let icns = resources.appendingPathComponent("AppIcon.icns")

try? FileManager.default.removeItem(at: iconset)
try FileManager.default.createDirectory(at: iconset, withIntermediateDirectories: true)

let sizes: [(String, CGFloat)] = [
    ("icon_16x16.png", 16),
    ("icon_16x16@2x.png", 32),
    ("icon_32x32.png", 32),
    ("icon_32x32@2x.png", 64),
    ("icon_128x128.png", 128),
    ("icon_128x128@2x.png", 256),
    ("icon_256x256.png", 256),
    ("icon_256x256@2x.png", 512),
    ("icon_512x512.png", 512),
    ("icon_512x512@2x.png", 1024)
]

func drawIcon(size: CGFloat) -> NSImage {
    let image = NSImage(size: CGSize(width: size, height: size))
    image.lockFocus()

    let rect = CGRect(x: 0, y: 0, width: size, height: size)
    NSColor.clear.setFill()
    rect.fill()

    let radius = size * 0.245
    let inset = size * 0.055
    let tile = NSBezierPath(roundedRect: rect.insetBy(dx: inset, dy: inset), xRadius: radius, yRadius: radius)
    tile.addClip()

    let gradient = NSGradient(colors: [
        NSColor(red: 0.04, green: 0.10, blue: 0.20, alpha: 1.0),
        NSColor(red: 0.02, green: 0.46, blue: 0.96, alpha: 1.0),
        NSColor(red: 0.19, green: 0.86, blue: 0.67, alpha: 1.0)
    ])
    gradient?.draw(in: tile, angle: 42)

    NSColor.white.withAlphaComponent(0.18).setFill()
    NSBezierPath(ovalIn: CGRect(x: size * 0.58, y: size * 0.58, width: size * 0.40, height: size * 0.40)).fill()
    NSColor(red: 0.29, green: 0.97, blue: 0.75, alpha: 0.22).setFill()
    NSBezierPath(ovalIn: CGRect(x: size * -0.08, y: size * 0.04, width: size * 0.58, height: size * 0.58)).fill()

    let glassRect = CGRect(x: size * 0.19, y: size * 0.18, width: size * 0.62, height: size * 0.64)
    let glass = NSBezierPath(roundedRect: glassRect, xRadius: size * 0.14, yRadius: size * 0.14)
    NSColor.white.withAlphaComponent(0.20).setFill()
    glass.fill()
    NSColor.white.withAlphaComponent(0.34).setStroke()
    glass.lineWidth = max(1, size * 0.012)
    glass.stroke()

    let ringRect = CGRect(x: size * 0.30, y: size * 0.30, width: size * 0.40, height: size * 0.40)
    let ring = NSBezierPath(ovalIn: ringRect)
    ring.lineWidth = max(5, size * 0.055)
    NSColor.white.withAlphaComponent(0.92).setStroke()
    ring.stroke()

    let pulse = NSBezierPath()
    pulse.lineWidth = max(4, size * 0.043)
    pulse.lineCapStyle = .round
    pulse.lineJoinStyle = .round
    pulse.move(to: CGPoint(x: size * 0.22, y: size * 0.50))
    pulse.line(to: CGPoint(x: size * 0.36, y: size * 0.50))
    pulse.line(to: CGPoint(x: size * 0.43, y: size * 0.61))
    pulse.line(to: CGPoint(x: size * 0.52, y: size * 0.39))
    pulse.line(to: CGPoint(x: size * 0.60, y: size * 0.51))
    pulse.line(to: CGPoint(x: size * 0.78, y: size * 0.51))
    NSColor(red: 0.26, green: 1.0, blue: 0.78, alpha: 1.0).setStroke()
    pulse.stroke()

    let dotSize = size * 0.058
    for point in [
        CGPoint(x: size * 0.34, y: size * 0.69),
        CGPoint(x: size * 0.50, y: size * 0.69),
        CGPoint(x: size * 0.66, y: size * 0.69)
    ] {
        NSColor.white.withAlphaComponent(0.86).setFill()
        NSBezierPath(ovalIn: CGRect(x: point.x - dotSize / 2, y: point.y - dotSize / 2, width: dotSize, height: dotSize)).fill()
    }

    image.unlockFocus()
    return image
}

func writePNG(_ image: NSImage, to url: URL) throws {
    guard let tiff = image.tiffRepresentation,
          let bitmap = NSBitmapImageRep(data: tiff),
          let png = bitmap.representation(using: .png, properties: [:]) else {
        throw NSError(domain: "SubPulseIcon", code: 1)
    }
    try png.write(to: url)
}

for (name, size) in sizes {
    try writePNG(drawIcon(size: size), to: iconset.appendingPathComponent(name))
}

try? FileManager.default.removeItem(at: icns)
let process = Process()
process.executableURL = URL(fileURLWithPath: "/usr/bin/iconutil")
process.arguments = ["-c", "icns", iconset.path, "-o", icns.path]
try process.run()
process.waitUntilExit()

if process.terminationStatus != 0 {
    throw NSError(domain: "SubPulseIcon", code: Int(process.terminationStatus))
}

print("Generated \(icns.path)")
