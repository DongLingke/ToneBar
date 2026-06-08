import SwiftUI

// MARK: - Icon style

enum IconStyle: String, CaseIterable, Identifiable {
    case waves        // speaker.wave.* — fills proportionally to volume
    case speaker      // plain speaker.fill
    case waveform     // waveform glyph
    case dot          // minimalist circle
    case none         // no icon, slider only

    var id: String { rawValue }

    var label: String {
        switch self {
        case .waves:    return "扬声器声波"
        case .speaker:  return "扬声器"
        case .waveform: return "波形"
        case .dot:      return "极简圆点"
        case .none:     return "无图标"
        }
    }

    /// Whether this glyph supports SF Symbols' `variableValue` fill.
    var usesVariableValue: Bool {
        self == .waves || self == .waveform
    }

    /// Resolve the SF Symbol name for the current state.
    func symbolName(volume: Double, muted: Bool) -> String? {
        if muted { return self == .none ? nil : "speaker.slash.fill" }
        switch self {
        case .none:     return nil
        case .speaker:  return "speaker.fill"
        case .waveform: return "waveform"
        case .dot:      return volume <= 0.001 ? "circle" : "circle.fill"
        case .waves:    return volume <= 0.001 ? "speaker.fill" : "speaker.wave.3.fill"
        }
    }
}

// MARK: - Tint

enum TintChoice: String, CaseIterable, Identifiable {
    case system, blue, indigo, purple, pink, red, orange, green, graphite

    var id: String { rawValue }

    var label: String {
        switch self {
        case .system:   return "系统"
        case .blue:     return "蓝色"
        case .indigo:   return "靛蓝"
        case .purple:   return "紫色"
        case .pink:     return "粉色"
        case .red:      return "红色"
        case .orange:   return "橙色"
        case .green:    return "绿色"
        case .graphite: return "石墨"
        }
    }

    var color: Color? {
        switch self {
        case .system:   return nil          // use the system accent
        case .blue:     return .blue
        case .indigo:   return .indigo
        case .purple:   return .purple
        case .pink:     return .pink
        case .red:      return .red
        case .orange:   return .orange
        case .green:    return .green
        case .graphite: return Color(white: 0.5)
        }
    }

    /// Concrete color for drawing (falls back to the system accent).
    var resolved: Color { color ?? .accentColor }
}

// MARK: - Slider style

enum SliderStyle: String, CaseIterable, Identifiable {
    case capsule      // filled capsule track + white knob (default)
    case glass        // liquid-glass track + glass knob
    case gradient     // gradient-filled track
    case line         // thin minimal line
    case segmented    // capsule track with step ticks
    case system       // native macOS slider

    var id: String { rawValue }

    var label: String {
        switch self {
        case .capsule:   return "胶囊"
        case .glass:     return "液态玻璃"
        case .gradient:  return "渐变"
        case .line:      return "极细线"
        case .segmented: return "分段刻度"
        case .system:    return "系统原生"
        }
    }
}

// MARK: - Knob (thumb) style

enum KnobStyle: String, CaseIterable, Identifiable {
    case circle       // white circle (default)
    case glass        // liquid-glass circle
    case tinted       // filled with the accent color
    case ring         // hollow ring
    case bar          // vertical rounded bar
    case none         // no knob, just the track fill

    var id: String { rawValue }

    var label: String {
        switch self {
        case .circle: return "圆形"
        case .glass:  return "液态玻璃"
        case .tinted: return "彩色填充"
        case .ring:   return "圆环"
        case .bar:    return "竖条"
        case .none:   return "无"
        }
    }
}

// MARK: - Preferences store

/// Single source of truth shared by the AppKit status item and the SwiftUI
/// settings window. Backed by `UserDefaults`; each property persists on write.
final class Preferences: ObservableObject {

    static let shared = Preferences()

    /// Allowed range for the number of discrete steps.
    static let stepRange = 5...20

    private let store = UserDefaults.standard

    @Published var iconStyle: IconStyle {
        didSet { store.set(iconStyle.rawValue, forKey: Keys.iconStyle) }
    }
    @Published var sliderStyle: SliderStyle {
        didSet { store.set(sliderStyle.rawValue, forKey: Keys.sliderStyle) }
    }
    @Published var knobStyle: KnobStyle {
        didSet { store.set(knobStyle.rawValue, forKey: Keys.knobStyle) }
    }
    /// Hide the knob unless the pointer is hovering over the slider.
    @Published var hideKnobWhenIdle: Bool {
        didSet { store.set(hideKnobWhenIdle, forKey: Keys.hideKnobWhenIdle) }
    }
    @Published var sliderWidth: Double {
        didSet { store.set(sliderWidth, forKey: Keys.sliderWidth) }
    }
    /// Number of discrete steps. 0 == continuous, otherwise within `stepRange`.
    /// e.g. 5 => 0, 25, 50, 75, 100.
    @Published var steps: Int {
        didSet { store.set(steps, forKey: Keys.steps) }
    }
    @Published var showPercentage: Bool {
        didSet { store.set(showPercentage, forKey: Keys.showPercentage) }
    }
    @Published var scrollToAdjust: Bool {
        didSet { store.set(scrollToAdjust, forKey: Keys.scrollToAdjust) }
    }
    @Published var glassBackground: Bool {
        didSet { store.set(glassBackground, forKey: Keys.glassBackground) }
    }
    @Published var tint: TintChoice {
        didSet { store.set(tint.rawValue, forKey: Keys.tint) }
    }
    @Published var launchAtLogin: Bool {
        didSet { LaunchAtLogin.isEnabled = launchAtLogin }
    }

    private init() {
        iconStyle = IconStyle(rawValue: store.string(forKey: Keys.iconStyle) ?? "") ?? .waves
        sliderStyle = SliderStyle(rawValue: store.string(forKey: Keys.sliderStyle) ?? "") ?? .capsule
        knobStyle = KnobStyle(rawValue: store.string(forKey: Keys.knobStyle) ?? "") ?? .circle
        hideKnobWhenIdle = store.object(forKey: Keys.hideKnobWhenIdle) as? Bool ?? false
        sliderWidth = (store.object(forKey: Keys.sliderWidth) as? Double).map { max(60, min(240, $0)) } ?? 120

        // Normalize persisted step counts into the supported 5...20 range
        // (0 stays "continuous").
        let rawSteps = store.object(forKey: Keys.steps) as? Int ?? 0
        steps = rawSteps == 0 ? 0 : min(Preferences.stepRange.upperBound,
                                        max(Preferences.stepRange.lowerBound, rawSteps))

        showPercentage = store.object(forKey: Keys.showPercentage) as? Bool ?? true
        scrollToAdjust = store.object(forKey: Keys.scrollToAdjust) as? Bool ?? true
        glassBackground = store.object(forKey: Keys.glassBackground) as? Bool ?? true
        tint = TintChoice(rawValue: store.string(forKey: Keys.tint) ?? "") ?? .system
        launchAtLogin = LaunchAtLogin.isEnabled
    }

    /// Snap a 0...1 value to the configured number of steps.
    func snap(_ value: Double) -> Double {
        guard steps > 1 else { return value }
        let divisions = Double(steps - 1)
        return (value * divisions).rounded() / divisions
    }

    /// The increment applied per scroll/keyboard nudge.
    var nudgeAmount: Double {
        steps > 1 ? 1.0 / Double(steps - 1) : 0.0625   // 1/16 for continuous
    }

    private enum Keys {
        static let iconStyle = "iconStyle"
        static let sliderStyle = "sliderStyle"
        static let knobStyle = "knobStyle"
        static let hideKnobWhenIdle = "hideKnobWhenIdle"
        static let sliderWidth = "sliderWidth"
        static let steps = "steps"
        static let showPercentage = "showPercentage"
        static let scrollToAdjust = "scrollToAdjust"
        static let glassBackground = "glassBackground"
        static let tint = "tint"
    }
}
