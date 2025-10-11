import SwiftUI

var activeSettingsWindow: NSWindow? = nil

func openSettingsWindow(viewModel: UniFiViewModel) {

    if let existing = activeSettingsWindow {
        existing.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
        return
    }

    let settingsWindow = NSWindow(
        contentRect: NSRect(x: 0, y: 0, width: 420, height: 240),
        styleMask: [.titled, .closable],
        backing: .buffered,
        defer: false
    )
    settingsWindow.center()
    settingsWindow.title = "UniFi Settings"
    settingsWindow.isReleasedWhenClosed = false

    let content = SettingsView()
        .environmentObject(viewModel)
    settingsWindow.contentView = NSHostingView(rootView: content)

    settingsWindow.makeKeyAndOrderFront(nil)
    NSApp.activate(ignoringOtherApps: true)

    activeSettingsWindow = settingsWindow

    NotificationCenter.default.addObserver(forName: NSWindow.willCloseNotification, object: settingsWindow, queue: .main) { _ in
        activeSettingsWindow = nil
    }
}

func closeSettingsWindow() {
    activeSettingsWindow?.close()
    activeSettingsWindow = nil
}
