import AppKit
import CoreGraphics

/// Reads/writes the built-in display's backlight brightness via the private
/// DisplayServices framework (the reliable path on Apple Silicon). Polls
/// periodically so the slider stays in sync with the keyboard brightness keys.
final class BrightnessController: ObservableObject {

    @Published var brightness: Double = 0.5
    /// False when no controllable display is present (e.g. desktop Mac with
    /// only an external monitor that doesn't expose DisplayServices brightness).
    @Published var available: Bool = false

    private typealias GetFn = @convention(c) (CGDirectDisplayID, UnsafeMutablePointer<Float>) -> Int32
    private typealias SetFn = @convention(c) (CGDirectDisplayID, Float) -> Int32

    private var getFn: GetFn?
    private var setFn: SetFn?
    private var displayID: CGDirectDisplayID = CGMainDisplayID()
    private var timer: Timer?

    init() {
        loadSymbols()
        pickDisplay()
        reload()
        startPolling()
    }

    deinit { timer?.invalidate() }

    private func loadSymbols() {
        let path = "/System/Library/PrivateFrameworks/DisplayServices.framework/DisplayServices"
        guard let handle = dlopen(path, RTLD_NOW) else { return }
        if let g = dlsym(handle, "DisplayServicesGetBrightness") {
            getFn = unsafeBitCast(g, to: GetFn.self)
        }
        if let s = dlsym(handle, "DisplayServicesSetBrightness") {
            setFn = unsafeBitCast(s, to: SetFn.self)
        }
    }

    /// Prefer the built-in display; fall back to the main display.
    private func pickDisplay() {
        var count: UInt32 = 0
        CGGetActiveDisplayList(0, nil, &count)
        guard count > 0 else { displayID = CGMainDisplayID(); return }
        var ids = [CGDirectDisplayID](repeating: 0, count: Int(count))
        CGGetActiveDisplayList(count, &ids, &count)
        displayID = ids.first(where: { CGDisplayIsBuiltin($0) != 0 }) ?? CGMainDisplayID()
    }

    func reload() {
        guard let getFn else { available = false; return }
        var value: Float = 0
        if getFn(displayID, &value) == 0 {
            available = true
            let clamped = Double(max(0, min(1, value)))
            // Avoid stomping the value mid-drag with a stale poll read.
            if abs(clamped - brightness) > 0.001 { brightness = clamped }
        } else {
            available = false
        }
    }

    func setBrightness(_ value: Double) {
        let clamped = max(0, min(1, value))
        brightness = clamped
        guard let setFn else { return }
        _ = setFn(displayID, Float(clamped))
    }

    func nudge(by delta: Double) {
        setBrightness(brightness + delta)
    }

    private func startPolling() {
        timer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { [weak self] _ in
            self?.reload()
        }
    }
}
