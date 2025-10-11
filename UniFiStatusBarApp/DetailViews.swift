import SwiftUI

struct DeviceDetailView: View {
    let device: UniFiDevice

    var body: some View {
        DetailContainer(title: device.displayName, subtitle: device.typeLabel) {
            DetailRow(label: "Model", value: device.modelDisplay ?? device.model ?? "–")
            DetailRow(label: "IP", value: device.ip ?? "–")
            DetailRow(label: "MAC", value: device.mac)
            DetailRow(label: "Version", value: device.version ?? "–")
            DetailRow(label: "Clients", value: "\(device.numSta ?? 0)")
            DetailRow(label: "Uptime", value: formatUptime(device.uptime))
            if let power = device.totalMaxPower, power > 0 {
                DetailRow(label: "PoE Budget", value: String(format: "%.0f W", power))
            }
            if let uplink = device.uplink {
                DetailRow(label: "Uplink", value: "\(uplink.name ?? "–") \(uplink.speed.map { "\($0) Mbps" } ?? "")")
            }
        }
    }
}

struct ClientDetailView: View {
    let client: UniFiClient

    var body: some View {
        DetailContainer(title: client.displayName, subtitle: client.wiredStatus ? "Wired" : "Wireless") {
            DetailRow(label: "IP", value: client.ip ?? "–")
            DetailRow(label: "MAC", value: client.mac ?? "–")
            DetailRow(label: "Vendor", value: client.oui ?? "–")
            DetailRow(label: "Radio", value: client.radioBand)
            DetailRow(label: "SSID", value: client.essid ?? "–")
            DetailRow(label: "RSSI", value: "\(client.rssi ?? 0) dBm")
            DetailRow(label: "Uptime", value: formatUptime(client.uptime))
        }
    }
}

struct NetworkDetailView: View {
    let network: UniFiNetwork

    var body: some View {
        DetailContainer(title: network.name ?? "Network", subtitle: network.purpose ?? "") {
            DetailRow(label: "Subnet", value: network.ipSubnet ?? "–")
            DetailRow(label: "VLAN", value: "\(network.vlan ?? 0)")
            DetailRow(label: "DHCP", value: (network.dhcpdEnabled ?? false) ? "On" : "Off")
            DetailRow(label: "NAT", value: (network.isNat ?? false) ? "On" : "Off")
            DetailRow(label: "Domain", value: network.domainName ?? "–")
        }
    }
}

struct WlanDetailView: View {
    let wlan: UniFiWLAN

    var body: some View {
        DetailContainer(title: wlan.name ?? "WLAN", subtitle: wlan.bandLabel) {
            DetailRow(label: "Security", value: wlan.security ?? "–")
            DetailRow(label: "Hidden", value: (wlan.hideSSID ?? false) ? "Yes" : "No")
            DetailRow(label: "Guest", value: (wlan.isGuest ?? false) ? "Yes" : "No")
            DetailRow(label: "Enabled", value: (wlan.enabled ?? true) ? "Yes" : "No")
        }
    }
}

struct TrafficDetailView: View {
    let report: TrafficReport

    var body: some View {
        DetailContainer(title: "Traffic Report", subtitle: report.time.map { Date(timeIntervalSince1970: Double($0)).formatted(date: .abbreviated, time: .shortened) } ?? "") {
            DetailRow(label: "WAN Down", value: (report.wanRxBytes ?? 0).formattedBytes())
            DetailRow(label: "WAN Up", value: (report.wanTxBytes ?? 0).formattedBytes())
            DetailRow(label: "WLAN", value: (report.wlanBytes ?? 0).formattedBytes())
            DetailRow(label: "Clients", value: "\(report.numSta ?? 0)")
        }
    }
}

struct SpeedTestDetailView: View {
    let test: SpeedTestResult

    var body: some View {
        DetailContainer(title: "Speed Test", subtitle: test.timestamp.map { Date(timeIntervalSince1970: Double($0)).formatted(date: .abbreviated, time: .shortened) } ?? "") {
            DetailRow(label: "Download", value: formatMbps(test.xputDownload))
            DetailRow(label: "Upload", value: formatMbps(test.xputUpload))
            DetailRow(label: "Ping", value: formatPing(test.ping))
            DetailRow(label: "Status", value: test.status ?? "–")
        }
    }
}

struct VpnDetailView: View {
    let session: VpnSession

    var body: some View {
        DetailContainer(title: session.username ?? session.userId ?? "VPN Session", subtitle: session.protocolType ?? "") {
            DetailRow(label: "Remote IP", value: session.remoteIP ?? "–")
            DetailRow(label: "Local IP", value: session.localIP ?? "–")
            DetailRow(label: "Connected", value: session.connectedAt.map { Int($0).formattedUptime() } ?? "–")
        }
    }
}

struct RogueDetailView: View {
    let rogue: RogueAP

    var body: some View {
        DetailContainer(title: rogue.essid ?? "Rogue AP", subtitle: rogue.bssid ?? "") {
            DetailRow(label: "Channel", value: "\(rogue.channel ?? 0)")
            DetailRow(label: "RSSI", value: "\(rogue.rssi ?? 0) dBm")
            DetailRow(label: "Security", value: rogue.security ?? "–")
            DetailRow(label: "Status", value: (rogue.isRogue ?? false) ? "Rogue" : "Neighbor")
        }
    }
}

struct DetailContainer<Content: View>: View {
    let title: String
    let subtitle: String
    let content: Content

    @Environment(\.dismiss) private var dismiss

    init(title: String, subtitle: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.subtitle = subtitle
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.system(size: 20, weight: .bold))
                    Text(subtitle)
                        .font(.callout)
                        .foregroundColor(.secondary)
                }

                Spacer()

                Button("Close") {
                    dismiss()
                }
                .buttonStyle(.bordered)
            }

            Divider()

            VStack(alignment: .leading, spacing: 8) {
                content
            }

            Spacer()
        }
        .padding(20)
        .frame(minWidth: 420, minHeight: 280)
    }
}

struct DetailRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack {
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .font(.callout)
        }
    }
}

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
