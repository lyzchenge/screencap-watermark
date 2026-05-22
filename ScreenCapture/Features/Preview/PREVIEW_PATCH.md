# PreviewViewModel 水印补丁 — 精确修改说明

原始文件: `ScreenCapture/Features/Preview/PreviewViewModel.swift` (1057行)

---

## 修改 1: copyToClipboard() — 第 848-858 行

### 原始代码:
```swift
    /// Copies the screenshot to clipboard (Cmd+C action)
    func copyToClipboard() {
        guard !isCopying else { return }
        isCopying = true

        do {
            try clipboardService.copy(image, annotations: annotations)
        } catch {
            errorMessage = NSLocalizedString("error.clipboard.write.failed", comment: "Failed to copy to clipboard")
            clearError()
        }

        isCopying = false
    }
```

### 改为:
```swift
    /// Copies the screenshot to clipboard (Cmd+C action)
    func copyToClipboard() {
        guard !isCopying else { return }
        isCopying = true

        do {
            // Apply watermark if enabled
            var finalImage = image
            let watermarkCfg = settings.watermarkConfig
            if watermarkCfg.enabled && !watermarkCfg.text.isEmpty {
                let renderer = WatermarkRenderer()
                finalImage = renderer.applyWatermark(to: finalImage, config: watermarkCfg)
            }
            try clipboardService.copy(finalImage, annotations: annotations)
        } catch {
            errorMessage = NSLocalizedString("error.clipboard.write.failed", comment: "Failed to copy to clipboard")
            clearError()
        }

        isCopying = false
    }
```

---

## 修改 2: performSave() — 第 891-899 行

### 原始代码:
```swift
        do {
            try imageExporter.save(
                image,
                annotations: annotations,
                to: fileURL,
                format: format,
                quality: quality
            )
```

### 改为:
```swift
        do {
            try imageExporter.save(
                image,
                annotations: annotations,
                to: fileURL,
                format: format,
                quality: quality,
                watermarkConfig: settings.watermarkConfig
            )
```

---

## 修改 3: 文件顶部 import 区域（约第 5 行），确认没有遗漏依赖

PreviewViewModel 已经 import Foundation / SwiftUI / AppKit / Observation，
WatermarkRenderer 和 WatermarkConfig 在同一个 target 内，无需额外 import。

---

就这三处改动，改完 ⌘B 编译即可。
