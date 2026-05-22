import Foundation
import CoreGraphics
import AppKit

/// 水印渲染引擎 — 使用 NSImage 合成，避免 CGContext bitmapInfo 兼容性问题
struct WatermarkRenderer: Sendable {

    func applyWatermark(to image: CGImage, config: WatermarkConfig) -> CGImage {
        guard config.enabled else { return image }

        let hasText = config.textEnabled && !config.text.isEmpty
        let hasImage = config.imageEnabled && config.imageData != nil
        guard hasText || hasImage else { return image }

        let w = CGFloat(image.width)
        let h = CGFloat(image.height)
        let size = NSSize(width: w, height: h)

        let base = NSImage(cgImage: image, size: size)
        let canvas = NSImage(size: size)

        canvas.lockFocus()
        base.draw(in: NSRect(origin: .zero, size: size))

        if hasText {
            renderText(config: config, imageSize: CGSize(width: w, height: h))
        }
        if hasImage {
            renderImage(config: config, imageSize: CGSize(width: w, height: h))
        }

        canvas.unlockFocus()
        return canvas.cgImage(forProposedRect: nil, context: nil, hints: nil) ?? image
    }

    // MARK: - 文字水印

    private func renderText(config: WatermarkConfig, imageSize: CGSize) {
        let color = Self.parseColor(hex: config.colorHex).withAlphaComponent(config.opacity)
        let fontSize = config.fontSize(for: imageSize)
        let margin = config.margin(for: imageSize)
        let w = imageSize.width
        let h = imageSize.height

        let attrs: [NSAttributedString.Key: Any] = [
            .font: NSFont.systemFont(ofSize: fontSize, weight: .medium),
            .foregroundColor: color
        ]
        let str = NSAttributedString(string: config.text, attributes: attrs)
        let textSize = str.size()

        switch config.position {
        case .bottomRight:
            str.draw(at: NSPoint(x: w - textSize.width - margin, y: margin))
        case .bottomLeft:
            str.draw(at: NSPoint(x: margin, y: margin))
        case .topRight:
            str.draw(at: NSPoint(x: w - textSize.width - margin, y: h - textSize.height - margin))
        case .topLeft:
            str.draw(at: NSPoint(x: margin, y: h - textSize.height - margin))
        case .center:
            str.draw(at: NSPoint(x: (w - textSize.width) / 2, y: (h - textSize.height) / 2))
        case .tile:
            let spacing = config.tileSpacing(for: imageSize)
            let sx = textSize.width + spacing
            let sy = textSize.height + spacing
            var y: CGFloat = spacing
            while y < h {
                var x: CGFloat = spacing
                while x < w {
                    str.draw(at: NSPoint(x: x, y: y))
                    x += sx
                }
                y += sy
            }
        }
    }

    // MARK: - 图片水印

    private func renderImage(config: WatermarkConfig, imageSize: CGSize) {
        guard let data = config.imageData,
              let img = NSImage(data: data), img.isValid else { return }

        let margin = config.margin(for: imageSize)
        let target = config.imageSize(for: imageSize)
        let w = imageSize.width
        let h = imageSize.height

        let aspect = img.size.width / img.size.height
        var drawW: CGFloat, drawH: CGFloat
        if aspect >= 1 {
            drawW = target; drawH = target / aspect
        } else {
            drawH = target; drawW = target * aspect
        }

        let rect: NSRect
        switch config.position {
        case .bottomRight:
            rect = NSRect(x: w - drawW - margin, y: margin, width: drawW, height: drawH)
        case .bottomLeft:
            rect = NSRect(x: margin, y: margin, width: drawW, height: drawH)
        case .topRight:
            rect = NSRect(x: w - drawW - margin, y: h - drawH - margin, width: drawW, height: drawH)
        case .topLeft:
            rect = NSRect(x: margin, y: h - drawH - margin, width: drawW, height: drawH)
        case .center:
            rect = NSRect(x: (w - drawW) / 2, y: (h - drawH) / 2, width: drawW, height: drawH)
        case .tile:
            let spacing = config.tileSpacing(for: imageSize)
            let sx = drawW + spacing
            let sy = drawH + spacing
            var y: CGFloat = spacing
            while y < h {
                var x: CGFloat = spacing
                while x < w {
                    let r = NSRect(x: x, y: y, width: drawW, height: drawH)
                    img.draw(in: r, from: .zero, operation: .sourceOver, fraction: CGFloat(config.opacity))
                    x += sx
                }
                y += sy
            }
            return
        }

        img.draw(in: rect, from: .zero, operation: .sourceOver, fraction: CGFloat(config.opacity))
    }

    // MARK: - 颜色解析

    static func parseColor(hex: String) -> NSColor {
        var s = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        if s.hasPrefix("#") { s.removeFirst() }
        guard s.count == 6, let v = UInt64(s, radix: 16) else { return .white }
        return NSColor(
            red: CGFloat((v >> 16) & 0xFF) / 255,
            green: CGFloat((v >> 8) & 0xFF) / 255,
            blue: CGFloat(v & 0xFF) / 255,
            alpha: 1
        )
    }
}
