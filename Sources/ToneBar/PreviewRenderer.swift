import SwiftUI
import AppKit

/// Debug helper: renders every slider + knob style to a PNG so the visuals can
/// be inspected without screenshotting the (filtered) menu bar.
/// Triggered with the hidden `--render-preview` launch argument.
enum PreviewRenderer {

    @MainActor
    static func render(to path: String) {
        let view = PreviewSheet().frame(width: 720).padding(16).background(Color(white: 0.12))
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
            dialRow
            stylesGrid
        }
    }

    /// The four rotary-dial designs, plus a value comparison.
    private var dialRow: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("旋钮设计（仿真 / 扁平 / 饼状 / 环形）")
                .font(.system(size: 12, weight: .bold)).foregroundStyle(.white.opacity(0.6))
            HStack(spacing: 26) {
                ForEach(Array([("仿真", DialStyle.realistic), ("扁平", .flat),
                               ("饼状", .pie), ("环形", .ring)].enumerated()), id: \.offset) { _, item in
                    VStack(spacing: 6) {
                        DialControl(value: .constant(0.68), diameter: 40, tint: .blue,
                                    style: item.1, muted: false)
                        Text(item.0).font(.system(size: 11)).foregroundStyle(.white.opacity(0.8))
                    }
                }
                // bigger sample to show detail
                DialControl(value: .constant(0.35), diameter: 64, tint: .orange, style: .realistic, muted: false)
                DialControl(value: .constant(0.5), diameter: 64, tint: .green, style: .pie, muted: false)
            }
        }
    }

    /// Mock of the menu-bar item with both sliders, each independently styled.
    private var dualMock: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("菜单栏布局（横向并排 / 上下并排 / 旋钮）")
                .font(.system(size: 12, weight: .bold)).foregroundStyle(.white.opacity(0.6))
            HStack(spacing: 16) {
                // horizontal
                HStack(spacing: 8) {
                    Image(systemName: "speaker.wave.2.fill")
                        .font(.system(size: 13, weight: .semibold)).foregroundStyle(.white).frame(width: 16)
                    VolumeSliderControl(value: .constant(0.6), width: 90, tint: .blue,
                                        style: .segmented, knobStyle: .bar, hideKnobWhenIdle: false,
                                        steps: 11, muted: false, snap: { $0 })
                    Divider().frame(height: 13).overlay(Color.white.opacity(0.4))
                    Image(systemName: "sun.max.fill")
                        .font(.system(size: 13, weight: .semibold)).foregroundStyle(.white).frame(width: 16)
                    VolumeSliderControl(value: .constant(0.85), width: 90, tint: .orange,
                                        style: .capsule, knobStyle: .circle, hideKnobWhenIdle: false,
                                        steps: 0, muted: false, snap: { $0 })
                }
                .padding(.horizontal, 10).padding(.vertical, 6)
                .frame(height: 24).background(Capsule().fill(Color.white.opacity(0.08)))

                // vertical (compact)
                HStack(spacing: 5) {
                    VStack(spacing: 1) {
                        VolumeSliderControl(value: .constant(0.6), width: 80, tint: .blue,
                                            style: .capsule, knobStyle: .bar, hideKnobWhenIdle: false,
                                            steps: 0, muted: false, snap: { $0 }, height: 10)
                        VolumeSliderControl(value: .constant(0.85), width: 80, tint: .orange,
                                            style: .capsule, knobStyle: .bar, hideKnobWhenIdle: false,
                                            steps: 0, muted: false, snap: { $0 }, height: 10)
                    }
                }
                .padding(.horizontal, 10).padding(.vertical, 3)
                .frame(height: 24).background(Capsule().fill(Color.white.opacity(0.08)))

                // dials in the bar
                HStack(spacing: 8) {
                    DialControl(value: .constant(0.6), diameter: 18, tint: .blue, style: .ring, muted: false)
                    DialControl(value: .constant(0.85), diameter: 18, tint: .orange, style: .pie, muted: false)
                }
                .padding(.horizontal, 10).padding(.vertical, 3)
                .frame(height: 24).background(Capsule().fill(Color.white.opacity(0.08)))
            }
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
