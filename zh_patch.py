#!/usr/bin/env python3
"""
批量替换 ScreenCapture 源码中的英文 UI 字符串为中文
在 Apply patches 之后、Build 之前运行
"""
import os, re, sys

TRANSLATIONS = {
    # ========== App/AppDelegate.swift ==========
    '"Capture &Screenshot"': '"截图(&S)"',
    '"&Preferences..."': '"偏好设置(&P)...",',
    '"&About ScreenCapture"': '"关于 截图工具(&A)",',
    '"&Quit ScreenCapture"': '"退出 截图工具(&Q)",',
    
    # ========== App/ScreenCaptureApp.swift ==========
    '"ScreenCapture"': '"截图工具"',
    # ========== Features/Capture/CaptureManager.swift ==========
    # Error messages
    '"Failed to capture screen"': '"截图失败"',
    '"Could not access screen content"': '"无法访问屏幕内容"',
    '"Screen capture permission denied"': '"屏幕录制权限被拒绝"',
    '"Capture cancelled"': '"已取消截图"',
    '"No display available"': '"没有可用的显示器"',
    '"Multiple displays detected"': '"检测到多个显示器"',
    '"Failed to capture display"': '"捕获显示器失败"',
    
    # ========== Features/Preview/PreviewContentView.swift ==========
    '"Copy to Clipboard"': '"复制到剪贴板"',
    '"Save"': '"保存"',
    '"OCR"': '"文字识别"',
    '"Delete"': '"删除"',
    '"Close"': '"关闭"',
    '"Screenshot Preview"': '"截图预览"',
    '"No text detected"': '"未检测到文字"',
    '"Copy Text"': '"复制文字"',
    '"Recognizing text..."': '"正在识别文字..."',
    
    # ========== Features/Preview/PreviewViewModel.swift ==========
    '"Failed to save screenshot"': '"保存截图失败"',
    '"Failed to copy to clipboard"': '"复制到剪贴板失败"',
    '"Screenshot saved"': '"截图已保存"',
    '"Screenshot copied"': '"已复制到剪贴板"',
    
    # ========== Features/Preview/PreviewWindow.swift ==========
    '"Preview"': '"预览"',
    
    # ========== Features/Preview/OCRResultsSheet.swift ==========
    '"Text Recognition Results"': '"文字识别结果"',
    '"No text was found in the screenshot."': '"截图中未找到文字。"',
    '"Copy All"': '"全部复制"',
    
    # ========== Features/Annotations/ ==========
    '"Rectangle"': '"矩形"',
    '"Arrow"': '"箭头"',
    '"Freehand"': '"自由绘制"',
    '"Text"': '"文字"',
    
    # ========== Features/Capture/DisplaySelector.swift ==========
    '"Select a display to capture"': '"选择要截取的显示器"',
    '"Capture"': '"截取"',
    '"Cancel"': '"取消"',
    
    # ========== Features/MenuBar/MenuBarController.swift ==========
    '"Capture Full Screen"': '"全屏截图"',
    '"Capture Selection"': '"区域截图"',
    '"Open Settings"': '"打开设置"',
    '"Quit"': '"退出"',
    '"ScreenCapture is running"': '"截图工具正在运行"',
    
    # ========== Features/Settings/SettingsWindowController.swift ==========
    '"Settings"': '"设置"',
    '"Preferences"': '"偏好设置"',
    
    # ========== Services/ClipboardService.swift ==========
    '"Failed to write to clipboard"': '"写入剪贴板失败"',
    
    # ========== Errors/ScreenCaptureError.swift ==========
    '"Save Location"': '"保存位置"',
    'invalidSaveLocation': 'invalidSaveLocation',
    '"Disk is full"': '"磁盘空间不足"',
    '"Export encoding failed"': '"导出编码失败"',
    'exportEncodingFailed': 'exportEncodingFailed',
    '"Clipboard error"': '"剪贴板错误"',
}

def translate_file(filepath):
    """Replace English strings with Chinese in a Swift file."""
    if not os.path.exists(filepath):
        return
    
    with open(filepath, 'r') as f:
        content = f.read()
    
    original = content
    changed = 0
    
    for eng, chn in TRANSLATIONS.items():
        if eng in content:
            content = content.replace(eng, chn)
            changed += 1
    
    if content != original:
        with open(filepath, 'w') as f:
            f.write(content)
        print(f'  ✓ {os.path.basename(filepath)}: {changed} strings translated')
    else:
        print(f'  - {os.path.basename(filepath)}: no changes')

def main():
    src_dir = sys.argv[1] if len(sys.argv) > 1 else '/tmp/original/ScreenCapture'
    
    swift_files = []
    for root, dirs, files in os.walk(src_dir):
        for f in files:
            if f.endswith('.swift'):
                swift_files.append(os.path.join(root, f))
    
    for f in sorted(swift_files):
        translate_file(f)
    
    print(f'\n✓ 中文化完成，共处理 {len(swift_files)} 个文件')

if __name__ == '__main__':
    main()
