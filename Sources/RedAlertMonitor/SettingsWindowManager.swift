import AppKit
import SwiftUI

/// Opens (or focuses) a standalone settings window.
/// Used instead of the SwiftUI `Settings` scene, which requires a standard
/// menu bar — unavailable in LSUIElement (menu-bar-only) apps.
class SettingsWindowManager {
    static let shared = SettingsWindowManager()

    private var window: NSWindow?

    func show(monitor: AlertMonitorService) {
        if let existing = window, existing.isVisible {
            existing.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            return
        }

        let view = SettingsView().environmentObject(monitor)
        let controller = NSHostingController(rootView: view)

        let win = NSWindow(contentViewController: controller)
        win.title = "Settings"
        win.styleMask = [.titled, .closable]
        win.isReleasedWhenClosed = false
        win.level = .floating
        win.setContentSize(NSSize(width: 440, height: 680))
        win.center()
        self.window = win

        // Small delay so the menu fully closes before we steal focus
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
            win.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
        }
    }
}
