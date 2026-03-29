import SwiftUI

@main
struct RedAlertMonitorApp: App {
    @StateObject private var monitor = AlertMonitorService()

    init() {
        // Quit immediately if another instance is already running
        let bundleID = Bundle.main.bundleIdentifier ?? "com.redalertmonitor.app"
        let running = NSRunningApplication.runningApplications(withBundleIdentifier: bundleID)
        if running.count > 1 {
            NSApplication.shared.terminate(nil)
        }
    }

    var body: some Scene {
        MenuBarExtra {
            AppMenuView()
                .environmentObject(monitor)
        } label: {
            MenuBarIconView(isAlerting: monitor.isAlerting, frame: monitor.animationFrame, pulseFrame: monitor.pulseFrame)
        }
        .menuBarExtraStyle(.menu)
    }
}

// MARK: - Menu bar icon (animated during alert)

struct MenuBarIconView: View {
    let isAlerting: Bool
    let frame: Int
    let pulseFrame: Int

    private let alertSymbols = [
        "exclamationmark.triangle.fill",
        "flame.fill",
        "exclamationmark.triangle.fill",
        "flame.fill",
    ]
    private let alertNSColors: [NSColor] = [.red, .orange, .yellow, .orange]

    private let pulseNSColors: [NSColor] = [
        NSColor(hue: 0.38, saturation: 1.0, brightness: 0.85, alpha: 1), // green
        NSColor(hue: 0.44, saturation: 0.9, brightness: 1.00, alpha: 1), // lime
        NSColor(hue: 0.50, saturation: 1.0, brightness: 0.90, alpha: 1), // teal
    ]

    var body: some View {
        if isAlerting {
            let idx = frame % alertSymbols.count
            Image(nsImage: coloredSymbol(alertSymbols[idx], color: alertNSColors[idx % alertNSColors.count]))
        } else if pulseFrame >= 0 && pulseFrame % 2 == 0 {
            let colorIdx = (pulseFrame / 2) % pulseNSColors.count
            Image(nsImage: coloredSymbol("dot.radiowaves.left.and.right", color: pulseNSColors[colorIdx]))
        } else {
            // Normal / off-frame — let system color it as template
            Image(systemName: "antenna.radiowaves.left.and.right")
                .imageScale(.medium)
        }
    }

    /// Renders an SF Symbol into a bitmap NSImage tinted with `color`.
    /// Sets isTemplate = false so macOS preserves the color in the menu bar.
    private func coloredSymbol(_ name: String, color: NSColor, pointSize: CGFloat = 16) -> NSImage {
        let config = NSImage.SymbolConfiguration(pointSize: pointSize, weight: .medium)
        guard let base = NSImage(systemSymbolName: name, accessibilityDescription: nil)?
                .withSymbolConfiguration(config) else { return NSImage() }

        let result = NSImage(size: base.size, flipped: false) { rect in
            base.draw(in: rect)
            color.setFill()
            rect.fill(using: .sourceAtop)
            return true
        }
        result.isTemplate = false
        return result
    }
}

// MARK: - Dropdown menu content

struct AppMenuView: View {
    @EnvironmentObject var monitor: AlertMonitorService

    var body: some View {
        // Alert section (shown only when active)
        if monitor.isAlerting {
            Text(monitor.isSilentAlert ? "⚠️ ALERT OUTSIDE YOUR AREA" : "⚠️ MISSILE ALERT DETECTED")

            if !monitor.alertLocations.isEmpty {
                Divider()
                ForEach(Array(monitor.alertLocations.prefix(10)), id: \.self) { location in
                    Text("  \(location)")
                }
                if monitor.alertLocations.count > 10 {
                    Text("  ...and \(monitor.alertLocations.count - 10) more areas")
                }
            }

            Divider()

            if !monitor.isSilentAlert {
                Button("Stop Sound") {
                    SoundManager.shared.stop()
                }
            }

            Button("Dismiss Alert") {
                monitor.dismissAlert()
            }

            Divider()
        }

        // Status
        Text(monitor.statusText)
        if let date = monitor.lastCheckDate {
            Text("Last check: \(date.formatted(date: .omitted, time: .shortened))")
        }

        Divider()

        Button("Test Demo Mode") {
            monitor.enableDemoMode()
        }

        Divider()

        Button("Settings...") {
            SettingsWindowManager.shared.show(monitor: monitor)
        }

        Button("Quit") {
            NSApplication.shared.terminate(nil)
        }
    }

}
