import SwiftUI

/// A compact, fully custom volume slider that supports several visual styles.
/// Handles its own drag gesture so it works inside the menu-bar status item.
struct VolumeSliderControl: View {

    @Binding var value: Double          // 0...1
    var width: CGFloat
    var tint: Color
    var style: SliderStyle
    var steps: Int
    var muted: Bool
    var snap: (Double) -> Double

    private var knobSize: CGFloat {
        switch style {
        case .line: return 10
        case .glass: return 14
        default: return 13
        }
    }

    private var trackHeight: CGFloat {
        switch style {
        case .line: return 3
        case .glass: return 9
        case .segmented: return 6
        default: return 5
        }
    }

    var body: some View {
        Group {
            if style == .system {
                Slider(value: Binding(get: { value }, set: { value = snap($0) }), in: 0...1)
                    .controlSize(.mini)
                    .tint(tint)
            } else {
                custom
            }
        }
        .frame(width: width, height: 18)
        .opacity(muted ? 0.5 : 1)
    }

    // MARK: - Custom rendering

    private var custom: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height
            let usable = max(1, w - knobSize)
            let v = min(1, max(0, value))
            let knobX = knobSize / 2 + v * usable
            let fillWidth = max(trackHeight, knobX)

            ZStack {
                trackShape
                    .frame(width: w, height: trackHeight)
                    .position(x: w / 2, y: h / 2)

                fillShape
                    .frame(width: fillWidth, height: trackHeight)
                    .position(x: fillWidth / 2, y: h / 2)

                if style == .segmented && steps > 1 {
                    ForEach(0..<steps, id: \.self) { i in
                        let x = knobSize / 2 + CGFloat(i) / CGFloat(steps - 1) * usable
                        Circle()
                            .fill(.primary.opacity(0.35))
                            .frame(width: 2.5, height: 2.5)
                            .position(x: x, y: h / 2)
                    }
                }

                knobShape
                    .frame(width: knobSize, height: knobSize)
                    .position(x: knobX, y: h / 2)
            }
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { g in
                        let raw = (g.location.x - knobSize / 2) / usable
                        value = snap(min(1, max(0, raw)))
                    }
            )
        }
    }

    // MARK: - Style pieces

    @ViewBuilder private var trackShape: some View {
        switch style {
        case .glass:
            Capsule().fill(.clear).glassEffect(.regular, in: Capsule())
        case .line:
            Capsule().fill(.primary.opacity(0.18))
        default:
            Capsule().fill(tint.opacity(0.22))
        }
    }

    @ViewBuilder private var fillShape: some View {
        switch style {
        case .gradient:
            Capsule().fill(
                LinearGradient(colors: [tint.opacity(0.45), tint],
                               startPoint: .leading, endPoint: .trailing))
        case .glass:
            Capsule().fill(tint.opacity(0.9))
        default:
            Capsule().fill(tint)
        }
    }

    @ViewBuilder private var knobShape: some View {
        switch style {
        case .glass:
            Circle().fill(.clear).glassEffect(.regular, in: Circle())
                .overlay(Circle().strokeBorder(.white.opacity(0.3), lineWidth: 0.5))
        case .line:
            Circle().fill(tint)
                .overlay(Circle().strokeBorder(.white.opacity(0.7), lineWidth: 0.5))
        default:
            Circle().fill(.white)
                .overlay(Circle().strokeBorder(.black.opacity(0.06), lineWidth: 0.5))
                .shadow(color: .black.opacity(0.25), radius: 1.5, y: 0.5)
        }
    }
}
