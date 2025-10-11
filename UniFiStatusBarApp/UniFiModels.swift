import Foundation

// MARK: - Generic API Response Wrapper

struct UniFiResponse<T: Decodable>: Decodable {
    let meta: UniFiMeta
    let data: [T]
}

struct UniFiMeta: Decodable {
    let rc: String
    let msg: String?
}

// MARK: - Site Health

struct SiteHealth: Codable, Identifiable {
    var id: String { subsystem ?? UUID().uuidString }

    let subsystem: String?
    let status: String?

    // WAN-specific
    let wanIP: String?
    let nameservers: [String]?
    let gateways: [String]?
    let netmask: String?
    let numGw: Int?
    let gwMac: String?
    let gwName: String?
    let gwVersion: String?
    let gwSystemStats: GatewaySystemStats?
    let ispName: String?
    let ispOrganization: String?

    // WLAN-specific
    let numAp: Int?
    let numAdopted: Int?
    let numDisabled: Int?
    let numDisconnected: Int?
    let numPending: Int?
    let numUser: Int?
    let numGuest: Int?
    let numIot: Int?

    let numSta: Int?
    let txBytesR: Double?
    let rxBytesR: Double?

    let numSw: Int?

    enum CodingKeys: String, CodingKey {
        case subsystem, status, nameservers, gateways, netmask
        case wanIP = "wan_ip"
        case numGw = "num_gw"
        case gwMac = "gw_mac"
        case gwName = "gw_name"
        case gwVersion = "gw_version"
        case gwSystemStats = "gw_system-stats"
        case ispName = "isp_name"
        case ispOrganization = "isp_organization"
        case numAp = "num_ap"
        case numAdopted = "num_adopted"
        case numDisabled = "num_disabled"
        case numDisconnected = "num_disconnected"
        case numPending = "num_pending"
        case numUser = "num_user"
        case numGuest = "num_guest"
        case numIot = "num_iot"
        case numSta = "num_sta"
        case txBytesR = "tx_bytes-r"
        case rxBytesR = "rx_bytes-r"
        case numSw = "num_sw"
    }
}

struct GatewaySystemStats: Codable {
    let cpu: String?
    let mem: String?
    let uptime: String?
}

// MARK: - System Info

struct SystemInfo: Codable {
    let version: String?
    let buildNumber: String?
    let timezone: String?
    let hostname: String?
    let name: String?
    let ubntDeviceType: String?
    let updateAvailable: Bool?

    enum CodingKeys: String, CodingKey {
        case version, timezone, hostname, name
        case buildNumber = "build"
        case ubntDeviceType = "ubnt_device_type"
        case updateAvailable = "update_available"
    }
}

// MARK: - UniFi Device

private extension KeyedDecodingContainer {
    func decodeString(forKey key: Key) -> String? {
        if let value = try? decodeIfPresent(String.self, forKey: key) { return value }
        if let value = try? decodeIfPresent(Int.self, forKey: key) { return String(value) }
        if let value = try? decodeIfPresent(Double.self, forKey: key) { return String(value) }
        return nil
    }

    func decodeIntFlexible(forKey key: Key) -> Int? {
        if let value = try? decodeIfPresent(Int.self, forKey: key) { return value }
        if let value = try? decodeIfPresent(Double.self, forKey: key) { return Int(value) }
        if let value = try? decodeIfPresent(String.self, forKey: key) { return Int(value) }
        return nil
    }

    func decodeDoubleFlexible(forKey key: Key) -> Double? {
        if let value = try? decodeIfPresent(Double.self, forKey: key) { return value }
        if let value = try? decodeIfPresent(Int.self, forKey: key) { return Double(value) }
        if let value = try? decodeIfPresent(String.self, forKey: key) { return Double(value) }
        return nil
    }

    func decodeBoolFlexible(forKey key: Key) -> Bool? {
        if let value = try? decodeIfPresent(Bool.self, forKey: key) { return value }
        if let value = try? decodeIfPresent(Int.self, forKey: key) { return value != 0 }
        if let value = try? decodeIfPresent(String.self, forKey: key) {
            return value == "1" || value.lowercased() == "true"
        }
        return nil
    }
}

struct UniFiDevice: Codable, Identifiable {
    var id: String { _id }

    let _id: String
    let mac: String
    let model: String?
    let modelDisplay: String?
    let shortName: String?
    let modelName: String?
    let name: String?
    let type: String?
    let serial: String?
    let ip: String?
    let version: String?
    let state: Int?
    let adopted: Bool?
    let uptime: Int?
    let upgradable: Bool?
    let numSta: Int?
    let userNumSta: Int?
    let guestNumSta: Int?

    // Traffic
    let txBytes: Double?
    let rxBytes: Double?
    let txBytesR: Double?
    let rxBytesR: Double?

    // System stats
    let systemStats: DeviceSystemStats?
    let sysStats: DeviceSysStats?

    // Uplink
    let uplink: DeviceUplink?

    // WAN (gateway only)
    let wan1: WANInterface?
    let wan2: WANInterface?

    // Speed test
    let speedtestStatus: SpeedTestStatus?

    // PoE (switch only)
    let totalMaxPower: Double?
    let powerSource: String?

    // AP-specific
    let radioTable: [RadioEntry]?
    let vapTable: [VAPEntry]?

    // Port table (switch)
    let portTable: [PortEntry]?

    let siteId: String?
    let lastSeen: Int?
    let locating: Bool?
    let ledOverride: String?
    let configNetwork: ConfigNetwork?

    enum CodingKeys: String, CodingKey {
        case _id, mac, model, name, type, serial, ip, version, state
        case adopted, uptime, upgradable, uplink, wan1, wan2, locating
        case modelDisplay = "model_display"
        case shortName = "shortname"
        case modelName = "model_name"
        case numSta = "num_sta"
        case userNumSta = "user-num_sta"
        case guestNumSta = "guest-num_sta"
        case txBytes = "tx_bytes"
        case rxBytes = "rx_bytes"
        case txBytesR = "tx_bytes-r"
        case rxBytesR = "rx_bytes-r"
        case systemStats = "system-stats"
        case sysStats = "sys_stats"
        case speedtestStatus = "speedtest-status"
        case totalMaxPower = "total_max_power"
        case powerSource = "power_source"
        case radioTable = "radio_table"
        case vapTable = "vap_table"
        case portTable = "port_table"
        case siteId = "site_id"
        case lastSeen = "last_seen"
        case ledOverride = "led_override"
        case configNetwork = "config_network"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        _id = container.decodeString(forKey: ._id) ?? UUID().uuidString
        mac = container.decodeString(forKey: .mac) ?? ""
        model = container.decodeString(forKey: .model)
        modelDisplay = container.decodeString(forKey: .modelDisplay)
        shortName = container.decodeString(forKey: .shortName)
        modelName = container.decodeString(forKey: .modelName)
        name = container.decodeString(forKey: .name)
        type = container.decodeString(forKey: .type)
        serial = container.decodeString(forKey: .serial)
        ip = container.decodeString(forKey: .ip)
        version = container.decodeString(forKey: .version)
        state = container.decodeIntFlexible(forKey: .state)
        adopted = container.decodeBoolFlexible(forKey: .adopted)
        uptime = container.decodeIntFlexible(forKey: .uptime)
        upgradable = container.decodeBoolFlexible(forKey: .upgradable)
        numSta = container.decodeIntFlexible(forKey: .numSta)
        userNumSta = container.decodeIntFlexible(forKey: .userNumSta)
        guestNumSta = container.decodeIntFlexible(forKey: .guestNumSta)
        txBytes = container.decodeDoubleFlexible(forKey: .txBytes)
        rxBytes = container.decodeDoubleFlexible(forKey: .rxBytes)
        txBytesR = container.decodeDoubleFlexible(forKey: .txBytesR)
        rxBytesR = container.decodeDoubleFlexible(forKey: .rxBytesR)
        systemStats = try? container.decodeIfPresent(DeviceSystemStats.self, forKey: .systemStats)
        sysStats = try? container.decodeIfPresent(DeviceSysStats.self, forKey: .sysStats)
        uplink = try? container.decodeIfPresent(DeviceUplink.self, forKey: .uplink)
        wan1 = try? container.decodeIfPresent(WANInterface.self, forKey: .wan1)
        wan2 = try? container.decodeIfPresent(WANInterface.self, forKey: .wan2)
        speedtestStatus = try? container.decodeIfPresent(SpeedTestStatus.self, forKey: .speedtestStatus)
        totalMaxPower = container.decodeDoubleFlexible(forKey: .totalMaxPower)
        powerSource = container.decodeString(forKey: .powerSource)
        radioTable = try? container.decodeIfPresent([RadioEntry].self, forKey: .radioTable)
        vapTable = try? container.decodeIfPresent([VAPEntry].self, forKey: .vapTable)
        portTable = try? container.decodeIfPresent([PortEntry].self, forKey: .portTable)
        siteId = container.decodeString(forKey: .siteId)
        lastSeen = container.decodeIntFlexible(forKey: .lastSeen)
        locating = container.decodeBoolFlexible(forKey: .locating)
        ledOverride = container.decodeString(forKey: .ledOverride)
        configNetwork = try? container.decodeIfPresent(ConfigNetwork.self, forKey: .configNetwork)
    }

    var isOnline: Bool { state == 1 }

    var displayName: String { name ?? modelName ?? modelDisplay ?? shortName ?? model ?? mac }

    var typeIcon: String {
        if isCloudGateway { return "server.rack" }
        switch type {
        case "uap": return "wifi.router"
        case "usw": return "switch.2"
        case "ugw", "udm", "udm-pro", "udm-se", "uxg": return "server.rack"
        default: return "network"
        }
    }

    var typeLabel: String {
        if isCloudGateway {
            return "UCG Fiber"
        }
        switch type {
        case "uap": return "Access Point"
        case "usw": return "Switch"
        case "ugw": return "Gateway"
        case "udm": return "Dream Machine"
        case "udm-pro": return "Dream Machine Pro"
        case "udm-se": return "Dream Machine SE"
        case "uxg": return "Express Gateway"
        default: return type?.uppercased() ?? "Device"
        }
    }

    private var isCloudGateway: Bool {
        let tokens = [
            modelDisplay,
            model,
            modelName,
            shortName,
            name
        ]
        .compactMap { $0?.lowercased() }

        return tokens.contains { token in
            token.contains("ucg") ||
            token.contains("cloud gateway") ||
            token.contains("ucg fiber")
        }
    }
}

struct DeviceSystemStats: Codable {
    let cpu: String?
    let mem: String?
    let uptime: String?
}

struct DeviceSysStats: Codable {
    let loadavg1: String?
    let loadavg5: String?
    let loadavg15: String?
    let memBuffer: Int?
    let memTotal: Int?
    let memUsed: Int?

    enum CodingKeys: String, CodingKey {
        case loadavg1 = "loadavg_1"
        case loadavg5 = "loadavg_5"
        case loadavg15 = "loadavg_15"
        case memBuffer = "mem_buffer"
        case memTotal = "mem_total"
        case memUsed = "mem_used"
    }
}

struct DeviceUplink: Codable {
    let name: String?
    let type: String?
    let speed: Int?
    let fullDuplex: Bool?
    let mac: String?
    let ip: String?
    let uplinkMac: String?
    let uplinkRemotePort: Int?

    enum CodingKeys: String, CodingKey {
        case name, type, speed, mac, ip
        case fullDuplex = "full_duplex"
        case uplinkMac = "uplink_mac"
        case uplinkRemotePort = "uplink_remote_port"
    }
}

struct WANInterface: Codable {
    let type: String?
    let ip: String?
    let netmask: String?
    let gateway: String?
    let dns: [String]?
    let txBytesR: Double?
    let rxBytesR: Double?
    let txBytes: Double?
    let rxBytes: Double?
    let maxSpeed: Int?
    let fullDuplex: Bool?
    let enable: Bool?
    let ifname: String?

    enum CodingKeys: String, CodingKey {
        case type, ip, netmask, gateway, dns, enable, ifname
        case txBytesR = "tx_bytes-r"
        case rxBytesR = "rx_bytes-r"
        case txBytes = "tx_bytes"
        case rxBytes = "rx_bytes"
        case maxSpeed = "max_speed"
        case fullDuplex = "full_duplex"
    }
}

struct SpeedTestStatus: Codable {
    let latency: Int?
    let rundate: Int?
    let runtime: Int?
    let xputDownload: Double?
    let xputUpload: Double?

    enum CodingKeys: String, CodingKey {
        case latency, rundate, runtime
        case xputDownload = "xput_download"
        case xputUpload = "xput_upload"
    }
}

struct RadioEntry: Codable {
    let radio: String?
    let name: String?
    let channel: Int?
    let txPower: Int?
    let txPowerMode: String?

    enum CodingKeys: String, CodingKey {
        case radio, name, channel
        case txPower = "tx_power"
        case txPowerMode = "tx_power_mode"
    }

    var bandLabel: String {
        switch radio {
        case "ng": return "2.4 GHz"
        case "na": return "5 GHz"
        case "6e": return "6 GHz"
        default: return radio ?? "Unknown"
        }
    }
}

struct VAPEntry: Codable {
    let essid: String?
    let radio: String?
    let bssid: String?
    let numSta: Int?
    let channel: Int?
    let isGuest: Bool?

    enum CodingKeys: String, CodingKey {
        case essid, radio, bssid, channel
        case numSta = "num_sta"
        case isGuest = "is_guest"
    }
}

struct PortEntry: Codable {
    let portIdx: Int?
    let name: String?
    let media: String?
    let enable: Bool?
    let speed: Int?
    let fullDuplex: Bool?
    let isUplink: Bool?
    let poeEnable: Bool?
    let poePower: String?
    let txBytesR: Double?
    let rxBytesR: Double?

    enum CodingKeys: String, CodingKey {
        case name, media, enable, speed
        case portIdx = "port_idx"
        case fullDuplex = "full_duplex"
        case isUplink = "is_uplink"
        case poeEnable = "poe_enable"
        case poePower = "poe_power"
        case txBytesR = "tx_bytes-r"
        case rxBytesR = "rx_bytes-r"
    }
}

struct ConfigNetwork: Codable {
    let type: String?
    let ip: String?
}

// MARK: - UniFi Client

struct UniFiClient: Codable, Identifiable {
    var id: String { _id ?? mac ?? UUID().uuidString }

    let _id: String?
    let mac: String?
    let hostname: String?
    let name: String?
    let ip: String?
    let isWired: Bool?
    let isGuest: Bool?
    let authorized: Bool?
    let blocked: Bool?
    let isVpn: Bool?
    let isRemoteUser: Bool?
    let vpnType: String?
    let tunnelType: String?
    let vpnProto: String?
    let remoteIP: String?
    let localIP: String?
    let remoteUserId: String?
    let remoteUserUsername: String?

    // Wireless-specific
    let essid: String?
    let bssid: String?
    let radio: String?
    let radioName: String?
    let channel: Int?
    let rssi: Int?
    let signal: Int?
    let noise: Int?
    let apMac: String?
    let satisfaction: Int?

    // Traffic
    let txBytes: Double?
    let rxBytes: Double?
    let txBytesR: Double?
    let rxBytesR: Double?
    let txRate: Double?
    let rxRate: Double?

    // Timing
    let uptime: Int?
    let firstSeen: Int?
    let lastSeen: Int?

    // Identity
    let oui: String?

    // Network
    let networkId: String?
    let network: String?
    let vlan: Int?
    let swMac: String?
    let swPort: Int?

    enum CodingKeys: String, CodingKey {
        case _id, mac, hostname, name, ip, authorized, blocked
        case essid, bssid, radio, channel, rssi, signal, noise, satisfaction
        case uptime, oui, network, vlan
        case isWired = "is_wired"
        case isGuest = "is_guest"
        case radioName = "radio_name"
        case apMac = "ap_mac"
        case txBytes = "tx_bytes"
        case rxBytes = "rx_bytes"
        case txBytesR = "tx_bytes-r"
        case rxBytesR = "rx_bytes-r"
        case txRate = "tx_rate"
        case rxRate = "rx_rate"
        case firstSeen = "first_seen"
        case lastSeen = "last_seen"
        case networkId = "network_id"
        case swMac = "sw_mac"
        case swPort = "sw_port"
        case isVpn = "is_vpn"
        case isRemoteUser = "is_remote_user"
        case vpnType = "vpn_type"
        case tunnelType = "tunnel_type"
        case vpnProto = "vpn_proto"
        case remoteIP = "remote_ip"
        case localIP = "local_ip"
        case remoteUserId = "remote_user_id"
        case remoteUserUsername = "remote_user_username"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        _id = container.decodeString(forKey: ._id)
        mac = container.decodeString(forKey: .mac)
        hostname = container.decodeString(forKey: .hostname)
        name = container.decodeString(forKey: .name)
        ip = container.decodeString(forKey: .ip)
        isWired = container.decodeBoolFlexible(forKey: .isWired)
        isGuest = container.decodeBoolFlexible(forKey: .isGuest)
        authorized = container.decodeBoolFlexible(forKey: .authorized)
        blocked = container.decodeBoolFlexible(forKey: .blocked)
        isVpn = container.decodeBoolFlexible(forKey: .isVpn)
        isRemoteUser = container.decodeBoolFlexible(forKey: .isRemoteUser)
        vpnType = container.decodeString(forKey: .vpnType)
        tunnelType = container.decodeString(forKey: .tunnelType)
        vpnProto = container.decodeString(forKey: .vpnProto)
        remoteIP = container.decodeString(forKey: .remoteIP)
        localIP = container.decodeString(forKey: .localIP)
        remoteUserId = container.decodeString(forKey: .remoteUserId)
        remoteUserUsername = container.decodeString(forKey: .remoteUserUsername)

        essid = container.decodeString(forKey: .essid)
        bssid = container.decodeString(forKey: .bssid)
        radio = container.decodeString(forKey: .radio)
        radioName = container.decodeString(forKey: .radioName)
        channel = container.decodeIntFlexible(forKey: .channel)
        rssi = container.decodeIntFlexible(forKey: .rssi)
        signal = container.decodeIntFlexible(forKey: .signal)
        noise = container.decodeIntFlexible(forKey: .noise)
        apMac = container.decodeString(forKey: .apMac)
        satisfaction = container.decodeIntFlexible(forKey: .satisfaction)

        txBytes = container.decodeDoubleFlexible(forKey: .txBytes)
        rxBytes = container.decodeDoubleFlexible(forKey: .rxBytes)
        txBytesR = container.decodeDoubleFlexible(forKey: .txBytesR)
        rxBytesR = container.decodeDoubleFlexible(forKey: .rxBytesR)
        txRate = container.decodeDoubleFlexible(forKey: .txRate)
        rxRate = container.decodeDoubleFlexible(forKey: .rxRate)

        uptime = container.decodeIntFlexible(forKey: .uptime)
        firstSeen = container.decodeIntFlexible(forKey: .firstSeen)
        lastSeen = container.decodeIntFlexible(forKey: .lastSeen)

        oui = container.decodeString(forKey: .oui)

        networkId = container.decodeString(forKey: .networkId)
        network = container.decodeString(forKey: .network)
        vlan = container.decodeIntFlexible(forKey: .vlan)
        swMac = container.decodeString(forKey: .swMac)
        swPort = container.decodeIntFlexible(forKey: .swPort)
    }

    var displayName: String {
        if let n = name, !n.isEmpty { return n }
        if let h = hostname, !h.isEmpty { return h }
        return mac ?? "Unknown"
    }

    var wiredStatus: Bool { isWired ?? false }

    var radioBand: String {
        switch radio {
        case "ng": return "2.4G"
        case "na": return "5G"
        case "6e": return "6G"
        default: return ""
        }
    }
}

// MARK: - Events & Alarms

struct UniFiEvent: Codable, Identifiable {
    var id: String { _id }

    let _id: String
    let key: String?
    let msg: String?
    let subsystem: String?
    let time: Int?
    let datetime: String?
    let siteId: String?
    let ap: String?
    let apName: String?
    let user: String?
    let hostname: String?
    let ssid: String?

    enum CodingKeys: String, CodingKey {
        case _id, key, msg, subsystem, time, datetime
        case ap, hostname, ssid, user
        case siteId = "site_id"
        case apName = "ap_name"
    }

    var eventDate: Date? {
        guard let t = time else { return nil }
        let ts = t > 1_000_000_000_000 ? Double(t) / 1000.0 : Double(t)
        return Date(timeIntervalSince1970: ts)
    }

    var severityIcon: String {
        guard let k = key else { return "info.circle" }
        if k.contains("Lost") || k.contains("Offline") || k.contains("Down") {
            return "exclamationmark.triangle"
        }
        if k.contains("Connected") || k.contains("Online") || k.contains("Up") {
            return "checkmark.circle"
        }
        if k.contains("Alert") || k.contains("Alarm") {
            return "bell.badge"
        }
        return "info.circle"
    }

    var severityColor: String {
        guard let k = key else { return "blue" }
        if k.contains("Lost") || k.contains("Offline") || k.contains("Down") { return "red" }
        if k.contains("Connected") || k.contains("Online") || k.contains("Up") { return "green" }
        return "blue"
    }
}

struct UniFiAlarm: Codable, Identifiable {
    var id: String { _id }

    let _id: String
    let key: String?
    let msg: String?
    let time: Int?
    let datetime: String?
    let archived: Bool?
    let handledAdminId: String?
    let siteId: String?
    let apMac: String?
    let apName: String?
    let subsystem: String?

    enum CodingKeys: String, CodingKey {
        case _id, key, msg, time, datetime, archived, subsystem
        case handledAdminId = "handled_admin_id"
        case siteId = "site_id"
        case apMac = "ap"
        case apName = "ap_name"
    }

    var alarmDate: Date? {
        guard let t = time else { return nil }
        let ts = t > 1_000_000_000_000 ? Double(t) / 1000.0 : Double(t)
        return Date(timeIntervalSince1970: ts)
    }
}

// MARK: - Network Configuration

struct UniFiNetwork: Codable, Identifiable {
    var id: String { _id }

    let _id: String
    let name: String?
    let purpose: String?
    let ipSubnet: String?
    let vlan: Int?
    let vlanEnabled: Bool?
    let dhcpdEnabled: Bool?
    let dhcpdStart: String?
    let dhcpdStop: String?
    let enabled: Bool?
    let isNat: Bool?
    let networkgroup: String?
    let domainName: String?
    let siteId: String?

    enum CodingKeys: String, CodingKey {
        case _id, name, purpose, vlan, enabled, networkgroup
        case ipSubnet = "ip_subnet"
        case vlanEnabled = "vlan_enabled"
        case dhcpdEnabled = "dhcpd_enabled"
        case dhcpdStart = "dhcpd_start"
        case dhcpdStop = "dhcpd_stop"
        case isNat = "is_nat"
        case domainName = "domain_name"
        case siteId = "site_id"
    }

    var purposeIcon: String {
        switch purpose {
        case "corporate": return "building.2"
        case "guest": return "person.wave.2"
        case "vlan-only": return "network"
        case "remote-user-vpn": return "lock.shield"
        default: return "network"
        }
    }
}

// MARK: - WLAN Configuration

struct UniFiWLAN: Codable, Identifiable {
    var id: String { _id }

    let _id: String
    let name: String?
    var enabled: Bool?
    let isGuest: Bool?
    let security: String?
    let wpaMode: String?
    let networkId: String?
    let radioBand: String?
    let hideSSID: Bool?
    let scheduleEnabled: Bool?
    let macFilterEnabled: Bool?
    let siteId: String?

    enum CodingKeys: String, CodingKey {
        case _id, name, enabled, security
        case isGuest = "is_guest"
        case wpaMode = "wpa_mode"
        case networkId = "networkconf_id"
        case radioBand = "radio_band"
        case hideSSID = "hide_ssid"
        case scheduleEnabled = "schedule_enabled"
        case macFilterEnabled = "mac_filter_enabled"
        case siteId = "site_id"
    }

    var securityIcon: String {
        switch security {
        case "open": return "lock.open"
        default: return "lock"
        }
    }

    var bandLabel: String {
        switch radioBand {
        case "2g": return "2.4 GHz"
        case "5g": return "5 GHz"
        case "both": return "2.4 + 5 GHz"
        default: return "All Bands"
        }
    }
}

// MARK: - Traffic Reports

struct TrafficReport: Codable, Identifiable {
    var id: String { "\(time ?? 0)" }

    let time: Int?
    let wanTxBytes: Double?
    let wanRxBytes: Double?
    let wlanBytes: Double?
    let numSta: Int?

    enum CodingKeys: String, CodingKey {
        case time
        case wanTxBytes = "wan-tx_bytes"
        case wanRxBytes = "wan-rx_bytes"
        case wlanBytes = "wlan_bytes"
        case numSta = "num_sta"
    }

    var date: Date {
        guard let t = time else { return Date() }
        return Date(timeIntervalSince1970: Double(t) / 1000.0)
    }

    var totalBytes: Double { (wanTxBytes ?? 0) + (wanRxBytes ?? 0) }
}

// MARK: - DPI Stats

struct DPICategory: Codable, Identifiable {
    var id: Int { cat }

    let cat: Int
    let rxBytes: Double?
    let txBytes: Double?

    enum CodingKeys: String, CodingKey {
        case cat
        case rxBytes = "rx_bytes"
        case txBytes = "tx_bytes"
    }

    var totalBytes: Double { (rxBytes ?? 0) + (txBytes ?? 0) }

    var categoryName: String {
        switch cat {
        case 0: return "Unclassified"
        case 3: return "VoIP"
        case 4: return "Messaging"
        case 5: return "Remote Mgmt"
        case 6: return "Games"
        case 7: return "Peer-to-Peer"
        case 8: return "Streaming"
        case 9: return "File Transfer"
        case 10: return "Social Media"
        case 11: return "Advertising"
        case 12: return "Email"
        case 14: return "Network Mgmt"
        case 17: return "Video"
        case 18: return "News"
        case 255: return "Other"
        default: return "Category \(cat)"
        }
    }

    var categoryIcon: String {
        switch cat {
        case 3: return "phone.badge.waveform"
        case 4: return "message"
        case 6: return "gamecontroller"
        case 7: return "arrow.triangle.swap"
        case 8: return "play.rectangle"
        case 9: return "arrow.down.doc"
        case 10: return "person.2"
        case 12: return "envelope"
        case 17: return "video"
        default: return "globe"
        }
    }
}

// MARK: - Sites

struct UniFiSite: Codable, Identifiable {
    var id: String { _id }

    let _id: String
    let name: String?
    let desc: String?
    let role: String?

    var displayName: String { desc ?? name ?? _id }
}

// MARK: - Port Forwarding

struct PortForward: Codable, Identifiable {
    var id: String { _id }

    let _id: String
    let name: String?
    let enabled: Bool?
    let pfwdInterface: String?
    let dstPort: String?
    let fwd: String?
    let fwdPort: String?
    let proto: String?
    let siteId: String?

    enum CodingKeys: String, CodingKey {
        case _id, name, enabled, fwd, proto
        case pfwdInterface = "pfwd_interface"
        case dstPort = "dst_port"
        case fwdPort = "fwd_port"
        case siteId = "site_id"
    }

    var protoLabel: String {
        switch proto {
        case "tcp_udp": return "TCP/UDP"
        case "tcp": return "TCP"
        case "udp": return "UDP"
        default: return proto?.uppercased() ?? "-"
        }
    }
}

// MARK: - Rogue APs

struct RogueAP: Codable, Identifiable {
    var id: String { bssid ?? UUID().uuidString }

    let bssid: String?
    let essid: String?
    let channel: Int?
    let rssi: Int?
    let security: String?
    let apMac: String?
    let lastSeen: Int?
    let isRogue: Bool?

    enum CodingKeys: String, CodingKey {
        case bssid, essid, channel, rssi, security
        case apMac = "ap_mac"
        case lastSeen = "last_seen"
        case isRogue = "is_rogue"
    }
}

// MARK: - DPI Stats

struct DpiStat: Codable, Identifiable {
    var id: String { application ?? category ?? UUID().uuidString }

    let application: String?
    let category: String?
    let by: String?
    let txBytes: Double?
    let rxBytes: Double?
    let bytes: Double?

    enum CodingKeys: String, CodingKey {
        case application = "app"
        case category
        case by
        case txBytes = "tx_bytes"
        case rxBytes = "rx_bytes"
        case bytes
    }
}

// MARK: - Speed Tests

struct SpeedTestResult: Codable, Identifiable {
    var id: String { "\(timestamp ?? 0)" }

    let timestamp: Int?
    let ping: Double?
    let xputDownload: Double?
    let xputUpload: Double?
    let status: String?

    enum CodingKeys: String, CodingKey {
        case timestamp = "time"
        case ping
        case xputDownload = "xput_download"
        case xputUpload = "xput_upload"
        case status
    }
}

// MARK: - VPN Sessions

struct VpnSession: Codable, Identifiable {
    var id: String { userId ?? username ?? UUID().uuidString }

    let username: String?
    let userId: String?
    let remoteIP: String?
    let localIP: String?
    let connectedAt: Int?
    let protocolType: String?

    enum CodingKeys: String, CodingKey {
        case username
        case userId = "user_id"
        case remoteIP = "remote_ip"
        case localIP = "local_ip"
        case connectedAt = "connected_at"
        case protocolType = "protocol"
    }
}

// MARK: - Formatting Helpers

extension Double {
    func formattedBytes() -> String {
        if self >= 1_000_000_000 {
            return String(format: "%.1f GB", self / 1_000_000_000)
        } else if self >= 1_000_000 {
            return String(format: "%.1f MB", self / 1_000_000)
        } else if self >= 1_000 {
            return String(format: "%.1f KB", self / 1_000)
        }
        return String(format: "%.0f B", self)
    }

    func formattedBytesPerSecond() -> String {
        let bitsPerSec = self * 8
        if bitsPerSec >= 1_000_000 {
            return String(format: "%.1f Mb/s", bitsPerSec / 1_000_000)
        } else if bitsPerSec >= 1_000 {
            return String(format: "%.0f Kb/s", bitsPerSec / 1_000)
        }
        return String(format: "%.0f b/s", bitsPerSec)
    }
}

extension Int {
    func formattedUptime() -> String {
        let days = self / 86400
        let hours = (self % 86400) / 3600
        let minutes = (self % 3600) / 60
        if days > 0 { return "\(days)d \(hours)h" }
        if hours > 0 { return "\(hours)h \(minutes)m" }
        return "\(minutes)m"
    }
}
