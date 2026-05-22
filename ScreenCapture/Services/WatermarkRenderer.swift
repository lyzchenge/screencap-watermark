import Foundation
import CoreGraphics
import AppKit

/// 水印渲染 — 使用 NSBitmapImageRep 合成，最可靠方案
struct WatermarkRenderer: Sendable {

    func applyWatermark(to image: CGImage, config: WatermarkConfig) -> CGImage {
        guard config.enabled else { return image }

        let hasText = config.textEnabled && !config.text.isEmpty
        let hasImage = config.imageEnabled && config.imageData != nil
        guard hasText || hasImage else { return image }

        let w = image.width
        let h = image.height

        guard let rep = NSBitmapImageRep(
            bitmapDataPlanes: nil,
            pixelsWide: w, pixelsHigh: h,
            bitsPerSample: 8, samplesPerPixel: 4,
            hasAlpha: true, isPlanar: false,
            colorSpaceName: .deviceRGB,
            bytesPerRow: w * 4, bitsPerPixel: 32
        ) else { return image }

        NSGraphicsContext.saveGraphicsState()
        NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)

        // 画原图
        let nsImage = NSImage(cgImage: image, size: NSSize(width: w, height: h))
        nsImage.draw(in: NSRect(x: 0, y: 0, width: w, height: h),
                     from: .zero, operation: .copy, fraction: 1)

        // 画水印
        if hasText {
            renderText(config: config, imageSize: CGSize(width: w, height: h))
        }
        if hasImage {
            renderImage(config: config, imageSize: CGSize(width: w, height: h))
        }

        NSGraphicsContext.restoreGraphicsState()

        return rep.cgImage ?? image
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
        let sz = str.size()

        switch config.position {
        case .bottomRight:
            str.draw(at: NSPoint(x: w - sz.width - margin, y: margin))
        case .bottomLeft:
            str.draw(at: NSPoint(x: margin, y: margin))
        case .topRight:
            str.draw(at: NSPoint(x: w - sz.width - margin, y: h - sz.height - margin))
        case .topLeft:
            str.draw(at: NSPoint(x: margin, y: h - sz.height - margin))
        case .center:
            str.draw(at: NSPoint(x: (w - sz.width) / 2, y: (h - sz.height) / 2))
        case .tile:
            let sp = config.tileSpacing(for: imageSize)
            let sx = sz.width + sp; let sy = sz.height + sp
            var y: CGFloat = sp
            while y < h { var x: CGFloat = sp
                while x < w { str.draw(at: NSPoint(x: x, y: y)); x += sx }
                y += sy
            }
        }
    }

    // MARK: - 图片水印

    private func renderImage(config: WatermarkConfig, imageSize: CGSize) {
        guard let data = config.imageData, let img = NSImage(data: data), img.isValid else { return }
        let margin = config.margin(for: imageSize)
        let target = config.imageSize(for: imageSize)
        let w = imageSize.width; let h = imageSize.height
        let aspect = img.size.width / img.size.height
        var dw: CGFloat, dh: CGFloat
        if aspect >= 1 { dw = target; dh = target / aspect }
        else { dh = target; dw = target * aspect }

        let frac = CGFloat(config.opacity)
        switch config.position {
        case .bottomRight:
            img.draw(in: NSRect(x: w - dw - margin, y: margin, width: dw, height: dh),
                     from: .zero, operation: .sourceOver, fraction: frac)
        case .bottomLeft:
            img.draw(in: NSRect(x: margin, y: margin, width: dw, height: dh),
                     from: .zero, operation: .sourceOver, fraction: frac)
        case .topRight:
            img.draw(in: NSRect(x: w - dw - margin, y: h - dh - margin, width: dw, height: dh),
                     from: .zero, operation: .sourceOver, fraction: frac)
        case .topLeft:
            img.draw(in: NSRect(x: margin, y: h - dh - margin, width: dw, height: dh),
                     from: .zero, operation: .sourceOver, fraction: frac)
        case .center:
            img.draw(in: NSRect(x: (w - dw) / 2, y: (h - dh) / 2, width: dw, height: dh),
                     from: .zero, operation: .sourceOver, fraction: frac)
        case .tile:
            let sp = config.tileSpacing(for: imageSize)
            let sx = dw + sp; let sy = dh + sp
            var y: CGFloat = sp
            while y < h { var x: CGFloat = sp
                while x < w {
                    img.draw(in: NSRect(x: x, y: y, width: dw, height: dh),
                             from: .zero, operation: .sourceOver, fraction: frac)
                    x += sx
                }
                y += sy
            }
        }
    }

    static func parseColor(hex: String) -> NSColor {
        var s = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        if s.hasPrefix("#") { s.removeFirst() }
        guard s.count == 6, let v = UInt64(s, radix: 16) else { return .white }
        return NSColor(red: CGFloat((v >> 16) & 0xFF) / 255,
                       green: CGFloat((v >> 8) & 0xFF) / 255,
                       blue: CGFloat(v & 0xFF) / 255, alpha: 1)
    }
}
