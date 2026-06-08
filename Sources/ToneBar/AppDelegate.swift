import AppKit

final class AppDelegate: NSObject, NSApplicationDelegate {

    private var audio: AudioController!
    private var menuBar: MenuBarController!

    func applicationDidFinishLaunching(_ notification: Notification) {
        // Hidden debug path: render slider styles to a PNG and quit.
        if CommandLine.arguments.contains("--render-preview") {
            PreviewRenderer.render(to: "/tmp/tonebar_preview.png")
            DispatchQueue.main.async { NSApp.terminate(nil) }
            return
        }

        // Menu-bar agent: no Dock icon, no main window.
        NSApp.setActivationPolicy(.accessory)

        audio = AudioController()
        menuBar = MenuBarController(audio: audio)
    }
}
