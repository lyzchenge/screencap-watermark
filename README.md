# ScreenCapture Watermark

基于 [sadopc/ScreenCapture](https://github.com/sadopc/ScreenCapture)（MIT 协议）增加水印功能的增强版。

## 功能

- 6 种水印位置（左上/右上/左下/右下/居中/平铺）
- 可调字号（1%-10%）
- 可调透明度（5%-100%）
- 可调颜色
- 截图保存和剪贴板均自动叠加水印

## 自动构建

推送到 GitHub 后，Actions 会自动在 macOS 环境编译并生成 DMG，下载地址在 Actions → 最新一次 run → Artifacts。

## 手动构建（需要 Xcode）

```bash
chmod +x build_dmg.sh && ./build_dmg.sh
```
