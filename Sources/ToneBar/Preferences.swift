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
        case .waves:    return "Speaker Waves"
        case .speaker:  return "Speaker"
        case .waveform: return "Waveform"
        case .dot:      return "Minimal Dot"
        case .none:     return "No Icon"
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

    var label: String { rawValue.capitalized }

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
}

// MARK: - Preferences store

/// Single source of truth shared by the AppKit status item and the SwiftUI
/// settings window. Backed by `UserDefaults`; each property persists on write.
final class Preferences: ObservableObject {

    static let shared = Preferences()

    private let store = UserDefaults.standard

    @Published var iconStyle: IconStyle {
        didSet { store.set(iconStyle.rawValue, forKey: Keys.iconStyle) }
    }
    @Published var sliderWidth: Double {
        didSet { store.set(sliderWidth, forKey: Keys.sliderWidth) }
    }
    /// Number of discrete steps. 0 == continuous.
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
        sliderWidth = (store.object(forKey: Keys.sliderWidth) as? Double).map { max(60, min(240, $0)) } ?? 120
        steps = store.object(forKey: Keys.steps) as? Int ?? 0
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
        static let sliderWidth = "sliderWidth"
        static let steps = "steps"
        static let showPercentage = "showPercentage"
        static let scrollToAdjust = "scrollToAdjust"
        static let glassBackground = "glassBackground"
        static let tint = "tint"
    }
}
