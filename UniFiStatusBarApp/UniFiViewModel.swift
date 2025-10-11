import SwiftUI
import Foundation
import Combine

enum SidebarSection: String, CaseIterable, Identifiable {
    case overview = "Overview"
    case devices = "Devices"
    case topology = "Topology"
    case clients = "Clients"
    case networks = "Networks"
    case wlans = "Wi-Fi"
    case traffic = "Traffic"
    case speedtests = "Speed Tests"
    case insights = "Insights"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .overview: return "gauge.with.dots.needle.50percent"
        case .devices: return "server.rack"
        case .topology: return "point.3.connected.trianglepath.dotted"
        case .clients: return "laptopcomputer.and.iphone"
        case .networks: return "point.3.connected.trianglepath.dotted"
        case .wlans: return "wifi"
        case .traffic: return "chart.line.uptrend.xyaxis"
        case .speedtests: return "speedometer"
        case .insights: return "exclamationmark.triangle"
        }
    }
}

@MainActor
final class UniFiViewModel: ObservableObject {
    @Published var apiKey: String = ""
    @Published var controllerHost: String = ""
    @Published var hasApiKey: Bool = false
    @Published var selectedSection: SidebarSection = .overview

    @Published var health: [SiteHealth] = []
    @Published var devices: [UniFiDevice] = []
    @Published var clients: [UniFiClient] = []
    @Published var networks: [UniFiNetwork] = []
    @Published var wlans: [UniFiWLAN] = []
    @Published var trafficReports: [TrafficReport] = []
    @Published var speedTests: [SpeedTestResult] = []
    @Published var speedTestStatus: [SpeedTestStatus] = []
    @Published var rogueAps: [RogueAP] = []
    @Published var systemInfo: SystemInfo?

    @Published var errorMessage: String?
    @Published var lastRefresh: Date?
    @Published var isRefreshing: Bool = false
    @Published var isSpeedTestRunning: Bool = false
    @Published var speedTestMessage: String?

    private let serviceManager = ServiceManager()
    private var controllerManager: UniFiControllerStatusManager
    private var refreshTask: Task<Void, Never>?
    private let refreshInterval: TimeInterval = 10

    init() {
        serviceManager.load()

        let detected = detectGatewayIP() ?? ""
        let cleanedIP = detected
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "\n", with: "")
            .replacingOccurrences(of: "\r", with: "")

        let defaultHost = cleanedIP.isEmpty ? "192.168.1.1" : cleanedIP
        let savedHost = serviceManager.config.controllerHost
        let host = (savedHost?.isEmpty == false) ? (savedHost ?? defaultHost) : defaultHost

        controllerManager = UniFiControllerStatusManager(baseURL: "https://\(host)")
        controllerHost = host

        if let key = serviceManager.loadApiKey(), !key.isEmpty {
            apiKey = key
            hasApiKey = true
            startAutoRefresh()
        }
    }

    func refresh() async {
        guard !apiKey.isEmpty else { return }
        isRefreshing = true
        errorMessage = nil

        controllerManager.updateBaseURL("https://\(controllerHost)")

        async let healthTask = controllerManager.fetchHealth(apiKey: apiKey)
        async let devicesTask = controllerManager.fetchDevices(apiKey: apiKey)
        async let clientsTask = controllerManager.fetchClients(apiKey: apiKey)
        async let networksTask = controllerManager.fetchNetworks(apiKey: apiKey)
        async let wlansTask = controllerManager.fetchWLANs(apiKey: apiKey)
        async let trafficTask = controllerManager.fetchTrafficReports(apiKey: apiKey)
        async let speedTask = controllerManager.fetchSpeedTests(apiKey: apiKey)
        async let speedStatusTask = controllerManager.fetchSpeedTestStatus(apiKey: apiKey)
        async let rogueTask = controllerManager.fetchRogueAps(apiKey: apiKey)
        async let systemTask = controllerManager.fetchSystemInfo(apiKey: apiKey)

        var anySuccess = false

        if let value = try? await healthTask { health = value; anySuccess = true }
        if let value = try? await devicesTask { devices = value; anySuccess = true }
        if let value = try? await clientsTask { clients = value; anySuccess = true }
        if let value = try? await networksTask { networks = value; anySuccess = true }
        if let value = try? await wlansTask { wlans = value; anySuccess = true }
        if let value = try? await trafficTask { trafficReports = value; anySuccess = true }
        if let value = try? await speedTask { speedTests = value; anySuccess = true }
        if let value = try? await speedStatusTask { speedTestStatus = value; anySuccess = true }

        if speedTests.isEmpty, !speedTestStatus.isEmpty {
            speedTestMessage = "Speed test status available, waiting for results…"
        }
        if let value = try? await rogueTask { rogueAps = value; anySuccess = true }
        if let value = try? await systemTask { systemInfo = value; anySuccess = true }

        if !anySuccess {
            errorMessage = "❌ API request failed. Check API key and controller host."
        } else {
            lastRefresh = Date()
        }

        isRefreshing = false
    }

    func startAutoRefresh() {
        refreshTask?.cancel()
        refreshTask = Task { [weak self] in
            guard let self else { return }
            while !Task.isCancelled {
                await self.refresh()
                let ns = UInt64(self.refreshInterval * 1_000_000_000)
                try? await Task.sleep(nanoseconds: ns)
            }
        }
    }

    func stopAutoRefresh() {
        refreshTask?.cancel()
        refreshTask = nil
    }

    func saveApiKey() {
        serviceManager.saveApiKey(apiKey)
        hasApiKey = !apiKey.isEmpty
        serviceManager.save()
        if hasApiKey {
            startAutoRefresh()
        } else {
            stopAutoRefresh()
        }
    }

    func saveControllerHost() {
        serviceManager.config.controllerHost = controllerHost
        serviceManager.save()
    }

    func runSpeedTest() async {
        guard !apiKey.isEmpty else { return }
        isSpeedTestRunning = true
        speedTestMessage = "Starting speed test…"

        do {
            try await controllerManager.startSpeedTest(apiKey: apiKey)
            speedTestMessage = "Speed test started. Results will appear shortly."

            Task {
                try? await Task.sleep(nanoseconds: 10_000_000_000)
                await refresh()
                try? await Task.sleep(nanoseconds: 20_000_000_000)
                await refresh()
            }
        } catch {
            speedTestMessage = "Speed test failed to start."
        }

        isSpeedTestRunning = false
    }
}

// MARK: - Automatically detect gateway IP (IPv4 only)
func detectGatewayIP() -> String? {
    let cmds = [
        "/usr/sbin/netstat -rn | grep '^default' | awk '{print $2}' | grep -Eo '([0-9]{1,3}\\.){3}[0-9]{1,3}' | head -n1",
        "/usr/sbin/route -n get default | grep 'gateway' | awk '{print $2}' | grep -Eo '([0-9]{1,3}\\.){3}[0-9]{1,3}' | head -n1"
    ]

    for cmd in cmds {
        let task = Process()
        task.launchPath = "/bin/zsh"
        task.arguments = ["-c", cmd]

        let pipe = Pipe()
        task.standardOutput = pipe
        task.standardError = pipe

        do {
            try task.run()
            task.waitUntilExit()
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            if let output = String(data: data, encoding: .utf8)?
                .trimmingCharacters(in: .whitespacesAndNewlines),
               !output.isEmpty {
                print("🧭 Detected IPv4 Gateway:", output)
                return output
            }
        } catch {
            continue
        }
    }
    return nil
}
