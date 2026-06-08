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
