#!/usr/bin/env python3
"""
修改 PreviewViewModel.swift — 三处改动
用法: python3 patch_preview_vm.py <PreviewViewModel.swift路径>
"""
import sys, re

def patch(filepath):
    with open(filepath, 'r') as f:
        content = f.read()
    original = content

    # ── 修改 1: copyToClipboard() ──
    # 把 try clipboardService.copy(image, annotations: annotations) 
    # 包上水印逻辑
    old1 = '''        do {
            try clipboardService.copy(image, annotations: annotations)'''
    new1 = '''        do {
            // Apply watermark if enabled
            var finalImage = image
            let watermarkCfg = settings.watermarkConfig
            if watermarkCfg.enabled && !watermarkCfg.text.isEmpty {
                let renderer = WatermarkRenderer()
                finalImage = renderer.applyWatermark(to: finalImage, config: watermarkCfg)
            }
            try clipboardService.copy(finalImage, annotations: annotations)'''

    if old1 in content:
        content = content.replace(old1, new1)
        print('  ✓ copyToClipboard() 已修改')
    else:
        print('  ⚠ copyToClipboard() 未找到精确匹配，尝试模糊匹配...')
        # 尝试更宽松的匹配
        pattern1 = r'try clipboardService\.copy\(image,\s*annotations:\s*annotations\)'
        if re.search(pattern1, content):
            content = re.sub(
                pattern1,
                '''var finalImage = image
            let watermarkCfg = settings.watermarkConfig
            if watermarkCfg.enabled && !watermarkCfg.text.isEmpty {
                let renderer = WatermarkRenderer()
                finalImage = renderer.applyWatermark(to: finalImage, config: watermarkCfg)
            }
            try clipboardService.copy(finalImage, annotations: annotations)''',
                content
            )
            print('  ✓ copyToClipboard() 模糊匹配修改完成')
        else:
            print('  ✗ copyToClipboard() 修改失败，请手动修改')

    # ── 修改 2: performSave() — 在 imageExporter.save 调用加 watermarkConfig ──
    # 匹配 imageExporter.save(... quality: quality ...) 闭括号
    old2_pattern = r'(try imageExporter\.save\(\s*image,\s*annotations:\s*annotations,\s*to:\s*fileURL,\s*format:\s*format,\s*quality:\s*quality\s*)\)'
    new2 = r'\1,\n                watermarkConfig: settings.watermarkConfig\n            )'

    if re.search(old2_pattern, content, re.DOTALL):
        content = re.sub(old2_pattern, new2, content, flags=re.DOTALL)
        print('  ✓ performSave() 已修改')
    else:
        print('  ⚠ performSave() 未匹配，尝试简化模式...')
        # 备选: 找 quality: quality 后面的 )
        if 'quality: quality' in content:
            # 找到 quality: quality 之后第一个独立的 )
            idx = content.find('quality: quality')
            # 找后面的换行+空格+)
            sub = content[idx:]
            m = re.search(r'quality:\s*quality\s*\n(\s*)\)', sub)
            if m:
                old = m.group(0)
                indent = m.group(1)
                new = f'quality: quality,\n{indent}watermarkConfig: settings.watermarkConfig\n{indent})'
                content = content.replace(old, new)
                print('  ✓ performSave() 备选模式修改完成')
            else:
                print('  ✗ performSave() 修改失败，请手动修改')
        else:
            print('  ✗ performSave() 修改失败，请手动修改')

    # ── 写入 ──
    if content != original:
        with open(filepath, 'w') as f:
            f.write(content)
        print('  ✓ 文件已保存')
    else:
        print('  ✗ 文件无变化')

if __name__ == '__main__':
    patch(sys.argv[1])
