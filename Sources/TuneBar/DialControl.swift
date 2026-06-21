import SwiftUI

/// A compact rotary dial (knob) control: drag up/down to change the value.
/// Several visual designs — realistic, flat, pie, ring.
struct DialControl: View {

    @Binding var value: Double          // 0...1
    var diameter: CGFloat
    var tint: Color
    var style: DialStyle
    var muted: Bool
    var snap: (Double) -> Double = { $0 }
    var onHover: (Bool) -> Void = { _ in }

    @State private var dragStart: Double? = nil

    // A 270° gauge sweep, classic knob orientation (gap at the bottom).
    private let gaugeStart = 135.0
    private let gaugeSweep = 270.0

    var body: some View {
        content
            .frame(width: diameter, height: diameter)
            .opacity(muted ? 0.5 : 1)
            .contentShape(Circle())
            .onHover { onHover($0) }
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { g in
                        onHover(true)
                        if dragStart == nil { dragStart = value }
                        let delta = -Double(g.translation.height) / 90.0
                        value = snap(min(1, max(0, (dragStart ?? value) + delta)))
                    }
                    .onEnded { _ in dragStart = nil }
            )
    }

    @ViewBuilder private var content: some View {
        switch style {
        case .realistic: realistic
        case .flat:      flat
        case .pie:       pie
        case .ring:      ring
        case .minimal:   minimal
        case .tickDial:  tickDial
        }
    }

    // MARK: - Shared geometry

    /// A trimmed circle covering `frac` of the 270° gauge, starting lower-left.
    private func gauge(_ frac: Double) -> some Shape {
        Circle().trim(from: 0, to: frac * (gaugeSweep / 360.0)).rotation(.degrees(gaugeStart))
    }

    private var lineW: CGFloat { max(2, diameter * 0.13) }

    /// Pointer angle in screen space for the current value.
    private var pointerAngle: Angle { .degrees(gaugeStart + gaugeSweep * value) }

    // MARK: - Flat

    private var flat: some View {
        ZStack {
            Circle().fill(.primary.opacity(0.12))
            gauge(1).stroke(.primary.opacity(0.18), style: .init(lineWidth: lineW, lineCap: .round))
            gauge(value).stroke(tint, style: .init(lineWidth: lineW, lineCap: .round))
            pointer(length: diameter * 0.30, width: max(1.5, diameter * 0.09), color: tint)
        }
        .padding(lineW / 2)
    }

    // MARK: - Realistic (skeuomorphic)

    private var realistic: some View {
        ZStack {
            // outer value gauge
            gauge(1).stroke(.primary.opacity(0.18), style: .init(lineWidth: max(1.5, diameter * 0.08), lineCap: .round))
            gauge(value).stroke(tint, style: .init(lineWidth: max(1.5, diameter * 0.08), lineCap: .round))
                .padding(diameter * 0.005)

            // brushed-metal knob body
            Circle()
                .fill(
                    RadialGradient(
                        colors: [Color(white: 0.42), Color(white: 0.20), Color(white: 0.10)],
                        center: .init(x: 0.35, y: 0.30), startRadius: 0, endRadius: diameter * 0.55)
                )
                .overlay(
                    Circle().fill(
                        LinearGradient(colors: [.white.opacity(0.35), .clear, .black.opacity(0.35)],
                                       startPoint: .topLeading, endPoint: .bottomTrailing))
                )
                .overlay(Circle().strokeBorder(.black.opacity(0.55), lineWidth: max(0.5, diameter * 0.02)))
                .padding(diameter * 0.18)

            // indicator notch
            pointer(length: diameter * 0.20, width: max(1.5, diameter * 0.07), color: .white)
                .padding(diameter * 0.18)
        }
    }

    // MARK: - Pie (pie-chart fill)

    private var pie: some View {
        ZStack {
            Circle().fill(.primary.opacity(0.14))
            Circle().strokeBorder(.primary.opacity(0.2), lineWidth: 1)
            PieShape(fraction: value).fill(tint)
        }
    }

    // MARK: - Ring (thin gauge)

    private var ring: some View {
        ZStack {
            gauge(1).stroke(.primary.opacity(0.16), style: .init(lineWidth: max(1.5, diameter * 0.09), lineCap: .round))
            gauge(value).stroke(tint, style: .init(lineWidth: max(1.5, diameter * 0.09), lineCap: .round))
            // dot at the current position
            Circle().fill(tint)
                .frame(width: diameter * 0.16, height: diameter * 0.16)
                .offset(y: -diameter * 0.40)
                .rotationEffect(pointerAngle - .degrees(270))
        }
        .padding(diameter * 0.08)
    }

    // MARK: - Minimal (bare value arc)

    private var minimal: some View {
        gauge(value)
            .stroke(tint, style: .init(lineWidth: max(2, diameter * 0.16), lineCap: .round))
            .background(
                gauge(1).stroke(.primary.opacity(0.12), style: .init(lineWidth: max(2, diameter * 0.16), lineCap: .round))
            )
            .padding(max(1.5, diameter * 0.1))
    }

    // MARK: - Tick dial (instrument-style knob ringed with ticks)

    private var tickDial: some View {
        let count = 13
        let activeUpTo = Int((value * Double(count - 1)).rounded())
        return ZStack {
            ForEach(0..<count, id: \.self) { i in
                let f = Double(i) / Double(count - 1)
                let on = i <= activeUpTo
                Capsule()
                    .fill(on ? AnyShapeStyle(tint) : AnyShapeStyle(.primary.opacity(0.22)))
                    .frame(width: max(1.2, diameter * 0.05),
                           height: diameter * (on ? 0.17 : 0.12))
                    .shadow(color: on ? tint.opacity(0.6) : .clear, radius: diameter * 0.015)
                    .offset(y: -diameter * 0.40)
                    .rotationEffect(.degrees(gaugeStart + gaugeSweep * f - 270))
            }

            // raised center cap
            Circle()
                .fill(
                    RadialGradient(
                        colors: [Color(white: 0.34), Color(white: 0.15)],
                        center: .init(x: 0.35, y: 0.30),
                        startRadius: 0, endRadius: diameter * 0.32)
                )
                .overlay(Circle().strokeBorder(.white.opacity(0.14), lineWidth: 0.5))
                .overlay(Circle().strokeBorder(.black.opacity(0.4), lineWidth: 0.5).blur(radius: 0.5))
                .padding(diameter * 0.30)
                .shadow(color: .black.opacity(0.35), radius: diameter * 0.02, y: diameter * 0.01)

            // pointer + hub dot
            pointer(length: diameter * 0.17, width: max(1.5, diameter * 0.07), color: .white)
                .padding(diameter * 0.30)
            Circle().fill(tint)
                .frame(width: diameter * 0.07, height: diameter * 0.07)
        }
    }

    // MARK: - Pointer helper

    private func pointer(length: CGFloat, width: CGFloat, color: Color) -> some View {
        Capsule()
            .fill(color)
            .frame(width: width, height: length)
            .offset(y: -length / 2 - diameter * 0.06)
            .rotationEffect(pointerAngle - .degrees(270))
    }
}

/// A pie slice filling clockwise from the top, like a pie chart.
struct PieShape: Shape {
    var fraction: Double
    func path(in rect: CGRect) -> Path {
        var p = Path()
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let radius = min(rect.width, rect.height) / 2
        p.move(to: center)
        p.addArc(center: center, radius: radius,
                 startAngle: .degrees(-90),
                 endAngle: .degrees(-90 + 360 * max(0, min(1, fraction))),
                 clockwise: false)
        p.closeSubpath()
        return p
    }
}
