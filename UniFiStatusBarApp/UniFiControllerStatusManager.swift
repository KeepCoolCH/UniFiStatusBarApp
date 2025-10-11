import Foundation

@MainActor
final class UniFiControllerStatusManager: NSObject, URLSessionDelegate {
    private var baseURL: String

    init(baseURL: String) {
        self.baseURL = baseURL
    }

    func updateBaseURL(_ baseURL: String) {
        self.baseURL = baseURL
    }

    func fetchHealth(apiKey: String) async throws -> [SiteHealth] {
        try await requestList(path: "/proxy/network/api/s/default/stat/health", apiKey: apiKey)
    }

    func fetchDevices(apiKey: String) async throws -> [UniFiDevice] {
        try await requestList(path: "/proxy/network/api/s/default/stat/device", apiKey: apiKey)
    }

    func fetchClients(apiKey: String) async throws -> [UniFiClient] {
        try await requestList(path: "/proxy/network/api/s/default/stat/sta", apiKey: apiKey)
    }


    func fetchNetworks(apiKey: String) async throws -> [UniFiNetwork] {
        try await requestList(path: "/proxy/network/api/s/default/list/networkconf", apiKey: apiKey)
    }

    func fetchWLANs(apiKey: String) async throws -> [UniFiWLAN] {
        try await requestList(path: "/proxy/network/api/s/default/list/wlanconf", apiKey: apiKey)
    }

    func fetchTrafficReports(apiKey: String) async throws -> [TrafficReport] {
        try await requestList(path: "/proxy/network/api/s/default/stat/report/5minutes", apiKey: apiKey)
    }

    func fetchSpeedTests(apiKey: String) async throws -> [SpeedTestResult] {
        let paths = [
            "/proxy/network/api/s/default/stat/speedtest",
            "/proxy/network/api/s/default/stat/ipspeedtest",
            "/proxy/network/api/s/default/stat/speedtest/latest"
        ]

        for path in paths {
            if let result: [SpeedTestResult] = try? await requestList(path: path, apiKey: apiKey) {
                if !result.isEmpty { return result }
            }
        }

        return []
    }

    func startSpeedTest(apiKey: String) async throws {
        let payload = try JSONSerialization.data(withJSONObject: ["cmd": "speedtest"], options: [])
        do {
            _ = try await requestData(path: "/proxy/network/api/s/default/cmd/devmgr", apiKey: apiKey, method: "POST", body: payload)
        } catch {
            _ = try await requestData(path: "/proxy/network/api/s/default/cmd/speedtest", apiKey: apiKey, method: "POST", body: payload)
        }
    }

    func fetchSpeedTestStatus(apiKey: String) async throws -> [SpeedTestStatus] {
        let payload = try JSONSerialization.data(withJSONObject: ["cmd": "speedtest-status"], options: [])
        let endpoints = [
            "/proxy/network/api/s/default/cmd/devmgr",
            "/proxy/network/api/s/default/cmd/speedtest"
        ]

        for endpoint in endpoints {
            if let data = try? await requestData(path: endpoint, apiKey: apiKey, method: "POST", body: payload),
               let response = try? JSONDecoder().decode(UniFiResponse<SpeedTestStatus>.self, from: data) {
                if !response.data.isEmpty { return response.data }
            }
        }

        return []
    }


    func fetchRogueAps(apiKey: String) async throws -> [RogueAP] {
        try await requestList(path: "/proxy/network/api/s/default/stat/rogueap", apiKey: apiKey)
    }

    func fetchSystemInfo(apiKey: String) async throws -> SystemInfo? {
        let data = try await requestData(path: "/proxy/network/api/s/default/stat/sysinfo", apiKey: apiKey)
        if let response = try? JSONDecoder().decode(UniFiResponse<SystemInfo>.self, from: data) {
            return response.data.first
        }
        if let direct = try? JSONDecoder().decode(SystemInfo.self, from: data) {
            return direct
        }
        return nil
    }

    private func requestList<T: Decodable>(path: String, apiKey: String) async throws -> [T] {
        let data = try await requestData(path: path, apiKey: apiKey)
        let response = try JSONDecoder().decode(UniFiResponse<T>.self, from: data)
        return response.data
    }

    private func requestData(path: String, apiKey: String, method: String = "GET", body: Data? = nil) async throws -> Data {
        guard let url = URL(string: "\(baseURL)\(path)")?.standardized,
              url.scheme?.hasPrefix("http") == true else {
            print("❌ Invalid baseURL:", baseURL)
            throw URLError(.badURL)
        }

        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue(apiKey, forHTTPHeaderField: "X-API-KEY")
        if let body {
            request.httpBody = body
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        }

        let session = URLSession(configuration: .default, delegate: self, delegateQueue: nil)
        let (data, response) = try await session.data(for: request)

        if let http = response as? HTTPURLResponse {
            print("📡 API \(path):", http.statusCode)
            guard (200..<300).contains(http.statusCode) else { throw URLError(.badServerResponse) }
        }

        return data
    }

    // MARK: - Allow self-signed TLS
    nonisolated func urlSession(_ session: URLSession,
                                didReceive challenge: URLAuthenticationChallenge,
                                completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        if let trust = challenge.protectionSpace.serverTrust {
            completionHandler(.useCredential, URLCredential(trust: trust))
        } else {
            completionHandler(.performDefaultHandling, nil)
        }
    }
}
