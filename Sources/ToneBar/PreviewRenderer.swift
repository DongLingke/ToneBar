import SwiftUI
import AppKit

/// Debug helper: renders every slider + knob style to a PNG so the visuals can
/// be inspected without screenshotting the (filtered) menu bar.
/// Triggered with the hidden `--render-preview` launch argument.
enum PreviewRenderer {

    @MainActor
    static func render(to path: String) {
        let view = PreviewSheet().frame(width: 560).padding(16).background(Color(white: 0.12))
        let renderer = ImageRenderer(content: view)
        renderer.scale = 3
        guard let cg = renderer.cgImage else { return }
        let rep = NSBitmapImageRep(cgImage: cg)
        try? rep.representation(using: .png, properties: [:])?.write(to: URL(fileURLWithPath: path))
    }
}

private struct PreviewSheet: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 22) {
            dualMock
            stylesGrid
        }
    }

    /// Mock of the menu-bar item with both sliders, each independently styled.
    private var dualMock: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("菜单栏效果（音量 + 亮度，样式独立）")
                .font(.system(size: 12, weight: .bold)).foregroundStyle(.white.opacity(0.6))
            HStack(spacing: 8) {
                Image(systemName: "speaker.wave.2.fill")
                    .font(.system(size: 13, weight: .semibold)).foregroundStyle(.white).frame(width: 16)
                VolumeSliderControl(value: .constant(0.6), width: 110, tint: .blue,
                                    style: .segmented, knobStyle: .bar, hideKnobWhenIdle: false,
                                    steps: 11, muted: false, snap: { $0 })
                Divider().frame(height: 13).overlay(Color.white.opacity(0.4))
                Image(systemName: "sun.max.fill")
                    .font(.system(size: 13, weight: .semibold)).foregroundStyle(.white).frame(width: 16)
                VolumeSliderControl(value: .constant(0.85), width: 110, tint: .orange,
                                    style: .capsule, knobStyle: .circle, hideKnobWhenIdle: false,
                                    steps: 0, muted: false, snap: { $0 })
            }
            .padding(.horizontal, 12).padding(.vertical, 6)
            .background(Capsule().fill(Color.white.opacity(0.08)))
        }
    }

    private var stylesGrid: some View {
        HStack(alignment: .top, spacing: 28) {
            column(title: "滑条样式") {
                ForEach(SliderStyle.allCases) { style in
                    row(style.label) {
                        VolumeSliderControl(
                            value: .constant(0.65), width: 150, tint: .blue,
                            style: style, knobStyle: .circle, hideKnobWhenIdle: false,
                            steps: 8, muted: false, snap: { $0 })
                    }
                }
            }
            column(title: "旋钮样式") {
                ForEach(KnobStyle.allCases) { knob in
                    row(knob.label) {
                        VolumeSliderControl(
                            value: .constant(0.65), width: 150, tint: .blue,
                            style: .capsule, knobStyle: knob, hideKnobWhenIdle: false,
                            steps: 8, muted: false, snap: { $0 })
                    }
                }
            }
        }
    }

    private func column<C: View>(title: String, @ViewBuilder _ content: () -> C) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(title).font(.system(size: 12, weight: .bold)).foregroundStyle(.white.opacity(0.6))
            content()
        }
    }

    private func row<C: View>(_ label: String, @ViewBuilder _ control: () -> C) -> some View {
        HStack(spacing: 12) {
            Text(label)
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(.white)
                .frame(width: 72, alignment: .leading)
            control()
        }
    }
}
