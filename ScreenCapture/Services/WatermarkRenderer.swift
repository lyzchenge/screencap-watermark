import Foundation
import CoreGraphics
import AppKit

/// 水印渲染引擎，负责将水印文字绘制到 CGImage 上
struct WatermarkRenderer: Sendable {

    // MARK: - Public API

    /// 在图片上绘制水印，返回带水印的新 CGImage
    /// - Parameters:
    ///   - image: 原始图片
    ///   - config: 水印配置
    /// - Returns: 带水印的 CGImage，如果水印未启用或文字为空则返回原图
    func applyWatermark(to image: CGImage, config: WatermarkConfig) -> CGImage {
        guard config.enabled, !config.text.isEmpty else {
            return image
        }

        let width = CGFloat(image.width)
        let height = CGFloat(image.height)
        let imageSize = CGSize(width: width, height: height)

        // 创建位图上下文（先清除原图 alpha 信息，再设置新的，避免无效位掩码）
        let alphaInfo = CGImageAlphaInfo.premultipliedLast.rawValue
        let cleanInfo = image.bitmapInfo.rawValue & ~CGBitmapInfo.alphaInfoMask.rawValue
        let bitmapInfo = cleanInfo | alphaInfo
        guard let colorSpace = image.colorSpace ?? CGColorSpace(name: CGColorSpace.sRGB),
              let context = CGContext(
                  data: nil,
                  width: Int(width), height: Int(height),
                  bitsPerComponent: 8, bytesPerRow: 0,
                  space: colorSpace,
                  bitmapInfo: bitmapInfo
              ) else {
            return image
        }

        // 先画原图
        context.draw(image, in: CGRect(x: 0, y: 0, width: width, height: height))

        // 解析颜色
        let nsColor = Self.parseColor(hex: config.colorHex)
        let cgColor = nsColor.withAlphaComponent(config.opacity).cgColor

        let fontSize = config.fontSize(for: imageSize)
        let margin = config.margin(for: imageSize)

        // 创建 AttributedString 用于绘制
        let attributes: [NSAttributedString.Key: Any] = [
            .font: NSFont.systemFont(ofSize: fontSize, weight: .medium),
            .foregroundColor: nsColor.withAlphaComponent(config.opacity)
        ]

        let attrString = NSAttributedString(string: config.text, attributes: attributes)
        let textSize = attrString.size()

        // 上下文配置
        context.setShouldAntialias(true)
        context.setAllowsAntialiasing(true)

        switch config.position {
        case .bottomRight:
            let point = CGPoint(
                x: width - textSize.width - margin,
                y: margin
            )
            drawText(attrString, at: point, in: context)

        case .bottomLeft:
            let point = CGPoint(
                x: margin,
                y: margin
            )
            drawText(attrString, at: point, in: context)

        case .topRight:
            let point = CGPoint(
                x: width - textSize.width - margin,
                y: height - textSize.height - margin
            )
            drawText(attrString, at: point, in: context)

        case .topLeft:
            let point = CGPoint(
                x: margin,
                y: height - textSize.height - margin
            )
            drawText(attrString, at: point, in: context)

        case .center:
            let point = CGPoint(
                x: (width - textSize.width) / 2,
                y: (height - textSize.height) / 2
            )
            drawText(attrString, at: point, in: context)

        case .tile:
            drawTiledText(attrString, textSize: textSize, imageSize: imageSize, config: config, in: context)
        }

        guard let result = context.makeImage() else {
            return image
        }

        return result
    }

    // MARK: - Private Methods

    /// 绘制文字（使用 CTLine 避免翻转坐标系问题）
    private func drawText(_ attrString: NSAttributedString, at point: CGPoint, in context: CGContext) {
        let line = CTLineCreateWithAttributedString(attrString)
        context.textPosition = point
        CTLineDraw(line, context)
    }

    /// 平铺绘制
    private func drawTiledText(
        _ attrString: NSAttributedString,
        textSize: CGSize,
        imageSize: CGSize,
        config: WatermarkConfig,
        in context: CGContext
    ) {
        let spacing = config.tileSpacing(for: imageSize)
        let stepX = textSize.width + spacing
        let stepY = textSize.height + spacing

        var y: CGFloat = spacing
        while y < imageSize.height {
            var x: CGFloat = spacing
            while x < imageSize.width {
                let point = CGPoint(x: x, y: y)
                drawText(attrString, at: point, in: context)
                x += stepX
            }
            y += stepY
        }
    }

    /// 解析十六进制颜色
    static func parseColor(hex: String) -> NSColor {
        var hexSanitized = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        if hexSanitized.hasPrefix("#") {
            hexSanitized.removeFirst()
        }

        guard hexSanitized.count == 6,
              let value = UInt64(hexSanitized, radix: 16) else {
            return .white
        }

        let r = CGFloat((value >> 16) & 0xFF) / 255.0
        let g = CGFloat((value >> 8) & 0xFF) / 255.0
        let b = CGFloat(value & 0xFF) / 255.0

        return NSColor(red: r, green: g, blue: b, alpha: 1.0)
    }
}
