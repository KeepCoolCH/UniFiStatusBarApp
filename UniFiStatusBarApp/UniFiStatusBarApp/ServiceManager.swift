import SwiftUI
import Combine
import Foundation

struct UniFiServiceConfig: Codable {
    var clientId: String = UUID().uuidString
    var clientName: String = Host.current().localizedName ?? "Mac"
    var apiKey: String? = nil
}

@MainActor
final class ServiceManager: ObservableObject {
    @Published var config = UniFiServiceConfig()

    // Dynamischer Speicherort
    private var configURL: URL {
        #if DEBUG
        // 🧠 Im Debug-Build: Auf Desktop speichern (sichtbar und sicher)
        return FileManager.default
            .homeDirectoryForCurrentUser
            .appendingPathComponent("Desktop/UniFiStatusBar_service.json")
        #else
        // 🚀 Im Release-Build: In Application Support
        return FileManager.default
            .urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("UniFiStatusBar/service.json")
        #endif
    }

    func load() {
        do {
            let path = configURL.path
            print("📂 Loading config from:", path)

            if FileManager.default.fileExists(atPath: path) {
                let data = try Data(contentsOf: configURL)
                config = try JSONDecoder().decode(UniFiServiceConfig.self, from: data)
                print("✅ Loaded config:", config)
            } else {
                print("⚠️ No config file found, using defaults.")
            }
        } catch {
            print("❌ Failed to load config:", error.localizedDescription)
        }
    }

    func save() {
        let dir = configURL.deletingLastPathComponent()

        do {
            print("💾 Saving config to:", configURL.path)

            try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)

            let data = try JSONEncoder().encode(config)
            try data.write(to: configURL, options: .atomic)

            print("✅ Config saved successfully!")

        } catch {
            print("❌ Failed to save config:", error.localizedDescription)
        }
    }
}

