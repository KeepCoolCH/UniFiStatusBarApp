import AppKit
import SwiftUI

final class StatusBarController: NSObject {
    private let statusItem: NSStatusItem
    private let popover: NSPopover

    init(viewModel: UniFiViewModel) {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        popover = NSPopover()
        super.init()

        popover.behavior = .transient
        popover.contentSize = NSSize(width: 300, height: 340)

        let contentView = MenuContentView()
            .environmentObject(viewModel)
            .onAppear {
                NotificationCenter.default.addObserver(forName: .openSettings, object: nil, queue: .main) { _ in
                    openSettingsWindow(viewModel: viewModel)
                }

                if viewModel.apiKey.isEmpty {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        openSettingsWindow(viewModel: viewModel)
                    }
                }
            }
        let hostingView = NSHostingView(rootView: contentView)

        let viewController = NSViewController()
        viewController.view = hostingView
        popover.contentViewController = viewController

        if let button = statusItem.button {
            button.image = NSImage(systemSymbolName: "circle.lefthalf.filled.righthalf.striped.horizontal", accessibilityDescription: "UniFi")
            button.target = self
            button.action = #selector(togglePopover)
        }
    }

    @objc private func togglePopover(_ sender: Any?) {
        guard let button = statusItem.button else { return }
        if popover.isShown {
            popover.performClose(sender)
        } else {
            popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
            NSApp.activate(ignoringOtherApps: true)
        }
    }
}

final class AppState {
    static let shared = AppState()
    let viewModel = UniFiViewModel()
}

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusBarController: StatusBarController?

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
        statusBarController = StatusBarController(viewModel: AppState.shared.viewModel)
    }
}
