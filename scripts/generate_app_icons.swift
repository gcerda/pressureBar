import AppKit

struct IconSpec {
    let filename: String
    let pixels: Int
}

let specs: [IconSpec] = [
    .init(filename: "appicon-16.png", pixels: 16),
    .init(filename: "appicon-16@2x.png", pixels: 32),
    .init(filename: "appicon-32.png", pixels: 32),
    .init(filename: "appicon-32@2x.png", pixels: 64),
    .init(filename: "appicon-128.png", pixels: 128),
    .init(filename: "appicon-128@2x.png", pixels: 256),
    .init(filename: "appicon-256.png", pixels: 256),
    .init(filename: "appicon-256@2x.png", pixels: 512),
    .init(filename: "appicon-512.png", pixels: 512),
    .init(filename: "appicon-512@2x.png", pixels: 1024),
]

guard CommandLine.arguments.count == 2 else {
    fputs("Usage: swift generate_app_icons.swift <output-directory>\n", stderr)
    exit(1)
}

let outputDirectory = URL(fileURLWithPath: CommandLine.arguments[1], isDirectory: true)
let fileManager = FileManager.default

try fileManager.createDirectory(at: outputDirectory, withIntermediateDirectories: true)

for spec in specs {
    let rep = NSBitmapImageRep(
        bitmapDataPlanes: nil,
        pixelsWide: spec.pixels,
        pixelsHigh: spec.pixels,
        bitsPerSample: 8,
        samplesPerPixel: 4,
        hasAlpha: true,
        isPlanar: false,
        colorSpaceName: .deviceRGB,
        bytesPerRow: 0,
        bitsPerPixel: 0
    )!

    rep.size = NSSize(width: spec.pixels, height: spec.pixels)

    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)

    let canvas = NSRect(x: 0, y: 0, width: spec.pixels, height: spec.pixels)
    NSColor.clear.setFill()
    canvas.fill()

    let scale = CGFloat(spec.pixels) / 1024.0
    let inset = 84.0 * scale
    let cornerRadius = 236.0 * scale
    let backgroundRect = canvas.insetBy(dx: inset, dy: inset)
    let backgroundPath = NSBezierPath(
        roundedRect: backgroundRect,
        xRadius: cornerRadius,
        yRadius: cornerRadius
    )

    let gradient = NSGradient(
        colors: [
            NSColor(calibratedRed: 0.06, green: 0.25, blue: 0.54, alpha: 1.0),
            NSColor(calibratedRed: 0.09, green: 0.45, blue: 0.79, alpha: 1.0),
        ]
    )!
    gradient.draw(in: backgroundPath, angle: 90)

    let glowRect = NSRect(
        x: backgroundRect.minX + 60 * scale,
        y: backgroundRect.midY,
        width: backgroundRect.width - 120 * scale,
        height: backgroundRect.height * 0.55
    )
    let glowPath = NSBezierPath(ovalIn: glowRect)
    NSColor(calibratedWhite: 1.0, alpha: 0.12).setFill()
    glowPath.fill()

    let chipWidth = 180.0 * scale
    let chipHeight = 88.0 * scale
    let chipRadius = 28.0 * scale
    let chipGap = 42.0 * scale
    let chipY = backgroundRect.minY + 240.0 * scale
    let totalChipWidth = chipWidth * 2 + chipGap
    let chipX = backgroundRect.midX - totalChipWidth / 2.0

    for index in 0 ..< 2 {
        let rect = NSRect(
            x: chipX + CGFloat(index) * (chipWidth + chipGap),
            y: chipY,
            width: chipWidth,
            height: chipHeight
        )
        let path = NSBezierPath(roundedRect: rect, xRadius: chipRadius, yRadius: chipRadius)
        NSColor(calibratedWhite: 1.0, alpha: 0.18).setFill()
        path.fill()

        let pinWidth = 10.0 * scale
        let pinHeight = 16.0 * scale
        let pinGap = 7.0 * scale
        let totalPins = 8
        let pinsWidth = CGFloat(totalPins) * pinWidth + CGFloat(totalPins - 1) * pinGap
        let pinsX = rect.midX - pinsWidth / 2.0

        for pin in 0 ..< totalPins {
            let pinRect = NSRect(
                x: pinsX + CGFloat(pin) * (pinWidth + pinGap),
                y: rect.maxY - pinHeight - 10.0 * scale,
                width: pinWidth,
                height: pinHeight
            )
            let pinPath = NSBezierPath(roundedRect: pinRect, xRadius: 3 * scale, yRadius: 3 * scale)
            NSColor(calibratedWhite: 1.0, alpha: 0.35).setFill()
            pinPath.fill()
        }
    }

    let arcLineWidth = max(18.0 * scale, 1.5)
    let arcInset = 210.0 * scale
    let arcRect = NSRect(
        x: backgroundRect.minX + arcInset,
        y: backgroundRect.minY + arcInset + 70.0 * scale,
        width: backgroundRect.width - arcInset * 2,
        height: backgroundRect.height - arcInset * 2
    )
    let arcPath = NSBezierPath()
    arcPath.appendArc(
        withCenter: NSPoint(x: arcRect.midX, y: arcRect.midY),
        radius: arcRect.width / 2.0,
        startAngle: 210,
        endAngle: -30,
        clockwise: true
    )
    arcPath.lineWidth = arcLineWidth
    arcPath.lineCapStyle = .round
    NSColor(calibratedWhite: 1.0, alpha: 0.22).setStroke()
    arcPath.stroke()

    let accentArcPath = NSBezierPath()
    accentArcPath.appendArc(
        withCenter: NSPoint(x: arcRect.midX, y: arcRect.midY),
        radius: arcRect.width / 2.0,
        startAngle: 210,
        endAngle: 30,
        clockwise: true
    )
    accentArcPath.lineWidth = arcLineWidth
    accentArcPath.lineCapStyle = .round
    NSColor(calibratedRed: 1.0, green: 0.78, blue: 0.26, alpha: 1.0).setStroke()
    accentArcPath.stroke()

    let center = NSPoint(x: arcRect.midX, y: arcRect.midY)
    let needleLength = arcRect.width * 0.34
    let angle = CGFloat.pi / 180 * 18
    let needleEnd = NSPoint(
        x: center.x + cos(angle) * needleLength,
        y: center.y + sin(angle) * needleLength
    )

    let needlePath = NSBezierPath()
    needlePath.move(to: center)
    needlePath.line(to: needleEnd)
    needlePath.lineWidth = max(16.0 * scale, 1.25)
    needlePath.lineCapStyle = .round
    NSColor.white.setStroke()
    needlePath.stroke()

    let hubRect = NSRect(
        x: center.x - 22.0 * scale,
        y: center.y - 22.0 * scale,
        width: 44.0 * scale,
        height: 44.0 * scale
    )
    let hubPath = NSBezierPath(ovalIn: hubRect)
    NSColor.white.setFill()
    hubPath.fill()

    NSGraphicsContext.restoreGraphicsState()

    let outputURL = outputDirectory.appendingPathComponent(spec.filename)
    guard let data = rep.representation(using: .png, properties: [:]) else {
        fputs("Failed to create PNG for \(spec.filename)\n", stderr)
        exit(1)
    }

    try data.write(to: outputURL)
}
