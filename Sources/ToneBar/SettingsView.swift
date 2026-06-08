import SwiftUI

struct SettingsView: View {

    @ObservedObject var audio: AudioController
    @ObservedObject var prefs = Preferences.shared

    /// Discrete-step options offered in the picker. 0 == continuous.
    private let stepOptions = [0, 2, 3, 4, 5, 6, 11]

    var body: some View {
        Form {
            previewSection
            appearanceSection
            stepsSection
            behaviorSection
            generalSection
        }
        .formStyle(.grouped)
        .frame(width: 430)
        .frame(minHeight: 560)
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
                                .fill(prefs.tint.color ?? Color.accentColor)
                        }
                    VStack(alignment: .leading, spacing: 2) {
                        Text("音条 ToneBar").font(.headline)
                        Text("Lives in your menu bar")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                }

                // Live preview of the actual menu-bar control.
                ZStack {
                    RoundedRectangle(cornerRadius: 11, style: .continuous)
                        .fill(.black.opacity(0.18))
                    MenuSliderView(audio: audio)
                        .fixedSize()
                }
                .frame(height: 38)
            }
            .padding(.vertical, 4)
        }
    }

    // MARK: - Appearance

    private var appearanceSection: some View {
        Section("Appearance") {
            Picker("Icon", selection: $prefs.iconStyle) {
                ForEach(IconStyle.allCases) { style in
                    Text(style.label).tag(style)
                }
            }

            Picker("Accent", selection: $prefs.tint) {
                ForEach(TintChoice.allCases) { choice in
                    HStack {
                        Circle()
                            .fill(choice.color ?? Color.accentColor)
                            .frame(width: 12, height: 12)
                        Text(choice.label)
                    }
                    .tag(choice)
                }
            }

            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text("Slider width")
                    Spacer()
                    Text("\(Int(prefs.sliderWidth)) pt")
                        .foregroundStyle(.secondary)
                        .monospacedDigit()
                }
                Slider(value: $prefs.sliderWidth, in: 60...240, step: 5)
            }

            Toggle("Show percentage", isOn: $prefs.showPercentage)
            Toggle("Glass background", isOn: $prefs.glassBackground)
        }
    }

    // MARK: - Steps

    private var stepsSection: some View {
        Section {
            Picker("Steps", selection: $prefs.steps) {
                ForEach(stepOptions, id: \.self) { value in
                    Text(value == 0 ? "Continuous" : "\(value) steps").tag(value)
                }
            }
            if prefs.steps > 1 {
                Text(stepPreview)
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .monospacedDigit()
            }
        } header: {
            Text("Steps")
        } footer: {
            Text("Snap the slider to fixed levels. “5 steps” gives 0 · 25 · 50 · 75 · 100.")
        }
    }

    private var stepPreview: String {
        let n = prefs.steps
        guard n > 1 else { return "" }
        return (0..<n)
            .map { String(Int((Double($0) / Double(n - 1) * 100).rounded())) }
            .joined(separator: " · ")
    }

    // MARK: - Behavior

    private var behaviorSection: some View {
        Section("Behavior") {
            Toggle("Scroll over the slider to adjust", isOn: $prefs.scrollToAdjust)
        }
    }

    // MARK: - General

    private var generalSection: some View {
        Section("General") {
            Toggle("Launch at login", isOn: $prefs.launchAtLogin)

            HStack {
                Text("Output device")
                Spacer()
                Text(audio.deviceName.isEmpty ? "—" : audio.deviceName)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .truncationMode(.middle)
            }

            HStack {
                Text("Version")
                Spacer()
                Text(appVersion).foregroundStyle(.secondary)
            }

            Button(role: .destructive) {
                NSApp.terminate(nil)
            } label: {
                Text("Quit ToneBar")
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
    private var window: NSWindow?

    init(audio: AudioController) {
        self.audio = audio
    }

    func show() {
        if window == nil {
            let hosting = NSHostingController(rootView: SettingsView(audio: audio))
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
