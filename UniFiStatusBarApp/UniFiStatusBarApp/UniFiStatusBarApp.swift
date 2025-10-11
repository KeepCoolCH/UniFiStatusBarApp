import SwiftUI

@main
struct UniFiStatusBarApp: App {
    @StateObject private var viewModel = UniFiViewModel()

    var body: some Scene {
        MenuBarExtra("UniFi", systemImage: "circle.lefthalf.filled.righthalf.striped.horizontal") {
            MenuContentView()
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
        }
    }
}

extension Notification.Name {
    static let openSettings = Notification.Name("openSettings")
}
