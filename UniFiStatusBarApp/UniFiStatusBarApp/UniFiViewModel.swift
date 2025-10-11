import SwiftUI
import Combine

enum UniFiMode {
    case controller
}

@MainActor
final class UniFiViewModel: ObservableObject {
    @Published var apiKey: String = ""
    @Published var hasApiKey = false
    @Published var controllerStatus: GatewayStatus?
    @Published var controllerIP: String = ""
    @Published var errorMessage: String?
    
    private var controllerManager: UniFiControllerStatusManager!
    private let serviceManager = ServiceManager()
    private var refreshTimer: Timer?

    init() {
        serviceManager.load()
        let detected = detectGatewayIP() ?? ""
        let cleanedIP = detected
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "\n", with: "")
            .replacingOccurrences(of: "\r", with: "")

        let finalIP = cleanedIP.isEmpty ? "192.168.1.1" : cleanedIP
        print("🌐 Using UniFi Controller at:", finalIP)
        controllerManager = UniFiControllerStatusManager(baseURL: "https://\(finalIP)")
        controllerIP = finalIP

        if let key = serviceManager.config.apiKey, !key.isEmpty {
            apiKey = key
            hasApiKey = true
            Task { await refresh() }

            // 🕒 Auto-Refresh all 2 seconds (Main RunLoop)
            refreshTimer = Timer(timeInterval: 2, repeats: true) { [weak self] _ in
                Task { await self?.refresh() }
            }
            RunLoop.main.add(refreshTimer!, forMode: .common)
        }
    }

    func refresh() async {
        do {
            let healthJson = try await controllerManager.fetchHealth(apiKey: apiKey)
            var summary = "—"
            if let data = healthJson["data"] as? [[String: Any]] {
                let entries = data.compactMap { item -> String? in
                    guard let subsystem = item["subsystem"] as? String,
                          let status = item["status"] as? String else { return nil }
                    return "\(subsystem.uppercased()): \(status)"
                }
                summary = entries.joined(separator: ", ")
            }

            let devices = try await controllerManager.fetchDevices(apiKey: apiKey)
            let clients = try await controllerManager.fetchClients(apiKey: apiKey)

            let deviceSummary = devices.prefix(10).map { d -> String in
                // 🔹 Basic information
                let name = d["name"] as? String ?? "Unknown"
                let model = d["model_inform"] as? String ?? (d["model"] as? String ?? "–")
                let type = d["type"] as? String ?? "-"
                let ip = d["ip"] as? String ?? "–"
                let mac = d["mac"] as? String ?? "-"
                let version = d["version"] as? String ?? "–"
                let state = (d["state"] as? Int) == 1 ? "🟢" : "🔴"
                
                // 🔹 Uptime
                let uptime = d["uptime"] as? Int ?? 0
                let days = uptime / 86400
                let hours = (uptime % 86400) / 3600
                let uptimeText = "\(days)d \(hours)h"
                
                // 🔹 Network
                let numSta = d["num_sta"] as? Int ?? 0

                func num(_ v: Any?) -> Double {
                    if let n = v as? NSNumber { return n.doubleValue }
                    if let s = v as? String, let d = Double(s) { return d }
                    return 0
                }

                let wan1 = d["wan1"] as? [String: Any]
                let isGateway = type == "UGW" || model.contains("UDM") || model.contains("UCG") || model.contains("UXG")

                let txBps = {
                    if let s = wan1, num(s["tx_bytes-r"]) > 0 { return num(s["tx_bytes-r"]) * 8 }
                    if num(d["tx_bytes-r"]) > 0 { return num(d["tx_bytes-r"]) * 8 }
                    if num(d["tx_rate"]) > 0 { return num(d["tx_rate"]) }
                    return 0.0
                }()

                let rxBps = {
                    if let s = wan1, num(s["rx_bytes-r"]) > 0 { return num(s["rx_bytes-r"]) * 8 }
                    if num(d["rx_bytes-r"]) > 0 { return num(d["rx_bytes-r"]) * 8 }
                    if num(d["rx_rate"]) > 0 { return num(d["rx_rate"]) }
                    return 0.0
                }()

                let txText = String(format: "%.1f Mbps", txBps / 1_000_000)
                let rxText = String(format: "%.1f Mbps", rxBps / 1_000_000)
                
                let rateLine: String
                if isGateway {
                    // WAN Upload/Download
                    rateLine = (txBps > 0 || rxBps > 0)
                        ? "📡 Live: ↓ \(rxText) ↑ \(txText)"
                        : ""
                } else {
                    rateLine = ""
                }
                
                let txBytes = (d["tx_bytes"] as? Double ?? 0) / 1_000_000_000
                let rxBytes = (d["rx_bytes"] as? Double ?? 0) / 1_000_000_000
                let txTotal = String(format: "%.2f GB", txBytes)
                let rxTotal = String(format: "%.2f GB", rxBytes)
                
                // 🔹 Uplink-Info (Gateway / Switch)
                let uplink = d["uplink"] as? [String: Any]
                let uplinkName = uplink?["name"] as? String ?? "–"
                let uplinkSpeed = (uplink?["speed"] as? Int).map { "\($0) Mbps" } ?? "–"
                
                // 🔹 PoE & Power
                let poePower = (d["total_max_power"] as? Double)
                let powerSource = d["power_source"] as? String ?? "–"

                let poeInfo: String
                if let power = poePower, power > 0 {
                    poeInfo = "⚡ PoE: \(String(format: "%.0f W", power)) via \(powerSource)\n"
                } else {
                    poeInfo = ""
                }
                
                // 🔹 Miscellaneous
                let serial = d["serial"] as? String ?? "-"
                
                // 🔹 Formatted text output
                return """
                \(state) \(name) (\(model)) [\(type.uppercased())]
                🔢 Serial: \(serial)
                🕒 Uptime: \(uptimeText)
                🌐 IP: \(ip)
                🔢 MAC: \(mac)
                👥 Clients: \(numSta)
                🧩 Version: \(version)
                🔌 Uplink: \(uplinkName) \(uplinkSpeed)
                📊 Total: ↓ \(txTotal) ↑ \(rxTotal)
                \(rateLine)
                \((poePower ?? 0) > 0 ? "\(poeInfo)\n" : "")
                """
            }.joined(separator: "")

            let clientSummary = clients.prefix(15).map { c -> String in
                // 🔹 Basic information
                let name = c["hostname"] as? String ?? "Unknown"
                let ip = c["ip"] as? String ?? "–"
                let mac = c["mac"] as? String ?? "-"
                let essid = c["essid"] as? String ?? "-"
                let apMac = c["ap_mac"] as? String ?? "-"
                let radio = c["radio"] as? String ?? "-"
                let vendor = c["oui"] as? String ?? "-"
                let isWired = (c["is_wired"] as? Bool ?? false)
                let isGuest = (c["is_guest"] as? Bool ?? false)
                let authorized = (c["authorized"] as? Bool ?? true)

                // 🔹 Uptime
                let uptime = c["uptime"] as? Int ?? 0
                let hours = uptime / 3600
                let mins = (uptime % 3600) / 60
                let uptimeText = "\(hours)h \(mins)m"
                let rssi = c["rssi"] as? Int ?? 0
                let signalIcon = rssi > -60 ? "📶" : (rssi > -75 ? "📡" : "📴")

                // 🔹 Network
                func num(_ v: Any?) -> Double {
                    if let n = v as? NSNumber { return n.doubleValue }
                    if let s = v as? String, let d = Double(s) { return d }
                    return 0
                }

                let txBps = {
                    if num(c["tx_bytes-r"]) > 0 { return num(c["tx_bytes-r"]) * 8 }
                    return num(c["tx_rate"])
                }()

                let rxBps = {
                    if num(c["rx_bytes-r"]) > 0 { return num(c["rx_bytes-r"]) * 8 }
                    return num(c["rx_rate"])
                }()

                let txText = String(format: "%.1f Mbps", txBps / 1_000_000)
                let rxText = String(format: "%.1f Mbps", rxBps / 1_000_000)
                
                let txBytes = (c["tx_bytes"] as? Double ?? 0) / 1_000_000_000
                let rxBytes = (c["rx_bytes"] as? Double ?? 0) / 1_000_000_000
                let txTotal = String(format: "%.2f GB", txBytes)
                let rxTotal = String(format: "%.2f GB", rxBytes)

                // 🔹 Auth / Type
                let icon = isWired ? "🔌" : "🛜"
                let guestMark = isGuest ? "🧳 Guest" : ""
                let authMark = authorized ? "✅" : "🚫"

                // 🔹 Formatted text output
                return """
                \(icon) \(name) (\(vendor)) \(guestMark)
                🌐 IP: \(ip)   \(authMark)
                🔢 MAC: \(mac)
                📊 Total: ↓ \(txTotal) ↑ \(rxTotal)
                📡 Live: ↓ \(txText) ↑ \(rxText)
                🕒 Connected: \(uptimeText)
                \((isWired ? "" : "📡 SSID: \(essid) (\(radio.uppercased()))   AP: \(apMac)"))
                \((isWired ? "" : "\(signalIcon) RSSI: \(rssi)dBm\n\n"))
                """
            }.joined(separator: "")


            var status = GatewayStatus()
            status.model = "UniFi Controller"
            status.version = summary
            status.ip = controllerIP
            status.additionalInfo = """
            
            Devices:
            
            \(deviceSummary)
            Clients:
            
            \(clientSummary)
            """
            controllerStatus = status
            errorMessage = nil
        } catch {
            errorMessage = "❌ \(error.localizedDescription)"
        }
    }

    func saveApiKey() {
        serviceManager.config.apiKey = apiKey
        serviceManager.save()
        hasApiKey = !apiKey.isEmpty
    }
}

struct GatewayStatus: Codable {
    var model: String?
    var version: String?
    var ip: String?
    var uptime: Int?
    var additionalInfo: String?
}

// MARK: - 🔍 Automatically detect gateway IP (IPv4 only)
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

