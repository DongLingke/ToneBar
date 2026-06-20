import SwiftUI

struct SettingsView: View {

    @ObservedObject var audio: AudioController
    @ObservedObject var brightness: BrightnessController
    @ObservedObject var prefs = Preferences.shared

    var body: some View {
        Form {
            previewSection
            appearanceSection
            stepsSection
            brightnessSection
            behaviorSection
            generalSection
        }
        .formStyle(.grouped)
        .frame(width: 440)
        .frame(minHeight: 600)
        .scrollContentBackground(.hidden)
        .background(.ultraThinMaterial)
        .tint(prefs.tint.color)
    }

    // MARK: - Preview

    private var previewSection: some View {
        Section {
            VStack(spacing: 14) {
                HStack(spacing: 12) {
                    Image(systemName: "speaker.wave.2.fill")
                        .font(.system(size: 22, weight: .semibold))
                        .foregroundStyle(.white)
                        .frame(width: 52, height: 52)
                        .background {
                            RoundedRectangle(cornerRadius: 13, style: .continuous)
                                .fill(prefs.tint.resolved)
                        }
                    VStack(alignment: .leading, spacing: 2) {
                        Text("音条 ToneBar").font(.headline)
                        Text("常驻菜单栏的音量滑条")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                }

                // Live preview of the actual menu-bar control.
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

    // MARK: - Appearance

    private var appearanceSection: some View {
        Section("外观") {
            Picker("图标样式", selection: $prefs.iconStyle) {
                ForEach(IconStyle.allCases) { style in
                    Text(style.label).tag(style)
                }
            }

            Picker("音量控件", selection: $prefs.volumeControl) {
                ForEach(ControlStyle.allCases) { style in
                    Text(style.label).tag(style)
                }
            }

            Picker("滑条样式", selection: $prefs.sliderStyle) {
                ForEach(SliderStyle.allCases) { style in
                    Text(style.label).tag(style)
                }
            }
            .disabled(prefs.volumeControl != .bar)

            Picker("滑块旋钮样式", selection: $prefs.knobStyle) {
                ForEach(KnobStyle.allCases) { style in
                    Text(style.label).tag(style)
                }
            }
            .disabled(prefs.volumeControl != .bar || prefs.sliderStyle == .system)

            Toggle("仅在悬停时显示旋钮", isOn: $prefs.hideKnobWhenIdle)
                .disabled(prefs.volumeControl != .bar || prefs.sliderStyle == .system || prefs.knobStyle == .none)

            Picker("强调色", selection: $prefs.tint) {
                ForEach(TintChoice.allCases) { choice in
                    HStack {
                        Circle()
                            .fill(choice.resolved)
                            .frame(width: 12, height: 12)
                        Text(choice.label)
                    }
                    .tag(choice)
                }
            }

            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text("滑条宽度")
                    Spacer()
                    Text("\(Int(prefs.sliderWidth)) pt")
                        .foregroundStyle(.secondary)
                        .monospacedDigit()
                }
                Slider(value: $prefs.sliderWidth, in: 60...240, step: 5)
            }

            Toggle("显示百分比", isOn: $prefs.showPercentage)
            Toggle("玻璃背景", isOn: $prefs.glassBackground)
        }
    }

    // MARK: - Steps

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
            Toggle("吸附到固定档位", isOn: snapEnabled)

            if prefs.steps >= Preferences.stepRange.lowerBound {
                Stepper(value: stepCount, in: Preferences.stepRange) {
                    HStack {
                        Text("档位数量")
                        Spacer()
                        Text("\(prefs.steps) 档")
                            .foregroundStyle(.secondary)
                            .monospacedDigit()
                    }
                }
                Text(stepPreview)
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .monospacedDigit()
                    .lineLimit(2)
            }
        } header: {
            Text("档位")
        } footer: {
            Text("开启后滑条会吸附到固定音量级别，可设 5–20 档。例如 5 档为 0 · 25 · 50 · 75 · 100。")
        }
    }

    private var stepPreview: String {
        let n = prefs.steps
        guard n > 1 else { return "" }
        return (0..<n)
            .map { String(Int((Double($0) / Double(n - 1) * 100).rounded())) }
            .joined(separator: " · ")
    }

    // MARK: - Brightness

    private var brightnessSection: some View {
        Section {
            Toggle("显示屏幕亮度滑条", isOn: $prefs.showBrightness)

            if prefs.showBrightness {
                Picker("两条排列", selection: $prefs.sliderLayout) {
                    ForEach(SliderLayout.allCases) { layout in
                        Text(layout.label).tag(layout)
                    }
                }

                Picker("亮度控件", selection: $prefs.brightnessControl) {
                    ForEach(ControlStyle.allCases) { style in
                        Text(style.label).tag(style)
                    }
                }

                Picker("亮度滑条样式", selection: $prefs.brightnessSliderStyle) {
                    ForEach(SliderStyle.allCases) { style in
                        Text(style.label).tag(style)
                    }
                }
                .disabled(prefs.brightnessControl != .bar)
                Picker("亮度滑块旋钮样式", selection: $prefs.brightnessKnobStyle) {
                    ForEach(KnobStyle.allCases) { style in
                        Text(style.label).tag(style)
                    }
                }
                .disabled(prefs.brightnessControl != .bar || prefs.brightnessSliderStyle == .system)
                Picker("亮度强调色", selection: $prefs.brightnessTint) {
                    ForEach(TintChoice.allCases) { choice in
                        HStack {
                            Circle().fill(choice.resolved).frame(width: 12, height: 12)
                            Text(choice.label)
                        }
                        .tag(choice)
                    }
                }

                if !brightness.available {
                    Label("当前没有可调节亮度的内置显示器", systemImage: "exclamationmark.triangle")
                        .font(.callout)
                        .foregroundStyle(.secondary)
                }
            }
        } header: {
            Text("亮度")
        } footer: {
            Text("在音量滑条旁再显示一个屏幕亮度滑条，可单独设置样式。仅支持内置显示器。")
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
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .truncationMode(.middle)
            }

            HStack {
                Text("版本")
                Spacer()
                Text(appVersion).foregroundStyle(.secondary)
            }

            Button(role: .destructive) {
                NSApp.terminate(nil)
            } label: {
                Text("退出 音条 ToneBar")
            }
        }
    }

    private var appVersion: String {
        let v = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        return "v\(v)"
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
            win.title = "音条 ToneBar"
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
