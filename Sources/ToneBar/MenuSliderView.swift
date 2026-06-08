import SwiftUI

/// The compact control that lives inside the menu bar: an icon + a slider
/// (+ optional percentage). Designed to read clearly against the translucent
/// menu bar in both light and dark appearances.
struct MenuSliderView: View {

    @ObservedObject var audio: AudioController
    @ObservedObject var prefs = Preferences.shared

    var body: some View {
        HStack(spacing: 7) {
            if let symbol = prefs.iconStyle.symbolName(volume: audio.volume, muted: audio.muted) {
                icon(symbol)
            }

            slider

            if prefs.showPercentage {
                Text("\(Int((audio.volume * 100).rounded()))")
                    .font(.system(size: 11, weight: .medium))
                    .monospacedDigit()
                    .foregroundStyle(.secondary)
                    .frame(width: 26, alignment: .trailing)
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

    // MARK: - Pieces

    @ViewBuilder
    private func icon(_ symbol: String) -> some View {
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

    private var slider: some View {
        VolumeSliderControl(
            value: Binding(get: { audio.volume }, set: { audio.setVolume($0) }),
            width: prefs.sliderWidth,
            tint: prefs.tint.resolved,
            style: prefs.sliderStyle,
            steps: prefs.steps,
            muted: audio.muted,
            snap: { prefs.snap($0) }
        )
    }
}
