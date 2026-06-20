# 调条 TuneBar

A macOS menu-bar app that puts a **real, draggable volume slider directly in the menu bar** — not an icon you have to click open. Built for macOS 26 (Tahoe) with the Liquid Glass look.

![macOS](https://img.shields.io/badge/macOS-26%2B-blue) ![Swift](https://img.shields.io/badge/Swift-6-orange)

## Features

- **Inline slider** — adjust system volume right from the menu bar, no popover.
- **Liquid Glass UI** — optional translucent glass capsule behind the control.
- **Light & dark** — adapts to the menu bar appearance automatically.
- **Click the icon to mute**, right-click for a menu (mute / settings / quit).
- **Scroll to adjust** — roll the scroll wheel over the slider.
- **Settings**
  - Icon style: Speaker Waves / Speaker / Waveform / Minimal Dot / No Icon
  - Slider width (60–240 pt)
  - Accent color
  - Show percentage
  - **Steps / 档位** — snap to fixed levels (e.g. *5 steps* → 0 · 25 · 50 · 75 · 100)
- **Launch at login** (via `SMAppService`).
- Tracks the current output device and follows device switches.

## Requirements

- macOS 26.0+
- Swift 6 toolchain (Xcode 26 or the matching Command Line Tools)

## Build & run

```bash
./build.sh          # compiles + assembles TuneBar.app
open TuneBar.app    # launches it (look for the slider in your menu bar)
```

Install it permanently:

```bash
cp -R TuneBar.app /Applications/
```

## Packaging a DMG

```bash
./build.sh        # build the app
./make_dmg.sh     # produces TuneBar-1.0.dmg (app + Applications shortcut)
```

The app icon is generated from `Scripts/makeicon.swift` into
`Resources/AppIcon.icns` (rounded macOS squircle).

> **Gatekeeper:** the build is ad-hoc signed, not notarized. Running it
> straight from the mounted DMG (a local file) works. If macOS blocks it with
> *"cannot be opened because Apple cannot check it,"* right-click the app →
> **Open** once, or run `xattr -dr com.apple.quarantine /Applications/TuneBar.app`.

> Launch-at-login works most reliably when the app lives in `/Applications`
> and has been opened once. For ad-hoc dev builds you may need to approve it
> under **System Settings → General → Login Items**.

## Project layout

| File | Role |
|------|------|
| `AudioController.swift` | CoreAudio read/write of volume + mute, change listeners |
| `Preferences.swift` | `UserDefaults`-backed settings, step snapping |
| `MenuSliderView.swift` | The SwiftUI control shown in the menu bar |
| `MenuBarController.swift` | `NSStatusItem` host, scroll + right-click handling |
| `SettingsView.swift` | Settings window (SwiftUI) |
| `LaunchAtLogin.swift` | `SMAppService` login-item toggle |
| `AppDelegate.swift` / `main.swift` | Agent (`LSUIElement`) app entry point |

## License

MIT
