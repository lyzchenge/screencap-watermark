import Foundation
import CoreGraphics
import AppKit
import ImageIO

/// 水印渲染引擎，支持文字水印 + 图片水印
struct WatermarkRenderer: Sendable {

    // MARK: - Public API

    func applyWatermark(to image: CGImage, config: WatermarkConfig) -> CGImage {
        guard config.enabled else { return image }

        let hasText = config.textEnabled && !config.text.isEmpty
        let hasImage = config.imageEnabled && config.imageData != nil

        guard hasText || hasImage else { return image }

        let width = CGFloat(image.width)
        let height = CGFloat(image.height)
        let imageSize = CGSize(width: width, height: height)

        guard let colorSpace = image.colorSpace ?? CGColorSpace(name: CGColorSpace.sRGB),
              let context = CGContext(
                  data: nil,
                  width: Int(width), height: Int(height),
                  bitsPerComponent: 8, bytesPerRow: 0,
                  space: colorSpace,
                  bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
              ) else {
            return image
        }

        // 先画原图
        context.draw(image, in: CGRect(x: 0, y: 0, width: width, height: height))

        // 画水印
        if hasText {
            renderTextWatermark(config: config, imageSize: imageSize, in: context)
        }

        if hasImage {
            renderImageWatermark(config: config, imageSize: imageSize, in: context)
        }

        return context.makeImage() ?? image
    }

    // MARK: - 文字水印

    private func renderTextWatermark(config: WatermarkConfig, imageSize: CGSize, in context: CGContext) {
        let nsColor = Self.parseColor(hex: config.colorHex)
        let fontSize = config.fontSize(for: imageSize)
        let margin = config.margin(for: imageSize)

        let attributes: [NSAttributedString.Key: Any] = [
            .font: NSFont.systemFont(ofSize: fontSize, weight: .medium),
            .foregroundColor: nsColor.withAlphaComponent(config.opacity)
        ]

        let attrString = NSAttributedString(string: config.text, attributes: attributes)
        let textSize = attrString.size()

        context.setShouldAntialias(true)
        context.setAllowsAntialiasing(true)

        switch config.position {
        case .bottomRight:
            drawText(attrString, at: CGPoint(x: imageSize.width - textSize.width - margin, y: margin), in: context)
        case .bottomLeft:
            drawText(attrString, at: CGPoint(x: margin, y: margin), in: context)
        case .topRight:
            drawText(attrString, at: CGPoint(x: imageSize.width - textSize.width - margin, y: imageSize.height - textSize.height - margin), in: context)
        case .topLeft:
            drawText(attrString, at: CGPoint(x: margin, y: imageSize.height - textSize.height - margin), in: context)
        case .center:
            drawText(attrString, at: CGPoint(x: (imageSize.width - textSize.width) / 2, y: (imageSize.height - textSize.height) / 2), in: context)
        case .tile:
            let spacing = config.tileSpacing(for: imageSize)
            let stepX = textSize.width + spacing
            let stepY = textSize.height + spacing
            var y: CGFloat = spacing
            while y < imageSize.height {
                var x: CGFloat = spacing
                while x < imageSize.width {
                    drawText(attrString, at: CGPoint(x: x, y: y), in: context)
                    x += stepX
                }
                y += stepY
            }
        }
    }

    private func drawText(_ attrString: NSAttributedString, at point: CGPoint, in context: CGContext) {
        let line = CTLineCreateWithAttributedString(attrString)
        context.textPosition = point
        CTLineDraw(line, context)
    }

    // MARK: - 图片水印

    private func renderImageWatermark(config: WatermarkConfig, imageSize: CGSize, in context: CGContext) {
        guard let data = config.imageData,
              let dataProvider = CGDataProvider(data: data as CFData),
              let watermarkImage = CGImage(
                  pngDataProviderSource: dataProvider, decode: nil,
                  shouldInterpolate: true, intent: .defaultIntent
              ) ?? CGImage(
                  jpegDataProviderSource: dataProvider, decode: nil,
                  shouldInterpolate: true, intent: .defaultIntent
              ) else {
            return
        }

        let margin = config.margin(for: imageSize)
        let targetSize = config.imageSize(for: imageSize)
        let aspectRatio = CGFloat(watermarkImage.width) / CGFloat(watermarkImage.height)
        var drawW: CGFloat, drawH: CGFloat
        if aspectRatio >= 1 {
            drawW = targetSize
            drawH = targetSize / aspectRatio
        } else {
            drawH = targetSize
            drawW = targetSize * aspectRatio
        }

        // 计算位置
        let rect: CGRect
        switch config.position {
        case .bottomRight:
            rect = CGRect(x: imageSize.width - drawW - margin, y: margin, width: drawW, height: drawH)
        case .bottomLeft:
            rect = CGRect(x: margin, y: margin, width: drawW, height: drawH)
        case .topRight:
            rect = CGRect(x: imageSize.width - drawW - margin, y: imageSize.height - drawH - margin, width: drawW, height: drawH)
        case .topLeft:
            rect = CGRect(x: margin, y: imageSize.height - drawH - margin, width: drawW, height: drawH)
        case .center:
            rect = CGRect(x: (imageSize.width - drawW) / 2, y: (imageSize.height - drawH) / 2, width: drawW, height: drawH)
        case .tile:
            let spacing = config.tileSpacing(for: imageSize)
            let stepX = drawW + spacing
            let stepY = drawH + spacing
            var y: CGFloat = spacing
            while y < imageSize.height {
                var x: CGFloat = spacing
                while x < imageSize.width {
                    let r = CGRect(x: x, y: y, width: drawW, height: drawH)
                    drawImage(watermarkImage, in: r, opacity: config.opacity, in: context)
                    x += stepX
                }
                y += stepY
            }
            return
        }

        drawImage(watermarkImage, in: rect, opacity: config.opacity, in: context)
    }

    private func drawImage(_ cgImage: CGImage, in rect: CGRect, opacity: CGFloat, in context: CGContext) {
        context.saveGState()
        context.setAlpha(opacity)
        context.draw(cgImage, in: rect)
        context.restoreGState()
    }

    // MARK: - 颜色解析

    static func parseColor(hex: String) -> NSColor {
        var hexSanitized = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        if hexSanitized.hasPrefix("#") { hexSanitized.removeFirst() }
        guard hexSanitized.count == 6, let value = UInt64(hexSanitized, radix: 16) else { return .white }
        let r = CGFloat((value >> 16) & 0xFF) / 255.0
        let g = CGFloat((value >> 8) & 0xFF) / 255.0
        let b = CGFloat(value & 0xFF) / 255.0
        return NSColor(red: r, green: g, blue: b, alpha: 1.0)
    }
}
