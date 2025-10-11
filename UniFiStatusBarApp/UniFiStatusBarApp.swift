import SwiftUI

@main
struct UniFiStatusBarApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    var body: some Scene {
        Settings {
            EmptyView()
        }
    }
}

extension Notification.Name {
    static let openSettings = Notification.Name("openSettings")
}
