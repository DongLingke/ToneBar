import SwiftUI

struct SettingsView: View {

    @ObservedObject var audio: AudioController
    @ObservedObject var brightness: BrightnessController
    @ObservedObject var prefs = Preferences.shared

    var body: some View {
        Form {
            previewSection
            channelSection
            generalAppearanceSection
            generalSection
        }
        .formStyle(.grouped)
        .frame(width: 680)
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
            ChannelGrid()

            if prefs.showVolume && prefs.showBrightness {
                Picker("两条排列", selection: $prefs.sliderLayout) {
                    ForEach(SliderLayout.allCases) { Text($0.label).tag($0) }
                }
            }
            if prefs.showBrightness && !brightness.available {
                Label("当前没有可调节亮度的内置显示器", systemImage: "exclamationmark.triangle")
                    .font(.callout).foregroundStyle(.secondary)
            }
        } header: {
            Text("控件 · 音量与亮度")
        } footer: {
            Text("左列音量、右列亮度，分别设置。选「旋钮」时该列不再显示滑条样式、宽度等选项。档位 5–20，例如 5 档为 0·25·50·75·100。")
        }
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

    private var volOn: Bool { prefs.showVolume }
    private var briOn: Bool { prefs.showBrightness }
    private var volBar: Bool { volOn && prefs.volumeControl == .bar }
    private var briBar: Bool { briOn && prefs.brightnessControl == .bar }
    private var volDial: Bool { volOn && prefs.volumeControl == .dial }
    private var briDial: Bool { briOn && prefs.brightnessControl == .dial }
    private var volKnobRow: Bool { volBar && prefs.sliderStyle != .system }
    private var briKnobRow: Bool { briBar && prefs.brightnessSliderStyle != .system }

    var body: some View {
        Grid(alignment: .leading, horizontalSpacing: 18, verticalSpacing: 12) {
            GridRow {
                Color.clear.frame(width: 1, height: 1)
                Label("音量", systemImage: "speaker.wave.2.fill")
                    .font(.headline).gridColumnAlignment(.leading)
                    .foregroundStyle(volOn ? AnyShapeStyle(.primary) : AnyShapeStyle(.tertiary))
                Label("亮度", systemImage: "sun.max.fill")
                    .font(.headline).gridColumnAlignment(.leading)
                    .foregroundStyle(briOn ? AnyShapeStyle(.primary) : AnyShapeStyle(.tertiary))
            }
            Divider().gridCellColumns(3)

            // Enable — always interactive
            GridRow {
                rowLabel("启用")
                Toggle("", isOn: $prefs.showVolume).labelsHidden()
                Toggle("", isOn: $prefs.showBrightness).labelsHidden()
            }

            GridRow {
                rowLabel("控件")
                cell(volOn) { controlPicker($prefs.volumeControl) }
                cell(briOn) { controlPicker($prefs.brightnessControl) }
            }

            GridRow {
                rowLabel("强调色")
                cell(volOn) { tintPicker($prefs.tint) }
                cell(briOn) { tintPicker($prefs.brightnessTint) }
            }

            if volDial || briDial {
                GridRow {
                    rowLabel("旋钮设计")
                    cell(volDial) { dialStylePicker($prefs.volumeDialStyle) }
                    cell(briDial) { dialStylePicker($prefs.brightnessDialStyle) }
                }
            }

            if volBar || briBar {
                GridRow {
                    rowLabel("滑条样式")
                    cell(volBar) { sliderStylePicker($prefs.sliderStyle) }
                    cell(briBar) { sliderStylePicker($prefs.brightnessSliderStyle) }
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

            if volBar || briBar {
                GridRow {
                    rowLabel("滑条宽度")
                    cell(volBar) { widthSlider($prefs.sliderWidth) }
                    cell(briBar) { widthSlider($prefs.brightnessSliderWidth) }
                }
            }

            if volOn || briOn {
                GridRow {
                    rowLabel("吸附档位")
                    cell(volOn) { stepsPicker($prefs.steps) }
                    cell(briOn) { stepsPicker($prefs.brightnessSteps) }
                }
                GridRow {
                    rowLabel("滚动调节")
                    cell(volOn) { Toggle("", isOn: $prefs.volumeScroll).labelsHidden() }
                    cell(briOn) { Toggle("", isOn: $prefs.brightnessScroll).labelsHidden() }
                }
                GridRow {
                    rowLabel("反转滚动")
                    cell(volOn && prefs.volumeScroll) {
                        Toggle("", isOn: $prefs.invertVolumeScroll).labelsHidden()
                    }
                    cell(briOn && prefs.brightnessScroll) {
                        Toggle("", isOn: $prefs.invertBrightnessScroll).labelsHidden()
                    }
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
            .labelsHidden().pickerStyle(.segmented).fixedSize()
    }
    private func dialStylePicker(_ sel: Binding<DialStyle>) -> some View {
        Picker("", selection: sel) { ForEach(DialStyle.allCases) { Text($0.label).tag($0) } }
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
    private func stepsPicker(_ sel: Binding<Int>) -> some View {
        Picker("", selection: sel) {
            Text("连续").tag(0)
            ForEach(Array(Preferences.stepRange), id: \.self) { Text("\($0) 档").tag($0) }
        }
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
