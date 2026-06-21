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

// MARK: - Control type (bar vs. rotary dial)

enum ControlStyle: String, CaseIterable, Identifiable {
    case bar    // horizontal slider (uses sliderStyle + knobStyle)
    case dial   // rotary dial (uses dialStyle)

    var id: String { rawValue }
    var label: String { self == .bar ? "滚动条" : "旋钮" }
    var isDial: Bool { self == .dial }
}

// MARK: - Dial design (when the control is a rotary dial)

enum DialStyle: String, CaseIterable, Identifiable {
    case flat        // flat disc + arc
    case pie         // pie-chart fill
    case minimal     // bare value arc, no body
    case tickDial    // flat knob ringed with tick marks
    case semiGauge   // wide 180° gauge with a filled value arc
    case semiNeedle  // wide 180° speedometer with ticks + needle

    var id: String { rawValue }

    var label: String {
        switch self {
        case .flat:       return "扁平"
        case .pie:        return "饼状"
        case .minimal:    return "极简弧"
        case .tickDial:   return "刻度盘"
        case .semiGauge:  return "半圆 · 弧"
        case .semiNeedle: return "半圆 · 指针"
        }
    }

    /// Half-circle gauges render wider than tall.
    var isSemicircle: Bool {
        self == .semiGauge || self == .semiNeedle
    }
}

// MARK: - Percentage readout style

enum PercentStyle: String, CaseIterable, Identifiable {
    case none      // hidden
    case integer   // 75
    case percent   // 75%
    case decimal   // 0.75

    var id: String { rawValue }

    var label: String {
        switch self {
        case .none:    return "不显示"
        case .integer: return "数字  75"
        case .percent: return "百分号  75%"
        case .decimal: return "小数  0.75"
        }
    }

    /// Rendered text for a 0...1 value, or nil when hidden.
    func text(_ value: Double) -> String? {
        switch self {
        case .none:    return nil
        case .integer: return "\(Int((value * 100).rounded()))"
        case .percent: return "\(Int((value * 100).rounded()))%"
        case .decimal: return String(format: "%.2f", value)
        }
    }

    var width: CGFloat { self == .percent ? 34 : (self == .decimal ? 32 : 26) }
}

// MARK: - Layout of the two sliders

enum SliderLayout: String, CaseIterable, Identifiable {
    case horizontal   // side by side
    case vertical     // stacked top/bottom

    var id: String { rawValue }
    var label: String { self == .horizontal ? "横向并排" : "上下并排" }
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
    @Published var percentStyle: PercentStyle {
        didSet { store.set(percentStyle.rawValue, forKey: Keys.percentStyle) }
    }
    @Published var glassBackground: Bool {
        didSet { store.set(glassBackground, forKey: Keys.glassBackground) }
    }
    @Published var tint: TintChoice {
        didSet { store.set(tint.rawValue, forKey: Keys.tint) }
    }

    @Published var sliderLayout: SliderLayout {
        didSet { store.set(sliderLayout.rawValue, forKey: Keys.sliderLayout) }
    }
    // Volume channel — enable + per-channel scroll.
    @Published var showVolume: Bool {
        didSet { store.set(showVolume, forKey: Keys.showVolume) }
    }
    @Published var volumeControl: ControlStyle {
        didSet { store.set(volumeControl.rawValue, forKey: Keys.volumeControl) }
    }
    @Published var volumeDialStyle: DialStyle {
        didSet { store.set(volumeDialStyle.rawValue, forKey: Keys.volumeDialStyle) }
    }
    /// Scroll speed multiplier (0 == scrolling disabled).
    @Published var volumeScrollSpeed: Double {
        didSet { store.set(volumeScrollSpeed, forKey: Keys.volumeScrollSpeed) }
    }
    @Published var invertVolumeScroll: Bool {
        didSet { store.set(invertVolumeScroll, forKey: Keys.invertVolumeScroll) }
    }

    // Brightness channel — enable + independent styling + per-channel scroll.
    @Published var showBrightness: Bool {
        didSet { store.set(showBrightness, forKey: Keys.showBrightness) }
    }
    @Published var brightnessControl: ControlStyle {
        didSet { store.set(brightnessControl.rawValue, forKey: Keys.brightnessControl) }
    }
    @Published var brightnessDialStyle: DialStyle {
        didSet { store.set(brightnessDialStyle.rawValue, forKey: Keys.brightnessDialStyle) }
    }
    @Published var brightnessSliderStyle: SliderStyle {
        didSet { store.set(brightnessSliderStyle.rawValue, forKey: Keys.brightnessSliderStyle) }
    }
    @Published var brightnessKnobStyle: KnobStyle {
        didSet { store.set(brightnessKnobStyle.rawValue, forKey: Keys.brightnessKnobStyle) }
    }
    @Published var brightnessTint: TintChoice {
        didSet { store.set(brightnessTint.rawValue, forKey: Keys.brightnessTint) }
    }
    @Published var brightnessSliderWidth: Double {
        didSet { store.set(brightnessSliderWidth, forKey: Keys.brightnessSliderWidth) }
    }
    @Published var brightnessHideKnobWhenIdle: Bool {
        didSet { store.set(brightnessHideKnobWhenIdle, forKey: Keys.brightnessHideKnobWhenIdle) }
    }
    @Published var brightnessSteps: Int {
        didSet { store.set(brightnessSteps, forKey: Keys.brightnessSteps) }
    }
    @Published var brightnessScrollSpeed: Double {
        didSet { store.set(brightnessScrollSpeed, forKey: Keys.brightnessScrollSpeed) }
    }
    @Published var invertBrightnessScroll: Bool {
        didSet { store.set(invertBrightnessScroll, forKey: Keys.invertBrightnessScroll) }
    }

    @Published var launchAtLogin: Bool {
        didSet { LaunchAtLogin.isEnabled = launchAtLogin }
    }

    private init() {
        // Factory defaults reflect the curated out-of-the-box look:
        // both channels = semicircle dials, no icon, 60pt, glass on,
        // brightness scroll at 0.5×.
        iconStyle = IconStyle(rawValue: store.string(forKey: Keys.iconStyle) ?? "") ?? .none
        sliderStyle = SliderStyle(rawValue: store.string(forKey: Keys.sliderStyle) ?? "") ?? .line
        knobStyle = KnobStyle(rawValue: store.string(forKey: Keys.knobStyle) ?? "") ?? .circle
        hideKnobWhenIdle = store.object(forKey: Keys.hideKnobWhenIdle) as? Bool ?? true
        sliderWidth = (store.object(forKey: Keys.sliderWidth) as? Double).map { max(60, min(240, $0)) } ?? 60

        // Normalize persisted step counts into the supported 5...20 range
        // (0 stays "continuous").
        let rawSteps = store.object(forKey: Keys.steps) as? Int ?? 0
        steps = rawSteps == 0 ? 0 : min(Preferences.stepRange.upperBound,
                                        max(Preferences.stepRange.lowerBound, rawSteps))

        // Migrate the old on/off percentage toggle into a style.
        if let raw = store.string(forKey: Keys.percentStyle), let s = PercentStyle(rawValue: raw) {
            percentStyle = s
        } else {
            percentStyle = (store.object(forKey: "showPercentage") as? Bool ?? false) ? .integer : .none
        }
        glassBackground = store.object(forKey: Keys.glassBackground) as? Bool ?? true
        tint = TintChoice(rawValue: store.string(forKey: Keys.tint) ?? "") ?? .system

        sliderLayout = SliderLayout(rawValue: store.string(forKey: Keys.sliderLayout) ?? "") ?? .horizontal

        // Migrate the previously-shared scroll settings into per-channel ones.
        let legacyScroll = store.object(forKey: "scrollToAdjust") as? Bool
        let legacyInvert = store.object(forKey: "invertScroll") as? Bool

        // The control type + dial design used to be one combined value
        // (e.g. "dialFlat"); split them, preserving any prior dial choice.
        let (volCtl, volDialMig) = Self.splitControl(store.string(forKey: Keys.volumeControl))
        let (briCtl, briDialMig) = Self.splitControl(store.string(forKey: Keys.brightnessControl))

        showVolume = store.object(forKey: Keys.showVolume) as? Bool ?? true
        volumeControl = store.object(forKey: Keys.volumeControl) == nil ? .dial : volCtl
        volumeDialStyle = DialStyle(rawValue: store.string(forKey: Keys.volumeDialStyle) ?? "") ?? volDialMig ?? .semiGauge
        volumeScrollSpeed = Self.migratedSpeed(store, Keys.volumeScrollSpeed, "volumeScroll", legacyScroll, 1.0)
        invertVolumeScroll = store.object(forKey: Keys.invertVolumeScroll) as? Bool ?? legacyInvert ?? false

        showBrightness = store.object(forKey: Keys.showBrightness) as? Bool ?? true
        brightnessControl = store.object(forKey: Keys.brightnessControl) == nil ? .dial : briCtl
        brightnessDialStyle = DialStyle(rawValue: store.string(forKey: Keys.brightnessDialStyle) ?? "") ?? briDialMig ?? .semiGauge
        brightnessSliderStyle = SliderStyle(rawValue: store.string(forKey: Keys.brightnessSliderStyle) ?? "") ?? .capsule
        brightnessKnobStyle = KnobStyle(rawValue: store.string(forKey: Keys.brightnessKnobStyle) ?? "") ?? .circle
        brightnessTint = TintChoice(rawValue: store.string(forKey: Keys.brightnessTint) ?? "") ?? .orange
        brightnessSliderWidth = (store.object(forKey: Keys.brightnessSliderWidth) as? Double).map { max(60, min(240, $0)) } ?? 85
        brightnessHideKnobWhenIdle = store.object(forKey: Keys.brightnessHideKnobWhenIdle) as? Bool ?? false
        let rawBriSteps = store.object(forKey: Keys.brightnessSteps) as? Int ?? 0
        brightnessSteps = rawBriSteps == 0 ? 0 : min(Preferences.stepRange.upperBound,
                                                     max(Preferences.stepRange.lowerBound, rawBriSteps))
        brightnessScrollSpeed = Self.migratedSpeed(store, Keys.brightnessScrollSpeed, "brightnessScroll", legacyScroll, 0.5)
        invertBrightnessScroll = store.object(forKey: Keys.invertBrightnessScroll) as? Bool ?? legacyInvert ?? false

        launchAtLogin = LaunchAtLogin.isEnabled
    }

    /// Snap a 0...1 value to the given number of steps (0/1 == continuous).
    func snap(_ value: Double, steps: Int) -> Double {
        guard steps > 1 else { return value }
        let divisions = Double(steps - 1)
        return (value * divisions).rounded() / divisions
    }

    func snap(_ value: Double) -> Double { snap(value, steps: steps) }

    /// The increment applied per scroll/keyboard nudge for a step count.
    func nudgeAmount(steps: Int) -> Double {
        steps > 1 ? 1.0 / Double(steps - 1) : 0.0625   // 1/16 for continuous
    }

    var nudgeAmount: Double { nudgeAmount(steps: steps) }

    /// Whether scrolling adjusts anything (used to decide event interception).
    var anyScrollEnabled: Bool {
        (showVolume && volumeScrollSpeed > 0) || (showBrightness && brightnessScrollSpeed > 0)
    }

    /// Split a legacy combined control value (e.g. "dialFlat") into the new
    /// control type + dial design pair.
    /// Migrate an old on/off scroll boolean into a 0...4 speed (1 == on).
    private static func migratedSpeed(_ store: UserDefaults, _ key: String,
                                      _ legacyKey: String, _ legacyScroll: Bool?,
                                      _ fallback: Double) -> Double {
        if let v = store.object(forKey: key) as? Double { return v }
        if let on = (store.object(forKey: legacyKey) as? Bool) ?? legacyScroll { return on ? 1.0 : 0.0 }
        return fallback
    }

    private static func splitControl(_ raw: String?) -> (ControlStyle, DialStyle?) {
        switch raw {
        case "dial":          return (.dial, nil)
        case "dialRealistic": return (.dial, .flat)
        case "dialFlat":      return (.dial, .flat)
        case "dialPie":       return (.dial, .pie)
        case "dialRing":      return (.dial, .flat)
        default:              return (.bar, nil)
        }
    }

    private enum Keys {
        static let iconStyle = "iconStyle"
        static let sliderStyle = "sliderStyle"
        static let knobStyle = "knobStyle"
        static let hideKnobWhenIdle = "hideKnobWhenIdle"
        static let sliderWidth = "sliderWidth"
        static let steps = "steps"
        static let percentStyle = "percentStyle"
        static let glassBackground = "glassBackground"
        static let tint = "tint"
        static let sliderLayout = "sliderLayout"
        static let showVolume = "showVolume"
        static let volumeControl = "volumeControl"
        static let volumeDialStyle = "volumeDialStyle"
        static let volumeScrollSpeed = "volumeScrollSpeed"
        static let invertVolumeScroll = "invertVolumeScroll"
        static let showBrightness = "showBrightness"
        static let brightnessControl = "brightnessControl"
        static let brightnessDialStyle = "brightnessDialStyle"
        static let brightnessSliderStyle = "brightnessSliderStyle"
        static let brightnessKnobStyle = "brightnessKnobStyle"
        static let brightnessTint = "brightnessTint"
        static let brightnessSliderWidth = "brightnessSliderWidth"
        static let brightnessHideKnobWhenIdle = "brightnessHideKnobWhenIdle"
        static let brightnessSteps = "brightnessSteps"
        static let brightnessScrollSpeed = "brightnessScrollSpeed"
        static let invertBrightnessScroll = "invertBrightnessScroll"
    }
}
