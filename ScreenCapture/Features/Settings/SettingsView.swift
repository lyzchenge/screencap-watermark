import SwiftUI
import AppKit

/// Main settings view with all preference controls.
/// Organized into sections: General, Export, Keyboard Shortcuts, Annotations, OCR, and Watermark.
struct SettingsView: View {
    @Bindable var viewModel: SettingsViewModel

    var body: some View {
        Form {
            // Permissions Section
            Section {
                PermissionRow(viewModel: viewModel)
            } header: {
                Label("Permissions", systemImage: "lock.shield")
            }

            // General Settings Section
            Section {
                SaveLocationPicker(viewModel: viewModel)
            } header: {
                Label("General", systemImage: "gearshape")
            }

            // Export Settings Section
            Section {
                ExportFormatPicker(viewModel: viewModel)
                if viewModel.defaultFormat == .jpeg {
                    JPEGQualitySlider(viewModel: viewModel)
                } else if viewModel.defaultFormat == .heic {
                    HEICQualitySlider(viewModel: viewModel)
                }
            } header: {
                Label("Export", systemImage: "square.and.arrow.up")
            }

            // Keyboard Shortcuts Section
            Section {
                ShortcutRecorder(
                    label: "Full Screen Capture",
                    shortcut: viewModel.fullScreenShortcut,
                    isRecording: viewModel.isRecordingFullScreenShortcut,
                    onRecord: { viewModel.startRecordingFullScreenShortcut() },
                    onReset: { viewModel.resetFullScreenShortcut() }
                )

                ShortcutRecorder(
                    label: "Selection Capture",
                    shortcut: viewModel.selectionShortcut,
                    isRecording: viewModel.isRecordingSelectionShortcut,
                    onRecord: { viewModel.startRecordingSelectionShortcut() },
                    onReset: { viewModel.resetSelectionShortcut() }
                )
            } header: {
                Label("Keyboard Shortcuts", systemImage: "keyboard")
            }

            // OCR Settings Section
            Section {
                OCRRecognitionLevelPicker(viewModel: viewModel)
                OCRLanguagePicker(viewModel: viewModel)
            } header: {
                Label("OCR", systemImage: "doc.text.viewfinder")
            }

            // Annotation Settings Section
            Section {
                StrokeColorPicker(viewModel: viewModel)
                StrokeWidthSlider(viewModel: viewModel)
                TextSizeSlider(viewModel: viewModel)
            } header: {
                Label("Annotations", systemImage: "pencil.tip.crop.circle")
            }

            // Watermark Settings Section
            Section {
                WatermarkToggle(viewModel: viewModel)

                if viewModel.watermarkEnabled {
                    WatermarkTextField(viewModel: viewModel)
                    WatermarkFontSizeSlider(viewModel: viewModel)
                    WatermarkOpacitySlider(viewModel: viewModel)
                    WatermarkPositionPicker(viewModel: viewModel)
                }
            } header: {
                Label("Watermark", systemImage: "text.word.spacing")
            }

            // Reset Section
            Section {
                Button(role: .destructive) {
                    viewModel.resetAllToDefaults()
                } label: {
                    Label("Reset All to Defaults", systemImage: "arrow.counterclockwise")
                }
                .buttonStyle(.plain)
                .foregroundStyle(.red)
            }
        }
        .formStyle(.grouped)
        .frame(minWidth: 480, minHeight: 550)
        .alert("Error", isPresented: $viewModel.showErrorAlert) {
            Button("OK") {
                viewModel.errorMessage = nil
            }
        } message: {
            if let message = viewModel.errorMessage {
                Text(message)
            }
        }
    }
}

// MARK: - Watermark Toggle

private struct WatermarkToggle: View {
    @Bindable var viewModel: SettingsViewModel

    var body: some View {
        Toggle("Enable Watermark", isOn: $viewModel.watermarkEnabled)
            .accessibilityLabel(Text("Enable watermark on screenshots"))
    }
}

// MARK: - Watermark Text Field

private struct WatermarkTextField: View {
    @Bindable var viewModel: SettingsViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Watermark Text")
                .font(.subheadline)

            TextField("e.g. © 2026 Your Name", text: $viewModel.watermarkText)
                .textFieldStyle(.roundedBorder)
                .accessibilityLabel(Text("Watermark text content"))
        }
    }
}

// MARK: - Watermark Font Size Slider

private struct WatermarkFontSizeSlider: View {
    @Bindable var viewModel: SettingsViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Font Size")
                Spacer()
                Text("\(Int(viewModel.watermarkFontSizePercent))%")
                    .foregroundStyle(.secondary)
                    .monospacedDigit()
            }

            Slider(
                value: $viewModel.watermarkFontSizePercent,
                in: SettingsViewModel.watermarkFontSizeRange,
                step: 0.5
            ) {
                Text("Font Size")
            } minimumValueLabel: {
                Text("1%")
                    .font(.caption)
            } maximumValueLabel: {
                Text("10%")
                    .font(.caption)
            }
            .accessibilityValue(Text("\(Int(viewModel.watermarkFontSizePercent)) percent"))

            Text("Relative to image size")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
}

// MARK: - Watermark Opacity Slider

private struct WatermarkOpacitySlider: View {
    @Bindable var viewModel: SettingsViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Opacity")
                Spacer()
                Text("\(Int(viewModel.watermarkOpacityPercent))%")
                    .foregroundStyle(.secondary)
                    .monospacedDigit()
            }

            Slider(
                value: $viewModel.watermarkOpacityPercent,
                in: SettingsViewModel.watermarkOpacityRange,
                step: 5
            ) {
                Text("Opacity")
            } minimumValueLabel: {
                Text("5%")
                    .font(.caption)
            } maximumValueLabel: {
                Text("100%")
                    .font(.caption)
            }
            .accessibilityValue(Text("\(Int(viewModel.watermarkOpacityPercent)) percent"))
        }
    }
}

// MARK: - Watermark Position Picker

private struct WatermarkPositionPicker: View {
    @Bindable var viewModel: SettingsViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Position")
                .font(.subheadline)

            Picker("Position", selection: $viewModel.watermarkPosition) {
                ForEach(WatermarkPosition.allCases, id: \.self) { pos in
                    Text(pos.displayName).tag(pos)
                }
            }
            .pickerStyle(.segmented)
            .accessibilityLabel(Text("Watermark position"))
        }
    }
}

// MARK: - Permission Row

/// Row showing permission status with action button.
private struct PermissionRow: View {
    @Bindable var viewModel: SettingsViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Screen Recording permission
            PermissionItem(
                icon: "record.circle",
                title: "Screen Recording",
                hint: "Required to capture screenshots",
                isGranted: viewModel.hasScreenRecordingPermission,
                isChecking: viewModel.isCheckingPermissions,
                onGrant: { viewModel.requestScreenRecordingPermission() }
            )

            Divider()

            // Folder Access permission
            PermissionItem(
                icon: "folder",
                title: "Save Location Access",
                hint: "Required to save screenshots to the selected folder",
                isGranted: viewModel.hasFolderAccessPermission,
                isChecking: viewModel.isCheckingPermissions,
                onGrant: { viewModel.requestFolderAccess() }
            )

            HStack {
                Spacer()
                Button {
                    viewModel.checkPermissions()
                } label: {
                    Label("Refresh", systemImage: "arrow.clockwise")
                }
                .buttonStyle(.borderless)
            }
        }
        .onAppear {
            viewModel.checkPermissions()
        }
    }
}

/// Individual permission item row
private struct PermissionItem: View {
    let icon: String
    let title: String
    let hint: String
    let isGranted: Bool
    let isChecking: Bool
    let onGrant: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                HStack(spacing: 8) {
                    Image(systemName: icon)
                        .foregroundStyle(.secondary)
                        .frame(width: 20)
                    Text(title)
                }

                Spacer()

                if isChecking {
                    ProgressView()
                        .controlSize(.small)
                } else {
                    HStack(spacing: 8) {
                        if isGranted {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(.green)
                            Text("Granted")
                                .foregroundStyle(.secondary)
                        } else {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundStyle(.red)

                            Button {
                                onGrant()
                            } label: {
                                Text("Grant Access")
                            }
                            .buttonStyle(.borderedProminent)
                            .controlSize(.small)
                        }
                    }
                }
            }

            if !isGranted && !isChecking {
                Text(hint)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(Text("\(title): \(isGranted ? "Granted" : "Not Granted")"))
    }
}

// MARK: - Save Location Picker

/// Picker for selecting the default save location.
private struct SaveLocationPicker: View {
    @Bindable var viewModel: SettingsViewModel

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Save Location")
                    .font(.headline)
                Text(viewModel.saveLocationPath)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .truncationMode(.middle)
            }

            Spacer()

            Button {
                viewModel.selectSaveLocation()
            } label: {
                Text("Choose...")
            }

            Button {
                viewModel.revealSaveLocation()
            } label: {
                Image(systemName: "folder")
            }
            .help("Show in Finder")
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(Text("Save Location: \(viewModel.saveLocationPath)"))
    }
}

// MARK: - Export Format Picker

/// Picker for selecting the default export format (PNG/JPEG/HEIC).
private struct ExportFormatPicker: View {
    @Bindable var viewModel: SettingsViewModel

    var body: some View {
        Picker("Default Format", selection: $viewModel.defaultFormat) {
            Text("PNG").tag(ExportFormat.png)
            Text("JPEG").tag(ExportFormat.jpeg)
            Text("HEIC").tag(ExportFormat.heic)
        }
        .pickerStyle(.segmented)
        .accessibilityLabel(Text("Export Format"))
    }
}

// MARK: - JPEG Quality Slider

/// Slider for adjusting JPEG compression quality.
private struct JPEGQualitySlider: View {
    @Bindable var viewModel: SettingsViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("JPEG Quality")
                Spacer()
                Text("\(Int(viewModel.jpegQualityPercentage))%")
                    .foregroundStyle(.secondary)
                    .monospacedDigit()
            }

            Slider(
                value: $viewModel.jpegQuality,
                in: SettingsViewModel.jpegQualityRange,
                step: 0.05
            ) {
                Text("JPEG Quality")
            } minimumValueLabel: {
                Text("10%")
                    .font(.caption)
            } maximumValueLabel: {
                Text("100%")
                    .font(.caption)
            }
            .accessibilityValue(Text("\(Int(viewModel.jpegQualityPercentage)) percent"))

            Text("Higher quality results in larger file sizes")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
}

// MARK: - HEIC Quality Slider

/// Slider for adjusting HEIC compression quality.
private struct HEICQualitySlider: View {
    @Bindable var viewModel: SettingsViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("HEIC Quality")
                Spacer()
                Text("\(Int(viewModel.heicQualityPercentage))%")
                    .foregroundStyle(.secondary)
                    .monospacedDigit()
            }

            Slider(
                value: $viewModel.heicQuality,
                in: SettingsViewModel.heicQualityRange,
                step: 0.05
            ) {
                Text("HEIC Quality")
            } minimumValueLabel: {
                Text("10%")
                    .font(.caption)
            } maximumValueLabel: {
                Text("100%")
                    .font(.caption)
            }
            .accessibilityValue(Text("\(Int(viewModel.heicQualityPercentage)) percent"))

            Text("HEIC offers better compression than JPEG at similar quality")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
}

// MARK: - Shortcut Recorder

/// A control for recording keyboard shortcuts.
private struct ShortcutRecorder: View {
    let label: String
    let shortcut: KeyboardShortcut
    let isRecording: Bool
    let onRecord: () -> Void
    let onReset: () -> Void

    var body: some View {
        HStack {
            Text(label)

            Spacer()

            if isRecording {
                Text("Press keys...")
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.accentColor.opacity(0.2))
                    .clipShape(RoundedRectangle(cornerRadius: 6))
            } else {
                Button {
                    onRecord()
                } label: {
                    Text(shortcut.displayString)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.secondary.opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                }
                .buttonStyle(.plain)
            }

            Button {
                onReset()
            } label: {
                Image(systemName: "arrow.counterclockwise")
            }
            .buttonStyle(.borderless)
            .help("Reset to default")
            .disabled(isRecording)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(Text("\(label): \(shortcut.displayString)"))
    }
}

// MARK: - Stroke Color Picker

/// Color picker for annotation stroke color.
private struct StrokeColorPicker: View {
    @Bindable var viewModel: SettingsViewModel

    var body: some View {
        HStack {
            Text("Stroke Color")

            Spacer()

            // Preset color buttons
            HStack(spacing: 4) {
                ForEach(SettingsViewModel.presetColors, id: \.self) { color in
                    Button {
                        viewModel.strokeColor = color
                    } label: {
                        Circle()
                            .fill(color)
                            .frame(width: 20, height: 20)
                            .overlay {
                                if colorsAreEqual(viewModel.strokeColor, color) {
                                    Circle()
                                        .stroke(Color.primary, lineWidth: 2)
                                }
                            }
                            .overlay {
                                // Add border for light colors
                                if color == .white || color == .yellow {
                                    Circle()
                                        .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                                }
                            }
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(Text(colorName(for: color)))
                }
            }

            // Custom color picker
            ColorPicker("", selection: $viewModel.strokeColor, supportsOpacity: false)
                .labelsHidden()
                .frame(width: 30)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(Text("Stroke Color"))
    }

    /// Compare colors approximately
    private func colorsAreEqual(_ lhs: Color, _ rhs: Color) -> Bool {
        let lhsResolved = lhs.resolve(in: .init())
        let rhsResolved = rhs.resolve(in: .init())
        return lhsResolved.red == rhsResolved.red &&
               lhsResolved.green == rhsResolved.green &&
               lhsResolved.blue == rhsResolved.blue
    }

    /// Returns a human-readable name for a color
    private func colorName(for color: Color) -> String {
        switch color {
        case .red: return "Red"
        case .orange: return "Orange"
        case .yellow: return "Yellow"
        case .green: return "Green"
        case .blue: return "Blue"
        case .purple: return "Purple"
        case .pink: return "Pink"
        case .white: return "White"
        case .black: return "Black"
        default: return "Color"
        }
    }
}

// MARK: - Stroke Width Slider

/// Slider for adjusting annotation stroke width.
private struct StrokeWidthSlider: View {
    @Bindable var viewModel: SettingsViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Stroke Width")
                Spacer()
                Text(String(format: "%.1f pt", viewModel.strokeWidth))
                    .foregroundStyle(.secondary)
                    .monospacedDigit()
            }

            Slider(
                value: $viewModel.strokeWidth,
                in: SettingsViewModel.strokeWidthRange,
                step: 0.5
            ) {
                Text("Stroke Width")
            } minimumValueLabel: {
                Text("1")
                    .font(.caption)
            } maximumValueLabel: {
                Text("20")
                    .font(.caption)
            }
            .accessibilityValue(Text(String(format: "%.1f points", viewModel.strokeWidth)))
        }
    }
}

// MARK: - Text Size Slider

/// Slider for adjusting text annotation font size.
private struct TextSizeSlider: View {
    @Bindable var viewModel: SettingsViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Text Size")
                Spacer()
                Text("\(Int(viewModel.textSize)) pt")
                    .foregroundStyle(.secondary)
                    .monospacedDigit()
            }

            Slider(
                value: $viewModel.textSize,
                in: SettingsViewModel.textSizeRange,
                step: 1
            ) {
                Text("Text Size")
            } minimumValueLabel: {
                Text("8")
                    .font(.caption)
            } maximumValueLabel: {
                Text("72")
                    .font(.caption)
            }
            .accessibilityValue(Text("\(Int(viewModel.textSize)) points"))
        }
    }
}

// MARK: - OCR Pickers (placeholder - need to use actual pickers from original)

private struct OCRRecognitionLevelPicker: View {
    @Bindable var viewModel: SettingsViewModel

    var body: some View {
        Picker("Recognition Level", selection: $viewModel.ocrRecognitionLevel) {
            Text("Accurate").tag(OCRRecognitionLevel.accurate)
            Text("Fast").tag(OCRRecognitionLevel.fast)
        }
        .accessibilityLabel(Text("OCR Recognition Level"))
    }
}

private struct OCRLanguagePicker: View {
    @Bindable var viewModel: SettingsViewModel

    var body: some View {
        Picker("Language", selection: $viewModel.ocrLanguage) {
            Text("English").tag("en-US")
            Text("Chinese (Simplified)").tag("zh-Hans")
            Text("Chinese (Traditional)").tag("zh-Hant")
            Text("Japanese").tag("ja-JP")
            Text("Korean").tag("ko-KR")
        }
        .accessibilityLabel(Text("OCR Language"))
    }
}
