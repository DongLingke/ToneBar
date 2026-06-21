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
            .frame(width: style.isSemicircle ? diameter * 2 : diameter, height: diameter)
            .opacity(muted ? 0.5 : 1)
            .contentShape(Rectangle())
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
        case .flat:       flat
        case .pie:        pie
        case .minimal:    minimal
        case .tickDial:   tickDial
        case .semiGauge:  semicircle(fillArc: true, ticks: 0, needle: false)
        case .semiNeedle: semicircle(fillArc: false, ticks: 13, needle: true)
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

    // MARK: - Pie (pie-chart fill)

    private var pie: some View {
        ZStack {
            Circle().fill(.primary.opacity(0.14))
            Circle().strokeBorder(.primary.opacity(0.2), lineWidth: 1)
            PieShape(fraction: value).fill(tint)
        }
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

    // MARK: - Semicircle gauges (wide 180° dials)

    private func semicircle(fillArc: Bool, ticks: Int, needle: Bool) -> some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height
            let cx = w / 2
            let cy = h * 0.97
            let r = min(w / 2, h * 0.97) * 0.98
            let arcW = max(2.5, h * 0.18)

            ZStack {
                semiArc(cx, cy, r, 1).stroke(.primary.opacity(0.15),
                              style: .init(lineWidth: fillArc ? arcW : max(1.5, h * 0.05), lineCap: .round))
                if fillArc {
                    semiArc(cx, cy, r, value).stroke(tint, style: .init(lineWidth: arcW, lineCap: .round))
                }

                if ticks > 1 {
                    let active = Int((value * Double(ticks - 1)).rounded())
                    let tickW = max(1.3, h * 0.06)
                    GaugeTicks(count: ticks, active: active, lit: false,
                               innerRatio: 0.70, outerRatio: 0.96)
                        .stroke(.primary.opacity(0.28), style: .init(lineWidth: tickW, lineCap: .round))
                    GaugeTicks(count: ticks, active: active, lit: true,
                               innerRatio: 0.62, outerRatio: 0.99)
                        .stroke(tint, style: .init(lineWidth: tickW, lineCap: .round))
                        .shadow(color: tint.opacity(0.6), radius: h * 0.02)
                }

                if needle {
                    let rad = (180 + 180 * value) * .pi / 180
                    Path { p in
                        p.move(to: CGPoint(x: cx, y: cy))
                        p.addLine(to: CGPoint(x: cx + CGFloat(cos(rad)) * r * 0.8,
                                              y: cy + CGFloat(sin(rad)) * r * 0.8))
                    }
                    .stroke(tint, style: .init(lineWidth: max(1.5, h * 0.08), lineCap: .round))
                    Circle().fill(tint)
                        .frame(width: h * 0.18, height: h * 0.18)
                        .position(x: cx, y: cy)
                }
            }
        }
        .padding(.horizontal, diameter * 0.05)
    }

    private func semiArc(_ cx: CGFloat, _ cy: CGFloat, _ r: CGFloat, _ frac: Double) -> Path {
        Path { p in
            p.addArc(center: CGPoint(x: cx, y: cy), radius: r,
                     startAngle: .degrees(180),
                     endAngle: .degrees(180 + 180 * max(0, min(1, frac))),
                     clockwise: false)
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

/// Radial tick marks along a 180° semicircle gauge (center at bottom-middle).
struct GaugeTicks: Shape {
    var count: Int
    var active: Int
    var lit: Bool          // draw the lit subset (i <= active) or the rest
    var innerRatio: CGFloat
    var outerRatio: CGFloat

    func path(in rect: CGRect) -> Path {
        var path = Path()
        guard count > 1 else { return path }
        let cx = rect.midX
        let cy = rect.height * 0.97
        let r = min(rect.width / 2, rect.height * 0.97) * 0.98
        for i in 0..<count {
            if (i <= active) != lit { continue }
            let f = Double(i) / Double(count - 1)
            let a = (180 + 180 * f) * .pi / 180
            let dx = CGFloat(cos(a)), dy = CGFloat(sin(a))
            path.move(to: CGPoint(x: cx + dx * r * innerRatio, y: cy + dy * r * innerRatio))
            path.addLine(to: CGPoint(x: cx + dx * r * outerRatio, y: cy + dy * r * outerRatio))
        }
        return path
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
