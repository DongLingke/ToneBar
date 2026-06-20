import AppKit
import SwiftUI
import Combine

/// Hosts the SwiftUI slider and forwards scroll-wheel + right-click events that
/// SwiftUI can't easily intercept inside a status item.
final class StatusHostingView<Content: View>: NSHostingView<Content> {

    var onScroll: ((CGFloat) -> Void)?
    var onRightClick: ((NSEvent) -> Void)?

    override func scrollWheel(with event: NSEvent) {
        guard Preferences.shared.scrollToAdjust else {
            super.scrollWheel(with: event)
            return
        }
        let delta = event.hasPreciseScrollingDeltas ? event.scrollingDeltaY : event.deltaY
        onScroll?(delta)
    }

    override func rightMouseDown(with event: NSEvent) {
        onRightClick?(event)
    }

    required init(rootView: Content) { super.init(rootView: rootView) }
    @MainActor required dynamic init?(coder: NSCoder) { fatalError("init(coder:) is not used") }
}

/// Owns the `NSStatusItem` and keeps its width in sync with the preferences.
final class MenuBarController: NSObject {

    private let audio: AudioController
    private let brightness: BrightnessController
    private let prefs = Preferences.shared

    private var statusItem: NSStatusItem!
    private var hostingView: StatusHostingView<MenuSliderView>!
    private var cancellables = Set<AnyCancellable>()
    private var settingsController: SettingsWindowController?
    private var scrollAccumulator: Double = 0
    private var scrollTarget: ScrollTarget = .volume

    init(audio: AudioController, brightness: BrightnessController) {
        self.audio = audio
        self.brightness = brightness
        super.init()
        installStatusItem()
        observePreferences()
    }

    // MARK: - Setup

    private func installStatusItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        statusItem.behavior = .removalAllowed

        let rootView = MenuSliderView(audio: audio, brightness: brightness,
                                      setScrollTarget: { [weak self] in self?.scrollTarget = $0 })
        let view = StatusHostingView(rootView: rootView)
        view.translatesAutoresizingMaskIntoConstraints = true
        view.onScroll = { [weak self] delta in self?.handleScroll(delta) }
        view.onRightClick = { [weak self] event in self?.showMenu(event) }
        hostingView = view

        if let button = statusItem.button {
            button.addSubview(view)
        }
        updateLayout()
    }

    /// Recompute the status item width from the SwiftUI content's fitting size.
    private func updateLayout() {
        hostingView.layoutSubtreeIfNeeded()
        let width = max(44, hostingView.fittingSize.width)
        statusItem.length = width
        if let button = statusItem.button {
            hostingView.frame = NSRect(x: 0, y: 0, width: width, height: button.bounds.height)
        }
    }

    private func observePreferences() {
        // Width-affecting settings live on the same object; recompute after each.
        prefs.objectWillChange
            .receive(on: RunLoop.main)
            .sink { [weak self] in self?.updateLayout() }
            .store(in: &cancellables)
    }

    // MARK: - Scroll

    private func handleScroll(_ delta: CGFloat) {
        // Brightness is always continuous; volume may be stepped.
        let brightnessTarget = prefs.showBrightness && scrollTarget == .brightness
        scrollAccumulator += Double(delta)

        if !brightnessTarget && prefs.steps > 1 {
            let threshold = 4.0
            guard abs(scrollAccumulator) >= threshold else { return }
            let direction = scrollAccumulator > 0 ? 1.0 : -1.0
            audio.setVolume(prefs.snap(audio.volume + direction * prefs.nudgeAmount))
            scrollAccumulator = 0
        } else {
            if brightnessTarget {
                brightness.nudge(by: Double(delta) * 0.005)
            } else {
                audio.setVolume(audio.volume + Double(delta) * 0.005)
            }
            scrollAccumulator = 0
        }
    }

    // MARK: - Menu

    private func showMenu(_ event: NSEvent) {
        guard let button = statusItem.button else { return }
        let menu = NSMenu()

        let mute = NSMenuItem(title: audio.muted ? "取消静音" : "静音",
                              action: #selector(toggleMute), keyEquivalent: "")
        mute.target = self
        menu.addItem(mute)

        if !audio.deviceName.isEmpty {
            let device = NSMenuItem(title: "输出设备：\(audio.deviceName)", action: nil, keyEquivalent: "")
            device.isEnabled = false
            menu.addItem(device)
        }

        menu.addItem(.separator())

        let settings = NSMenuItem(title: "设置…", action: #selector(openSettings), keyEquivalent: ",")
        settings.target = self
        menu.addItem(settings)

        let quit = NSMenuItem(title: "退出 音条 ToneBar", action: #selector(quit), keyEquivalent: "q")
        quit.target = self
        menu.addItem(quit)

        menu.popUp(positioning: nil,
                   at: NSPoint(x: 0, y: button.bounds.height + 5),
                   in: button)
    }

    @objc private func toggleMute() { audio.toggleMute() }

    @objc private func openSettings() {
        if settingsController == nil {
            settingsController = SettingsWindowController(audio: audio, brightness: brightness)
        }
        NSApp.activate(ignoringOtherApps: true)
        settingsController?.show()
    }

    @objc private func quit() { NSApp.terminate(nil) }
}
