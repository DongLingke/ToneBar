import SwiftUI

/// The compact control that lives inside the menu bar: a volume slider, plus an
/// optional second slider for screen brightness. Each reads clearly against the
/// translucent menu bar in both light and dark appearances.
struct MenuSliderView: View {

    @ObservedObject var audio: AudioController
    @ObservedObject var brightness: BrightnessController
    @ObservedObject var prefs = Preferences.shared

    /// Tells the status item which slider the scroll wheel should drive.
    var setScrollTarget: (ScrollTarget) -> Void = { _ in }

    var body: some View {
        HStack(spacing: 8) {
            volumeChannel

            if prefs.showBrightness {
                Divider()
                    .frame(height: 13)
                    .opacity(0.45)
                brightnessChannel
            }
        }
        .padding(.horizontal, prefs.glassBackground ? 9 : 4)
        .padding(.vertical, 2)
        .background {
            if prefs.glassBackground {
                Capsule(style: .continuous)
                    .fill(.clear)
                    .glassEffect(.regular, in: .capsule)
            }
        }
        .frame(height: NSStatusBar.system.thickness)
        .fixedSize()
    }

    // MARK: - Volume

    private var volumeChannel: some View {
        HStack(spacing: 7) {
            if let symbol = prefs.iconStyle.symbolName(volume: audio.volume, muted: audio.muted) {
                muteButton(symbol)
            }
            VolumeSliderControl(
                value: Binding(get: { audio.volume }, set: { audio.setVolume($0) }),
                width: prefs.sliderWidth,
                tint: prefs.tint.resolved,
                style: prefs.sliderStyle,
                knobStyle: prefs.knobStyle,
                hideKnobWhenIdle: prefs.hideKnobWhenIdle,
                steps: prefs.steps,
                muted: audio.muted,
                snap: { prefs.snap($0) },
                onHover: { if $0 { setScrollTarget(.volume) } }
            )
            percentage(audio.volume)
        }
    }

    @ViewBuilder
    private func muteButton(_ symbol: String) -> some View {
        Button {
            audio.toggleMute()
        } label: {
            Group {
                if prefs.iconStyle.usesVariableValue && !audio.muted {
                    Image(systemName: symbol, variableValue: max(0.01, audio.volume))
                } else {
                    Image(systemName: symbol)
                }
            }
            .font(.system(size: 13, weight: .semibold))
            .foregroundStyle(audio.muted ? AnyShapeStyle(.secondary) : AnyShapeStyle(.primary))
            .frame(width: 16)
            .contentTransition(.symbolEffect(.replace))
        }
        .buttonStyle(.plain)
        .help(audio.muted ? "取消静音" : "静音")
    }

    // MARK: - Brightness

    private var brightnessChannel: some View {
        HStack(spacing: 7) {
            if prefs.iconStyle != .none {
                Image(systemName: "sun.max.fill", variableValue: max(0.2, brightness.brightness))
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(brightness.available ? AnyShapeStyle(.primary) : AnyShapeStyle(.tertiary))
                    .frame(width: 16)
                    .help("屏幕亮度")
            }
            VolumeSliderControl(
                value: Binding(get: { brightness.brightness }, set: { brightness.setBrightness($0) }),
                width: prefs.sliderWidth,
                tint: prefs.brightnessTint.resolved,
                style: prefs.brightnessSliderStyle,
                knobStyle: prefs.brightnessKnobStyle,
                hideKnobWhenIdle: prefs.hideKnobWhenIdle,
                steps: 0,                      // brightness is continuous
                muted: !brightness.available,
                snap: { $0 },
                onHover: { if $0 { setScrollTarget(.brightness) } }
            )
            percentage(brightness.brightness)
        }
    }

    // MARK: - Shared

    @ViewBuilder
    private func percentage(_ value: Double) -> some View {
        if prefs.showPercentage {
            Text("\(Int((value * 100).rounded()))")
                .font(.system(size: 11, weight: .medium))
                .monospacedDigit()
                .foregroundStyle(.secondary)
                .frame(width: 26, alignment: .trailing)
        }
    }
}
