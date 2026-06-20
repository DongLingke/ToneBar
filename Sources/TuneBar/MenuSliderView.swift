import SwiftUI

/// The compact control that lives in the menu bar: a volume control plus an
/// optional brightness control. Each can be a horizontal slider or a rotary
/// dial, and the pair can sit side-by-side or stacked.
struct MenuSliderView: View {

    @ObservedObject var audio: AudioController
    @ObservedObject var brightness: BrightnessController
    @ObservedObject var prefs = Preferences.shared

    /// Tells the status item which control the scroll wheel should drive.
    var setScrollTarget: (ScrollTarget) -> Void = { _ in }

    private var stacked: Bool { prefs.showBrightness && prefs.sliderLayout == .vertical }
    private var rowHeight: CGFloat { stacked ? 10 : 18 }
    private var compact: Bool { stacked }

    var body: some View {
        container
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

    @ViewBuilder private var container: some View {
        if prefs.showBrightness {
            if stacked {
                VStack(spacing: 1) { volumeChannel; brightnessChannel }
            } else {
                HStack(spacing: 8) {
                    volumeChannel
                    Divider().frame(height: 13).opacity(0.45)
                    brightnessChannel
                }
            }
        } else {
            volumeChannel
        }
    }

    // MARK: - Channels

    private var volumeChannel: some View {
        HStack(spacing: compact ? 5 : 7) {
            if let symbol = prefs.iconStyle.symbolName(volume: audio.volume, muted: audio.muted) {
                muteButton(symbol)
            }
            control(
                value: Binding(get: { audio.volume }, set: { audio.setVolume($0) }),
                style: prefs.volumeControl,
                tint: prefs.tint.resolved,
                sliderStyle: prefs.sliderStyle,
                knobStyle: prefs.knobStyle,
                width: prefs.sliderWidth,
                hideKnob: prefs.hideKnobWhenIdle,
                steps: prefs.steps,
                muted: audio.muted,
                snap: { prefs.snap($0) },
                target: .volume
            )
            percentage(audio.volume)
        }
    }

    private var brightnessChannel: some View {
        HStack(spacing: compact ? 5 : 7) {
            if prefs.iconStyle != .none {
                Image(systemName: "sun.max.fill", variableValue: max(0.2, brightness.brightness))
                    .font(.system(size: compact ? 9 : 13, weight: .semibold))
                    .foregroundStyle(brightness.available ? AnyShapeStyle(.primary) : AnyShapeStyle(.tertiary))
                    .frame(width: compact ? 12 : 16)
                    .help("屏幕亮度")
            }
            control(
                value: Binding(get: { brightness.brightness }, set: { brightness.setBrightness($0) }),
                style: prefs.brightnessControl,
                tint: prefs.brightnessTint.resolved,
                sliderStyle: prefs.brightnessSliderStyle,
                knobStyle: prefs.brightnessKnobStyle,
                width: prefs.brightnessSliderWidth,
                hideKnob: prefs.brightnessHideKnobWhenIdle,
                steps: 0,                       // brightness is continuous
                muted: !brightness.available,
                snap: { $0 },
                target: .brightness
            )
            percentage(brightness.brightness)
        }
    }

    // MARK: - Control (bar or dial)

    @ViewBuilder
    private func control(value: Binding<Double>, style: ControlStyle, tint: Color,
                         sliderStyle: SliderStyle, knobStyle: KnobStyle,
                         width: CGFloat, hideKnob: Bool, steps: Int,
                         muted: Bool, snap: @escaping (Double) -> Double,
                         target: ScrollTarget) -> some View {
        if let dial = style.dial {
            DialControl(
                value: value,
                diameter: rowHeight + (compact ? 0 : 2),
                tint: tint,
                style: dial,
                muted: muted,
                snap: snap,
                onHover: { if $0 { setScrollTarget(target) } }
            )
        } else {
            VolumeSliderControl(
                value: value,
                width: width,
                tint: tint,
                style: sliderStyle,
                knobStyle: knobStyle,
                hideKnobWhenIdle: hideKnob,
                steps: steps,
                muted: muted,
                snap: snap,
                onHover: { if $0 { setScrollTarget(target) } },
                height: rowHeight
            )
        }
    }

    // MARK: - Pieces

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
            .font(.system(size: compact ? 9 : 13, weight: .semibold))
            .foregroundStyle(audio.muted ? AnyShapeStyle(.secondary) : AnyShapeStyle(.primary))
            .frame(width: compact ? 12 : 16)
            .contentTransition(.symbolEffect(.replace))
        }
        .buttonStyle(.plain)
        .help(audio.muted ? "取消静音" : "静音")
    }

    @ViewBuilder
    private func percentage(_ value: Double) -> some View {
        if prefs.showPercentage && !compact {
            Text("\(Int((value * 100).rounded()))")
                .font(.system(size: 11, weight: .medium))
                .monospacedDigit()
                .foregroundStyle(.secondary)
                .frame(width: 26, alignment: .trailing)
        }
    }
}
