import SwiftUI

struct SettingsView: View {

    @ObservedObject var audio: AudioController
    @ObservedObject var brightness: BrightnessController
    @ObservedObject var prefs = Preferences.shared

    var body: some View {
        Form {
            previewSection
            channelSection
            generalSection
        }
        .formStyle(.grouped)
        .frame(width: 700)
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

    // MARK: - Channel cards

    private var channelSection: some View {
        Section("控件") {
            HStack(alignment: .top, spacing: 14) {
                ChannelCard(title: "音量", systemImage: "speaker.wave.2.fill", isVolume: true)
                ChannelCard(title: "亮度", systemImage: "sun.max.fill", isVolume: false,
                            available: brightness.available)
            }
            .padding(.vertical, 2)

            if prefs.showVolume && prefs.showBrightness {
                Picker("两条排列", selection: $prefs.sliderLayout) {
                    ForEach(SliderLayout.allCases) { Text($0.label).tag($0) }
                }
            }
        }
    }

    // MARK: - General (merged)

    private var generalSection: some View {
        Section("通用") {
            Picker("图标样式", selection: $prefs.iconStyle) {
                ForEach(IconStyle.allCases) { Text($0.label).tag($0) }
            }
            Picker("百分比样式", selection: $prefs.percentStyle) {
                ForEach(PercentStyle.allCases) { Text($0.label).tag($0) }
            }
            Toggle("玻璃背景", isOn: $prefs.glassBackground)
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

// MARK: - Channel card

/// A self-contained settings card for one channel (volume or brightness).
/// Only shows the rows relevant to the chosen control type.
struct ChannelCard: View {

    let title: String
    let systemImage: String
    let isVolume: Bool
    var available: Bool = true

    @ObservedObject var prefs = Preferences.shared

    // Per-channel bindings
    private var enabled: Binding<Bool> { isVolume ? $prefs.showVolume : $prefs.showBrightness }
    private var control: Binding<ControlStyle> { isVolume ? $prefs.volumeControl : $prefs.brightnessControl }
    private var dialStyle: Binding<DialStyle> { isVolume ? $prefs.volumeDialStyle : $prefs.brightnessDialStyle }
    private var tint: Binding<TintChoice> { isVolume ? $prefs.tint : $prefs.brightnessTint }
    private var sliderStyle: Binding<SliderStyle> { isVolume ? $prefs.sliderStyle : $prefs.brightnessSliderStyle }
    private var knobStyle: Binding<KnobStyle> { isVolume ? $prefs.knobStyle : $prefs.brightnessKnobStyle }
    private var hideKnob: Binding<Bool> { isVolume ? $prefs.hideKnobWhenIdle : $prefs.brightnessHideKnobWhenIdle }
    private var width: Binding<Double> { isVolume ? $prefs.sliderWidth : $prefs.brightnessSliderWidth }
    private var steps: Binding<Int> { isVolume ? $prefs.steps : $prefs.brightnessSteps }
    private var scrollSpeed: Binding<Double> { isVolume ? $prefs.volumeScrollSpeed : $prefs.brightnessScrollSpeed }
    private var invert: Binding<Bool> { isVolume ? $prefs.invertVolumeScroll : $prefs.invertBrightnessScroll }

    private var isBar: Bool { control.wrappedValue == .bar }
    private var isDial: Bool { control.wrappedValue == .dial }
    private var hasKnob: Bool { isBar && sliderStyle.wrappedValue != .system }

    var body: some View {
        VStack(alignment: .leading, spacing: 9) {
            HStack(spacing: 6) {
                Image(systemName: systemImage)
                Text(title).font(.headline)
                Spacer()
                Toggle("", isOn: enabled).labelsHidden().controlSize(.small)
            }
            .foregroundStyle(enabled.wrappedValue ? AnyShapeStyle(.primary) : AnyShapeStyle(.secondary))

            if enabled.wrappedValue {
                    Divider()
                    row("控件") {
                        Picker("", selection: control) {
                            ForEach(ControlStyle.allCases) { Text($0.label).tag($0) }
                        }
                        .labelsHidden().pickerStyle(.segmented).fixedSize()
                    }
                    row("强调色") { menuPicker(tint, TintChoice.allCases) { tintLabel($0) } }

                    if isDial {
                        row("旋钮设计") { menuPicker(dialStyle, DialStyle.allCases) { Text($0.label) } }
                    }
                    if isBar {
                        row("滑条样式") { menuPicker(sliderStyle, SliderStyle.allCases) { Text($0.label) } }
                        if sliderStyle.wrappedValue != .system {
                            row("滑块旋钮") { menuPicker(knobStyle, KnobStyle.allCases) { Text($0.label) } }
                            if knobStyle.wrappedValue != .none {
                                row("仅悬停显示旋钮") { Toggle("", isOn: hideKnob).labelsHidden() }
                            }
                        }
                        row("宽度") { widthSlider(width) }
                    }

                    row("吸附档位") { stepsPicker(steps) }
                    row("滚动速度") { speedSlider(scrollSpeed) }
                    if scrollSpeed.wrappedValue > 0 {
                        row("反转滚动") { Toggle("", isOn: invert).labelsHidden() }
                    }

                    if !available {
                        Label("无可调亮度的内置屏", systemImage: "exclamationmark.triangle")
                            .font(.caption).foregroundStyle(.secondary)
                    }
            } else {
                Text("已关闭")
                    .font(.callout).foregroundStyle(.tertiary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.vertical, 6)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color.primary.opacity(0.05))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .strokeBorder(Color.primary.opacity(0.08), lineWidth: 1)
        )
    }

    // MARK: - Row + control builders

    private func row<V: View>(_ label: String, @ViewBuilder _ content: () -> V) -> some View {
        HStack {
            Text(label).foregroundStyle(.secondary)
            Spacer(minLength: 8)
            content()
        }
    }

    private func menuPicker<T: Hashable & Identifiable, L: View>(
        _ sel: Binding<T>, _ all: [T], @ViewBuilder _ label: @escaping (T) -> L
    ) -> some View {
        Picker("", selection: sel) {
            ForEach(all) { label($0).tag($0) }
        }
        .labelsHidden().pickerStyle(.menu).fixedSize()
    }

    private func tintLabel(_ choice: TintChoice) -> some View {
        HStack {
            Circle().fill(choice.resolved).frame(width: 11, height: 11)
            Text(choice.label)
        }
    }

    private func stepsPicker(_ sel: Binding<Int>) -> some View {
        Picker("", selection: sel) {
            Text("连续").tag(0)
            ForEach(Array(Preferences.stepRange), id: \.self) { Text("\($0) 档").tag($0) }
        }
        .labelsHidden().pickerStyle(.menu).fixedSize()
    }

    private func speedSlider(_ value: Binding<Double>) -> some View {
        HStack(spacing: 6) {
            Slider(value: value, in: 0...4, step: 0.25).frame(width: 110)
            Text(value.wrappedValue == 0 ? "关" : String(format: "%.2g×", value.wrappedValue))
                .font(.caption).foregroundStyle(.secondary).monospacedDigit()
                .frame(width: 28, alignment: .trailing)
        }
    }

    private func widthSlider(_ value: Binding<Double>) -> some View {
        HStack(spacing: 6) {
            Slider(value: value, in: 60...240, step: 5).frame(width: 110)
            Text("\(Int(value.wrappedValue))")
                .font(.caption).foregroundStyle(.secondary).monospacedDigit()
                .frame(width: 28, alignment: .trailing)
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
