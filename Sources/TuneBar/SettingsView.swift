import SwiftUI

struct SettingsView: View {

    @ObservedObject var audio: AudioController
    @ObservedObject var brightness: BrightnessController
    @ObservedObject var prefs = Preferences.shared

    private var briOn: Bool { prefs.showBrightness }

    var body: some View {
        Form {
            previewSection
            channelSection
            stepsSection
            generalAppearanceSection
            behaviorSection
            generalSection
        }
        .formStyle(.grouped)
        .frame(width: 660)
        .frame(minHeight: 640)
        .scrollContentBackground(.hidden)
        .background(.ultraThinMaterial)
        .tint(prefs.tint.color)
    }

    // MARK: - Preview

    private var previewSection: some View {
        Section {
            VStack(spacing: 14) {
                HStack(spacing: 12) {
                    Image(systemName: "dial.medium.fill")
                        .font(.system(size: 22, weight: .semibold))
                        .foregroundStyle(.white)
                        .frame(width: 52, height: 52)
                        .background {
                            RoundedRectangle(cornerRadius: 13, style: .continuous)
                                .fill(prefs.tint.resolved)
                        }
                    VStack(alignment: .leading, spacing: 2) {
                        Text("调条 TuneBar").font(.headline)
                        Text("菜单栏里的音量 / 亮度控制条")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                }

                ZStack {
                    RoundedRectangle(cornerRadius: 11, style: .continuous)
                        .fill(.black.opacity(0.18))
                    MenuSliderView(audio: audio, brightness: brightness)
                        .fixedSize()
                }
                .frame(height: 38)
            }
            .padding(.vertical, 4)
        }
    }

    // MARK: - Two-column channel settings

    private var channelSection: some View {
        Section {
            Toggle("显示屏幕亮度（第二条）", isOn: $prefs.showBrightness)
            if briOn {
                Picker("两条排列", selection: $prefs.sliderLayout) {
                    ForEach(SliderLayout.allCases) { Text($0.label).tag($0) }
                }
            }

            ChannelGrid()

            if briOn && !brightness.available {
                Label("当前没有可调节亮度的内置显示器", systemImage: "exclamationmark.triangle")
                    .font(.callout).foregroundStyle(.secondary)
            }
        } header: {
            Text("控件 · 音量与亮度")
        } footer: {
            Text("左列为音量、右列为亮度，可分别设置。选「旋钮」时该列不再显示滑条样式、滑块旋钮、宽度等选项。")
        }
    }

    // MARK: - Steps (volume only)

    private var snapEnabled: Binding<Bool> {
        Binding(
            get: { prefs.steps >= Preferences.stepRange.lowerBound },
            set: { on in prefs.steps = on ? max(Preferences.stepRange.lowerBound, prefs.steps) : 0 }
        )
    }

    private var stepCount: Binding<Int> {
        Binding(
            get: { max(Preferences.stepRange.lowerBound, prefs.steps) },
            set: { prefs.steps = min(Preferences.stepRange.upperBound,
                                     max(Preferences.stepRange.lowerBound, $0)) }
        )
    }

    private var stepsSection: some View {
        Section {
            Toggle("音量吸附到固定档位", isOn: snapEnabled)
            if prefs.steps >= Preferences.stepRange.lowerBound {
                Stepper(value: stepCount, in: Preferences.stepRange) {
                    HStack {
                        Text("档位数量")
                        Spacer()
                        Text("\(prefs.steps) 档").foregroundStyle(.secondary).monospacedDigit()
                    }
                }
                Text(stepPreview)
                    .font(.callout).foregroundStyle(.secondary).monospacedDigit().lineLimit(2)
            }
        } header: {
            Text("音量档位")
        } footer: {
            Text("仅作用于音量。可设 5–20 档，例如 5 档为 0 · 25 · 50 · 75 · 100。亮度始终连续。")
        }
    }

    private var stepPreview: String {
        let n = prefs.steps
        guard n > 1 else { return "" }
        return (0..<n)
            .map { String(Int((Double($0) / Double(n - 1) * 100).rounded())) }
            .joined(separator: " · ")
    }

    // MARK: - General appearance (shared)

    private var generalAppearanceSection: some View {
        Section("通用外观") {
            Picker("图标样式", selection: $prefs.iconStyle) {
                ForEach(IconStyle.allCases) { Text($0.label).tag($0) }
            }
            Toggle("显示百分比", isOn: $prefs.showPercentage)
            Toggle("玻璃背景", isOn: $prefs.glassBackground)
        }
    }

    // MARK: - Behavior

    private var behaviorSection: some View {
        Section {
            Toggle("在控件上滚动以调节", isOn: $prefs.scrollToAdjust)
            Toggle("反转滚动方向", isOn: $prefs.invertScroll)
                .disabled(!prefs.scrollToAdjust)
        } header: {
            Text("行为")
        } footer: {
            Text("反转后，向上滚动为减小、向下滚动为增大。")
        }
    }

    // MARK: - General

    private var generalSection: some View {
        Section("通用") {
            Toggle("开机启动", isOn: $prefs.launchAtLogin)

            HStack {
                Text("输出设备")
                Spacer()
                Text(audio.deviceName.isEmpty ? "—" : audio.deviceName)
                    .foregroundStyle(.secondary).lineLimit(1).truncationMode(.middle)
            }
            HStack {
                Text("版本")
                Spacer()
                Text(appVersion).foregroundStyle(.secondary)
            }
            Button(role: .destructive) {
                NSApp.terminate(nil)
            } label: {
                Text("退出 调条 TuneBar")
            }
        }
    }

    private var appVersion: String {
        let v = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        return "v\(v)"
    }
}

// MARK: - Channel comparison grid

/// Two-column (volume | brightness) grid of per-channel controls. Slider-only
/// rows disappear for a channel that's set to a dial.
struct ChannelGrid: View {

    @ObservedObject var prefs = Preferences.shared

    private var volBar: Bool { prefs.volumeControl == .bar }
    private var briBar: Bool { prefs.brightnessControl == .bar }
    private var briOn: Bool { prefs.showBrightness }
    private var volKnobRow: Bool { volBar && prefs.sliderStyle != .system }
    private var briKnobRow: Bool { briOn && briBar && prefs.brightnessSliderStyle != .system }

    var body: some View {
        Grid(alignment: .leading, horizontalSpacing: 18, verticalSpacing: 12) {
            GridRow {
                Color.clear.frame(width: 1, height: 1)
                Label("音量", systemImage: "speaker.wave.2.fill")
                    .font(.headline).gridColumnAlignment(.leading)
                Label("亮度", systemImage: "sun.max.fill")
                    .font(.headline).gridColumnAlignment(.leading)
                    .foregroundStyle(briOn ? AnyShapeStyle(.primary) : AnyShapeStyle(.tertiary))
            }
            Divider().gridCellColumns(3)

            GridRow {
                rowLabel("控件")
                controlPicker($prefs.volumeControl)
                cell(briOn) { controlPicker($prefs.brightnessControl) }
            }

            GridRow {
                rowLabel("强调色")
                tintPicker($prefs.tint)
                cell(briOn) { tintPicker($prefs.brightnessTint) }
            }

            if volBar || (briOn && briBar) {
                GridRow {
                    rowLabel("滑条样式")
                    cell(volBar) { sliderStylePicker($prefs.sliderStyle) }
                    cell(briOn && briBar) { sliderStylePicker($prefs.brightnessSliderStyle) }
                }
            }

            if volKnobRow || briKnobRow {
                GridRow {
                    rowLabel("滑块旋钮")
                    cell(volKnobRow) { knobPicker($prefs.knobStyle) }
                    cell(briKnobRow) { knobPicker($prefs.brightnessKnobStyle) }
                }
            }

            if (volKnobRow && prefs.knobStyle != .none) || (briKnobRow && prefs.brightnessKnobStyle != .none) {
                GridRow {
                    rowLabel("仅悬停显示旋钮")
                    cell(volKnobRow && prefs.knobStyle != .none) {
                        Toggle("", isOn: $prefs.hideKnobWhenIdle).labelsHidden()
                    }
                    cell(briKnobRow && prefs.brightnessKnobStyle != .none) {
                        Toggle("", isOn: $prefs.brightnessHideKnobWhenIdle).labelsHidden()
                    }
                }
            }

            if volBar || (briOn && briBar) {
                GridRow {
                    rowLabel("滑条宽度")
                    cell(volBar) { widthSlider($prefs.sliderWidth) }
                    cell(briOn && briBar) { widthSlider($prefs.brightnessSliderWidth) }
                }
            }
        }
        .padding(.vertical, 2)
    }

    private func rowLabel(_ text: String) -> some View {
        Text(text).foregroundStyle(.secondary).gridColumnAlignment(.leading)
    }

    @ViewBuilder
    private func cell<V: View>(_ active: Bool, @ViewBuilder _ content: () -> V) -> some View {
        if active { content() } else { Text("—").foregroundStyle(.tertiary) }
    }

    private func controlPicker(_ sel: Binding<ControlStyle>) -> some View {
        Picker("", selection: sel) { ForEach(ControlStyle.allCases) { Text($0.label).tag($0) } }
            .labelsHidden().pickerStyle(.menu).fixedSize()
    }
    private func sliderStylePicker(_ sel: Binding<SliderStyle>) -> some View {
        Picker("", selection: sel) { ForEach(SliderStyle.allCases) { Text($0.label).tag($0) } }
            .labelsHidden().pickerStyle(.menu).fixedSize()
    }
    private func knobPicker(_ sel: Binding<KnobStyle>) -> some View {
        Picker("", selection: sel) { ForEach(KnobStyle.allCases) { Text($0.label).tag($0) } }
            .labelsHidden().pickerStyle(.menu).fixedSize()
    }
    private func tintPicker(_ sel: Binding<TintChoice>) -> some View {
        Picker("", selection: sel) {
            ForEach(TintChoice.allCases) { choice in
                HStack {
                    Circle().fill(choice.resolved).frame(width: 11, height: 11)
                    Text(choice.label)
                }.tag(choice)
            }
        }
        .labelsHidden().pickerStyle(.menu).fixedSize()
    }
    private func widthSlider(_ value: Binding<Double>) -> some View {
        VStack(alignment: .leading, spacing: 1) {
            Slider(value: value, in: 60...240, step: 5).frame(width: 150)
            Text("\(Int(value.wrappedValue)) pt")
                .font(.caption).foregroundStyle(.secondary).monospacedDigit()
        }
    }
}

// MARK: - Window controller

/// Lazily-created settings window hosting `SettingsView`.
final class SettingsWindowController {

    private let audio: AudioController
    private let brightness: BrightnessController
    private var window: NSWindow?

    init(audio: AudioController, brightness: BrightnessController) {
        self.audio = audio
        self.brightness = brightness
    }

    func show() {
        if window == nil {
            let hosting = NSHostingController(rootView: SettingsView(audio: audio, brightness: brightness))
            let win = NSWindow(contentViewController: hosting)
            win.title = "调条 TuneBar"
            win.styleMask = [.titled, .closable, .fullSizeContentView]
            win.titlebarAppearsTransparent = true
            win.isMovableByWindowBackground = true
            win.isReleasedWhenClosed = false
            win.center()
            window = win
        }
        window?.makeKeyAndOrderFront(nil)
    }
}
