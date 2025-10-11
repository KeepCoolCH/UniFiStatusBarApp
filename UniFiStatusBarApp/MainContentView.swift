import SwiftUI

private func formatUptime(_ seconds: Int?) -> String {
    let total = max(seconds ?? 0, 0)
    let days = total / 86_400
    let hours = (total % 86_400) / 3_600
    if days > 0 {
        return "\(days)d \(hours)h"
    }
    let minutes = (total % 3_600) / 60
    return "\(hours)h \(minutes)m"
}

private func formatMbps(_ value: Double?) -> String {
    let speed = max(value ?? 0, 0)
    if speed >= 1_000_000 {
        return String(format: "%.1f Gb/s", speed / 1_000_000)
    }
    return String(format: "%.1f Mb/s", speed)
}

private func formatPing(_ value: Double?) -> String {
    let ping = max(value ?? 0, 0)
    return String(format: "%.0f ms", ping)
}

struct MainContentView: View {
    @EnvironmentObject var viewModel: UniFiViewModel

    @State private var deviceFilter: String = ""
    @State private var clientFilter: String = ""

    @State private var selectedDevice: UniFiDevice?
    @State private var selectedClient: UniFiClient?
    @State private var selectedNetwork: UniFiNetwork?
    @State private var selectedWlan: UniFiWLAN?
    @State private var selectedTraffic: TrafficReport?
    @State private var selectedSpeedTest: SpeedTestResult?
    @State private var selectedRogue: RogueAP?

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color(red: 0.92, green: 0.95, blue: 0.98), Color(red: 0.84, green: 0.90, blue: 0.96)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            NavigationSplitView {
                List(SidebarSection.allCases, selection: $viewModel.selectedSection) { section in
                    Label(section.rawValue, systemImage: section.icon)
                        .font(.system(size: 13, weight: .semibold))
                        .tag(section)
                }
                .navigationTitle("UniFi")
                .listStyle(.sidebar)
            } detail: {
                detailView
                    .toolbar {
                        ToolbarItemGroup(placement: .automatic) {
                            Button {
                                Task { await viewModel.refresh() }
                            } label: {
                                Label("Refresh", systemImage: "arrow.clockwise")
                            }

                            Button {
                                openSettingsWindow(viewModel: viewModel)
                            } label: {
                                Label("Settings", systemImage: "gearshape")
                            }
                        }
                    }
            }
            .sheet(item: $selectedDevice) { device in
                DeviceDetailView(device: device)
            }
            .sheet(item: $selectedClient) { client in
                ClientDetailView(client: client)
            }
            .sheet(item: $selectedNetwork) { network in
                NetworkDetailView(network: network)
            }
            .sheet(item: $selectedWlan) { wlan in
                WlanDetailView(wlan: wlan)
            }
            .sheet(item: $selectedTraffic) { report in
                TrafficDetailView(report: report)
            }
            .sheet(item: $selectedSpeedTest) { test in
                SpeedTestDetailView(test: test)
            }
            .sheet(item: $selectedRogue) { rogue in
                RogueDetailView(rogue: rogue)
            }
        }
    }

    @ViewBuilder
    private var detailView: some View {
        switch viewModel.selectedSection {
        case .overview:
            overviewView
        case .devices:
            devicesView
        case .topology:
            topologyView
        case .clients:
            clientsView
        case .networks:
            networksView
        case .wlans:
            wlansView
        case .traffic:
            trafficView
        case .speedtests:
            speedTestsView
        case .insights:
            insightsView
        }
    }

    private var overviewView: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                headerBlock

                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 14) {
                    Button {
                        viewModel.selectedSection = .devices
                    } label: {
                        StatsCard(title: "Devices", value: "\(viewModel.devices.count)", subtitle: onlineCount(viewModel.devices), tint: Color(red: 0.18, green: 0.78, blue: 0.72))
                    }
                    .buttonStyle(.plain)

                    Button {
                        viewModel.selectedSection = .clients
                    } label: {
                        StatsCard(title: "Clients", value: "\(viewModel.clients.count)", subtitle: guestCount(viewModel.clients), tint: Color(red: 0.30, green: 0.62, blue: 0.93))
                    }
                    .buttonStyle(.plain)

                    Button {
                        viewModel.selectedSection = .insights
                    } label: {
                        StatsCard(title: "Insights", value: "\(viewModel.rogueAps.count)", subtitle: "Rogue APs", tint: Color(red: 0.95, green: 0.55, blue: 0.35))
                    }
                    .buttonStyle(.plain)
                }

                GroupBox(label: sectionTitle("Health")) {
                    if viewModel.health.isEmpty {
                        emptyState("No health data")
                    } else {
                        LazyVGrid(columns: [GridItem(.adaptive(minimum: 140), alignment: .leading)], spacing: 8) {
                            ForEach(viewModel.health) { item in
                                HealthPill(title: item.subsystem ?? "Unknown", status: item.status ?? "unknown")
                            }
                        }
                        .padding(.top, 6)
                    }
                }

                GroupBox(label: sectionTitle("Top Devices")) {
                    if viewModel.devices.isEmpty {
                        emptyState("No devices found")
                    } else {
                        VStack(spacing: 10) {
                            ForEach(viewModel.devices.prefix(6)) { device in
                                Button {
                                    selectedDevice = device
                                } label: {
                                    DeviceRow(device: device)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.top, 6)
                    }
                }

                GroupBox(label: sectionTitle("Top Clients")) {
                    if viewModel.clients.isEmpty {
                        emptyState("No clients found")
                    } else {
                        VStack(spacing: 10) {
                            ForEach(viewModel.clients.prefix(6)) { client in
                                Button {
                                    selectedClient = client
                                } label: {
                                    ClientRow(client: client)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.top, 6)
                    }
                }
            }
            .padding(24)
        }
        .background(.clear)
    }

    private var devicesView: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Text("Devices")
                        .font(.system(size: 22, weight: .semibold, design: .rounded))
                    Spacer()
                    TextField("Search", text: $deviceFilter)
                        .textFieldStyle(.roundedBorder)
                        .frame(width: 220)
                }

                if viewModel.devices.isEmpty {
                    emptyState("No devices returned")
                } else {
                    VStack(spacing: 10) {
                        ForEach(filteredDevices) { device in
                            Button {
                                selectedDevice = device
                            } label: {
                                DeviceRow(device: device)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
            .padding(24)
        }
    }

    private var clientsView: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Text("Clients")
                        .font(.system(size: 22, weight: .semibold, design: .rounded))
                    Spacer()
                    TextField("Search", text: $clientFilter)
                        .textFieldStyle(.roundedBorder)
                        .frame(width: 220)
                }

                if viewModel.clients.isEmpty {
                    emptyState("No clients returned")
                } else {
                    VStack(spacing: 10) {
                        ForEach(filteredClients) { client in
                            Button {
                                selectedClient = client
                            } label: {
                                ClientRow(client: client)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
            .padding(24)
        }
    }

    private var topologyView: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("Topology")
                    .font(.system(size: 22, weight: .semibold, design: .rounded))

                if topologyRoots.isEmpty {
                    emptyState("No topology data available")
                } else {
                    VStack(spacing: 12) {
                        ForEach(topologyRoots) { node in
                            TopologyNodeView(
                                node: node,
                                level: 0,
                                onSelectDevice: { device in
                                    selectedDevice = device
                                },
                                onSelectClient: { client in
                                    selectedClient = client
                                }
                            )
                        }
                    }
                }
            }
            .padding(24)
        }
    }

    private var networksView: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("Networks")
                    .font(.system(size: 22, weight: .semibold, design: .rounded))

                if viewModel.networks.isEmpty {
                    emptyState("No networks returned")
                } else {
                    VStack(spacing: 10) {
                        ForEach(viewModel.networks) { network in
                            Button {
                                selectedNetwork = network
                            } label: {
                                NetworkRow(network: network, wanEntries: wanEntries)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
            .padding(24)
        }
    }

    private var wlansView: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("Wi-Fi")
                    .font(.system(size: 22, weight: .semibold, design: .rounded))

                if viewModel.wlans.isEmpty {
                    emptyState("No WLANs returned")
                } else {
                    VStack(spacing: 10) {
                        ForEach(viewModel.wlans) { wlan in
                            Button {
                                selectedWlan = wlan
                            } label: {
                                WlanRow(wlan: wlan)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
            .padding(24)
        }
    }

    private var trafficView: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("Traffic")
                    .font(.system(size: 22, weight: .semibold, design: .rounded))

                if viewModel.trafficReports.isEmpty {
                    if let live = liveTrafficRates {
                        LiveTrafficRow(rxBytesPerSec: live.rx, txBytesPerSec: live.tx)
                        Text("Traffic reports are not available from this controller, showing live WAN rates instead.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    } else {
                        emptyState("No traffic reports returned")
                    }
                } else {
                    VStack(spacing: 10) {
                        ForEach(viewModel.trafficReports.prefix(48)) { report in
                            Button {
                                selectedTraffic = report
                            } label: {
                                TrafficRow(report: report)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }

                GroupBox(label: sectionTitle("Top Clients (overall traffic)")) {
                    if topClientsByTraffic.isEmpty {
                        Text("No client traffic data available.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .padding(.vertical, 6)
                    } else {
                        VStack(spacing: 10) {
                            ForEach(topClientsByTraffic) { client in
                                TopClientTrafficRow(client: client)
                            }
                        }
                        .padding(.top, 6)
                    }
                }
            }
            .padding(24)
        }
    }

    private var speedTestsView: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Text("Speed Tests")
                        .font(.system(size: 22, weight: .semibold, design: .rounded))
                    Spacer()
                    Button(viewModel.isSpeedTestRunning ? "Running…" : "Run Speed Test") {
                        Task { await viewModel.runSpeedTest() }
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(viewModel.isSpeedTestRunning)
                }

                if let message = viewModel.speedTestMessage {
                    Text(message)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                if viewModel.speedTests.isEmpty {
                    if viewModel.speedTestStatus.isEmpty {
                        emptyState("No speed tests returned")
                    } else {
                        VStack(spacing: 10) {
                            ForEach(viewModel.speedTestStatus.indices, id: \.self) { index in
                                SpeedTestStatusRow(status: viewModel.speedTestStatus[index])
                            }
                        }
                    }
                } else {
                    VStack(spacing: 10) {
                        ForEach(viewModel.speedTests.prefix(20)) { test in
                            Button {
                                selectedSpeedTest = test
                            } label: {
                                SpeedTestRow(test: test)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
            .padding(24)
        }
    }

    private var insightsView: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("Insights")
                    .font(.system(size: 22, weight: .semibold, design: .rounded))

                if viewModel.rogueAps.isEmpty {
                    emptyState("No rogue APs detected")
                } else {
                    VStack(spacing: 10) {
                        ForEach(viewModel.rogueAps) { rogue in
                            Button {
                                selectedRogue = rogue
                            } label: {
                                RogueRow(rogue: rogue)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
            .padding(24)
        }
    }

    private var headerBlock: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("UCG Fiber Network")
                .font(.system(size: 28, weight: .bold, design: .rounded))
            HStack(spacing: 12) {
                labelValue("Host", viewModel.controllerHost)
                if let wanHeader = wanHeaderEntry {
                    labelValue(wanHeader.label, wanHeader.value)
                }
                if let version = viewModel.systemInfo?.version {
                    labelValue("Controller", version)
                }
                if let lastRefresh = viewModel.lastRefresh {
                    labelValue("Updated", lastRefresh.formatted(date: .numeric, time: .standard))
                }
                if viewModel.isRefreshing {
                    Text("Refreshing…")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            if let error = viewModel.errorMessage {
                Text(error)
                    .font(.callout)
                    .foregroundColor(.red)
            }
        }
    }

    private func sectionTitle(_ title: String) -> some View {
        Text(title)
            .font(.system(size: 14, weight: .semibold, design: .rounded))
            .foregroundColor(.secondary)
    }

    private func emptyState(_ message: String) -> some View {
        HStack {
            Image(systemName: "bolt.horizontal.circle")
                .foregroundColor(.secondary)
            Text(message)
                .foregroundColor(.secondary)
            Spacer()
        }
        .padding(.vertical, 8)
    }

    private func labelValue(_ label: String, _ value: String) -> some View {
        HStack(spacing: 4) {
            Text(label + ":")
                .font(.caption)
                .foregroundColor(.secondary)
            Text(value)
                .font(.caption)
        }
    }

    private func onlineCount(_ devices: [UniFiDevice]) -> String {
        let online = devices.filter { $0.isOnline }.count
        return "\(online) online"
    }

    private var liveTrafficRates: (rx: Double, tx: Double)? {
        if let wan = viewModel.health.first(where: { ($0.subsystem ?? "").lowercased() == "wan" }) {
            let rx = wan.rxBytesR ?? 0
            let tx = wan.txBytesR ?? 0
            if rx > 0 || tx > 0 { return (rx, tx) }
        }

        if let gateway = viewModel.devices.first(where: { device in
            let modelToken = (device.modelDisplay ?? device.model ?? "").lowercased()
            if modelToken.contains("ucg") { return true }
            return ["udm", "udm-pro", "udm-se", "ugw", "uxg"].contains(device.type ?? "")
        }) {
            let rx = gateway.wan1?.rxBytesR ?? gateway.rxBytesR ?? 0
            let tx = gateway.wan1?.txBytesR ?? gateway.txBytesR ?? 0
            if rx > 0 || tx > 0 { return (rx, tx) }
        }

        return nil
    }

    private func guestCount(_ clients: [UniFiClient]) -> String {
        let guests = clients.filter { $0.isGuest ?? false }.count
        return "\(guests) guests"
    }

    private var wanEntries: [WanEntry] {
        let isp = viewModel.health.first(where: { ($0.subsystem ?? "").lowercased() == "wan" })
            .map { $0.ispName ?? $0.ispOrganization }

        guard let gateway = viewModel.devices.first(where: { device in
            let modelToken = (device.modelDisplay ?? device.model ?? "").lowercased()
            if modelToken.contains("ucg") { return true }
            return ["udm", "udm-pro", "udm-se", "ugw", "uxg"].contains(device.type ?? "")
        }) else {
            return []
        }

        var entries: [WanEntry] = []
        if let wan1 = gateway.wan1 {
            entries.append(WanEntry(label: "WAN 1", ip: wan1.ip ?? "", isp: isp ?? nil))
        }
        if let wan2 = gateway.wan2 {
            entries.append(WanEntry(label: "WAN 2", ip: wan2.ip ?? "", isp: isp ?? nil))
        }
        return entries
    }

    private var wanHeaderEntry: (label: String, value: String)? {
        guard let entry = wanEntries.first(where: { $0.label.lowercased().contains("1") }) ?? wanEntries.first else {
            return nil
        }
        let ip = entry.ip.isEmpty ? "–" : entry.ip
        if let isp = entry.isp, !isp.isEmpty {
            return (label: entry.label, value: "\(ip) • \(isp)")
        }
        return (label: entry.label, value: ip)
    }

    private var topologyRoots: [TopologyNode] {
        TopologyBuilder.build(devices: viewModel.devices, clients: viewModel.clients)
    }

    private var filteredDevices: [UniFiDevice] {
        guard !deviceFilter.isEmpty else { return viewModel.devices }
        return viewModel.devices.filter { device in
            device.displayName.localizedCaseInsensitiveContains(deviceFilter) ||
            (device.ip ?? "").localizedCaseInsensitiveContains(deviceFilter) ||
            (device.modelDisplay ?? "").localizedCaseInsensitiveContains(deviceFilter)
        }
    }

    private var filteredClients: [UniFiClient] {
        guard !clientFilter.isEmpty else { return viewModel.clients }
        return viewModel.clients.filter { client in
            client.displayName.localizedCaseInsensitiveContains(clientFilter) ||
            (client.ip ?? "").localizedCaseInsensitiveContains(clientFilter) ||
            (client.oui ?? "").localizedCaseInsensitiveContains(clientFilter)
        }
    }

    private var topClientsByTraffic: [UniFiClient] {
        viewModel.clients
            .sorted { (lhs, rhs) -> Bool in
                let lhsTotal = (lhs.rxBytes ?? 0) + (lhs.txBytes ?? 0)
                let rhsTotal = (rhs.rxBytes ?? 0) + (rhs.txBytes ?? 0)
                return lhsTotal > rhsTotal
            }
            .prefix(5)
            .map { $0 }
    }
}

struct WanEntry: Identifiable {
    let id = UUID()
    let label: String
    let ip: String
    let isp: String?
}

struct StatsCard: View {
    let title: String
    let value: String
    let subtitle: String
    let tint: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.caption)
                .foregroundColor(.white.opacity(0.7))
            Text(value)
                .font(.system(size: 30, weight: .bold, design: .rounded))
                .foregroundColor(.white)
            Text(subtitle)
                .font(.caption)
                .foregroundColor(.white.opacity(0.7))
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(tint.gradient)
                .shadow(color: tint.opacity(0.3), radius: 10, x: 0, y: 6)
        )
    }
}

struct HealthPill: View {
    let title: String
    let status: String

    var body: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(status.lowercased() == "ok" ? Color.green : Color.orange)
                .frame(width: 8, height: 8)
            Text(title.uppercased())
                .font(.caption)
                .foregroundColor(.primary)
            Text(status.uppercased())
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(.ultraThinMaterial)
        )
    }
}

struct DeviceRow: View {
    let device: UniFiDevice

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: device.typeIcon)
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(device.isOnline ? .green : .red)
                .frame(width: 28)

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(device.displayName)
                        .font(.system(size: 15, weight: .semibold))
                    if device.upgradable == true {
                        Text("Update")
                            .font(.caption2)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.orange.opacity(0.2))
                            .clipShape(Capsule())
                    }
                }
                Text("\(device.typeLabel) • \(device.modelDisplay ?? device.model ?? "")")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text("IP \(device.ip ?? "–") • Clients \(device.numSta ?? 0)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                Text(device.isOnline ? "Online" : "Offline")
                    .font(.caption)
                    .foregroundColor(device.isOnline ? .green : .red)
                Text(formatUptime(device.uptime))
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color.white.opacity(0.08))
        )
    }
}

struct ClientRow: View {
    let client: UniFiClient

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: client.wiredStatus ? "cable.connector" : "wifi")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(client.wiredStatus ? .blue : .cyan)
                .frame(width: 28)

            VStack(alignment: .leading, spacing: 4) {
                Text(client.displayName)
                    .font(.system(size: 15, weight: .semibold))
                Text("IP \(client.ip ?? "–") • \(client.radioBand)")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text("RSSI \(client.rssi ?? 0) dBm • Uptime \(formatUptime(client.uptime))")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }

            Spacer()

            if client.isGuest == true {
                Text("Guest")
                    .font(.caption2)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.orange.opacity(0.2))
                    .clipShape(Capsule())
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color.white.opacity(0.08))
        )
    }
}

struct NetworkRow: View {
    let network: UniFiNetwork
    let wanEntries: [WanEntry]

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: network.purposeIcon)
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.mint)
                .frame(width: 28)

            VStack(alignment: .leading, spacing: 4) {
                Text(network.name ?? "Unnamed Network")
                    .font(.system(size: 15, weight: .semibold))
                Text(subtitleLine)
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text("VLAN \(network.vlan ?? 0) • DHCP \((network.dhcpdEnabled ?? false) ? "On" : "Off")")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }

            Spacer()

            Text((network.enabled ?? true) ? "Enabled" : "Disabled")
                .font(.caption2)
                .foregroundColor((network.enabled ?? true) ? .green : .red)
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color.white.opacity(0.08))
        )
    }

    private var isInternetNetwork: Bool {
        let nameToken = (network.name ?? "").lowercased()
        let purposeToken = (network.purpose ?? "").lowercased()
        return nameToken.contains("internet") || purposeToken.contains("wan")
    }

    private var subtitleLine: String {
        if isInternetNetwork, let entry = wanEntryForNetwork {
            let ip = entry.ip.isEmpty ? "–" : entry.ip
            if let isp = entry.isp, !isp.isEmpty {
                return "WAN • \(ip) • \(isp)"
            }
            return "WAN • \(ip)"
        }
        return "\(network.purpose ?? "") • \(network.ipSubnet ?? "")"
    }

    private var wanEntryForNetwork: WanEntry? {
        let nameToken = (network.name ?? "").lowercased()
        if nameToken.contains("internet 2") {
            return wanEntries.first(where: { $0.label.lowercased().contains("2") })
        }
        if nameToken.contains("internet 1") || nameToken.contains("wan") {
            return wanEntries.first(where: { $0.label.lowercased().contains("1") }) ?? wanEntries.first
        }
        return wanEntries.first
    }
}

struct WlanRow: View {
    let wlan: UniFiWLAN

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "wifi")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(wlan.enabled == true ? .cyan : .gray)
                .frame(width: 28)

            VStack(alignment: .leading, spacing: 4) {
                Text(wlan.name ?? "Unnamed WLAN")
                    .font(.system(size: 15, weight: .semibold))
                Text("\(wlan.security ?? "") • \(wlan.radioBand ?? "")")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text("Guest \((wlan.isGuest ?? false) ? "Yes" : "No") • Hidden \((wlan.hideSSID ?? false) ? "Yes" : "No")")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }

            Spacer()

            Text((wlan.enabled ?? true) ? "Active" : "Paused")
                .font(.caption2)
                .foregroundColor((wlan.enabled ?? true) ? .green : .red)
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color.white.opacity(0.08))
        )
    }
}

struct TrafficRow: View {
    let report: TrafficReport

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "chart.line.uptrend.xyaxis")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.blue)
                .frame(width: 28)

            VStack(alignment: .leading, spacing: 4) {
                Text(report.time.map { Date(timeIntervalSince1970: Double($0)).formatted(date: .abbreviated, time: .shortened) } ?? "Traffic")
                    .font(.system(size: 15, weight: .semibold))
                Text("WAN ↓ \((report.wanRxBytes ?? 0).formattedBytes()) • ↑ \((report.wanTxBytes ?? 0).formattedBytes())")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text("WLAN \((report.wlanBytes ?? 0).formattedBytes()) • Clients \(report.numSta ?? 0)")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            Spacer()
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color.white.opacity(0.08))
        )
    }
}

struct LiveTrafficRow: View {
    let rxBytesPerSec: Double
    let txBytesPerSec: Double

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "antenna.radiowaves.left.and.right")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.blue)
                .frame(width: 28)

            VStack(alignment: .leading, spacing: 4) {
                Text("Live WAN Traffic")
                    .font(.system(size: 15, weight: .semibold))
                Text("Down \(rxBytesPerSec.formattedBytesPerSecond()) • Up \(txBytesPerSec.formattedBytesPerSecond())")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            Spacer()
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color.white.opacity(0.08))
        )
    }
}

struct TopClientTrafficRow: View {
    let client: UniFiClient

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: client.wiredStatus ? "cable.connector" : "wifi")
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(client.wiredStatus ? .blue : .cyan)
                .frame(width: 24)

            VStack(alignment: .leading, spacing: 4) {
                Text(client.displayName)
                    .font(.system(size: 14, weight: .semibold))
                Text(client.ip ?? "–")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            let total = (client.rxBytes ?? 0) + (client.txBytes ?? 0)
            Text(total.formattedBytes())
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color.white.opacity(0.08))
        )
    }
}

struct SpeedTestRow: View {
    let test: SpeedTestResult

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "speedometer")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.orange)
                .frame(width: 28)

            VStack(alignment: .leading, spacing: 4) {
                Text(test.timestamp.map { Date(timeIntervalSince1970: Double($0)).formatted(date: .abbreviated, time: .shortened) } ?? "Speed Test")
                    .font(.system(size: 15, weight: .semibold))
                Text("↓ \(formatMbps(test.xputDownload)) • ↑ \(formatMbps(test.xputUpload))")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text("Ping \(formatPing(test.ping)) • \(test.status ?? "")")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            Spacer()
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color.white.opacity(0.08))
        )
    }
}

struct SpeedTestStatusRow: View {
    let status: SpeedTestStatus

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "speedometer")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.orange)
                .frame(width: 28)

            VStack(alignment: .leading, spacing: 4) {
                Text("Speed Test Status")
                    .font(.system(size: 15, weight: .semibold))
                Text("↓ \(formatMbps(status.xputDownload)) • ↑ \(formatMbps(status.xputUpload))")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text("Ping \(formatPing(status.latency.map { Double($0) })) • Runtime \(status.runtime ?? 0)s")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            Spacer()
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color.white.opacity(0.08))
        )
    }
}

struct RogueRow: View {
    let rogue: RogueAP

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.red)
                .frame(width: 28)

            VStack(alignment: .leading, spacing: 4) {
                Text(rogue.essid ?? "Unknown SSID")
                    .font(.system(size: 15, weight: .semibold))
                Text("BSSID \(rogue.bssid ?? "–") • Channel \(rogue.channel ?? 0)")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text("RSSI \(rogue.rssi ?? 0) dBm • \((rogue.isRogue ?? false) ? "Rogue" : "Neighbor")")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            Spacer()
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color.white.opacity(0.08))
        )
    }
}

private struct TopologyNode: Identifiable {
    enum Kind {
        case device(UniFiDevice)
        case client(UniFiClient)
        case unknownSwitch(String)
    }

    let id: String
    let kind: Kind
    let children: [TopologyNode]
}

private enum TopologyBuilder {
    static func build(devices: [UniFiDevice], clients: [UniFiClient]) -> [TopologyNode] {
        let deviceByMac = Dictionary(uniqueKeysWithValues: devices.compactMap { device -> (String, UniFiDevice)? in
            guard let mac = normalizeMac(device.mac) else { return nil }
            return (mac, device)
        })

        var clientBuckets: [String: [UniFiClient]] = [:]
        for client in clients {
            let apMac = normalizeMac(client.apMac)
            let swMac = normalizeMac(client.swMac)

            let parentMac: String?
            if client.wiredStatus {
                parentMac = swMac ?? apMac
            } else {
                parentMac = apMac ?? swMac
            }

            if let parentMac {
                clientBuckets[parentMac, default: []].append(client)
            }
        }

        var deviceChildren: [String: [TopologyNode]] = [:]
        for device in devices {
            guard let key = normalizeMac(device.mac) else { continue }
            let assignedClients = (clientBuckets[key] ?? []).map { client in
                TopologyNode(id: "client-\(client.id)", kind: .client(client), children: [])
            }
            deviceChildren[key] = assignedClients.sorted { lhs, rhs in
                label(for: lhs).localizedCaseInsensitiveCompare(label(for: rhs)) == .orderedAscending
            }
        }

        var childrenByParentMac: [String: [TopologyNode]] = [:]
        for device in devices {
            let parentMac = normalizeMac(device.uplink?.uplinkMac)
            let node = TopologyNode(
                id: "device-\(device.id)",
                kind: .device(device),
                children: normalizeMac(device.mac).flatMap { deviceChildren[$0] } ?? []
            )

            if let parentMac {
                childrenByParentMac[parentMac, default: []].append(node)
            } else {
                childrenByParentMac["ROOT", default: []].append(node)
            }
        }

        var roots = childrenByParentMac["ROOT"] ?? []

        if let gateway = gatewayRoot(devices: devices, deviceByMac: deviceByMac) {
            roots.removeAll { $0.id == "device-\(gateway.id)" }
            let gatewayNode = TopologyNode(
                id: "device-\(gateway.id)",
                kind: .device(gateway),
                children: normalizeMac(gateway.mac).map {
                    buildDeviceSubtree(
                        forMac: $0,
                        deviceChildren: deviceChildren,
                        childrenByParentMac: childrenByParentMac
                    )
                } ?? []
            )
            roots.insert(gatewayNode, at: 0)
        } else {
            roots = roots.map { node in
                expandNode(node, deviceChildren: deviceChildren, childrenByParentMac: childrenByParentMac)
            }
        }

        if let unknownNode = unknownWiredClientsNode(clients: clients, deviceByMac: deviceByMac) {
            roots.append(unknownNode)
        }

        return roots.sorted { label(for: $0).localizedCaseInsensitiveCompare(label(for: $1)) == .orderedAscending }
    }

    private static func buildDeviceSubtree(
        forMac mac: String,
        deviceChildren: [String: [TopologyNode]],
        childrenByParentMac: [String: [TopologyNode]]
    ) -> [TopologyNode] {
        let directDeviceChildren = childrenByParentMac[mac] ?? []
        let expandedDevices = directDeviceChildren.map { node in
            expandNode(node, deviceChildren: deviceChildren, childrenByParentMac: childrenByParentMac)
        }

        var combined = expandedDevices
        if let clients = deviceChildren[mac] {
            combined.append(contentsOf: clients)
        }
        return combined.sorted { label(for: $0).localizedCaseInsensitiveCompare(label(for: $1)) == .orderedAscending }
    }

    private static func expandNode(
        _ node: TopologyNode,
        deviceChildren: [String: [TopologyNode]],
        childrenByParentMac: [String: [TopologyNode]]
    ) -> TopologyNode {
        guard case let .device(device) = node.kind else { return node }
        guard let mac = normalizeMac(device.mac) else {
            return TopologyNode(id: node.id, kind: node.kind, children: [])
        }
        let children = buildDeviceSubtree(forMac: mac, deviceChildren: deviceChildren, childrenByParentMac: childrenByParentMac)
        return TopologyNode(id: node.id, kind: node.kind, children: children)
    }

    private static func gatewayRoot(devices: [UniFiDevice], deviceByMac: [String: UniFiDevice]) -> UniFiDevice? {
        if let gateway = devices.first(where: { device in
            let modelToken = (device.modelDisplay ?? device.model ?? "").lowercased()
            if modelToken.contains("ucg") { return true }
            return ["udm", "udm-pro", "udm-se", "ugw", "uxg"].contains(device.type ?? "")
        }) {
            return gateway
        }

        for device in devices {
            guard let uplinkMac = normalizeMac(device.uplink?.uplinkMac) else { continue }
            if deviceByMac[uplinkMac] == nil {
                if let mac = normalizeMac(device.mac) {
                    return deviceByMac[mac]
                }
            }
        }
        return nil
    }

    private static func unknownWiredClientsNode(clients: [UniFiClient], deviceByMac: [String: UniFiDevice]) -> TopologyNode? {
        let unknownClients = clients.filter { client in
            guard let swMac = normalizeMac(client.swMac) else { return false }
            return deviceByMac[swMac] == nil
        }

        guard !unknownClients.isEmpty else { return nil }
        let children = unknownClients.map { client in
            TopologyNode(id: "client-\(client.id)", kind: .client(client), children: [])
        }
        return TopologyNode(id: "unknown-switches", kind: .unknownSwitch("Unmanaged Switches"), children: children)
    }

    private static func label(for node: TopologyNode) -> String {
        switch node.kind {
        case .device(let device): return device.displayName
        case .client(let client): return client.displayName
        case .unknownSwitch(let title): return title
        }
    }

    private static func normalizeMac(_ value: String?) -> String? {
        guard let value, !value.isEmpty else { return nil }
        return value.lowercased()
            .replacingOccurrences(of: ":", with: "")
            .replacingOccurrences(of: "-", with: "")
    }
}

private struct TopologyNodeView: View {
    let node: TopologyNode
    let level: Int
    let onSelectDevice: (UniFiDevice) -> Void
    let onSelectClient: (UniFiClient) -> Void

    @State private var isExpanded: Bool = true

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                if !node.children.isEmpty {
                    Button {
                        isExpanded.toggle()
                    } label: {
                        Image(systemName: isExpanded ? "chevron.down" : "chevron.right")
                            .font(.system(size: 12, weight: .semibold))
                    }
                    .buttonStyle(.plain)
                } else {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .semibold))
                        .opacity(0.2)
                }

                nodeLabel
                Spacer()
            }
            .padding(.leading, CGFloat(level) * 18)

            if isExpanded {
                ForEach(node.children) { child in
                    TopologyNodeView(
                        node: child,
                        level: level + 1,
                        onSelectDevice: onSelectDevice,
                        onSelectClient: onSelectClient
                    )
                }
            }
        }
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color.white.opacity(0.08))
        )
    }

    @ViewBuilder
    private var nodeLabel: some View {
        switch node.kind {
        case .device(let device):
            Button {
                onSelectDevice(device)
            } label: {
                HStack(spacing: 10) {
                    Image(systemName: device.typeIcon)
                        .foregroundColor(device.isOnline ? .green : .red)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(device.displayName)
                            .font(.system(size: 14, weight: .semibold))
                        Text(device.typeLabel)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .buttonStyle(.plain)
        case .client(let client):
            Button {
                onSelectClient(client)
            } label: {
                HStack(spacing: 10) {
                    Image(systemName: client.wiredStatus ? "cable.connector" : "wifi")
                        .foregroundColor(client.wiredStatus ? .blue : .cyan)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(client.displayName)
                            .font(.system(size: 14, weight: .semibold))
                        Text(client.ip ?? "–")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .buttonStyle(.plain)
        case .unknownSwitch(let title):
            HStack(spacing: 10) {
                Image(systemName: "questionmark.square.dashed")
                    .foregroundColor(.orange)
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.system(size: 14, weight: .semibold))
                    Text("Clients connected via unmanaged switches")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
    }
}
