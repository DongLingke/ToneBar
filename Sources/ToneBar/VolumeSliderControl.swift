import SwiftUI

/// Which slider the scroll wheel should drive, based on what's hovered.
enum ScrollTarget {
    case volume
    case brightness
}

/// A compact, fully custom volume slider that supports several visual styles
/// for both the track and the knob. Handles its own drag gesture so it works
/// inside the menu-bar status item.
struct VolumeSliderControl: View {

    @Binding var value: Double          // 0...1
    var width: CGFloat
    var tint: Color
    var style: SliderStyle
    var knobStyle: KnobStyle
    var hideKnobWhenIdle: Bool
    var steps: Int
    var muted: Bool
    var snap: (Double) -> Double
    var onHover: (Bool) -> Void = { _ in }
    /// Overall control height; shrink for the stacked (vertical) layout.
    var height: CGFloat = 18

    @State private var hovering = false

    private var knobWidth: CGFloat {
        switch knobStyle {
        case .none: return 0
        case .bar:  return min(5, height - 1)
        case .glass: return min(14, height - 1)
        default:    return min(13, height - 1)
        }
    }

    private var knobHeight: CGFloat {
        switch knobStyle {
        case .none: return 0
        case .bar:  return min(15, height)
        case .glass: return min(14, height - 1)
        default:    return min(13, height - 1)
        }
    }

    private var trackHeight: CGFloat {
        let base: CGFloat
        switch style {
        case .line: base = 3
        case .glass: base = 9
        case .segmented: base = 6
        default: base = 5
        }
        return min(base, height - 2)
    }

    private var knobVisible: Bool {
        knobStyle != .none && (!hideKnobWhenIdle || hovering)
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
        .frame(width: width, height: height)
        .opacity(muted ? 0.5 : 1)
    }

    // MARK: - Custom rendering

    private var custom: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height
            // Keep the geometry stable whether or not the knob is visible.
            let inset = max(knobWidth, 6)
            let usable = max(1, w - inset)
            let v = min(1, max(0, value))
            let knobX = inset / 2 + v * usable
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
                        let x = inset / 2 + CGFloat(i) / CGFloat(steps - 1) * usable
                        Circle()
                            .fill(.primary.opacity(0.35))
                            .frame(width: 2.5, height: 2.5)
                            .position(x: x, y: h / 2)
                    }
                }

                if knobStyle != .none {
                    knobShape
                        .frame(width: knobWidth, height: knobHeight)
                        .opacity(knobVisible ? 1 : 0)
                        .position(x: knobX, y: h / 2)
                }
            }
            .animation(.easeInOut(duration: 0.15), value: hovering)
            .contentShape(Rectangle())
            .onHover { inside in
                hovering = inside
                onHover(inside)
            }
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { g in
                        hovering = true
                        onHover(true)
                        let raw = (g.location.x - inset / 2) / usable
                        value = snap(min(1, max(0, raw)))
                    }
            )
        }
    }

    // MARK: - Track / fill

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

    // MARK: - Knob

    @ViewBuilder private var knobShape: some View {
        switch knobStyle {
        case .none:
            EmptyView()
        case .glass:
            Circle().fill(.clear).glassEffect(.regular, in: Circle())
                .overlay(Circle().strokeBorder(.white.opacity(0.3), lineWidth: 0.5))
        case .tinted:
            Circle().fill(tint)
                .overlay(Circle().strokeBorder(.white.opacity(0.85), lineWidth: 1))
                .shadow(color: .black.opacity(0.2), radius: 1, y: 0.5)
        case .ring:
            Circle().fill(.white.opacity(0.001))      // keep the hit area
                .overlay(Circle().strokeBorder(.white, lineWidth: 2.5))
                .shadow(color: .black.opacity(0.25), radius: 1, y: 0.5)
        case .bar:
            Capsule().fill(.white)
                .shadow(color: .black.opacity(0.3), radius: 1.5, y: 0.5)
        case .circle:
            Circle().fill(.white)
                .overlay(Circle().strokeBorder(.black.opacity(0.06), lineWidth: 0.5))
                .shadow(color: .black.opacity(0.25), radius: 1.5, y: 0.5)
        }
    }
}
