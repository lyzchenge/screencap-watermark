import Foundation
import CoreGraphics
import AppKit

/// 水印位置枚举
enum WatermarkPosition: String, Codable, CaseIterable, Sendable {
    case topLeft = "topLeft"
    case topRight = "topRight"
    case bottomLeft = "bottomLeft"
    case bottomRight = "bottomRight"
    case center = "center"
    case tile = "tile"

    var displayName: String {
        switch self {
        case .topLeft: return "左上角"
        case .topRight: return "右上角"
        case .bottomLeft: return "左下角"
        case .bottomRight: return "右下角"
        case .center: return "居中"
        case .tile: return "平铺"
        }
    }
}

/// 水印配置（支持文字 + 图片）
struct WatermarkConfig: Codable, Sendable {
    /// 是否启用水印
    var enabled: Bool = false

    /// 文字水印是否启用
    var textEnabled: Bool = true

    /// 水印文字
    var text: String = ""

    /// 字体大小（相对于图片宽度的比例，如 0.03 表示字高为图宽的 3%）
    var fontSizeRatio: Double = 0.03

    /// 不透明度 (0.0 ~ 1.0)
    var opacity: Double = 0.6

    /// 水印位置
    var position: WatermarkPosition = .bottomRight

    /// 距离边缘的内边距（相对于图片宽度的比例）
    var marginRatio: Double = 0.02

    /// 水印颜色（文字水印用，默认白色）
    var colorHex: String = "#FFFFFF"

    /// 平铺时的间距比例
    var tileSpacingRatio: Double = 0.25

    // MARK: - 图片水印

    /// 图片水印是否启用
    var imageEnabled: Bool = false

    /// 图片水印数据（PNG/JPEG）
    var imageData: Data? = nil

    /// 图片水印尺寸比例（相对于图片短边的比例）
    var imageSizeRatio: Double = 0.08

    // MARK: - Computed Properties

    func fontSize(for imageSize: CGSize) -> CGFloat {
        let baseSize = min(imageSize.width, imageSize.height)
        return baseSize * fontSizeRatio
    }

    func margin(for imageSize: CGSize) -> CGFloat {
        let baseSize = min(imageSize.width, imageSize.height)
        return baseSize * marginRatio
    }

    func tileSpacing(for imageSize: CGSize) -> CGFloat {
        let baseSize = min(imageSize.width, imageSize.height)
        return baseSize * tileSpacingRatio
    }

    func imageSize(for imageSize: CGSize) -> CGFloat {
        let baseSize = min(imageSize.width, imageSize.height)
        return baseSize * imageSizeRatio
    }
}
