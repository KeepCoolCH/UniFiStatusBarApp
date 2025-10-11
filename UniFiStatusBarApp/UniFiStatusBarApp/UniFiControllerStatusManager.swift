import Foundation

actor UniFiControllerStatusManager: NSObject, URLSessionDelegate {
    private var baseURL: String

    init(baseURL: String) {
        self.baseURL = baseURL
    }

    // MARK: - 🔹 Fetch Health
    func fetchHealth(apiKey: String) async throws -> [String: Any] {
        guard let url = URL(string: "\(baseURL)/proxy/network/api/s/default/stat/health") else {
            print("❌ Invalid URL from baseURL:", baseURL)
            throw URLError(.badURL)
        }
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue(apiKey, forHTTPHeaderField: "X-API-KEY")

        let session = URLSession(configuration: .default, delegate: self, delegateQueue: nil)
        let (data, response) = try await session.data(for: request)

        if let http = response as? HTTPURLResponse {
            print("📡 Health API:", http.statusCode)
            guard (200..<300).contains(http.statusCode) else { throw URLError(.badServerResponse) }
        }

        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            let raw = String(data: data, encoding: .utf8) ?? "nil"
            print("⚠️ Health JSON parse failed:\n\(raw)")
            throw URLError(.cannotParseResponse)
        }

        return json
    }

    // MARK: - 🔹 Fetch Devices
    func fetchDevices(apiKey: String) async throws -> [[String: Any]] {
        guard let url = URL(string: "\(baseURL)/proxy/network/api/s/default/stat/device")?
                .standardized,
              url.scheme?.hasPrefix("http") == true else {
            print("❌ Invalid baseURL:", baseURL)
            throw URLError(.badURL)
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue(apiKey, forHTTPHeaderField: "X-API-KEY")

        let session = URLSession(configuration: .default, delegate: self, delegateQueue: nil)
        let (data, response) = try await session.data(for: request)

        if let http = response as? HTTPURLResponse {
            print("📡 Devices API:", http.statusCode)
            guard (200..<300).contains(http.statusCode) else { throw URLError(.badServerResponse) }
        }

        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let devices = json["data"] as? [[String: Any]] else {
            throw URLError(.cannotParseResponse)
        }

        print("📶 Found \(devices.count) devices")
        return devices
    }

    // MARK: - 🔹 Fetch Clients
    func fetchClients(apiKey: String) async throws -> [[String: Any]] {
        guard let url = URL(string: "\(baseURL)/proxy/network/api/s/default/stat/sta")?
                    .standardized,
                  url.scheme?.hasPrefix("http") == true else {
                print("❌ Invalid baseURL:", baseURL)
                throw URLError(.badURL)
            }
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue(apiKey, forHTTPHeaderField: "X-API-KEY")

        let session = URLSession(configuration: .default, delegate: self, delegateQueue: nil)
        let (data, response) = try await session.data(for: request)

        if let http = response as? HTTPURLResponse {
            print("📡 Clients API:", http.statusCode)
            guard (200..<300).contains(http.statusCode) else { throw URLError(.badServerResponse) }
        }

        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let clients = json["data"] as? [[String: Any]] else {
            throw URLError(.cannotParseResponse)
        }

        print("👥 Found \(clients.count) clients")
        return clients
    }

    // MARK: - 🔹 Allow self-signed TLS
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
