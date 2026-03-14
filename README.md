# 🚨 Red Alert Monitor

A macOS menu bar app that monitors the Israel Home Front Command (Pikud HaOref) API for incoming missile alerts and instantly notifies you with sound, animation, and a macOS notification banner.

![macOS](https://img.shields.io/badge/macOS-13%2B-blue?logo=apple)
![Swift](https://img.shields.io/badge/Swift-5.9-orange?logo=swift)
![License](https://img.shields.io/badge/license-MIT-green)

---

## How it works

The app polls the official Pikud HaOref API every 30 or 60 seconds (configurable):

```
https://www.oref.org.il/warningMessages/alert/History/AlertsHistory.json
```

An alert is triggered when the response contains events with the title:

> **"בדקות הקרובות צפויות להתקבל התרעות באזורך"**
> *(In the coming minutes, alerts are expected in your area)*

…that occurred within the **last 5 minutes**, and haven't been seen before (deduplication by timestamp).

---

## Features

- **Lives in the menu bar** — no Dock icon, always running quietly in the background
- **Animated alert icon** — cycles red → orange → yellow flame/triangle when a threat is detected
- **Pulse on every check** — the antenna icon flashes green 3× after each successful API poll so you can see the app is alive
- **Sound alert** — plays a system sound (configurable) up to 5 times; supports custom audio files
- **macOS notification** — fires a banner notification with the affected area names
- **Smart deduplication** — won't re-alert for the same attack event on subsequent polls
- **Auto-dismiss** — alert clears automatically after 5 minutes
- **Demo mode** — test the full alert flow offline using a local JSON file

---

## Requirements

- macOS 13 (Ventura) or later
- Xcode Command Line Tools or full Xcode (for `swift build`)

---

## Build & Run

```bash
# Clone
git clone https://github.com/jazzyjester/RedAlertMonitor.git
cd RedAlertMonitor

# Debug build — compiles and opens the app
make debug

# Release build
make app

# Install to /Applications
make install

# Clean
make clean
```

The Makefile assembles a proper `.app` bundle (with `Info.plist` and `AppIcon.icns`) from the SPM-built executable.

---

## Settings

Click the menu bar icon → **Settings…**

| Setting | Options |
|---|---|
| Check interval | 30 seconds / 60 seconds |
| Alert sound | Basso, Funk, Hero, Sosumi, or custom file |

---

## Demo mode

Place `demo_alert.json` next to the `.app` bundle, then click **Test Demo Mode** in the menu. The app will parse the file and trigger a full alert (sound, animation, notification) without hitting the live API.

A sample `demo_alert.json` is included in the repository.

---

## Project structure

```
RedAlertMonitor/
├── Package.swift                          # SPM manifest (macOS 13+)
├── Makefile                               # build / bundle / install
├── make_icon.swift                        # generates AppIcon.icns
├── demo_alert.json                        # sample alert payload
└── Sources/RedAlertMonitor/
    ├── RedAlertMonitorApp.swift           # @main, MenuBarExtra, icon animation
    ├── AlertMonitorService.swift          # polling, detection, notification
    ├── SoundManager.swift                 # NSSound playback with repeat
    ├── SettingsView.swift                 # settings UI (SwiftUI)
    ├── SettingsWindowManager.swift        # opens settings window (LSUIElement safe)
    ├── Models.swift                       # AlertItem codable struct
    └── Resources/
        └── Info.plist                     # LSUIElement, icon, ATS config
```

---

## Data source

All alert data comes from the **Israel Home Front Command** official public API.
This app is an independent project and is not affiliated with or endorsed by the IDF or any government body.

---

## License

MIT — free to use, modify, and distribute.

---

*Stay safe. 🛡️*
