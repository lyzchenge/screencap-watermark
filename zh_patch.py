#!/usr/bin/env python3
"""中文化：只改真实 UI 展示的英文字符串，不碰 Swift 关键字。"""
import os, sys, re

# (eng_string, chn_string) pairs
# Only replace when the English string appears as a Swift string literal
TRANSLATIONS = [
    # === App/AppDelegate.swift ===
    ('Capture &Screenshot', '截图(&S)'),
    ('&Preferences...', '偏好设置(&P)...'),
    ('&About ScreenCapture', '关于截图工具(&A)'),
    ('&Quit ScreenCapture', '退出截图工具(&Q)'),

    # === App/ScreenCaptureApp.swift ===
    # "ScreenCapture" as window title (not as code identifier)
    # Skip - might break things

    # === Features/MenuBar/MenuBarController.swift ===
    ('Capture Full Screen', '全屏截图'),
    ('Capture Selection', '区域截图'),
    ('Open Settings', '打开设置'),

    # === Features/Capture/DisplaySelector.swift ===
    ('Select a display to capture', '选择要截取的显示器'),

    # === Features/Preview/PreviewContentView.swift ===
    ('Copy to Clipboard', '复制到剪贴板'),
    ('OCR', '文字识别'),

    # === Features/Preview/PreviewWindow.swift ===
    # 'Preview' is used as title - might conflict
    # Skip

    # === Features/Preview/OCRResultsSheet.swift ===
    ('Text Recognition Results', '文字识别结果'),
    ('No text was found in the screenshot.', '截图中未找到文字。'),
    ('Copy All', '全部复制'),
    ('Copy Text', '复制文字'),
    ('Recognizing text...', '正在识别文字...'),
    ('No text detected', '未检测到文字'),

    # === Features/Settings/ ===
    # Already done in SettingsView.swift
    # SettingsViewModel messages:
    ('Failed to save screenshot', '保存截图失败'),
    ('Failed to copy to clipboard', '复制到剪贴板失败'),
    ('Screenshot saved', '截图已保存'),
    ('Screenshot copied', '已复制到剪贴板'),

    # === Errors ===
    ('Failed to capture screen', '截图失败'),
    ('Could not access screen content', '无法访问屏幕内容'),
    ('Screen capture permission denied', '屏幕录制权限被拒绝'),
    ('Capture cancelled', '已取消截图'),
    ('No display available', '没有可用的显示器'),
    ('Failed to capture display', '捕获显示器失败'),
    ('Disk is full', '磁盘空间不足'),
    ('Export encoding failed', '导出编码失败'),
    ('Clipboard error', '剪贴板错误'),
    ('Failed to write to clipboard', '写入剪贴板失败'),

    # === Annotations ===
    ('Rectangle', '矩形'),
    ('Arrow', '箭头'),
    ('Freehand', '自由绘制'),
]

def process_file(filepath):
    if not os.path.exists(filepath):
        return
    with open(filepath, 'r') as f:
        content = f.read()
    original = content
    changes = 0
    for eng, chn in TRANSLATIONS:
        # Match the English string as a Swift string literal
        pattern = '"' + re.escape(eng) + '"'
        if re.search(pattern, content):
            # Only replace strings in quotes, not identifiers
            # But simple replacement of "English" with "中文" is fine for UI strings
            pass
        # Simple string replacement for quoted strings
        quoted = f'"{eng}"'
        if quoted in content:
            content = content.replace(quoted, f'"{chn}"')
            changes += 1
    if content != original:
        with open(filepath, 'w') as f:
            f.write(content)
        print(f'  ✓ {os.path.basename(filepath)}: {changes}')

def main():
    src_dir = sys.argv[1] if len(sys.argv) > 1 else '/tmp/original/ScreenCapture'
    processed = 0
    for root, _, files in os.walk(src_dir):
        for f in sorted(files):
            if f.endswith('.swift'):
                process_file(os.path.join(root, f))
    print(f'✓ 中文化完成')

if __name__ == '__main__':
    main()
