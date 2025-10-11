import SwiftUI

struct MenuContentView: View {
    @EnvironmentObject var viewModel: UniFiViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("UniFi UCG Fiber")
                        .font(.headline)
                        .foregroundColor(.primary)
                    Text(viewModel.controllerHost)
                        .font(.caption)
                        .foregroundColor(.primary)
                    if !wanSummaries.isEmpty {
                        ForEach(wanSummaries, id: \.self) { line in
                            Text(line)
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                if viewModel.isRefreshing {
                    ProgressView()
                        .scaleEffect(0.7)
                }
            }
            Divider().padding(.vertical, 4)
            if let error = viewModel.errorMessage {
                Text(error)
                    .foregroundColor(.red)
                    .font(.caption)
            } else {
                HStack(spacing: 10) {
                    Button {
                        viewModel.selectedSection = .devices
                        openMainWindow(viewModel: viewModel)
                    } label: {
                        MenuStatCard(title: "Devices", value: "\(viewModel.devices.count)", tint: Color(red: 0.18, green: 0.78, blue: 0.72))
                    }
                    .buttonStyle(.plain)

                    Button {
                        viewModel.selectedSection = .clients
                        openMainWindow(viewModel: viewModel)
                    } label: {
                        MenuStatCard(title: "Clients", value: "\(viewModel.clients.count)", tint: Color(red: 0.30, green: 0.62, blue: 0.93))
                    }
                    .buttonStyle(.plain)

                    Button {
                        viewModel.selectedSection = .insights
                        openMainWindow(viewModel: viewModel)
                    } label: {
                        MenuStatCard(title: "Insights", value: "\(viewModel.rogueAps.count)", tint: Color(red: 0.95, green: 0.55, blue: 0.35))
                    }
                    .buttonStyle(.plain)
                }
                Divider().padding(.vertical, 4)
                if let last = viewModel.lastRefresh {
                    Text("Updated \(last.formatted(date: .omitted, time: .shortened))")
                        .font(.caption2)
                        .foregroundColor(.primary)
                }
            }

            Divider().padding(.vertical, 4)

            Button {
                openMainWindow(viewModel: viewModel)
            } label: {
                Label("Open Dashboard", systemImage: "rectangle.3.offgrid")
            }
            .buttonStyle(.plain)

            Button {
                Task { await viewModel.refresh() }
            } label: {
                Label("Refresh Now", systemImage: "arrow.clockwise")
            }
            .buttonStyle(.plain)

            Button {
                NotificationCenter.default.post(name: .openSettings, object: nil)
            } label: {
                Label("Settings", systemImage: "gearshape")
            }
            .buttonStyle(.plain)

            Divider().padding(.vertical, 4)

            Button(role: .destructive) {
                NSApplication.shared.terminate(nil)
            } label: {
                Label("Quit", systemImage: "power")
            }
            .buttonStyle(.plain)
        }
        .foregroundStyle(.primary)
        .padding(12)
        .frame(width: 280)
        .onAppear {
            if viewModel.hasApiKey {
                Task { await viewModel.refresh() }
            }
        }
    }

    private var wanSummaries: [String] {
        let isp = viewModel.health.first(where: { ($0.subsystem ?? "").lowercased() == "wan" })
            .flatMap { $0.ispName ?? $0.ispOrganization }

        guard let gateway = viewModel.devices.first(where: { device in
            let modelToken = (device.modelDisplay ?? device.model ?? "").lowercased()
            if modelToken.contains("ucg") { return true }
            return ["udm", "udm-pro", "udm-se", "ugw", "uxg"].contains(device.type ?? "")
        }) else {
            return []
        }

        var entries: [(label: String, ip: String)] = []
        if let wan1 = gateway.wan1 {
            entries.append(("WAN 1", wan1.ip ?? ""))
        }
        if let wan2 = gateway.wan2 {
            entries.append(("WAN 2", wan2.ip ?? ""))
        }
        guard !entries.isEmpty else { return [] }

        return entries.map { entry in
            let ip = entry.ip.isEmpty ? "–" : entry.ip
            let ispValue = isp ?? ""
            if !ispValue.isEmpty {
                return "\(entry.label): \(ip) • \(ispValue)"
            }
            return "\(entry.label): \(ip)"
        }
    }
}

struct MenuStatCard: View {
    let title: String
    let value: String
    let tint: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(.caption2)
                .foregroundColor(.white.opacity(0.9))
            Text(value)
                .font(.system(size: 16, weight: .bold, design: .rounded))
                .foregroundColor(.white)
        }
        .padding(.vertical, 6)
        .padding(.horizontal, 8)
        .background(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(tint.gradient)
        )
    }
}
