import SwiftUI
import AppKit

/// Debug helper: renders every slider style to a PNG so the visuals can be
/// inspected without screenshotting the (filtered) menu bar.
/// Triggered with the hidden `--render-preview` launch argument.
enum PreviewRenderer {

    @MainActor
    static func render(to path: String) {
        let view = PreviewSheet().frame(width: 360).padding(16).background(Color(white: 0.12))
        let renderer = ImageRenderer(content: view)
        renderer.scale = 3
        guard let cg = renderer.cgImage else { return }
        let rep = NSBitmapImageRep(cgImage: cg)
        try? rep.representation(using: .png, properties: [:])?.write(to: URL(fileURLWithPath: path))
    }
}

private struct PreviewSheet: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            ForEach(SliderStyle.allCases) { style in
                HStack(spacing: 14) {
                    Text(style.label)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(.white)
                        .frame(width: 84, alignment: .leading)
                    VolumeSliderControl(
                        value: .constant(0.65),
                        width: 150,
                        tint: .blue,
                        style: style,
                        steps: 8,
                        muted: false,
                        snap: { $0 }
                    )
                }
            }
        }
    }
}
