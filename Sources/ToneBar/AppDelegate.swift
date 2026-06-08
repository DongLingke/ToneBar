import AppKit

final class AppDelegate: NSObject, NSApplicationDelegate {

    private var audio: AudioController!
    private var menuBar: MenuBarController!

    func applicationDidFinishLaunching(_ notification: Notification) {
        // Menu-bar agent: no Dock icon, no main window.
        NSApp.setActivationPolicy(.accessory)

        audio = AudioController()
        menuBar = MenuBarController(audio: audio)
    }
}
