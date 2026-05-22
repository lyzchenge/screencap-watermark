import SwiftUI
import AppKit

struct SettingsView: View {
    @Bindable var viewModel: SettingsViewModel

    var body: some View {
        Form {
            Section {
                PermissionRow(viewModel: viewModel)
            } header: {
                Label("权限", systemImage: "lock.shield")
            }
            Section {
                SaveLocationPicker(viewModel: viewModel)
            } header: {
                Label("通用", systemImage: "gearshape")
            }
            Section {
                ExportFormatPicker(viewModel: viewModel)
                if viewModel.defaultFormat == .jpeg {
                    JPEGQualitySlider(viewModel: viewModel)
                } else if viewModel.defaultFormat == .heic {
                    HEICQualitySlider(viewModel: viewModel)
                }
            } header: {
                Label("导出", systemImage: "square.and.arrow.up")
            }
            Section {
                ShortcutRecorder(label: "全屏截图", shortcut: viewModel.fullScreenShortcut,
                    isRecording: viewModel.isRecordingFullScreenShortcut,
                    onRecord: { viewModel.startRecordingFullScreenShortcut() },
                    onReset: { viewModel.resetFullScreenShortcut() })
                ShortcutRecorder(label: "区域截图", shortcut: viewModel.selectionShortcut,
                    isRecording: viewModel.isRecordingSelectionShortcut,
                    onRecord: { viewModel.startRecordingSelectionShortcut() },
                    onReset: { viewModel.resetSelectionShortcut() })
            } header: {
                Label("快捷键", systemImage: "keyboard")
            }
            Section {
                OCRRecognitionLevelPicker(viewModel: viewModel)
                OCRLanguagePicker(viewModel: viewModel)
            } header: {
                Label("文字识别", systemImage: "doc.text.viewfinder")
            }
            Section {
                StrokeColorPicker(viewModel: viewModel)
                StrokeWidthSlider(viewModel: viewModel)
                TextSizeSlider(viewModel: viewModel)
            } header: {
                Label("标注", systemImage: "pencil.tip.crop.circle")
            }

            // 水印
            Section {
                WatermarkToggle(viewModel: viewModel)
                if viewModel.watermarkEnabled {
                    Divider()

                    // 文字水印
                    TextWatermarkToggle(viewModel: viewModel)
                    if viewModel.watermarkTextEnabled {
                        WatermarkTextField(viewModel: viewModel)
                        WatermarkFontSizeSlider(viewModel: viewModel)
                    }

                    // 图片水印
                    ImageWatermarkToggle(viewModel: viewModel)
                    if viewModel.watermarkImageEnabled {
                        WatermarkImagePicker(viewModel: viewModel)
                        WatermarkImageSizeSlider(viewModel: viewModel)
                    }

                    if viewModel.watermarkTextEnabled || viewModel.watermarkImageEnabled {
                        Divider()
                        WatermarkOpacitySlider(viewModel: viewModel)
                        WatermarkPositionPicker(viewModel: viewModel)
                    }
                }
            } header: {
                Label("水印", systemImage: "text.word.spacing")
            }

            Section {
                Button(role: .destructive) {
                    viewModel.resetAllToDefaults()
                } label: {
                    Label("恢复默认设置", systemImage: "arrow.counterclockwise")
                }.buttonStyle(.plain).foregroundStyle(.red)
            }
        }
        .formStyle(.grouped)
        .frame(minWidth: 480, minHeight: 580)
        .alert("错误", isPresented: $viewModel.showErrorAlert) {
            Button("确定") { viewModel.errorMessage = nil }
        } message: {
            if let message = viewModel.errorMessage { Text(message) }
        }
    }
}

// MARK: - 水印总开关
private struct WatermarkToggle: View {
    @Bindable var viewModel: SettingsViewModel
    var body: some View {
        Toggle("启用水印", isOn: $viewModel.watermarkEnabled)
    }
}

// MARK: - 文字水印开关
private struct TextWatermarkToggle: View {
    @Bindable var viewModel: SettingsViewModel
    var body: some View {
        Toggle("文字水印", isOn: $viewModel.watermarkTextEnabled)
    }
}

// MARK: - 文字水印输入
private struct WatermarkTextField: View {
    @Bindable var viewModel: SettingsViewModel
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("水印文字").font(.subheadline)
            TextField("例如：© 2026 某某某", text: $viewModel.watermarkText).textFieldStyle(.roundedBorder)
        }
    }
}

// MARK: - 文字字号
private struct WatermarkFontSizeSlider: View {
    @Bindable var viewModel: SettingsViewModel
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("字号"); Spacer()
                Text("\(Int(viewModel.watermarkFontSizePercent))%").foregroundStyle(.secondary).monospacedDigit()
            }
            Slider(value: $viewModel.watermarkFontSizePercent, in: SettingsViewModel.watermarkFontSizeRange, step: 0.5) {
                Text("字号")
            } minimumValueLabel: { Text("1%").font(.caption) } maximumValueLabel: { Text("10%").font(.caption) }
            Text("相对于图片尺寸的比例").font(.caption).foregroundStyle(.secondary)
        }
    }
}

// MARK: - 图片水印开关
private struct ImageWatermarkToggle: View {
    @Bindable var viewModel: SettingsViewModel
    var body: some View {
        Toggle("图片水印", isOn: $viewModel.watermarkImageEnabled)
    }
}

// MARK: - 图片水印选择
private struct WatermarkImagePicker: View {
    @Bindable var viewModel: SettingsViewModel
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("水印图片").font(.subheadline)
            HStack {
                if let img = viewModel.watermarkPreviewImage {
                    Image(nsImage: img)
                        .resizable().aspectRatio(contentMode: .fit)
                        .frame(maxWidth: 150, maxHeight: 60)
                        .clipShape(RoundedRectangle(cornerRadius: 4))
                        .overlay(RoundedRectangle(cornerRadius: 4).stroke(Color.secondary.opacity(0.3)))
                } else {
                    Text("未选择图片")
                        .foregroundStyle(.secondary)
                        .frame(height: 40)
                }
                Spacer()
                HStack(spacing: 8) {
                    Button { viewModel.selectWatermarkImage() } label: {
                        Text("选择...")
                    }
                    if viewModel.watermarkPreviewImage != nil {
                        Button { viewModel.clearWatermarkImage() } label: {
                            Text("清除")
                        }.foregroundStyle(.red)
                    }
                }
            }
        }
    }
}

// MARK: - 图片水印大小
private struct WatermarkImageSizeSlider: View {
    @Bindable var viewModel: SettingsViewModel
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("图片大小"); Spacer()
                Text("\(Int(viewModel.watermarkImageSizePercent))%").foregroundStyle(.secondary).monospacedDigit()
            }
            Slider(value: $viewModel.watermarkImageSizePercent, in: SettingsViewModel.watermarkImageSizeRange, step: 0.5) {
                Text("图片大小")
            } minimumValueLabel: { Text("2%").font(.caption) } maximumValueLabel: { Text("30%").font(.caption) }
            Text("相对于图片短边的比例").font(.caption).foregroundStyle(.secondary)
        }
    }
}

// MARK: - 透明度
private struct WatermarkOpacitySlider: View {
    @Bindable var viewModel: SettingsViewModel
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("透明度"); Spacer()
                Text("\(Int(viewModel.watermarkOpacityPercent))%").foregroundStyle(.secondary).monospacedDigit()
            }
            Slider(value: $viewModel.watermarkOpacityPercent, in: SettingsViewModel.watermarkOpacityRange, step: 5) {
                Text("透明度")
            } minimumValueLabel: { Text("10%").font(.caption) } maximumValueLabel: { Text("100%").font(.caption) }
        }
    }
}

// MARK: - 位置
private struct WatermarkPositionPicker: View {
    @Bindable var viewModel: SettingsViewModel
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("位置").font(.subheadline)
            Picker("位置", selection: $viewModel.watermarkPosition) {
                ForEach(WatermarkPosition.allCases, id: \.self) { pos in Text(pos.displayName).tag(pos) }
            }.pickerStyle(.segmented)
        }
    }
}

// MARK: - 权限行
private struct PermissionRow: View {
    @Bindable var viewModel: SettingsViewModel
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            PermissionItem(icon: "record.circle", title: "屏幕录制", hint: "截图功能需要此权限",
                isGranted: viewModel.hasScreenRecordingPermission, isChecking: viewModel.isCheckingPermissions,
                onGrant: { viewModel.requestScreenRecordingPermission() })
            Divider()
            PermissionItem(icon: "folder", title: "保存位置访问", hint: "保存截图需要访问所选文件夹",
                isGranted: viewModel.hasFolderAccessPermission, isChecking: viewModel.isCheckingPermissions,
                onGrant: { viewModel.requestFolderAccess() })
            HStack { Spacer(); Button { viewModel.checkPermissions() } label: {
                Label("刷新", systemImage: "arrow.clockwise") }.buttonStyle(.borderless) }
        }.onAppear { viewModel.checkPermissions() }
    }
}

private struct PermissionItem: View {
    let icon: String; let title: String; let hint: String
    let isGranted: Bool; let isChecking: Bool; let onGrant: () -> Void
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                HStack(spacing: 8) {
                    Image(systemName: icon).foregroundStyle(.secondary).frame(width: 20); Text(title)
                }; Spacer()
                if isChecking { ProgressView().controlSize(.small) }
                else { HStack(spacing: 8) {
                    if isGranted {
                        Image(systemName: "checkmark.circle.fill").foregroundStyle(.green)
                        Text("已授权").foregroundStyle(.secondary)
                    } else {
                        Image(systemName: "xmark.circle.fill").foregroundStyle(.red)
                        Button { onGrant() } label: { Text("授权") }.buttonStyle(.borderedProminent).controlSize(.small)
                    }
                }}
            }
            if !isGranted && !isChecking { Text(hint).font(.caption).foregroundStyle(.secondary) }
        }
    }
}

private struct SaveLocationPicker: View {
    @Bindable var viewModel: SettingsViewModel
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("保存位置").font(.headline)
                Text(viewModel.saveLocationPath).font(.caption).foregroundStyle(.secondary).lineLimit(1).truncationMode(.middle)
            }; Spacer()
            Button { viewModel.selectSaveLocation() } label: { Text("选择...") }
            Button { viewModel.revealSaveLocation() } label: { Image(systemName: "folder") }.help("在访达中显示")
        }
    }
}

private struct ExportFormatPicker: View {
    @Bindable var viewModel: SettingsViewModel
    var body: some View {
        Picker("默认格式", selection: $viewModel.defaultFormat) {
            Text("PNG").tag(ExportFormat.png); Text("JPEG").tag(ExportFormat.jpeg); Text("HEIC").tag(ExportFormat.heic)
        }.pickerStyle(.segmented)
    }
}

private struct JPEGQualitySlider: View {
    @Bindable var viewModel: SettingsViewModel
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("JPEG 质量"); Spacer()
                Text("\(Int(viewModel.jpegQualityPercentage))%").foregroundStyle(.secondary).monospacedDigit()
            }
            Slider(value: $viewModel.jpegQuality, in: SettingsViewModel.jpegQualityRange, step: 0.05) {
                Text("JPEG 质量")
            } minimumValueLabel: { Text("10%").font(.caption) } maximumValueLabel: { Text("100%").font(.caption) }
            Text("质量越高，文件越大").font(.caption).foregroundStyle(.secondary)
        }
    }
}

private struct HEICQualitySlider: View {
    @Bindable var viewModel: SettingsViewModel
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("HEIC 质量"); Spacer()
                Text("\(Int(viewModel.heicQualityPercentage))%").foregroundStyle(.secondary).monospacedDigit()
            }
            Slider(value: $viewModel.heicQuality, in: SettingsViewModel.heicQualityRange, step: 0.05) {
                Text("HEIC 质量")
            } minimumValueLabel: { Text("10%").font(.caption) } maximumValueLabel: { Text("100%").font(.caption) }
            Text("HEIC 比 JPEG 压缩率更高").font(.caption).foregroundStyle(.secondary)
        }
    }
}

private struct ShortcutRecorder: View {
    let label: String; let shortcut: KeyboardShortcut
    let isRecording: Bool; let onRecord: () -> Void; let onReset: () -> Void
    var body: some View {
        HStack {
            Text(label); Spacer()
            if isRecording {
                Text("按下快捷键...").foregroundStyle(.secondary).padding(.horizontal, 12).padding(.vertical, 6)
                    .background(Color.accentColor.opacity(0.2)).clipShape(RoundedRectangle(cornerRadius: 6))
            } else {
                Button { onRecord() } label: {
                    Text(shortcut.displayString).padding(.horizontal, 12).padding(.vertical, 6)
                        .background(Color.secondary.opacity(0.1)).clipShape(RoundedRectangle(cornerRadius: 6))
                }.buttonStyle(.plain)
            }
            Button { onReset() } label: {
                Image(systemName: "arrow.counterclockwise")
            }.buttonStyle(.borderless).help("恢复默认").disabled(isRecording)
        }
    }
}

private struct StrokeColorPicker: View {
    @Bindable var viewModel: SettingsViewModel
    var body: some View {
        HStack {
            Text("线条颜色"); Spacer()
            HStack(spacing: 4) {
                ForEach(SettingsViewModel.presetColors, id: \.self) { color in
                    Button { viewModel.strokeColor = color } label: {
                        Circle().fill(color).frame(width: 20, height: 20)
                            .overlay { if colorsAreEqual(viewModel.strokeColor, color) {
                                Circle().stroke(Color.primary, lineWidth: 2) } }
                            .overlay { if color == .white || color == .yellow {
                                Circle().stroke(Color.gray.opacity(0.3), lineWidth: 1) } }
                    }.buttonStyle(.plain)
                }
            }
            ColorPicker("", selection: $viewModel.strokeColor, supportsOpacity: false).labelsHidden().frame(width: 30)
        }
    }
    private func colorsAreEqual(_ lhs: Color, _ rhs: Color) -> Bool {
        let l = NSColor(lhs).usingColorSpace(.sRGB)!
        let r = NSColor(rhs).usingColorSpace(.sRGB)!
        return l.redComponent == r.redComponent && l.greenComponent == r.greenComponent && l.blueComponent == r.blueComponent
    }
}

private struct StrokeWidthSlider: View {
    @Bindable var viewModel: SettingsViewModel
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("线条宽度"); Spacer()
                Text(String(format: "%.1f pt", viewModel.strokeWidth)).foregroundStyle(.secondary).monospacedDigit()
            }
            Slider(value: $viewModel.strokeWidth, in: SettingsViewModel.strokeWidthRange, step: 0.5) {
                Text("线条宽度")
            } minimumValueLabel: { Text("1").font(.caption) } maximumValueLabel: { Text("20").font(.caption) }
        }
    }
}

private struct TextSizeSlider: View {
    @Bindable var viewModel: SettingsViewModel
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("文字大小"); Spacer()
                Text("\(Int(viewModel.textSize)) pt").foregroundStyle(.secondary).monospacedDigit()
            }
            Slider(value: $viewModel.textSize, in: SettingsViewModel.textSizeRange, step: 1) {
                Text("文字大小")
            } minimumValueLabel: { Text("8").font(.caption) } maximumValueLabel: { Text("72").font(.caption) }
        }
    }
}

private struct OCRRecognitionLevelPicker: View {
    @Bindable var viewModel: SettingsViewModel
    var body: some View {
        Picker("识别精度", selection: $viewModel.ocrRecognitionLevel) {
            Text("精确").tag(OCRRecognitionLevel.accurate); Text("快速").tag(OCRRecognitionLevel.fast)
        }
    }
}

private struct OCRLanguagePicker: View {
    @Bindable var viewModel: SettingsViewModel
    var body: some View {
        Picker("语言", selection: $viewModel.ocrLanguage) {
            Text("英文").tag("en-US"); Text("简体中文").tag("zh-Hans")
            Text("繁体中文").tag("zh-Hant"); Text("日文").tag("ja-JP"); Text("韩文").tag("ko-KR")
        }
    }
}
