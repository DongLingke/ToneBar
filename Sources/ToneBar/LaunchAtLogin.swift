import Foundation
import ServiceManagement

/// Wraps `SMAppService` so the app can register itself as a login item.
/// Works best when the app lives in /Applications and is signed; ad-hoc
/// development builds may need to be approved in System Settings > General >
/// Login Items.
enum LaunchAtLogin {

    static var isEnabled: Bool {
        get {
            SMAppService.mainApp.status == .enabled
        }
        set {
            do {
                if newValue {
                    if SMAppService.mainApp.status != .enabled {
                        try SMAppService.mainApp.register()
                    }
                } else {
                    if SMAppService.mainApp.status == .enabled {
                        try SMAppService.mainApp.unregister()
                    }
                }
            } catch {
                NSLog("VolumeSlider: launch-at-login update failed: \(error.localizedDescription)")
            }
        }
    }
}
